import "package:flutter/material.dart";
import "dart:math" as math;
import "../../../core/services/api_client.dart";
import "../../navigation/screens/app_shell_screen.dart";
import "../../patterns/screens/patterns_screen.dart";

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> assessment;
  final Map<String, dynamic> recommendation;

  const ResultScreen({
    super.key,
    required this.assessment,
    required this.recommendation,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool loadingPatterns = true;
  List<dynamic> patterns = [];
  String? patternError;

  @override
  void initState() {
    super.initState();
    syncStoredPatterns();
    loadPatterns();
  }

  Future<void> syncStoredPatterns() async {
    try {
      await ApiClient.post("/patterns/backfill", auth: true, body: {});
    } catch (_) {}
  }

  Future<void> loadPatterns() async {
    try {
      final response = await ApiClient.get("/patterns/latest", auth: true);
      if (!mounted) return;
      setState(() {
        patterns = response["patterns"] as List<dynamic>? ?? [];
        loadingPatterns = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        patternError = error.toString().replaceAll("Exception: ", "");
        loadingPatterns = false;
      });
    }
  }

  Color scoreColor(int score) {
    if (score <= 40) return const Color(0xFFE8505B);
    if (score <= 70) return const Color(0xFFF5B942);
    return const Color(0xFF59B36A);
  }

  String scoreLabel(int score) {
    if (score <= 40) return "Momento de atenção";
    if (score <= 70) return "Em desenvolvimento";
    return "Bom equilíbrio";
  }

  Color dimensionColor(int score) {
    if (score <= 4) return const Color(0xFFE8505B);
    if (score <= 7) return const Color(0xFFF5B942);
    return const Color(0xFF59B36A);
  }

  void goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppShellScreen()),
      (_) => false,
    );
  }

  void openPatterns() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PatternsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final int generalScore = widget.assessment["general_score"] as int;
    final dimensions = widget.assessment["dimensions"] as List<dynamic>;
    final actions = widget.recommendation["daily_actions"] as List<dynamic>;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Seu resultado"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: "Início",
            onPressed: goHome,
            icon: const Icon(Icons.home_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            _ScoreHeroCard(
              score: generalScore,
              label: scoreLabel(generalScore),
              color: scoreColor(generalScore),
              summary: widget.recommendation["summary"].toString(),
            ),
            const SizedBox(height: 16),
            _FocusCard(focus: widget.recommendation["main_focus"].toString()),
            const SizedBox(height: 16),
            _PatternsPreviewCard(
              loading: loadingPatterns,
              patterns: patterns,
              error: patternError,
              onOpen: openPatterns,
            ),
            const SizedBox(height: 18),
            const _SectionTitle(
              title: "Ações para hoje",
              subtitle: "Pequenos passos práticos, sem cobrança excessiva.",
            ),
            const SizedBox(height: 10),
            ...actions.map((action) => _ActionCard(text: action.toString())),
            const SizedBox(height: 18),
            const _SectionTitle(
              title: "Suas 9 dimensões",
              subtitle: "Veja onde você está mais forte e onde pode cuidar melhor.",
            ),
            const SizedBox(height: 10),
            ...dimensions.map((item) {
              final int score = item["score"] as int;
              return _DimensionBar(
                label: item["label"].toString(),
                status: item["status"].toString(),
                score: score,
                color: dimensionColor(score),
              );
            }),
            const SizedBox(height: 18),
            _QuoteCard(
              quote: widget.recommendation["quote"].toString(),
              author: widget.recommendation["quote_author"].toString(),
            ),
            const SizedBox(height: 14),
            _SafetyCard(text: widget.recommendation["safety_note"].toString()),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4FD8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: goHome,
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  "Concluir",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcScorePainter extends CustomPainter {
  final double value;
  final Color color;
  final double strokeWidth;

  _ArcScorePainter({required this.value, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final startAngle = math.pi * 0.75;
    final sweepFull = math.pi * 1.5;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepFull, false, bgPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepFull * value, false, fgPaint);
  }

  @override
  bool shouldRepaint(_ArcScorePainter old) => old.value != value || old.color != color;
}

class _ScoreHeroCard extends StatelessWidget {
  final int score;
  final String label;
  final Color color;
  final String summary;

  const _ScoreHeroCard({
    required this.score,
    required this.label,
    required this.color,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 144, height: 144,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _ArcScorePainter(value: score / 100, color: color, strokeWidth: 13),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$score",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: color,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "de 100",
                        style: TextStyle(
                          fontSize: 12,
                          color: color.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ),
          const SizedBox(height: 14),
          Text(
            summary,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF4A4A6A),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final String focus;
  const _FocusCard({required this.focus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4FD8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.center_focus_strong_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Foco de hoje",
                  style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(focus,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternsPreviewCard extends StatelessWidget {
  final bool loading;
  final List<dynamic> patterns;
  final String? error;
  final VoidCallback onOpen;

  const _PatternsPreviewCard({
    required this.loading,
    required this.patterns,
    required this.error,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.08)),
        ),
        child: const Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text("Buscando padrões...",
              style: TextStyle(fontSize: 13, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    if (error != null || patterns.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.08)),
        ),
        child: const Row(
          children: [
            Icon(Icons.account_tree_rounded, color: Color(0xFF6B4FD8), size: 18),
            SizedBox(width: 12),
            Expanded(child: Text(
              "Nenhum padrão relevante identificado ainda. Continue fazendo avaliações.",
              style: TextStyle(fontSize: 12, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w500))),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4FD8).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_tree_rounded, color: Color(0xFF6B4FD8), size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text("Padrões percebidos",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2544)))),
            ],
          ),
          const SizedBox(height: 6),
          const Text("Hipóteses de reflexão baseadas nas suas respostas.",
            style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF6B6F8A))),
          const SizedBox(height: 12),
          ...patterns.take(3).map((item) {
            final pattern = Map<String, dynamic>.from(item);
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 5, height: 5,
                    decoration: const BoxDecoration(color: Color(0xFF6B4FD8), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(pattern["label"]?.toString() ?? "",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1F2544), fontWeight: FontWeight.w600))),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: const Text("Ver mapa completo",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
        const SizedBox(height: 3),
        Text(subtitle,
          style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF6B6F8A))),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String text;
  const _ActionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF59B36A).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFF59B36A), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text,
            style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF1F2544), fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _DimensionBar extends StatelessWidget {
  final String label;
  final String status;
  final int score;
  final Color color;

  const _DimensionBar({
    required this.label,
    required this.status,
    required this.score,
    required this.color,
  });

  String statusText() {
    switch (status) {
      case "atencao":
        return "Atenção";
      case "em_desenvolvimento":
        return "Em desenvolvimento";
      case "equilibrado":
        return "Equilibrado";
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2544)))),
              Text("$score/10",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 10,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.10),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 5),
          Text(statusText(),
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final String quote;
  final String author;
  const _QuoteCard({required this.quote, required this.author});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5B942).withOpacity(0.20)),
      ),
      child: Column(
        children: [
          const Icon(Icons.format_quote_rounded, color: Color(0xFFF5B942), size: 26),
          const SizedBox(height: 8),
          Text(quote, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF1F2544),
              fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text("— $author",
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  final String text;
  const _SafetyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8505B).withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFE8505B), size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(text,
            style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF4A4A6A)))),
        ],
      ),
    );
  }
}
