import "dart:math" as math;
import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";
import "../../assessment/screens/assessment_screen.dart";
import "../../breathing/screens/breathing_screen.dart";
import "../../ritual/screens/ritual_screen.dart";

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool loading = true;
  Map<String, dynamic>? latest;

  @override
  void initState() {
    super.initState();
    loadLatest();
  }

  Future<void> loadLatest() async {
    try {
      final response = await ApiClient.get("/history", auth: true);
      final items = response["items"] as List<dynamic>;
      if (!mounted) return;
      setState(() {
        latest = items.isNotEmpty ? Map<String, dynamic>.from(items.first) : null;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll("Exception: ", ""))));
    }
  }

  Color scoreColor(int score) {
    if (score <= 40) return const Color(0xFFE8505B);
    if (score <= 70) return const Color(0xFFF5B942);
    return const Color(0xFF59B36A);
  }

  String scoreLabel(int score) {
    if (score <= 40) return "Pede cuidado";
    if (score <= 70) return "Em construção";
    return "Bom equilíbrio";
  }

  Map<String, dynamic>? weakestDimension(Map<String, dynamic> item) {
    final dimensions = item["dimensions"] as List<dynamic>;
    if (dimensions.isEmpty) return null;
    final sorted = [...dimensions]..sort((a, b) => (a["score"] as int).compareTo(b["score"] as int));
    return Map<String, dynamic>.from(sorted.first);
  }

  Map<String, dynamic>? strongestDimension(Map<String, dynamic> item) {
    final dimensions = item["dimensions"] as List<dynamic>;
    if (dimensions.isEmpty) return null;
    final sorted = [...dimensions]..sort((a, b) => (b["score"] as int).compareTo(a["score"] as int));
    return Map<String, dynamic>.from(sorted.first);
  }

  Future<void> openAssessment() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessmentScreen()));
    if (mounted) loadLatest();
  }

  void openBreathing() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BreathingScreen()));
  }

  void openRitual() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RitualScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hasResult = latest != null;
    final score = hasResult ? latest!["general_score"] as int : 0;
    final color = hasResult ? scoreColor(score) : const Color(0xFF6B4FD8);
    final weakest = hasResult ? weakestDimension(latest!) : null;
    final strongest = hasResult ? strongestDimension(latest!) : null;
    final hasStrongDimension = strongest != null && (strongest["score"] as int) >= 7;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(title: const Text("Hoje")),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadLatest,
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              if (hasResult) ...[
                _ScoreCard(
                  score: score,
                  color: color,
                  label: scoreLabel(score),
                  focus: weakest?["label"]?.toString() ?? "Sua rotina",
                ),
              ] else ...[
                _EmptyHero(onAssessment: openAssessment),
              ],
              const SizedBox(height: 18),
              if (hasStrongDimension)
                _InsightCard(
                  icon: Icons.bolt_rounded,
                  title: "Força atual",
                  text: strongest!["label"].toString(),
                  color: const Color(0xFF59B36A),
                ),
              if (hasStrongDimension) const SizedBox(height: 12),
              _TodayActionCard(
                title: "Ritual do dia",
                text: "Transforme seu resultado em pequenas ações concluídas.",
                icon: Icons.checklist_rounded,
                color: const Color(0xFF6B4FD8),
                onTap: openRitual,
              ),
              const SizedBox(height: 12),
              _TodayActionCard(
                title: "Pausa guiada",
                text: "Respiração simples de 60 segundos para reduzir ruído.",
                icon: Icons.air_rounded,
                color: const Color(0xFF42B8B0),
                onTap: openBreathing,
              ),
              const SizedBox(height: 12),
              _TodayActionCard(
                title: "Nova avaliação",
                text: "Atualize seu momento e gere um novo resultado.",
                icon: Icons.favorite_rounded,
                color: const Color(0xFFF5B942),
                onTap: openAssessment,
              ),
              const SizedBox(height: 18),
              const _ResponsibleNote(),
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
    const sw = 11.0;
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

class _ScoreCard extends StatelessWidget {
  final int score;
  final Color color;
  final String label;
  final String focus;
  const _ScoreCard({required this.score, required this.color, required this.label, required this.focus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100, height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _ArcPainter(value: score / 100, color: color)),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("$score", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: color, height: 1)),
                      Text("pts", style: TextStyle(fontSize: 11, color: color.withOpacity(0.6))),
                    ],
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
                const Text("Seu momento",
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(label,
                  style: const TextStyle(fontSize: 20, color: Color(0xFF1F2544), fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text("Foco: $focus",
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF6B6F8A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHero extends StatelessWidget {
  final VoidCallback onAssessment;
  const _EmptyHero({required this.onAssessment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6B4FD8), Color(0xFF42B8B0)]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(Icons.wb_sunny_rounded, size: 48, color: Colors.white),
          const SizedBox(height: 14),
          const Text("Comece seu check-up",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          const Text(
            "Faça uma avaliação rápida para receber seu foco e ações práticas de hoje.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 48,
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
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const _InsightCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(text,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF1F2544), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayActionCard extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TodayActionCard({
    required this.title,
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
                    const SizedBox(height: 3),
                    Text(text,
                      style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF6B6F8A))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF6B6F8A), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsibleNote extends StatelessWidget {
  const _ResponsibleNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4FD8).withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        "O Vibra9 oferece orientações gerais de bem-estar e autoconhecimento. Não substitui acompanhamento profissional.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w500),
      ),
    );
  }
}
