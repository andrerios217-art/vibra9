import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";
import "privacy_policy_screen.dart";
import "terms_screen.dart";

class ConsentStatusScreen extends StatefulWidget {
  const ConsentStatusScreen({super.key});

  @override
  State<ConsentStatusScreen> createState() => _ConsentStatusScreenState();
}

class _ConsentStatusScreenState extends State<ConsentStatusScreen> {
  bool loading = true;
  Map<String, dynamic>? status;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await ApiClient.get("/lgpd/consent/status", auth: true);
      if (!mounted) return;
      setState(() { status = response; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString().replaceAll("Exception: ", ""); loading = false; });
    }
  }

  String formatDate(String? value) {
    if (value == null) return "Não registrado";
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    return "${local.day.toString().padLeft(2, "0")}/${local.month.toString().padLeft(2, "0")}/${local.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(title: const Text("Privacidade e Consentimento"), backgroundColor: const Color(0xFFF8F5FF), elevation: 0),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6B4FD8), Color(0xFF42B8B0)]),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.verified_user_rounded, color: Colors.white, size: 36),
                          SizedBox(height: 12),
                          Text("Seus consentimentos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                          SizedBox(height: 6),
                          Text("Conforme a Lei Geral de Proteção de Dados (LGPD)", style: TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ConsentCard(
                      title: "Política de Privacidade",
                      version: status!["current_privacy_policy_version"].toString(),
                      accepted: status!["privacy_policy_accepted"] == true,
                      acceptedAt: formatDate(status!["privacy_policy_accepted_at"]?.toString()),
                      icon: Icons.shield_rounded,
                      color: const Color(0xFF6B4FD8),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                    ),
                    const SizedBox(height: 14),
                    _ConsentCard(
                      title: "Termos de Uso",
                      version: status!["current_terms_version"].toString(),
                      accepted: status!["terms_accepted"] == true,
                      acceptedAt: formatDate(status!["terms_accepted_at"]?.toString()),
                      icon: Icons.gavel_rounded,
                      color: const Color(0xFF42B8B0),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8505B).withOpacity(0.07),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: Color(0xFFE8505B), size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Para revogar seu consentimento, exclua sua conta em Perfil → Excluir conta. Todos os seus dados serão removidos permanentemente.",
                              style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF1F2544)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  final String title;
  final String version;
  final bool accepted;
  final String acceptedAt;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ConsentCard({
    required this.title,
    required this.version,
    required this.accepted,
    required this.acceptedAt,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accepted ? color.withOpacity(0.3) : const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accepted ? const Color(0xFF59B36A).withOpacity(0.12) : const Color(0xFFE8505B).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  accepted ? "Aceito" : "Pendente",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                    color: accepted ? const Color(0xFF59B36A) : const Color(0xFFE8505B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text("Versão $version", style: const TextStyle(fontSize: 12, color: Color(0xFF6B6F8A))),
              const SizedBox(width: 12),
              if (accepted) ...[
                const Icon(Icons.check_circle_rounded, color: Color(0xFF59B36A), size: 14),
                const SizedBox(width: 4),
                Text("Aceito em $acceptedAt", style: const TextStyle(fontSize: 12, color: Color(0xFF6B6F8A))),
              ],
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new_rounded, color: color, size: 14),
                  const SizedBox(width: 6),
                  Text("Ler documento", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
