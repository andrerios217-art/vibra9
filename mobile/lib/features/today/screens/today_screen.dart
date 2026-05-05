import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";
import "../../assessment/screens/assessment_screen.dart";
import "../../breathing/screens/breathing_screen.dart";
import "../../ritual/screens/ritual_screen.dart";
import "../../result/screens/result_screen.dart";

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
      final response = await ApiClient.get(
        "/history",
        auth: true,
      );

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
        SnackBar(
          content: Text(error.toString().replaceAll("Exception: ", "")),
        ),
      );
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

  String weakestDimensionLabel(Map<String, dynamic> item) {
    final dimensions = item["dimensions"] as List<dynamic>;

    if (dimensions.isEmpty) return "Sua rotina";

    final sorted = [...dimensions]..sort(
        (a, b) => (a["score"] as int).compareTo(b["score"] as int),
      );

    return sorted.first["label"].toString();
  }

  String strongestDimensionLabel(Map<String, dynamic> item) {
    final dimensions = item["dimensions"] as List<dynamic>;

    if (dimensions.isEmpty) return "Seu autocuidado";

    final sorted = [...dimensions]..sort(
        (a, b) => (b["score"] as int).compareTo(a["score"] as int),
      );

    return sorted.first["label"].toString();
  }

  Future<void> openAssessment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AssessmentScreen()),
    );

    if (mounted) {
      loadLatest();
    }
  }

  void openBreathing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BreathingScreen()),
    );
  }

  void openRitual() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RitualScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasResult = latest != null;
    final score = hasResult ? latest!["general_score"] as int : 0;
    final color = hasResult ? scoreColor(score) : const Color(0xFF6B4FD8);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Hoje"),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: color.withOpacity(0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: hasResult
                  ? Row(
                      children: [
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: score / 100,
                                strokeWidth: 10,
                                backgroundColor: color.withOpacity(0.10),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                              Center(
                                child: Text(
                                  "$score",
                                  style: TextStyle(
                                    fontSize: 36,
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
                                "Seu momento",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B6F8A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                scoreLabel(score),
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Color(0xFF1F2544),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Foco sugerido: ${weakestDimensionLabel(latest!)}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.35,
                                  color: Color(0xFF6B6F8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Icon(
                          Icons.wb_sunny_rounded,
                          size: 58,
                          color: Color(0xFF6B4FD8),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Comece seu check-up",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1F2544),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Faça uma avaliação rápida para receber seu foco e ações práticas de hoje.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: Color(0xFF6B6F8A),
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: openAssessment,
                            child: const Text(
                              "Fazer avaliação",
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            if (hasResult)
              _InsightCard(
                icon: Icons.bolt_rounded,
                title: "Força atual",
                text: strongestDimensionLabel(latest!),
                color: const Color(0xFF59B36A),
              ),
            if (hasResult) const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: color.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(icon, color: color),
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
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF1F2544),
                    fontWeight: FontWeight.w900,
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
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: color.withOpacity(0.10),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
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
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2544),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Color(0xFF6B6F8A),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6B6F8A),
              ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4FD8).withOpacity(0.07),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text(
        "O Vibra9 oferece orientações gerais de bem-estar e autoconhecimento. Não substitui acompanhamento profissional.",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: Color(0xFF6B6F8A),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

