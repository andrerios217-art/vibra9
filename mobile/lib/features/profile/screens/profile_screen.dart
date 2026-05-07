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
          final days = end.difference(DateTime.now()).inDays;
          if (days >= 0) return "Trial — $days dias restantes";
        }
      }
      return "Trial";
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir conta?"),
        content: const Text("Essa ação removerá sua conta, avaliações e recomendações salvas. Não será possível desfazer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE8505B)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );
    if (confirmed == true) await deleteAccount();
  }

  Future<void> deleteAccount() async {
    setState(() => deleting = true);
    try {
      await ApiClient.delete("/me", auth: true);
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
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.12)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 82, height: 82,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4FD8).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Icon(Icons.person_rounded, size: 46, color: Color(0xFF6B4FD8)),
                        ),
                        const SizedBox(height: 16),
                        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1F2544))),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(fontSize: 15, color: Color(0xFF6B6F8A))),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: subscriptionColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(subscriptionLabel, style: TextStyle(fontWeight: FontWeight.w800, color: subscriptionColor)),
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
                  _ProfileTile(icon: Icons.verified_user_rounded, label: "Privacidade e Consentimento",
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
                    height: 54,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE8505B),
                        side: const BorderSide(color: Color(0xFFE8505B)),
                      ),
                      onPressed: deleting ? null : confirmDeleteAccount,
                      icon: deleting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.delete_outline_rounded),
                      label: Text(deleting ? "Excluindo..." : "Excluir minha conta",
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "A exclusão remove sua conta e todos os dados associados permanentemente.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF6B6F8A)),
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
      title: Text(label, style: color != null ? TextStyle(color: color, fontWeight: FontWeight.w700) : null),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
