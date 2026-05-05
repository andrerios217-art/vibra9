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
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          const Text(
            "Vibra9",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2544),
            ),
          ),
        ],
      ],
    );
  }
}
