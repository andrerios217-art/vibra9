import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";

class HistoryDetailScreen extends StatefulWidget {
  final String assessmentId;
  const HistoryDetailScreen({super.key, required this.assessmentId});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  bool loading = true;
  String? errorMessage;
  Map<String, dynamic>? assessment;
  Map<String, dynamic>? recommendation;

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    setState(() { loading = true; errorMessage = null; });
    try {
      final response = await ApiClient.get("/history/${widget.assessmentId}", auth: true);
      if (!mounted) return;
      setState(() {
        assessment = Map<String, dynamic>.from(response["assessment"]);
        if (response["recommendation"] != null) {
          recommendation = Map<String, dynamic>.from(response["recommendation"]);
        }
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

  Color dimColor(int score) {
    if (score <= 4) return const Color(0xFFE8505B);
    if (score <= 7) return const Color(0xFFF5B942);
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
    return "${local.day.toString().padLeft(2, "0")}/${local.month.toString().padLeft(2, "0")}/${local.year} às ${local.hour.toString().padLeft(2, "0")}:${local.minute.toString().padLeft(2, "0")}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Resultado"),
        backgroundColor: const Color(0xFFF8F5FF),
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFE8505B), size: 48),
                        const SizedBox(height: 12),
                        Text(errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B6F8A))),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: loadDetail, child: const Text("Tentar novamente")),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final a = assessment!;
    final score = a["general_score"] as int;
    final color = scoreColor(score);
    final dimensions = a["dimensions"] as List<dynamic>;
    final date = formatDate(a["created_at"].toString());

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        _ScoreHeroCard(score: score, color: color, label: scoreLabel(score), date: date),
        const SizedBox(height: 20),
        if (recommendation != null) ...[
          _SummaryCard(summary: recommendation!["summary"].toString()),
          const SizedBox(height: 16),
        ],
        _DimensionsCard(dimensions: dimensions, dimColor: dimColor),
        const SizedBox(height: 16),
        if (recommendation != null) ...[
          _ActionsCard(
            mainFocus: recommendation!["main_focus"].toString(),
            actions: recommendation!["daily_actions"] as List<dynamic>,
          ),
          const SizedBox(height: 16),
          _QuoteCard(
            quote: recommendation!["quote"].toString(),
            author: recommendation!["quote_author"].toString(),
          ),
          const SizedBox(height: 16),
          _SafetyCard(note: recommendation!["safety_note"].toString()),
        ] else ...[
          _NoRecommendationCard(),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ScoreHeroCard extends StatelessWidget {
  final int score;
  final Color color;
  final String label;
  final String date;
  const _ScoreHeroCard({required this.score, required this.color, required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6B4FD8), Color(0xFF42B8B0)]),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [BoxShadow(color: const Color(0xFF6B4FD8).withOpacity(0.18), blurRadius: 30, offset: const Offset(0, 14))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88, height: 88,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Center(child: Text("$score", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white))),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 6),
                Text(date, style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.10))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFF6B4FD8), size: 20),
              SizedBox(width: 8),
              Text("Resumo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1F2544))),
            ],
          ),
          const SizedBox(height: 12),
          Text(summary, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF4A4A6A))),
        ],
      ),
    );
  }
}

class _DimensionsCard extends StatelessWidget {
  final List<dynamic> dimensions;
  final Color Function(int) dimColor;
  const _DimensionsCard({required this.dimensions, required this.dimColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.radar_rounded, color: Color(0xFF6B4FD8), size: 20),
              SizedBox(width: 8),
              Text("Suas 9 dimensões", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1F2544))),
            ],
          ),
          const SizedBox(height: 16),
          ...dimensions.map((d) {
            final dim = Map<String, dynamic>.from(d);
            final score = dim["score"] as int;
            final color = dimColor(score);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dim["label"].toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1F2544))),
                      Text("$score/10", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: score / 10,
                      minHeight: 8,
                      backgroundColor: color.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  final String mainFocus;
  final List<dynamic> actions;
  const _ActionsCard({required this.mainFocus, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFF6B4FD8), size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text("Foco: $mainFocus", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1F2544)))),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(actions.length, (i) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF8F5FF), borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: const BoxDecoration(color: Color(0xFF6B4FD8), shape: BoxShape.circle),
                  child: Center(child: Text("${i + 1}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(actions[i].toString(), style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF1F2544), fontWeight: FontWeight.w600))),
              ],
            ),
          )),
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
        gradient: LinearGradient(colors: [const Color(0xFF6B4FD8).withOpacity(0.08), const Color(0xFF42B8B0).withOpacity(0.08)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded, color: Color(0xFF6B4FD8), size: 28),
          const SizedBox(height: 8),
          Text(quote, style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF1F2544), fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text("— $author", style: const TextStyle(fontSize: 13, color: Color(0xFF6B4FD8), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  final String note;
  const _SafetyCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFE8505B).withOpacity(0.07), borderRadius: BorderRadius.circular(20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFE8505B), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(note, style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF1F2544), fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _NoRecommendationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF6B6F8A)),
          SizedBox(width: 12),
          Expanded(child: Text("Nenhuma recomendação gerada para este registro.", style: TextStyle(fontSize: 13, color: Color(0xFF6B6F8A)))),
        ],
      ),
    );
  }
}
