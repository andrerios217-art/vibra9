import "dart:async";
import "dart:math" as math;
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

  // Ciclo de respiração: 4s inspirar + 4s soltar = 8s total
  static const int cycleSeconds = 8;
  static const int totalSeconds = 60;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
      lowerBound: 0.72,
      upperBound: 1.0,
    );
    // Não roda automaticamente — só anima durante a sessão
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
    controller.repeat(reverse: true);

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft <= 1) {
        t.cancel();
        controller.stop();
        controller.value = 0.72;
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
    controller.stop();
    setState(() => running = false);
  }

  void reset() {
    timer?.cancel();
    controller.stop();
    controller.value = 0.72;
    setState(() {
      secondsLeft = totalSeconds;
      running = false;
    });
  }

  String instruction() {
    if (!running) return "Pronto?";
    // Calcula em qual fase do ciclo estamos baseado no tempo decorrido
    final elapsed = totalSeconds - secondsLeft;
    final phase = elapsed % cycleSeconds;
    return phase < 4 ? "Inspire" : "Solte o ar";
  }

  Future<bool> _confirmExit() async {
    if (!running) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sair da pausa?"),
        content: const Text("Sua respiração será interrompida."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Continuar")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE8505B)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sair"),
          ),
        ],
      ),
    );
    return confirmed == true;
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
    final progress = secondsLeft / totalSeconds;

    return PopScope(
      canPop: !running,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmExit()) {
          pause();
          if (mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F5FF),
        appBar: AppBar(
          title: const Text("Pausa guiada"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              if (await _confirmExit()) {
                pause();
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Text(
                  "Respiração de 60 segundos",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2544),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Uma pausa simples para reduzir o ruído e voltar ao presente.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF6B6F8A)),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: running ? controller.value : 0.85,
                      child: Container(
                        width: 220, height: 220,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF6B4FD8), Color(0xFF42B8B0)],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 160, height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.18),
                            ),
                            child: Center(
                              child: Text(
                                instruction(),
                                style: const TextStyle(
                                  fontSize: 26,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 130, height: 130,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: _ArcPainter(
                          value: progress,
                          color: const Color(0xFF6B4FD8),
                        ),
                      ),
                      Center(
                        child: Text(
                          "${secondsLeft}s",
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
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
                        height: 50,
                        child: OutlinedButton(
                          onPressed: reset,
                          child: const Text(
                            "Reiniciar",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6B4FD8),
                          ),
                          onPressed: running ? pause : start,
                          child: Text(
                            running ? "Pausar" : "Iniciar",
                            style: const TextStyle(fontWeight: FontWeight.w700),
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
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value;
  final Color color;
  _ArcPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const sw = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - sw) / 2;
    final bg = Paint()..color = color.withOpacity(0.12)..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round;
    final fg = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.75, math.pi * 1.5, false, bg);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.75, math.pi * 1.5 * value, false, fg);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.value != value || old.color != color;
}
