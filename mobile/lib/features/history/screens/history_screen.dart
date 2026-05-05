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
  String? disclaimer;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiClient.get(
        "/history/with-patterns",
        auth: true,
      );

      if (!mounted) return;

      setState(() {
        items = response["items"] as List<dynamic>;
        disclaimer = response["disclaimer"]?.toString();
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

  String scoreLabel(int score) {
    if (score <= 40) return "Atenção";
    if (score <= 70) return "Em desenvolvimento";
    return "Equilibrado";
  }

  String formatDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed == null) return value;

    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, "0");
    final month = local.month.toString().padLeft(2, "0");
    final hour = local.hour.toString().padLeft(2, "0");
    final minute = local.minute.toString().padLeft(2, "0");

    return "$day/$month às $hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Histórico"),
        actions: [
          IconButton(
            onPressed: loadHistory,
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
                    onRetry: loadHistory,
                  )
                : RefreshIndicator(
                    onRefresh: loadHistory,
                    child: items.isEmpty
                        ? const _EmptyState()
                        : ListView(
                            padding: const EdgeInsets.all(22),
                            children: [
                              const _HeroCard(),
                              const SizedBox(height: 20),
                              ...items.map((item) {
                                final assessment =
                                    Map<String, dynamic>.from(item);
                                final score =
                                    assessment["general_score"] as int;
                                final patterns =
                                    assessment["patterns"] as List<dynamic>;

                                return _HistoryCard(
                                  score: score,
                                  color: scoreColor(score),
                                  label: scoreLabel(score),
                                  date: formatDate(
                                    assessment["created_at"].toString(),
                                  ),
                                  patterns: patterns,
                                );
                              }),
                              if (disclaimer != null) ...[
                                const SizedBox(height: 12),
                                _DisclaimerCard(text: disclaimer!),
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
            Icons.history_rounded,
            color: Colors.white,
            size: 44,
          ),
          SizedBox(height: 18),
          Text(
            "Sua linha do tempo",
            style: TextStyle(
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Veja seus resultados e os padrões percebidos em cada registro.",
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

class _HistoryCard extends StatelessWidget {
  final int score;
  final Color color;
  final String label;
  final String date;
  final List<dynamic> patterns;

  const _HistoryCard({
    required this.score,
    required this.color,
    required this.label,
    required this.date,
    required this.patterns,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 8,
                      backgroundColor: color.withOpacity(0.10),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    Center(
                      child: Text(
                        "$score",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2544),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6F8A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (patterns.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              "Padrões percebidos",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1F2544),
              ),
            ),
            const SizedBox(height: 10),
            ...patterns.take(3).map((item) {
              final pattern = Map<String, dynamic>.from(item);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_tree_rounded,
                      color: Color(0xFF6B4FD8),
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pattern["label"]?.toString() ?? "",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1F2544),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 14),
            const Text(
              "Nenhum padrão salvo neste registro.",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B6F8A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.history_rounded,
                color: Color(0xFF6B4FD8),
                size: 52,
              ),
              SizedBox(height: 16),
              Text(
                "Nenhum histórico ainda",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2544),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Faça uma avaliação para começar a acompanhar sua evolução.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Color(0xFF6B6F8A),
                ),
              ),
            ],
          ),
        ),
      ],
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
                "Não foi possível carregar histórico.",
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
