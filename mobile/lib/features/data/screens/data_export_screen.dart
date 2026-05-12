import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "../../../core/services/api_client.dart";

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  bool loading = true;
  Map<String, dynamic>? data;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiClient.get("/me/export", auth: true);
      if (!mounted) return;
      setState(() {
        data = response;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString().replaceAll("Exception: ", "");
        loading = false;
      });
    }
  }

  Future<void> copyJson() async {
    if (data == null) return;
    const encoder = JsonEncoder.withIndent("  ");
    final text = encoder.convert(data);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Dados copiados para a área de transferência.")));
  }

  String formatDate(String? value) {
    if (value == null || value.isEmpty) return "-";
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    return "${local.day.toString().padLeft(2, "0")}/${local.month.toString().padLeft(2, "0")}/${local.year}";
  }

  String subscriptionLabel(Map<String, dynamic>? user) {
    final status = user?["subscription_status"]?.toString();
    if (status == "active") return "Ativa";
    if (status == "trial") return "Trial";
    return "Inativa";
  }

  @override
  Widget build(BuildContext context) {
    final user = data?["user"] as Map<String, dynamic>?;
    final assessments = data?["assessments"] as List<dynamic>?;
    final recommendations = data?["recommendations"] as List<dynamic>?;
    final consentHistory = data?["consent_history"] as List<dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Meus dados"),
        actions: [
          IconButton(
            tooltip: "Recarregar",
            onPressed: loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: "Copiar JSON",
            onPressed: data == null ? null : copyJson,
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? _ErrorState(message: errorMessage!, onRetry: loadData)
                : ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.12)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 70, height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B4FD8).withOpacity(0.10),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(Icons.privacy_tip_rounded, color: Color(0xFF6B4FD8), size: 38),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              "Transparência dos dados",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1F2544)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Veja os dados associados à sua conta e copie uma exportação em JSON conforme a LGPD.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF6B6F8A)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _InfoCard(
                        title: "Conta",
                        rows: [
                          _InfoRow("Nome", user?["name"]?.toString() ?? "-"),
                          _InfoRow("E-mail", user?["email"]?.toString() ?? "-"),
                          _InfoRow("E-mail verificado",
                              user?["email_verified"] == true ? "Sim" : "Não"),
                          _InfoRow("Assinatura", subscriptionLabel(user)),
                          if (user?["trial_end"] != null)
                            _InfoRow("Trial até", formatDate(user!["trial_end"].toString())),
                          _InfoRow("Criada em", formatDate(user?["created_at"]?.toString())),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _CounterCard(
                              title: "Avaliações",
                              value: "${assessments?.length ?? 0}",
                              icon: Icons.favorite_rounded,
                              color: const Color(0xFF6B4FD8),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _CounterCard(
                              title: "Recomendações",
                              value: "${recommendations?.length ?? 0}",
                              icon: Icons.check_circle_rounded,
                              color: const Color(0xFF59B36A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (consentHistory != null && consentHistory.isNotEmpty)
                        _InfoCard(
                          title: "Histórico de consentimentos",
                          rows: consentHistory.map((entry) {
                            final c = Map<String, dynamic>.from(entry);
                            final type = c["document_type"]?.toString() == "privacy_policy"
                                ? "Política"
                                : c["document_type"]?.toString() == "terms"
                                    ? "Termos"
                                    : c["document_type"]?.toString() ?? "-";
                            return _InfoRow(
                              "$type v${c["version"]}",
                              formatDate(c["accepted_at"]?.toString()),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6B4FD8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: copyJson,
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text(
                            "Copiar exportação JSON",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "A exportação ajuda na portabilidade e transparência (LGPD). Dados sensíveis como senha nunca são exibidos.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, height: 1.5, color: Color(0xFF6B6F8A)),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 44, color: Color(0xFFE8505B)),
              const SizedBox(height: 14),
              const Text(
                "Não foi possível carregar seus dados.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1F2544)),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF6B6F8A))),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text("Tentar novamente")),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  _InfoRow(this.label, this.value);
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;

  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(row.label,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: Text(row.value,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1F2544), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _CounterCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(value,
            style: TextStyle(fontSize: 26, color: color, fontWeight: FontWeight.w700)),
          Text(title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
