import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";

class PatternsScreen extends StatefulWidget {
  const PatternsScreen({super.key});

  @override
  State<PatternsScreen> createState() => _PatternsScreenState();
}

class _PatternsScreenState extends State<PatternsScreen> {
  bool loading = true;
  List<dynamic> patterns = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadPatterns();
  }

  Future<void> loadPatterns() async {
    setState(() { loading = true; errorMessage = null; });
    try {
      await ApiClient.post("/patterns/backfill", auth: true, body: {});
    } catch (_) {}
    try {
      final response = await ApiClient.get("/patterns/latest", auth: true);
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
    if (index == 0) return const Color(0xFF6B4FD8);
    if (index == 1) return const Color(0xFF42B8B0);
    return const Color(0xFFF5B942);
  }

  String trendLabel(String trend) {
    if (trend == "declining") return "Em queda";
    if (trend == "improving") return "Em melhora";
    return "Estável";
  }

  IconData trendIcon(String trend) {
    if (trend == "declining") return Icons.trending_down_rounded;
    if (trend == "improving") return Icons.trending_up_rounded;
    return Icons.trending_flat_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Mapa de padrões"),
        actions: [
          IconButton(onPressed: loadPatterns, icon: const Icon(Icons.refresh_rounded), tooltip: "Atualizar"),
        ],
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? _ErrorState(message: errorMessage!, onRetry: loadPatterns)
                : RefreshIndicator(
                    onRefresh: loadPatterns,
                    child: ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        const _HeroCard(),
                        const SizedBox(height: 20),
                        if (patterns.isEmpty)
                          const _EmptyState()
                        else ...[
                          const Text("Padrões percebidos",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
                          const SizedBox(height: 6),
                          const Text(
                            "Hipóteses de reflexão baseadas nas suas avaliações recentes. Não representam diagnóstico.",
                            style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF6B6F8A))),
                          const SizedBox(height: 16),
                          ...List.generate(patterns.length, (index) {
                            final pattern = Map<String, dynamic>.from(patterns[index]);
                            return _PatternCard(
                              index: index + 1,
                              color: patternColor(index),
                              label: pattern["label"]?.toString() ?? "",
                              avgScore: (pattern["avg_score"] as num?)?.toDouble() ?? 0,
                              occurrences: (pattern["occurrences"] as num?)?.toInt() ?? 0,
                              trend: pattern["trend"]?.toString() ?? "stable",
                              message: pattern["message"]?.toString() ?? "",
                              trendLabel: trendLabel(pattern["trend"]?.toString() ?? "stable"),
                              trendIcon: trendIcon(pattern["trend"]?.toString() ?? "stable"),
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
                                  "Esses padrões são hipóteses de reflexão, não diagnósticos. Use como ponto de partida para o autoconhecimento.",
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
          Icon(Icons.account_tree_rounded, color: Colors.white, size: 40),
          SizedBox(height: 16),
          Text("Mapa de autopercepção",
            style: TextStyle(fontSize: 24, height: 1.2, fontWeight: FontWeight.w700, color: Colors.white)),
          SizedBox(height: 8),
          Text("Veja sinais possíveis que aparecem a partir das suas respostas. Use como reflexão, não como diagnóstico.",
            style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  final int index;
  final Color color;
  final String label;
  final double avgScore;
  final int occurrences;
  final String trend;
  final String message;
  final String trendLabel;
  final IconData trendIcon;

  const _PatternCard({
    required this.index, required this.color, required this.label,
    required this.avgScore, required this.occurrences, required this.trend,
    required this.message, required this.trendLabel, required this.trendIcon,
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
              _StatChip(label: "Média", value: "${avgScore.toStringAsFixed(1)}/10", color: color),
              const SizedBox(width: 8),
              _StatChip(label: "Ocorrências", value: "$occurrences avaliações", color: color),
              const SizedBox(width: 8),
              _StatChip(label: "Tendência", value: trendLabel, color: color, icon: trendIcon),
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const _StatChip({required this.label, required this.value, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFF8F5FF), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w500)),
            const SizedBox(height: 3),
            Row(
              children: [
                if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 3)],
                Expanded(child: Text(value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
              ],
            ),
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
          Icon(Icons.search_rounded, color: Color(0xFF6B4FD8), size: 48),
          SizedBox(height: 14),
          Text("Nenhum padrão identificado ainda.", textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
          SizedBox(height: 8),
          Text(
            "Faça pelo menos 2 avaliações para que o sistema identifique padrões nas suas respostas.",
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
              const Text("Não foi possível carregar padrões.", textAlign: TextAlign.center,
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
