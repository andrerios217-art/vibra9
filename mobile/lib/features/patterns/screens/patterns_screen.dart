import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";

class PatternsScreen extends StatefulWidget {
  const PatternsScreen({super.key});

  @override
  State<PatternsScreen> createState() => _PatternsScreenState();
}

class _PatternsScreenState extends State<PatternsScreen> {
  bool loading = true;
  Map<String, dynamic>? data;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadPatterns();
  }

  Future<void> loadPatterns() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiClient.get(
        "/patterns/latest",
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
    return const Color(0xFFF5B942);
  }

  @override
  Widget build(BuildContext context) {
    final hasData = data?["has_data"] == true;
    final patterns = hasData ? data!["patterns"] as List<dynamic> : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Mapa de padrões"),
        actions: [
          IconButton(
            onPressed: loadPatterns,
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
                    onRetry: loadPatterns,
                  )
                : RefreshIndicator(
                    onRefresh: loadPatterns,
                    child: ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        const _HeroCard(),
                        const SizedBox(height: 20),
                        if (!hasData || patterns.isEmpty)
                          _EmptyState(
                            message: data?["message"]?.toString() ??
                                "Faça uma avaliação para visualizar padrões percebidos.",
                          )
                        else ...[
                          Text(
                            "Padrões percebidos",
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1F2544),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Esses pontos são hipóteses de reflexão baseadas nas suas respostas mais recentes.",
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

                            return _PatternCard(
                              index: index + 1,
                              color: patternColor(index),
                              label: pattern["label"]?.toString() ?? "",
                              area: pattern["area"]?.toString() ?? "",
                              group: pattern["group"]?.toString() ?? "",
                              text: pattern["safe_text"]?.toString() ?? "",
                              reflection:
                                  pattern["reflection"]?.toString() ?? "",
                            );
                          }),
                          const SizedBox(height: 14),
                          _DisclaimerCard(
                            text: data?["disclaimer"]?.toString() ??
                                "Esses padrões não representam diagnóstico.",
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.account_tree_rounded,
            color: Colors.white,
            size: 46,
          ),
          SizedBox(height: 18),
          Text(
            "Mapa de autopercepção",
            style: TextStyle(
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Veja sinais possíveis que aparecem a partir das suas respostas. Use como reflexão, não como diagnóstico.",
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  final int index;
  final Color color;
  final String label;
  final String area;
  final String group;
  final String text;
  final String reflection;

  const _PatternCard({
    required this.index,
    required this.color,
    required this.label,
    required this.area,
    required this.group,
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
          const SizedBox(height: 12),
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
            Icons.search_rounded,
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
                "Não foi possível carregar padrões.",
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
