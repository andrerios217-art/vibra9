import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final tokenController = TextEditingController();
  final passwordController = TextEditingController();

  bool loadingRequest = false;
  bool loadingReset = false;
  String? message;
  String? devToken;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    tokenController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> requestReset() async {
    setState(() {
      loadingRequest = true;
      errorMessage = null;
      message = null;
      devToken = null;
    });

    try {
      final response = await ApiClient.post(
        "/auth/request-password-reset",
        body: {
          "email": emailController.text.trim(),
        },
      );

      if (!mounted) return;

      setState(() {
        message = response["message"]?.toString();
        devToken = response["dev_reset_token"]?.toString();

        if (devToken != null) {
          tokenController.text = devToken!;
        }

        loadingRequest = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceAll("Exception: ", "");
        loadingRequest = false;
      });
    }
  }

  Future<void> resetPassword() async {
    setState(() {
      loadingReset = true;
      errorMessage = null;
      message = null;
    });

    try {
      final response = await ApiClient.post(
        "/auth/reset-password",
        body: {
          "token": tokenController.text.trim(),
          "new_password": passwordController.text,
        },
      );

      if (!mounted) return;

      setState(() {
        message = response["message"]?.toString();
        loadingReset = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceAll("Exception: ", "");
        loadingReset = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Recuperar senha"),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_reset_rounded,
                    color: Color(0xFF6B4FD8),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Esqueceu sua senha?",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F2544),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Informe seu e-mail para gerar um código de redefinição. Em produção, esse código será enviado por e-mail.",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF6B6F8A),
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "E-mail",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: loadingRequest ? null : requestReset,
                      child: loadingRequest
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              "Gerar código",
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (devToken != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5B942).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  "Modo desenvolvimento: o código foi preenchido automaticamente.",
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF1F2544),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Definir nova senha",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F2544),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tokenController,
                    decoration: const InputDecoration(
                      labelText: "Código de redefinição",
                      prefixIcon: Icon(Icons.vpn_key_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Nova senha",
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: loadingReset ? null : resetPassword,
                      child: loadingReset
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              "Redefinir senha",
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              _InfoBox(
                text: message!,
                success: true,
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              _InfoBox(
                text: errorMessage!,
                success: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  final bool success;

  const _InfoBox({
    required this.text,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    final color = success ? const Color(0xFF59B36A) : const Color(0xFFE8505B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
