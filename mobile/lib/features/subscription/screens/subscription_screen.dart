import "package:flutter/material.dart";
import "../../navigation/screens/app_shell_screen.dart";

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  void activateDemo(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppShellScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Plano Vibra9"),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: const Color(0xFF6B4FD8).withOpacity(0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4FD8).withOpacity(0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
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
                      Icons.workspace_premium_rounded,
                      size: 46,
                      color: Color(0xFF6B4FD8),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    "Vibra9 Premium",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F2544),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Bem-estar guiado em 9 dimensões",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B6F8A),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    "R\$ 9,99/mês",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6B4FD8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Cancele quando quiser pela loja do seu dispositivo.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B6F8A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              "Incluído no plano",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1F2544),
              ),
            ),
            const SizedBox(height: 14),
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
              title: "Histórico",
              text: "Acompanhe sua evolução ao longo do tempo.",
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: () => activateDemo(context),
                child: const Text(
                  "Ativar modo demonstração",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Nesta versão de desenvolvimento, o botão ativa apenas o modo demonstração. O pagamento real será integrado depois com RevenueCat, Google Play Billing ou App Store.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF6B6F8A),
              ),
            ),
          ],
        ),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF59B36A),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2544),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Color(0xFF6B6F8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


