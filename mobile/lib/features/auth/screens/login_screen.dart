import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";
import "../../../core/services/token_storage.dart";
import "../../../core/widgets/app_button.dart";
import "../../../core/widgets/app_input.dart";
import "../../navigation/screens/app_shell_screen.dart";
import "register_screen.dart";
import "forgot_password_screen.dart";
import "email_verification_screen.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha e-mail e senha.")));
      return;
    }
    setState(() => loading = true);
    try {
      final response = await ApiClient.post("/auth/login",
          body: {"email": email, "password": password});

      await TokenStorage.saveSession(
        token: response["access_token"],
        refreshToken: response["refresh_token"] ?? "",
        name: response["name"] ?? "",
        email: response["email"] ?? "",
      );

      if (!mounted) return;

      // Se o e-mail ainda não foi verificado, redireciona para verificação
      final emailVerified = response["email_verified"] == true;
      if (!emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: response["email"] ?? email),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AppShellScreen()),
      );
    } on EmailNotVerifiedException {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EmailVerificationScreen(email: email)),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.spa_rounded, size: 72, color: Color(0xFF6B4FD8)),
              const SizedBox(height: 18),
              const Text("Entrar no Vibra9",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
              const SizedBox(height: 8),
              const Text("Acesse sua jornada de bem-estar.",
                style: TextStyle(fontSize: 15, color: Color(0xFF6B6F8A))),
              const SizedBox(height: 36),
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
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                  child: const Text("Esqueci minha senha"),
                ),
              ),
              const SizedBox(height: 8),
              AppButton(text: "Entrar", loading: loading, onPressed: login),
              const SizedBox(height: 18),
              TextButton(
                onPressed: loading
                    ? null
                    : () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text("Ainda não tenho conta"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
