import "package:flutter/material.dart";
import "../../features/subscription/screens/subscription_screen.dart";

class TrialBanner extends StatelessWidget {
  final int daysRemaining;

  const TrialBanner({super.key, required this.daysRemaining});

  @override
  Widget build(BuildContext context) {
    final bool urgent = daysRemaining <= 1;
    final Color color = urgent ? const Color(0xFFE8505B) : const Color(0xFFF5B942);
    final String message = daysRemaining == 0
        ? "Seu trial encerra hoje."
        : daysRemaining == 1
            ? "Último dia de trial."
            : "$daysRemaining dias restantes no trial.";

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.30)),
        ),
        child: Row(
          children: [
            Icon(urgent ? Icons.warning_amber_rounded : Icons.access_time_rounded, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                  const Text("Assine para continuar usando o Vibra9.",
                    style: TextStyle(fontSize: 12, color: Color(0xFF4A4A6A))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
