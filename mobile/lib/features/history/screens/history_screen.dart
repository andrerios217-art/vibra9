import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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

  String formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, "0");
    final month = local.month.toString().padLeft(2, "0");
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, "0");
    final minute = local.minute.toString().padLeft(2, "0");

    return "$day/$month/$year às $hour:$minute";
  }

  Color scoreColor(int score) {
    if (score <= 40) {
      return const Color(0xFFE8505B);
    }

    if (score <= 70) {
      return const Color(0xFFF5B942);
    }

    return const Color(0xFF59B36A);
  }

  String scoreLabel(int score) {
    if (score <= 40) {
      return "Momento de atenção";
    }

    if (score <= 70) {
      return "Em desenvolvimento";
    }

    return "Bom equilíbrio";
  }

  Color dimensionColor(int score) {
    if (score <= 4) {
      return const Color(0xFFE8505B);
    }

    if (score <= 7) {
      return const Color(0xFFF5B942);
    }

    return const Color(0xFF59B36A);
  }

  String statusText(String value) {
    if (value == "atenção") {
      return "Atenção";
    }

    if (value == "em_desenvolvimento") {
      return "Em desenvolvimento";
    }

    return "Equilibrado";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Histórico"),
      ),
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : items.isEmpty
                ? const _EmptyHistory()
                : RefreshIndicator(
                    onRefresh: loadHistory,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final int score = item["general_score"] as int;
                        final dimensions = item["dimensions"] as List<dynamic>;
                        final color = scoreColor(score);

                        return _HistoryResultCard(
                          score: score,
                          color: color,
                          label: scoreLabel(score),
                          date: formatDate(item["created_at"].toString()),
                          dimensions: dimensions,
                          dimensionColor: dimensionColor,
                          statusText: statusText,
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

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
                Icons.history_rounded,
                size: 54,
                color: Color(0xFF6B4FD8),
              ),
              SizedBox(height: 16),
              Text(
                "Nenhuma avaliação ainda",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2544),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Quando você fizer avaliações, seus resultados aparecerão aqui em formato de linha do tempo.",
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

class _HistoryResultCard extends StatelessWidget {
  final int score;
  final Color color;
  final String label;
  final String date;
  final List<dynamic> dimensions;
  final Color Function(int score) dimensionColor;
  final String Function(String status) statusText;

  const _HistoryResultCard({
    required this.score,
    required this.color,
    required this.label,
    required this.date,
    required this.dimensions,
    required this.dimensionColor,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final weakest = [...dimensions]..sort(
        (a, b) => (a["score"] as int).compareTo(b["score"] as int),
      );

    final strongest = [...dimensions]..sort(
        (a, b) => (b["score"] as int).compareTo(a["score"] as int),
      );

    final weakestLabel = weakest.isNotEmpty ? weakest.first["label"].toString() : "";
    final strongestLabel = strongest.isNotEmpty ? strongest.first["label"].toString() : "";

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: color.withOpacity(0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 9,
                      backgroundColor: color.withOpacity(0.10),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    Center(
                      child: Text(
                        "$score",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2544),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6F8A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        "Índice $score/100",
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (strongestLabel.isNotEmpty)
                  _InsightLine(
                    icon: Icons.arrow_upward_rounded,
                    color: const Color(0xFF59B36A),
                    text: "Ponto mais forte: $strongestLabel",
                  ),
                if (weakestLabel.isNotEmpty) const SizedBox(height: 8),
                if (weakestLabel.isNotEmpty)
                  _InsightLine(
                    icon: Icons.center_focus_strong_rounded,
                    color: const Color(0xFF6B4FD8),
                    text: "Campo para cuidar: $weakestLabel",
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Column(
            children: dimensions.map((item) {
              final int dimensionScore = item["score"] as int;
              final color = dimensionColor(dimensionScore);

              return _MiniDimensionBar(
                label: item["label"].toString(),
                status: statusText(item["status"].toString()),
                score: dimensionScore,
                color: color,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _InsightLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InsightLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2544),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniDimensionBar extends StatelessWidget {
  final String label;
  final String status;
  final int score;
  final Color color;

  const _MiniDimensionBar({
    required this.label,
    required this.status,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = score / 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2544),
                  ),
                ),
              ),
              Text(
                "$score/10",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.10),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B6F8A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

