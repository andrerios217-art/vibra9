import "dart:async";
import "package:flutter/material.dart";

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  Timer? timer;

  int secondsLeft = 60;
  bool running = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
      lowerBound: 0.72,
      upperBound: 1.0,
    );

    controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  void start() {
    if (running) return;

    setState(() => running = true);

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft <= 1) {
        timer.cancel();

        setState(() {
          secondsLeft = 0;
          running = false;
        });

        showFinishedDialog();
      } else {
        setState(() => secondsLeft--);
      }
    });
  }

  void pause() {
    timer?.cancel();

    setState(() => running = false);
  }

  void reset() {
    timer?.cancel();

    setState(() {
      secondsLeft = 60;
      running = false;
    });
  }

  String instruction() {
    final phase = secondsLeft % 8;

    if (phase >= 4) {
      return "Solte o ar";
    }

    return "Inspire";
  }

  void showFinishedDialog() {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pausa concluída"),
          content: const Text(
            "Você completou 60 segundos de respiração. Volte ao seu dia com mais calma.",
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                reset();
              },
              child: const Text("Fechar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = secondsLeft / 60;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Pausa guiada"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 18),
              const Text(
                "Respiração de 60 segundos",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2544),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Uma pausa simples para reduzir o ruído e voltar ao presente.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Color(0xFF6B6F8A),
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: controller.value,
                    child: Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6B4FD8),
                            Color(0xFF42B8B0),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B4FD8).withOpacity(0.22),
                            blurRadius: 42,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 168,
                          height: 168,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.18),
                          ),
                          child: Center(
                            child: Text(
                              instruction(),
                              style: const TextStyle(
                                fontSize: 30,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: const Color(0xFF6B4FD8).withOpacity(0.10),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF6B4FD8),
                      ),
                    ),
                    Center(
                      child: Text(
                        "${secondsLeft}s",
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1F2544),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: reset,
                        child: const Text(
                          "Reiniciar",
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: running ? pause : start,
                        child: Text(
                          running ? "Pausar" : "Iniciar",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

