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
      final response = await ApiClient.get(
        "/me/export",
        auth: true,
      );

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

    await Clipboard.setData(
      ClipboardData(text: text),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Dados copiados para a área de transferência."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = data?["user"] as Map<String, dynamic>?;
    final assessments = data?["assessments"] as List<dynamic>?;
    final recommendations = data?["recommendations"] as List<dynamic>?;

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
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: Color(0xFFE8505B),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Não foi possível carregar seus dados.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1F2544),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: Color(0xFF6B6F8A),
                              ),
                            ),
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: loadData,
                              child: const Text("Tentar novamente"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: const Color(0xFF6B4FD8).withOpacity(0.12),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 78,
                              height: 78,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B4FD8).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: const Icon(
                                Icons.privacy_tip_rounded,
                                color: Color(0xFF6B4FD8),
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Transparência dos dados",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1F2544),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Veja os principais dados associados à sua conta e copie uma exportação em JSON.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.45,
                                color: Color(0xFF6B6F8A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _InfoCard(
                        title: "Conta",
                        rows: [
                          _InfoRow("Nome", user?["name"]?.toString() ?? ""),
                          _InfoRow("E-mail", user?["email"]?.toString() ?? ""),
                          _InfoRow(
                            "Assinatura",
                            user?["subscription_active"] == true
                                ? "Ativa"
                                : "Inativa",
                          ),
                          _InfoRow(
                            "Criada em",
                            user?["created_at"]?.toString() ?? "",
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
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
                          const SizedBox(width: 12),
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
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: copyJson,
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text(
                            "Copiar exportação JSON",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "A exportação ajuda na portabilidade e transparência. Dados de senha nunca são exibidos.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Color(0xFF6B6F8A),
                        ),
                      ),
                    ],
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

  const _InfoCard({
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF6B4FD8).withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2544),
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      row.label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6F8A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1F2544),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: color.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 30,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B6F8A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
