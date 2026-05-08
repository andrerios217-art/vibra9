import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";

class RecurringPatternsScreen extends StatefulWidget {
  const RecurringPatternsScreen({super.key});

  @override
  State<RecurringPatternsScreen> createState() => _RecurringPatternsScreenState();
}

class _RecurringPatternsScreenState extends State<RecurringPatternsScreen> {
  bool loading = true;
  List<dynamic> patterns = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadRecurringPatterns();
  }

  Future<void> loadRecurringPatterns() async {
    setState(() { loading = true; errorMessage = null; });
    try {
      final response = await ApiClient.get("/patterns/recurring", auth: true);
      if (!mounted) return;
      setState(() {
        patterns = response["patterns"] as List<dynamic>? ?? [];
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
    const colors = [
      Color(0xFF6B4FD8), Color(0xFF42B8B0),
      Color(0xFFF5B942), Color(0xFF59B36A), Color(0xFFE8505B),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Padrões recorrentes"),
        actions: [
          IconButton(onPressed: loadRecurringPatterns, icon: const Icon(Icons.refresh_rounded), tooltip: "Atualizar"),
        ],
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? _ErrorState(message: errorMessage!, onRetry: loadRecurringPatterns)
                : RefreshIndicator(
                    onRefresh: loadRecurringPatterns,
                    child: ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        const _HeroCard(),
                        const SizedBox(height: 20),
                        if (patterns.isEmpty)
                          const _EmptyState()
                        else ...[
                          const Text("Mais frequentes",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
                          const SizedBox(height: 6),
                          const Text(
                            "Dimensões que apareceram com atenção em 60% ou mais das suas avaliações recentes.",
                            style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF6B6F8A))),
                          const SizedBox(height: 16),
                          ...List.generate(patterns.length, (index) {
                            final p = Map<String, dynamic>.from(patterns[index]);
                            return _RecurringCard(
                              index: index + 1,
                              color: patternColor(index),
                              label: p["label"]?.toString() ?? "",
                              occurrences: (p["occurrences"] as num?)?.toInt() ?? 0,
                              lowPercentage: (p["low_percentage"] as num?)?.toInt() ?? 0,
                              avgScore: (p["avg_score"] as num?)?.toDouble() ?? 0,
                              message: p["message"]?.toString() ?? "",
                            );
                          }),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8505B).withOpacity(0.07),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline_rounded, color: Color(0xFFE8505B), size: 18),
                                SizedBox(width: 10),
                                Expanded(child: Text(
                                  "Padrões recorrentes são hipóteses de reflexão, não diagnósticos.",
                                  style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF1F2544)))),
                              ],
                            ),
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
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6B4FD8), Color(0xFF42B8B0)]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.repeat_rounded, color: Colors.white, size: 40),
          SizedBox(height: 16),
          Text("O que vem se repetindo",
            style: TextStyle(fontSize: 24, height: 1.2, fontWeight: FontWeight.w700, color: Colors.white)),
          SizedBox(height: 8),
          Text("Veja sinais que aparecem mais de uma vez nos seus registros. Use como mapa de reflexão.",
            style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  final int index;
  final Color color;
  final String label;
  final int occurrences;
  final int lowPercentage;
  final double avgScore;
  final String message;

  const _RecurringCard({
    required this.index, required this.color, required this.label,
    required this.occurrences, required this.lowPercentage,
    required this.avgScore, required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text("$index", style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1F2544)))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Metric(label: "Avaliações", value: "$occurrences", color: color),
              const SizedBox(width: 8),
              _Metric(label: "Com atenção", value: "$lowPercentage%", color: color),
              const SizedBox(width: 8),
              _Metric(label: "Média", value: "${avgScore.toStringAsFixed(1)}/10", color: color),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(16)),
            child: Text(message, style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF1F2544))),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Metric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFF8F5FF), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
            Text(label, style: const TextStyle(color: Color(0xFF6B6F8A), fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: const Column(
        children: [
          Icon(Icons.repeat_rounded, color: Color(0xFF6B4FD8), size: 48),
          SizedBox(height: 14),
          Text("Nenhum padrão recorrente ainda.", textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
          SizedBox(height: 8),
          Text(
            "Faça pelo menos 3 avaliações para que o sistema identifique o que vem se repetindo.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF6B6F8A))),
        ],
      ),
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
              const Text("Não foi possível carregar recorrências.", textAlign: TextAlign.center,
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
