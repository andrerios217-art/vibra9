import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";
import "../../../core/services/token_storage.dart";
import "../../../core/widgets/app_button.dart";
import "../../../core/widgets/app_input.dart";
import "../../navigation/screens/app_shell_screen.dart";

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController(text: "Andre");
  final emailController = TextEditingController();
  final passwordController = TextEditingController(text: "12345678");

  bool loading = false;
  bool accepted = true;

  Future<void> register() async {
    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aceite os termos para continuar.")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final response = await ApiClient.post(
        "/auth/register",
        body: {
          "name": nameController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
          "privacy_policy_accepted": true,
          "terms_accepted": true,
        },
      );

      await TokenStorage.saveSession(
        token: response["access_token"],
        name: response["name"],
        email: response["email"],
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AppShellScreen()),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll("Exception: ", ""))),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final randomEmail = "andre${DateTime.now().millisecondsSinceEpoch}@test.com";

    if (emailController.text.isEmpty) {
      emailController.text = randomEmail;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Criar conta"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "Comece sua avaliação",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2544),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Crie sua conta para salvar seu histórico.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B6F8A),
                ),
              ),
              const SizedBox(height: 30),
              AppInput(
                controller: nameController,
                label: "Nome",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              AppInput(
                controller: emailController,
                label: "E-mail",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              AppInput(
                controller: passwordController,
                label: "Senha",
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: accepted,
                onChanged: (value) {
                  setState(() => accepted = value ?? false);
                },
                title: const Text(
                  "Aceito os termos de uso e a política de privacidade.",
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              AppButton(
                text: "Criar conta",
                loading: loading,
                onPressed: register,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


