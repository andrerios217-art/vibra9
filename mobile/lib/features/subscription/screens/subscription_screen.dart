import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";
import "../../navigation/screens/app_shell_screen.dart";

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool loading = true;
  String subscriptionStatus = "trial";
  int? trialDaysLeft;

  @override
  void initState() {
    super.initState();
    loadStatus();
  }

  Future<void> loadStatus() async {
    try {
      final response = await ApiClient.get("/me", auth: true);
      if (!mounted) return;
      final status = response["subscription_status"]?.toString() ?? "trial";
      int? days;
      final trialEnd = response["trial_end"]?.toString();
      if (status == "trial" && trialEnd != null) {
        final end = DateTime.tryParse(trialEnd);
        if (end != null) {
          days = end.difference(DateTime.now()).inDays;
        }
      }
      setState(() {
        subscriptionStatus = status;
        trialDaysLeft = days;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  void activateDemo() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppShellScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = subscriptionStatus == "active";
    final isTrial = subscriptionStatus == "trial";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(title: const Text("Plano Vibra9")),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  if (isActive) _ActiveStatusCard(),
                  if (isTrial && trialDaysLeft != null) _TrialStatusCard(daysLeft: trialDaysLeft!),
                  if (isActive || (isTrial && trialDaysLeft != null)) const SizedBox(height: 16),
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
                          width: 76, height: 76,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4FD8).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, size: 42, color: Color(0xFF6B4FD8)),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Vibra9 Premium",
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF1F2544)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Bem-estar guiado em 9 dimensões",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Color(0xFF6B6F8A)),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          "R\$ 9,99/mês",
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF6B4FD8)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Cancele quando quiser pela loja do seu dispositivo.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B6F8A)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    "Como funciona",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2544)),
                  ),
                  const SizedBox(height: 12),
                  const _StepTile(
                    number: "1",
                    title: "Trial gratuito de 7 dias",
                    text: "Acesso completo a todas as funcionalidades sem nenhuma cobrança.",
                  ),
                  const _StepTile(
                    number: "2",
                    title: "Continue com a assinatura",
                    text: "Após os 7 dias, assine por R\$ 9,99/mês para continuar usando.",
                  ),
                  const _StepTile(
                    number: "3",
                    title: "Cancele a qualquer momento",
                    text: "Sem multa, sem fidelidade. O cancelamento é feito direto na loja.",
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    "Incluído no plano",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2544)),
                  ),
                  const SizedBox(height: 12),
                  const _BenefitTile(
                    icon: Icons.check_circle_rounded,
                    title: "Avaliação diária",
                    text: "Responda 9 perguntas rápidas e acompanhe seu momento.",
                  ),
                  const _BenefitTile(
                    icon: Icons.insights_rounded,
                    title: "Resultado personalizado",
                    text: "Veja seu índice geral, foco do dia e dimensões em destaque.",
                  ),
                  const _BenefitTile(
                    icon: Icons.favorite_rounded,
                    title: "Ações práticas",
                    text: "Receba orientações simples e seguras para o seu dia.",
                  ),
                  const _BenefitTile(
                    icon: Icons.history_rounded,
                    title: "Histórico e evolução",
                    text: "Acompanhe sua evolução ao longo do tempo com gráficos.",
                  ),
                  const _BenefitTile(
                    icon: Icons.account_tree_rounded,
                    title: "Mapa de padrões",
                    text: "Descubra padrões recorrentes nas suas avaliações.",
                  ),
                  const SizedBox(height: 22),
                  if (!isActive)
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6B4FD8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: activateDemo,
                        child: const Text(
                          "Ativar modo demonstração",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    "Versão de desenvolvimento: o botão ativa apenas o modo demonstração. O pagamento real será integrado com Google Play Billing e App Store.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, height: 1.5, color: Color(0xFF6B6F8A)),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ActiveStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF59B36A).withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF59B36A).withOpacity(0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF59B36A), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Sua assinatura está ativa.",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2544)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrialStatusCard extends StatelessWidget {
  final int daysLeft;
  const _TrialStatusCard({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final urgent = daysLeft <= 3;
    final color = urgent ? const Color(0xFFE8505B) : const Color(0xFFF5B942);
    final message = daysLeft <= 0
        ? "Seu trial encerrou."
        : daysLeft == 1
            ? "Último dia de trial."
            : "$daysLeft dias restantes no seu trial.";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(urgent ? Icons.warning_amber_rounded : Icons.access_time_rounded, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String number;
  final String title;
  final String text;

  const _StepTile({required this.number, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(color: Color(0xFF6B4FD8), shape: BoxShape.circle),
            child: Center(
              child: Text(number,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
                const SizedBox(height: 3),
                Text(text,
                  style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF6B6F8A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF59B36A).withOpacity(0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF59B36A), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
                const SizedBox(height: 3),
                Text(text,
                  style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF6B6F8A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
