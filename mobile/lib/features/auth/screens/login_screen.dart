import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";
import "../../../core/services/token_storage.dart";
import "../../../core/widgets/app_button.dart";
import "../../../core/widgets/app_input.dart";
import "../../home/screens/home_screen.dart";
import "register_screen.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController(text: "andre@test.com");
  final passwordController = TextEditingController(text: "12345678");

  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);

    try {
      final response = await ApiClient.post(
        "/auth/login",
        body: {
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
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
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(
                Icons.spa_rounded,
                size: 72,
                color: Color(0xFF6B4FD8),
              ),
              const SizedBox(height: 18),
              const Text(
                "Entrar no Vibra9",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2544),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Acesse sua jornada de bem-estar.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B6F8A),
                ),
              ),
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
              const SizedBox(height: 26),
              AppButton(
                text: "Entrar",
                loading: loading,
                onPressed: login,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: loading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                child: const Text("Ainda não tenho conta"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
