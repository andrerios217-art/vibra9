import "package:flutter/material.dart";

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({
    super.key,
    this.size = 96,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          "assets/images/vibra9_lotus_logo.png",
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback: ícone caso a imagem não carregue
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFF6B4FD8).withOpacity(0.12),
                borderRadius: BorderRadius.circular(size * 0.25),
              ),
              child: Icon(
                Icons.spa_rounded,
                size: size * 0.55,
                color: const Color(0xFF6B4FD8),
              ),
            );
          },
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            "Vibra9",
            style: TextStyle(
              fontSize: size * 0.32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2544),
            ),
          ),
        ],
      ],
    );
  }
}
