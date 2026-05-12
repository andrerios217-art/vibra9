import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";
import "../../../core/services/token_storage.dart";
import "../../../core/widgets/app_button.dart";
import "../../../core/widgets/app_input.dart";
import "../../lgpd/screens/privacy_policy_screen.dart";
import "../../lgpd/screens/terms_screen.dart";
import "email_verification_screen.dart";

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  bool privacyOpened = false;
  bool privacyAccepted = false;
  bool termsOpened = false;
  bool termsAccepted = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> openPrivacyPolicy() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen(showAcceptButton: true)),
    );
    setState(() {
      privacyOpened = true;
      if (result == true) privacyAccepted = true;
    });
  }

  Future<void> openTerms() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TermsScreen(showAcceptButton: true)),
    );
    setState(() {
      termsOpened = true;
      if (result == true) termsAccepted = true;
    });
  }

  bool _isPasswordValid(String password) {
    if (password.length < 8) return false;
    final hasLetter = RegExp(r"[A-Za-z]").hasMatch(password);
    final hasDigit = RegExp(r"\d").hasMatch(password);
    return hasLetter && hasDigit;
  }

  Future<void> register() async {
    if (!privacyAccepted || !termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Leia e aceite a política de privacidade e os termos de uso.")));
      return;
    }
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos.")));
      return;
    }
    if (!_isPasswordValid(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("A senha precisa ter ao menos 8 caracteres, com letra e número.")));
      return;
    }
    setState(() => loading = true);
    try {
      final response = await ApiClient.post("/auth/register", body: {
        "name": name,
        "email": email,
        "password": password,
        "privacy_policy_accepted": true,
        "terms_accepted": true,
      });
      await TokenStorage.saveSession(
        token: response["access_token"],
        refreshToken: response["refresh_token"] ?? "",
        name: response["name"] ?? "",
        email: response["email"] ?? "",
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: email,
            devCode: response["dev_code"]?.toString(),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll("Exception: ", ""))));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Criar conta")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text("Bem-vindo ao Vibra9",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
              const SizedBox(height: 8),
              const Text(
                "Crie sua conta para começar sua jornada de bem-estar.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF6B6F8A)),
              ),
              const SizedBox(height: 28),
              AppInput(controller: nameController, label: "Nome", icon: Icons.person_outline),
              const SizedBox(height: 14),
              AppInput(controller: emailController, label: "E-mail", icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              AppInput(
                controller: passwordController,
                label: "Senha",
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  "Mínimo 8 caracteres, com pelo menos uma letra e um número.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B6F8A)),
                ),
              ),
              const SizedBox(height: 24),
              _ConsentTile(
                label: "Política de Privacidade",
                description: "Leia o documento para liberar o aceite.",
                icon: Icons.shield_rounded,
                color: const Color(0xFF6B4FD8),
                opened: privacyOpened,
                accepted: privacyAccepted,
                onOpen: openPrivacyPolicy,
                onToggle: privacyOpened ? (v) => setState(() => privacyAccepted = v) : null,
              ),
              const SizedBox(height: 12),
              _ConsentTile(
                label: "Termos de Uso",
                description: "Leia o documento para liberar o aceite.",
                icon: Icons.gavel_rounded,
                color: const Color(0xFF42B8B0),
                opened: termsOpened,
                accepted: termsAccepted,
                onOpen: openTerms,
                onToggle: termsOpened ? (v) => setState(() => termsAccepted = v) : null,
              ),
              const SizedBox(height: 24),
              AppButton(text: "Criar conta", loading: loading, onPressed: register),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final bool opened;
  final bool accepted;
  final VoidCallback onOpen;
  final ValueChanged<bool>? onToggle;

  const _ConsentTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.opened,
    required this.accepted,
    required this.onOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = accepted
        ? color.withOpacity(0.4)
        : opened
            ? color.withOpacity(0.2)
            : const Color(0xFFE0E0E0);

    final Color bgColor = accepted ? color.withOpacity(0.06) : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Icon(icon, color: opened ? color : Colors.grey.shade400, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: opened ? color : Colors.grey.shade500,
                      )),
                      const SizedBox(height: 3),
                      Text(
                        opened ? (accepted ? "Aceito ✓" : "Lido — marque para aceitar") : description,
                        style: TextStyle(
                          fontSize: 11,
                          color: accepted
                              ? color.withOpacity(0.8)
                              : opened
                                  ? const Color(0xFF6B6F8A)
                                  : Colors.grey.shade400,
                          fontWeight: accepted ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    value: accepted,
                    activeColor: color,
                    side: BorderSide(
                      color: onToggle != null ? color.withOpacity(0.5) : Colors.grey.shade300,
                    ),
                    onChanged: onToggle != null ? (v) => onToggle!(v ?? false) : null,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onOpen,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: opened
                    ? color.withOpacity(0.07)
                    : const Color(0xFF6B4FD8).withOpacity(0.04),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    opened ? Icons.refresh_rounded : Icons.open_in_new_rounded,
                    color: opened ? color : Colors.grey.shade400,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    opened ? "Ler novamente" : "Ler documento — obrigatório",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: opened ? color : Colors.grey.shade400,
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
