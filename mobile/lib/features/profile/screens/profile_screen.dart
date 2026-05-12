import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";
import "../../../core/services/token_storage.dart";
import "../../auth/screens/login_screen.dart";
import "../../data/screens/data_export_screen.dart";
import "../../help/screens/help_safety_screen.dart";
import "../../subscription/screens/subscription_screen.dart";
import "../../lgpd/screens/privacy_policy_screen.dart";
import "../../lgpd/screens/terms_screen.dart";
import "../../lgpd/screens/consent_status_screen.dart";

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;
  bool deleting = false;
  String name = "";
  String email = "";
  String subscriptionStatus = "trial";
  String? trialEnd;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final response = await ApiClient.get("/me", auth: true);
      if (!mounted) return;
      setState(() {
        name = response["name"] ?? "";
        email = response["email"] ?? "";
        subscriptionStatus = response["subscription_status"] ?? "trial";
        trialEnd = response["trial_end"]?.toString();
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll("Exception: ", ""))));
    }
  }

  String get subscriptionLabel {
    if (subscriptionStatus == "active") return "Assinatura ativa";
    if (subscriptionStatus == "trial") {
      if (trialEnd != null) {
        final end = DateTime.tryParse(trialEnd!);
        if (end != null) {
          final hours = end.difference(DateTime.now()).inHours;
          if (hours < 0) return "Trial expirado";
          if (hours < 24) return "Trial — menos de 1 dia restante";
          final days = (hours / 24).floor();
          return "Trial — $days ${days == 1 ? 'dia' : 'dias'} restantes";
        }
      }
      return "Trial ativo";
    }
    return "Assinatura inativa";
  }

  Color get subscriptionColor {
    if (subscriptionStatus == "active") return const Color(0xFF59B36A);
    if (subscriptionStatus == "trial") return const Color(0xFFF5B942);
    return const Color(0xFFE8505B);
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> confirmDeleteAccount() async {
    final passwordController = TextEditingController();
    String? errorText;

    final confirmed = await showDialog<String?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Excluir conta?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Essa ação removerá sua conta, avaliações, recomendações e consentimentos. Não será possível desfazer.",
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                "Digite sua senha para confirmar:",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2544)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Senha",
                  errorText: errorText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE8505B)),
              onPressed: () {
                if (passwordController.text.isEmpty) {
                  setDialogState(() => errorText = "Digite sua senha.");
                  return;
                }
                Navigator.pop(context, passwordController.text);
              },
              child: const Text("Excluir"),
            ),
          ],
        ),
      ),
    );

    if (confirmed != null && confirmed.isNotEmpty) {
      await deleteAccount(confirmed);
    }
  }

  Future<void> deleteAccount(String password) async {
    setState(() => deleting = true);
    try {
      await ApiClient.delete("/me", auth: true, body: {"password": password});
      await TokenStorage.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll("Exception: ", ""))));
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.10)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 78, height: 78,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4FD8).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.person_rounded, size: 42, color: Color(0xFF6B4FD8)),
                        ),
                        const SizedBox(height: 14),
                        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(fontSize: 14, color: Color(0xFF6B6F8A))),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: subscriptionColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(subscriptionLabel,
                            style: TextStyle(fontWeight: FontWeight.w700, color: subscriptionColor, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ProfileTile(icon: Icons.help_outline_rounded, label: "Ajuda e segurança",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSafetyScreen()))),
                  const Divider(),
                  _ProfileTile(icon: Icons.download_rounded, label: "Exportar meus dados",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataExportScreen()))),
                  const Divider(),
                  _ProfileTile(icon: Icons.workspace_premium_outlined, label: "Plano e assinatura",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()))),
                  const Divider(),
                  _ProfileTile(icon: Icons.verified_user_rounded, label: "Privacidade e consentimento",
                    color: const Color(0xFF6B4FD8),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsentStatusScreen()))),
                  const Divider(),
                  _ProfileTile(icon: Icons.shield_rounded, label: "Política de Privacidade",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
                  const Divider(),
                  _ProfileTile(icon: Icons.gavel_rounded, label: "Termos de Uso",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()))),
                  const Divider(),
                  _ProfileTile(icon: Icons.logout_rounded, label: "Sair da conta", onTap: logout),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE8505B),
                        side: const BorderSide(color: Color(0xFFE8505B)),
                      ),
                      onPressed: deleting ? null : confirmDeleteAccount,
                      icon: deleting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.delete_outline_rounded, size: 20),
                      label: Text(deleting ? "Excluindo..." : "Excluir minha conta",
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "A exclusão remove permanentemente sua conta e todos os dados associados. Será solicitada sua senha para confirmar.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, height: 1.5, color: Color(0xFF6B6F8A)),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label,
        style: color != null
          ? TextStyle(color: color, fontWeight: FontWeight.w600)
          : const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
