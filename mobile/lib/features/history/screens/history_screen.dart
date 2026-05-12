import "dart:math" as math;
import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";
import "../../assessment/screens/assessment_screen.dart";
import "history_detail_screen.dart";

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool loading = true;
  List<dynamic> items = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    setState(() { loading = true; errorMessage = null; });
    try {
      final response = await ApiClient.get("/history/with-patterns", auth: true);
      if (!mounted) return;
      setState(() {
        items = response["items"] as List<dynamic>;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString().replaceAll("Exception: ", "");
        loading = false;
      });
    }
  }

  Color scoreColor(int score) {
    if (score <= 40) return const Color(0xFFE8505B);
    if (score <= 70) return const Color(0xFFF5B942);
    return const Color(0xFF59B36A);
  }

  String scoreLabel(int score) {
    if (score <= 40) return "Atenção";
    if (score <= 70) return "Em desenvolvimento";
    return "Equilibrado";
  }

  String formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    return "${local.day.toString().padLeft(2, "0")}/${local.month.toString().padLeft(2, "0")} às ${local.hour.toString().padLeft(2, "0")}:${local.minute.toString().padLeft(2, "0")}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Histórico"),
        actions: [
          IconButton(
            onPressed: loadHistory,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Atualizar",
          ),
        ],
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? _ErrorState(message: errorMessage!, onRetry: loadHistory)
                : RefreshIndicator(
                    onRefresh: loadHistory,
                    child: items.isEmpty
                        ? _EmptyState(onAssessment: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AssessmentScreen())).then((_) => loadHistory()))
                        : ListView(
                            padding: const EdgeInsets.all(22),
                            children: [
                              _IntroCard(count: items.length),
                              const SizedBox(height: 16),
                              ...items.map((item) {
                                final assessment = Map<String, dynamic>.from(item);
                                final score = assessment["general_score"] as int;
                                final patterns = assessment["patterns"] as List<dynamic>;
                                final assessmentId = assessment["id"].toString();
                                return _HistoryCard(
                                  assessmentId: assessmentId,
                                  score: score,
                                  color: scoreColor(score),
                                  label: scoreLabel(score),
                                  date: formatDate(assessment["created_at"].toString()),
                                  patterns: patterns,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HistoryDetailScreen(assessmentId: assessmentId),
                                      ),
                                    );
                                  },
                                );
                              }),
                            ],
                          ),
                  ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value;
  final Color color;
  final double strokeWidth;
  _ArcPainter({required this.value, required this.color, this.strokeWidth = 7});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final bg = Paint()..color = color.withOpacity(0.12)..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
    final fg = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.75, math.pi * 1.5, false, bg);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.75, math.pi * 1.5 * value, false, fg);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.value != value || old.color != color;
}

class _IntroCard extends StatelessWidget {
  final int count;
  const _IntroCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF6B4FD8).withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.history_rounded, color: Color(0xFF6B4FD8), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Sua linha do tempo",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
                const SizedBox(height: 3),
                Text("$count ${count == 1 ? "avaliação" : "avaliações"} · toque para ver detalhes",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B6F8A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String assessmentId;
  final int score;
  final Color color;
  final String label;
  final String date;
  final List<dynamic> patterns;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.assessmentId,
    required this.score,
    required this.color,
    required this.label,
    required this.date,
    required this.patterns,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 64, height: 64,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(painter: _ArcPainter(value: score / 100, color: color)),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("$score", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color, height: 1)),
                              Text("pts", style: TextStyle(fontSize: 9, color: color.withOpacity(0.6))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
                        const SizedBox(height: 3),
                        Text(date,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: color, size: 24),
                ],
              ),
              if (patterns.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text("Padrões neste registro",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B6F8A))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: patterns.take(3).map((item) {
                    final pattern = Map<String, dynamic>.from(item);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B4FD8).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(pattern["label"]?.toString() ?? "",
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B4FD8), fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAssessment;
  const _EmptyState({required this.onAssessment});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6B4FD8), Color(0xFF42B8B0)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Icon(Icons.history_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 14),
              const Text("Nenhum histórico ainda",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 8),
              const Text(
                "Faça sua primeira avaliação para começar a acompanhar sua evolução.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white70),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6B4FD8),
                  ),
                  onPressed: onAssessment,
                  child: const Text("Fazer avaliação",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFE8505B), size: 48),
              const SizedBox(height: 14),
              const Text("Não foi possível carregar histórico.", textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF6B6F8A))),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text("Tentar novamente")),
            ],
          ),
        ),
      ),
    );
  }
}
