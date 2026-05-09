import "package:flutter/material.dart";
import "dart:math" as math;
import "../../../core/services/api_client.dart";

class EvolutionScreen extends StatefulWidget {
  const EvolutionScreen({super.key});

  @override
  State<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends State<EvolutionScreen> {
  bool loading = true;
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    setState(() => loading = true);
    try {
      final response = await ApiClient.get("/history", auth: true);
      if (!mounted) return;
      setState(() {
        items = response["items"] as List<dynamic>;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll("Exception: ", ""))));
    }
  }

  int averageScore(List<dynamic> values) {
    if (values.isEmpty) return 0;
    final total = values.fold<int>(0, (sum, item) => sum + (item["general_score"] as int));
    return (total / values.length).round();
  }

  int bestScore(List<dynamic> values) {
    if (values.isEmpty) return 0;
    return values.map((item) => item["general_score"] as int).reduce((a, b) => a > b ? a : b);
  }

  int lowestScore(List<dynamic> values) {
    if (values.isEmpty) return 0;
    return values.map((item) => item["general_score"] as int).reduce((a, b) => a < b ? a : b);
  }

  Color scoreColor(int score) {
    if (score <= 40) return const Color(0xFFE8505B);
    if (score <= 70) return const Color(0xFFF5B942);
    return const Color(0xFF59B36A);
  }

  String scoreLabel(int score) {
    if (score <= 40) return "Atenção";
    if (score <= 70) return "Em desenvolvimento";
    return "Bom equilíbrio";
  }

  String formatShortDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return "";
    final local = date.toLocal();
    return "${local.day.toString().padLeft(2, "0")}/${local.month.toString().padLeft(2, "0")}";
  }

  Map<String, dynamic>? _bestDimension(List<dynamic> values) {
    if (values.isEmpty) return null;
    final Map<String, List<int>> grouped = {};
    for (final item in values) {
      for (final d in item["dimensions"] as List<dynamic>) {
        final key = d["dimension"].toString();
        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add(d["score"] as int);
      }
    }
    Map<String, dynamic>? best;
    double bestAvg = -1;
    grouped.forEach((key, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        best = {"dimension": key, "label": _dimLabel(key), "avg": avg.round()};
      }
    });
    return best;
  }

  Map<String, dynamic>? _weakestDimension(List<dynamic> values) {
    if (values.isEmpty) return null;
    final Map<String, List<int>> grouped = {};
    for (final item in values) {
      for (final d in item["dimensions"] as List<dynamic>) {
        final key = d["dimension"].toString();
        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add(d["score"] as int);
      }
    }
    Map<String, dynamic>? weakest;
    double weakestAvg = 999;
    grouped.forEach((key, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg < weakestAvg) {
        weakestAvg = avg;
        weakest = {"dimension": key, "label": _dimLabel(key), "avg": avg.round()};
      }
    });
    return weakest;
  }

  String _dimLabel(String key) {
    const labels = {
      "clareza_mental": "Clareza mental",
      "estado_emocional": "Estado emocional",
      "proposito_pessoal": "Propósito pessoal",
      "energia_diaria": "Energia diária",
      "corpo_habitos": "Corpo e hábitos",
      "comunicacao": "Comunicação",
      "relacoes": "Relações",
      "rotina_foco": "Rotina e foco",
      "seguranca_financeira": "Segurança financeira",
    };
    return labels[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final recent = items.take(7).toList().reversed.toList();
    final average = averageScore(recent);
    final best = bestScore(recent);
    final lowest = lowestScore(recent);
    final bestDim = _bestDimension(recent);
    final weakestDim = _weakestDimension(recent);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(title: const Text("Evolução")),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? const _EmptyEvolution()
                : RefreshIndicator(
                    onRefresh: loadHistory,
                    child: ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        _AverageCard(average: average, label: scoreLabel(average), color: scoreColor(average)),
                        const SizedBox(height: 20),
                        _ChartCard(items: recent, formatShortDate: formatShortDate),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _MetricCard(title: "Melhor", value: "$best", subtitle: "maior índice", icon: Icons.arrow_upward_rounded, color: const Color(0xFF59B36A))),
                            const SizedBox(width: 12),
                            Expanded(child: _MetricCard(title: "Menor", value: "$lowest", subtitle: "ponto de atenção", icon: Icons.arrow_downward_rounded, color: const Color(0xFFE8505B))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (bestDim != null) ...[
                          _DimensionInsightCard(
                            title: "Dimensão mais forte",
                            dimension: bestDim["label"].toString(),
                            score: bestDim["avg"] as int,
                            icon: Icons.bolt_rounded,
                            color: const Color(0xFF59B36A),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (weakestDim != null) ...[
                          _DimensionInsightCard(
                            title: "Dimensão para cuidar",
                            dimension: weakestDim["label"].toString(),
                            score: weakestDim["avg"] as int,
                            icon: Icons.center_focus_strong_rounded,
                            color: const Color(0xFF6B4FD8),
                          ),
                          const SizedBox(height: 20),
                        ],
                        const _NoteCard(),
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

class _AverageCard extends StatelessWidget {
  final int average;
  final String label;
  final Color color;
  const _AverageCard({required this.average, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100, height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _ArcPainter(value: average / 100, color: color)),
                Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("$average", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: color, height: 1)),
                    Text("pts", style: TextStyle(fontSize: 11, color: color.withOpacity(0.6))),
                  ],
                )),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Média recente", style: TextStyle(fontSize: 13, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 20, color: Color(0xFF1F2544), fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text("Baseado nas últimas avaliações.", style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF6B6F8A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final List<dynamic> items;
  final String Function(String) formatShortDate;
  const _ChartCard({required this.items, required this.formatShortDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Linha do tempo", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
          const SizedBox(height: 4),
          const Text("Últimos 7 registros", style: TextStyle(fontSize: 12, color: Color(0xFF6B6F8A))),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _ChartPainter(items: items),
              child: Container(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.map((item) => Text(
              formatShortDate(item["created_at"].toString()),
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w600),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<dynamic> items;
  _ChartPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final gridPaint = Paint()..color = const Color(0xFFEEEAFF)..strokeWidth = 1;
    final linePaint = Paint()..color = const Color(0xFF6B4FD8)..strokeWidth = 3..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = const Color(0xFF6B4FD8)..style = PaintingStyle.fill;
    final fillPaint = Paint()..color = const Color(0xFF6B4FD8).withOpacity(0.07)..style = PaintingStyle.fill;
    final labelStyle = const TextStyle(fontSize: 10, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w600);

    // Grid lines + labels
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      final score = (100 - (i * 25)).toString();
      final tp = TextPainter(text: TextSpan(text: score, style: labelStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(size.width - tp.width, y - tp.height / 2));
    }

    final points = <Offset>[];
    for (int i = 0; i < items.length; i++) {
      final score = items[i]["general_score"] as int;
      final x = items.length == 1 ? size.width / 2 : (size.width / (items.length - 1)) * i;
      final y = size.height - ((score / 100) * size.height);
      points.add(Offset(x, y));
    }

    // Fill
    final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i - 1].dy);
      final cp2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }
    fillPath..lineTo(points.last.dx, size.height)..lineTo(points.first.dx, size.height)..close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i - 1].dy);
      final cp2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    for (final point in points) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 3, Paint()..color = Colors.white..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.items != items;
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 28, color: color, fontWeight: FontWeight.w700)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF6B6F8A))),
        ],
      ),
    );
  }
}

class _DimensionInsightCard extends StatelessWidget {
  final String title;
  final String dimension;
  final int score;
  final IconData icon;
  final Color color;
  const _DimensionInsightCard({required this.title, required this.dimension, required this.score, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(dimension, style: const TextStyle(fontSize: 16, color: Color(0xFF1F2544), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Text("$score/10", style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4FD8).withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF6B4FD8), size: 18),
          SizedBox(width: 10),
          Expanded(child: Text(
            "A evolução mostra tendências gerais de bem-estar. Use como referência para autocuidado, não como diagnóstico.",
            style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF1F2544)))),
        ],
      ),
    );
  }
}

class _EmptyEvolution extends StatelessWidget {
  const _EmptyEvolution();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insights_rounded, size: 52, color: Color(0xFF6B4FD8)),
              SizedBox(height: 16),
              Text("Sem dados de evolução", textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
              SizedBox(height: 8),
              Text("Faça algumas avaliações para acompanhar sua evolução visual.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF6B6F8A))),
            ],
          ),
        ),
      ),
    );
  }
}
