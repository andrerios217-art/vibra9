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
    setState(() { loading = true; error = null; });
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
      appBar: AppBar(
        title: const Text("Privacidade e Consentimento"),
        backgroundColor: const Color(0xFFF8F5FF),
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFE8505B), size: 40),
                        const SizedBox(height: 12),
                        Text(error!, textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFE8505B))),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: load, child: const Text("Tentar novamente")),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final needsReacceptance = status!["needs_reacceptance"] == true;
    final userPrivacyVersion = status!["privacy_policy_version"]?.toString();
    final userTermsVersion = status!["terms_version"]?.toString();
    final currentPrivacyVersion = status!["current_privacy_policy_version"].toString();
    final currentTermsVersion = status!["current_terms_version"].toString();

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6B4FD8), Color(0xFF42B8B0)]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.white, size: 32),
              SizedBox(height: 10),
              Text("Seus consentimentos",
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white)),
              SizedBox(height: 4),
              Text("Conforme a Lei Geral de Proteção de Dados (LGPD)",
                style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ),
        if (needsReacceptance) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5B942).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF5B942).withOpacity(0.4)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFFF5B942), size: 18),
                SizedBox(width: 10),
                Expanded(child: Text(
                  "Os documentos foram atualizados. Por favor, leia e aceite a versão mais recente.",
                  style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF1F2544), fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        _ConsentCard(
          title: "Política de Privacidade",
          userVersion: userPrivacyVersion,
          currentVersion: currentPrivacyVersion,
          accepted: status!["privacy_policy_accepted"] == true,
          acceptedAt: formatDate(status!["privacy_policy_accepted_at"]?.toString()),
          icon: Icons.shield_rounded,
          color: const Color(0xFF6B4FD8),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
        ),
        const SizedBox(height: 12),
        _ConsentCard(
          title: "Termos de Uso",
          userVersion: userTermsVersion,
          currentVersion: currentTermsVersion,
          accepted: status!["terms_accepted"] == true,
          acceptedAt: formatDate(status!["terms_accepted_at"]?.toString()),
          icon: Icons.gavel_rounded,
          color: const Color(0xFF42B8B0),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE8505B).withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFFE8505B), size: 16),
              SizedBox(width: 10),
              Expanded(child: Text(
                "Para revogar seu consentimento, exclua sua conta em Perfil → Excluir minha conta. Todos os dados serão removidos permanentemente.",
                style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF1F2544)))),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsentCard extends StatelessWidget {
  final String title;
  final String? userVersion;
  final String currentVersion;
  final bool accepted;
  final String acceptedAt;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ConsentCard({
    required this.title,
    required this.userVersion,
    required this.currentVersion,
    required this.accepted,
    required this.acceptedAt,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final outdated = accepted && userVersion != null && userVersion != currentVersion;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: outdated
              ? const Color(0xFFF5B942).withOpacity(0.4)
              : accepted
                  ? color.withOpacity(0.25)
                  : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: outdated
                      ? const Color(0xFFF5B942).withOpacity(0.12)
                      : accepted
                          ? const Color(0xFF59B36A).withOpacity(0.12)
                          : const Color(0xFFE8505B).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  outdated ? "Desatualizado" : accepted ? "Aceito" : "Pendente",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: outdated
                        ? const Color(0xFFF5B942)
                        : accepted
                            ? const Color(0xFF59B36A)
                            : const Color(0xFFE8505B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (accepted) ...[
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text("Aceito em $acceptedAt",
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B6F8A))),
                Text("Versão aceita: ${userVersion ?? "-"}",
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B6F8A))),
                Text("Versão atual: $currentVersion",
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B6F8A))),
              ],
            ),
          ] else ...[
            Text("Versão atual: $currentVersion",
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B6F8A))),
          ],
          const SizedBox(height: 12),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new_rounded, color: color, size: 13),
                  const SizedBox(width: 6),
                  Text("Ler documento",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
