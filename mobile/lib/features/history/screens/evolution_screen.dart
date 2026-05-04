import "package:flutter/material.dart";
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
    try {
      final response = await ApiClient.get(
        "/history",
        auth: true,
      );

      if (!mounted) return;

      setState(() {
        items = response["items"] as List<dynamic>;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll("Exception: ", "")),
        ),
      );
    }
  }

  int averageScore(List<dynamic> values) {
    if (values.isEmpty) return 0;

    final total = values.fold<int>(
      0,
      (sum, item) => sum + (item["general_score"] as int),
    );

    return (total / values.length).round();
  }

  int bestScore(List<dynamic> values) {
    if (values.isEmpty) return 0;

    return values
        .map((item) => item["general_score"] as int)
        .reduce((a, b) => a > b ? a : b);
  }

  int lowestScore(List<dynamic> values) {
    if (values.isEmpty) return 0;

    return values
        .map((item) => item["general_score"] as int)
        .reduce((a, b) => a < b ? a : b);
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
    final day = local.day.toString().padLeft(2, "0");
    final month = local.month.toString().padLeft(2, "0");

    return "$day/$month";
  }

  Map<String, dynamic>? strongestDimension(List<dynamic> values) {
    if (values.isEmpty) return null;

    final allDimensions = <Map<String, dynamic>>[];

    for (final item in values) {
      final dimensions = item["dimensions"] as List<dynamic>;

      for (final dimension in dimensions) {
        allDimensions.add(Map<String, dynamic>.from(dimension));
      }
    }

    if (allDimensions.isEmpty) return null;

    allDimensions.sort(
      (a, b) => (b["score"] as int).compareTo(a["score"] as int),
    );

    return allDimensions.first;
  }

  Map<String, dynamic>? weakestDimension(List<dynamic> values) {
    if (values.isEmpty) return null;

    final allDimensions = <Map<String, dynamic>>[];

    for (final item in values) {
      final dimensions = item["dimensions"] as List<dynamic>;

      for (final dimension in dimensions) {
        allDimensions.add(Map<String, dynamic>.from(dimension));
      }
    }

    if (allDimensions.isEmpty) return null;

    allDimensions.sort(
      (a, b) => (a["score"] as int).compareTo(b["score"] as int),
    );

    return allDimensions.first;
  }

  @override
  Widget build(BuildContext context) {
    final recent = items.take(7).toList().reversed.toList();
    final average = averageScore(recent);
    final best = bestScore(recent);
    final lowest = lowestScore(recent);
    final strongest = strongestDimension(recent);
    final weakest = weakestDimension(recent);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Evolução"),
      ),
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
                        _AverageCard(
                          average: average,
                          label: scoreLabel(average),
                          color: scoreColor(average),
                        ),
                        const SizedBox(height: 20),
                        _ChartCard(
                          items: recent,
                          formatShortDate: formatShortDate,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: "Melhor",
                                value: "$best",
                                subtitle: "maior índice",
                                icon: Icons.arrow_upward_rounded,
                                color: const Color(0xFF59B36A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: "Menor",
                                value: "$lowest",
                                subtitle: "ponto de atenção",
                                icon: Icons.arrow_downward_rounded,
                                color: const Color(0xFFE8505B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (strongest != null)
                          _DimensionInsightCard(
                            title: "Dimensão mais forte",
                            dimension: strongest["label"].toString(),
                            score: strongest["score"] as int,
                            icon: Icons.bolt_rounded,
                            color: const Color(0xFF59B36A),
                          ),
                        if (strongest != null) const SizedBox(height: 12),
                        if (weakest != null)
                          _DimensionInsightCard(
                            title: "Dimensão para cuidar",
                            dimension: weakest["label"].toString(),
                            score: weakest["score"] as int,
                            icon: Icons.center_focus_strong_rounded,
                            color: const Color(0xFF6B4FD8),
                          ),
                        const SizedBox(height: 20),
                        const _NoteCard(),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _AverageCard extends StatelessWidget {
  final int average;
  final String label;
  final Color color;

  const _AverageCard({
    required this.average,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: color.withOpacity(0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.09),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            height: 118,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: average / 100,
                  strokeWidth: 11,
                  backgroundColor: color.withOpacity(0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Text(
                    "$average",
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Média recente",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B6F8A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Color(0xFF1F2544),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Baseado nas últimas avaliações salvas.",
                  style: TextStyle(
                    fontSize: 13,
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

class _ChartCard extends StatelessWidget {
  final List<dynamic> items;
  final String Function(String value) formatShortDate;

  const _ChartCard({
    required this.items,
    required this.formatShortDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: const Color(0xFF6B4FD8).withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Últimos resultados",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2544),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Visualização dos últimos 7 registros.",
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B6F8A),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 190,
            child: CustomPaint(
              painter: _EvolutionChartPainter(items: items),
              child: Container(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.map((item) {
              return Text(
                formatShortDate(item["created_at"].toString()),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B6F8A),
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _EvolutionChartPainter extends CustomPainter {
  final List<dynamic> items;

  _EvolutionChartPainter({
    required this.items,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final axisPaint = Paint()
      ..color = const Color(0xFFE8E2FF)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = const Color(0xFF6B4FD8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = const Color(0xFF6B4FD8)
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..color = const Color(0xFF6B4FD8).withOpacity(0.08)
      ..style = PaintingStyle.fill;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        axisPaint,
      );
    }

    final points = <Offset>[];

    for (int i = 0; i < items.length; i++) {
      final score = items[i]["general_score"] as int;

      final x = items.length == 1
          ? size.width / 2
          : (size.width / (items.length - 1)) * i;

      final y = size.height - ((score / 100) * size.height);

      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 6, pointPaint);

      final whitePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(point, 3, whitePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EvolutionChartPainter oldDelegate) {
    return oldDelegate.items != items;
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: color.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B6F8A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B6F8A),
            ),
          ),
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

  const _DimensionInsightCard({
    required this.title,
    required this.dimension,
    required this.score,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: color.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6F8A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dimension,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF1F2544),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "$score/10",
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4FD8).withOpacity(0.07),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF6B4FD8),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "A evolução mostra tendências gerais de bem-estar. Use como referência para autocuidado, não como diagnóstico.",
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF1F2544),
              ),
            ),
          ),
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
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFF6B4FD8).withOpacity(0.10),
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insights_rounded,
                size: 54,
                color: Color(0xFF6B4FD8),
              ),
              SizedBox(height: 16),
              Text(
                "Sem dados de evolução",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2544),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Faça algumas avaliações para acompanhar sua evolução visual.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Color(0xFF6B6F8A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
