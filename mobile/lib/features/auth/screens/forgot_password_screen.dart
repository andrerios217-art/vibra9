import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";
import "login_screen.dart";

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final tokenController = TextEditingController();
  final newPasswordController = TextEditingController();
  bool loading = false;
  bool step2 = false;
  String? devToken;
  String? errorMessage;

  Future<void> requestReset() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() => errorMessage = "Digite seu e-mail.");
      return;
    }
    setState(() { loading = true; errorMessage = null; });
    try {
      final response = await ApiClient.post("/auth/forgot-password", body: {"email": email});
      if (!mounted) return;
      setState(() {
        step2 = true;
        loading = false;
        if (response["dev_token"] != null) {
          devToken = response["dev_token"].toString();
          tokenController.text = devToken!;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString().replaceAll("Exception: ", "");
        loading = false;
      });
    }
  }

  Future<void> resetPassword() async {
    final token = tokenController.text.trim();
    final newPassword = newPasswordController.text.trim();
    if (token.isEmpty || newPassword.isEmpty) {
      setState(() => errorMessage = "Preencha todos os campos.");
      return;
    }
    if (newPassword.length < 8) {
      setState(() => errorMessage = "A senha deve ter pelo menos 8 caracteres.");
      return;
    }
    setState(() { loading = true; errorMessage = null; });
    try {
      await ApiClient.post("/auth/reset-password", body: {"token": token, "new_password": newPassword});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Senha redefinida! Faça login com a nova senha.")));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString().replaceAll("Exception: ", "");
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(title: const Text("Recuperar senha"), backgroundColor: const Color(0xFFF8F5FF), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF6B4FD8).withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: !step2 ? const Color(0xFF6B4FD8) : Colors.grey.shade300,
                      radius: 14,
                      child: Text("1", style: TextStyle(color: !step2 ? Colors.white : Colors.grey, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 8),
                    const Text("Informe o e-mail", style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 16),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF6B4FD8)),
                    const SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: step2 ? const Color(0xFF6B4FD8) : Colors.grey.shade300,
                      radius: 14,
                      child: Text("2", style: TextStyle(color: step2 ? Colors.white : Colors.grey, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 8),
                    const Text("Nova senha", style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (!step2) ...[
                const Text("Qual é o seu e-mail?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1F2544))),
                const SizedBox(height: 8),
                const Text("Enviaremos um token para redefinir sua senha.", style: TextStyle(fontSize: 15, color: Color(0xFF6B6F8A))),
                const SizedBox(height: 28),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "E-mail",
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : requestReset,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6B4FD8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Enviar instruções", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ] else ...[
                const Text("Redefina sua senha", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1F2544))),
                const SizedBox(height: 8),
                const Text("Use o token recebido para criar uma nova senha.", style: TextStyle(fontSize: 15, color: Color(0xFF6B6F8A))),
                if (devToken != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5B942).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF5B942).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.developer_mode_rounded, color: Color(0xFFF5B942), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text("DEV token: $devToken", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1F2544)))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextField(
                  controller: tokenController,
                  decoration: InputDecoration(
                    labelText: "Token de redefinição",
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Nova senha (mínimo 8 caracteres)",
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : resetPassword,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6B4FD8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Redefinir senha", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFE8505B).withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFE8505B), size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(errorMessage!, style: const TextStyle(fontSize: 13, color: Color(0xFFE8505B)))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
