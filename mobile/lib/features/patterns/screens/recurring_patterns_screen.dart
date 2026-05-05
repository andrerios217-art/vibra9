import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";

class RecurringPatternsScreen extends StatefulWidget {
  const RecurringPatternsScreen({super.key});

  @override
  State<RecurringPatternsScreen> createState() => _RecurringPatternsScreenState();
}

class _RecurringPatternsScreenState extends State<RecurringPatternsScreen> {
  bool loading = true;
  Map<String, dynamic>? data;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadRecurringPatterns();
  }

  Future<void> loadRecurringPatterns() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiClient.get(
        "/patterns/recurring",
        auth: true,
      );

      if (!mounted) return;

      setState(() {
        data = response;
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

  Color patternColor(int index) {
    if (index == 0) return const Color(0xFF6B4FD8);
    if (index == 1) return const Color(0xFF42B8B0);
    if (index == 2) return const Color(0xFFF5B942);
    if (index == 3) return const Color(0xFF59B36A);
    return const Color(0xFFE8505B);
  }

  @override
  Widget build(BuildContext context) {
    final hasData = data?["has_data"] == true;
    final patterns = hasData ? data!["patterns"] as List<dynamic> : [];
    final totalAssessments = data?["total_assessments"]?.toString() ?? "0";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Padrões recorrentes"),
        actions: [
          IconButton(
            onPressed: loadRecurringPatterns,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Atualizar",
          ),
        ],
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? _ErrorState(
                    message: errorMessage!,
                    onRetry: loadRecurringPatterns,
                  )
                : RefreshIndicator(
                    onRefresh: loadRecurringPatterns,
                    child: ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        _HeroCard(totalAssessments: totalAssessments),
                        const SizedBox(height: 20),
                        if (!hasData || patterns.isEmpty)
                          _EmptyState(
                            message: data?["message"]?.toString() ??
                                "Faça algumas avaliações para visualizar padrões recorrentes.",
                          )
                        else ...[
                          const Text(
                            "Mais frequentes",
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1F2544),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Esses sinais apareceram com mais frequência nos seus registros recentes.",
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Color(0xFF6B6F8A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(patterns.length, (index) {
                            final pattern =
                                Map<String, dynamic>.from(patterns[index]);

                            return _RecurringPatternCard(
                              index: index + 1,
                              color: patternColor(index),
                              label: pattern["label"]?.toString() ?? "",
                              area: pattern["area"]?.toString() ?? "",
                              group: pattern["group"]?.toString() ?? "",
                              count: pattern["count"]?.toString() ?? "0",
                              averageScore:
                                  pattern["average_score"]?.toString() ?? "0",
                              text: pattern["safe_text"]?.toString() ?? "",
                              reflection:
                                  pattern["reflection"]?.toString() ?? "",
                            );
                          }),
                          const SizedBox(height: 14),
                          _DisclaimerCard(
                            text: data?["disclaimer"]?.toString() ??
                                "Padrões recorrentes não representam diagnóstico.",
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String totalAssessments;

  const _HeroCard({
    required this.totalAssessments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6B4FD8),
            Color(0xFF42B8B0),
          ],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4FD8).withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.repeat_rounded,
            color: Colors.white,
            size: 46,
          ),
          const SizedBox(height: 18),
          const Text(
            "O que vem se repetindo",
            style: TextStyle(
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Veja sinais que aparecem mais de uma vez nos seus registros. Use como mapa de reflexão.",
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              "$totalAssessments registros analisados",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringPatternCard extends StatelessWidget {
  final int index;
  final Color color;
  final String label;
  final String area;
  final String group;
  final String count;
  final String averageScore;
  final String text;
  final String reflection;

  const _RecurringPatternCard({
    required this.index,
    required this.color,
    required this.label,
    required this.area,
    required this.group,
    required this.count,
    required this.averageScore,
    required this.text,
    required this.reflection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: color.withOpacity(0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    "$index",
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2544),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "$area • $group",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: "Aparições",
                  value: count,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  label: "Força média",
                  value: averageScore,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF1F2544),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              reflection,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF1F2544),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B6F8A),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  final String text;

  const _DisclaimerCard({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8505B).withOpacity(0.07),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFE8505B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF1F2544),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.repeat_rounded,
            color: Color(0xFF6B4FD8),
            size: 48,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Color(0xFF6B6F8A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFE8505B),
                size: 48,
              ),
              const SizedBox(height: 14),
              const Text(
                "Não foi possível carregar recorrências.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2544),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF6B6F8A),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text("Tentar novamente"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
