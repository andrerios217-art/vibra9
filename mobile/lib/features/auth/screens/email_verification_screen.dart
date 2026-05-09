import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";
import "../../navigation/screens/app_shell_screen.dart";

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String? devCode;
  const EmailVerificationScreen({super.key, required this.email, this.devCode});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final codeController = TextEditingController();
  bool loading = false;
  bool resending = false;
  String? successMessage;
  String? errorMessage;

  Future<void> verify() async {
    final code = codeController.text.trim();
    if (code.length != 6) {
      setState(() => errorMessage = "Digite o código de 6 dígitos.");
      return;
    }
    setState(() { loading = true; errorMessage = null; });
    try {
      await ApiClient.post("/auth/verify-email", body: {"code": code}, auth: true);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShellScreen()),
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

  Future<void> resend() async {
    setState(() { resending = true; errorMessage = null; successMessage = null; });
    try {
      final response = await ApiClient.post("/auth/resend-verification", body: {}, auth: true);
      if (!mounted) return;
      setState(() {
        successMessage = "Novo código enviado.";
        if (response["dev_code"] != null) {
          codeController.text = response["dev_code"].toString();
        }
        resending = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString().replaceAll("Exception: ", "");
        resending = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.devCode != null) {
      codeController.text = widget.devCode!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Color(0xFF6B4FD8), shape: BoxShape.circle),
                child: const Icon(Icons.mark_email_unread_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 24),
              const Text("Verifique seu e-mail",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
              const SizedBox(height: 12),
              Text(
                "Enviamos um código de 6 dígitos para\n${widget.email}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF6B6F8A)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8505B).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8505B).withOpacity(0.25)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline_rounded, color: Color(0xFFE8505B), size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text(
                      "A verificação é obrigatória. Sem ela, não é possível acessar avaliações, histórico e padrões.",
                      style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF1F2544), fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
              if (widget.devCode != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5B942).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF5B942).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.developer_mode_rounded, color: Color(0xFFF5B942), size: 18),
                      const SizedBox(width: 8),
                      Text("DEV: ${widget.devCode}",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 12, color: Color(0xFF1F2544)),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "000000",
                  hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFF6B4FD8), width: 2),
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(errorMessage!, style: const TextStyle(color: Color(0xFFE8505B), fontSize: 13)),
              ],
              if (successMessage != null) ...[
                const SizedBox(height: 12),
                Text(successMessage!, style: const TextStyle(color: Color(0xFF59B36A), fontSize: 13, fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: loading ? null : verify,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4FD8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Verificar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: resending ? null : resend,
                child: resending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Reenviar código"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
