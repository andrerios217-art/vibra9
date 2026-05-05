import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";
import "../../../core/services/token_storage.dart";
import "../../auth/screens/login_screen.dart";
import "../../data/screens/data_export_screen.dart";
import "../../help/screens/help_safety_screen.dart";
import "../../subscription/screens/subscription_screen.dart";

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
  bool subscriptionActive = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final response = await ApiClient.get(
        "/me",
        auth: true,
      );

      if (!mounted) return;

      setState(() {
        name = response["name"] ?? "";
        email = response["email"] ?? "";
        subscriptionActive = response["subscription_active"] == true;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll("Exception: ", "")),
        ),
      );
    }
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
      builder: (context) {
        return AlertDialog(
          title: const Text("Excluir conta?"),
          content: const Text(
            "Essa ação removerá sua conta, avaliações e recomendações salvas. Não será possível desfazer.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Color(0xFFE8505B),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Excluir"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await deleteAccount();
    }
  }

  Future<void> deleteAccount() async {
    setState(() => deleting = true);

    try {
      await ApiClient.delete(
        "/me",
        auth: true,
      );

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
        SnackBar(
          content: Text(error.toString().replaceAll("Exception: ", "")),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => deleting = false);
      }
    }
  }

  void openPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LegalTextScreen(
          title: "Política de Privacidade",
          content: """
O Vibra9 coleta apenas os dados necessários para funcionamento do app: nome, e-mail, senha protegida, avaliações e recomendações geradas.

Os dados são usados para autenticação, histórico de avaliações e funcionamento da experiência de bem-estar.

O usuário pode solicitar ou realizar a exclusão da conta e dos dados associados diretamente pelo app.

Este app oferece orientações gerais de bem-estar e autoconhecimento. Não substitui acompanhamento médico, psicológico, financeiro ou terapêutico.
""",
        ),
      ),
    );
  }

  void openTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LegalTextScreen(
          title: "Termos de Uso",
          content: """
Ao usar o Vibra9, você entende que o app oferece conteúdo geral de bem-estar, reflexão e organização pessoal.

O Vibra9 não realiza diagnósticos, tratamentos, prescrições ou aconselhamento profissional.

A assinatura, quando ativada, dará acesso aos recursos premium do app conforme as regras da App Store ou Google Play.

Você é responsável pelas informações inseridas e pelo uso adequado das orientações fornecidas.
""",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
      ),
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF6B4FD8).withOpacity(0.12),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4FD8).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 46,
                            color: Color(0xFF6B4FD8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1F2544),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B6F8A),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: subscriptionActive
                                ? const Color(0xFF59B36A).withOpacity(0.12)
                                : const Color(0xFFE8505B).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            subscriptionActive
                                ? "Assinatura ativa"
                                : "Assinatura inativa",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: subscriptionActive
                                  ? const Color(0xFF59B36A)
                                  : const Color(0xFFE8505B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.help_outline_rounded),
                    title: const Text("Ajuda e segurança"),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HelpSafetyScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.download_rounded),
                    title: const Text("Exportar meus dados"),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DataExportScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.workspace_premium_outlined),
                    title: const Text("Plano e assinatura"),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SubscriptionScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text("Política de Privacidade"),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: openPrivacy,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: const Text("Termos de Uso"),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: openTerms,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text("Sair da conta"),
                    onTap: logout,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE8505B),
                        side: const BorderSide(
                          color: Color(0xFFE8505B),
                        ),
                      ),
                      onPressed: deleting ? null : confirmDeleteAccount,
                      icon: deleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline_rounded),
                      label: Text(
                        deleting ? "Excluindo..." : "Excluir minha conta",
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "A exclusão remove sua conta e dados associados do banco local do Vibra9.",
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

class LegalTextScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalTextScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.55,
                color: Color(0xFF1F2544),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




