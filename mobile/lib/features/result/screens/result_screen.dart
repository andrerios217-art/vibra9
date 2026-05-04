import "package:flutter/material.dart";
import "../../home/screens/home_screen.dart";

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> assessment;
  final Map<String, dynamic> recommendation;

  const ResultScreen({
    super.key,
    required this.assessment,
    required this.recommendation,
  });

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

  @override
  Widget build(BuildContext context) {
    final int generalScore = assessment["general_score"] as int;
    final dimensions = assessment["dimensions"] as List<dynamic>;
    final actions = recommendation["daily_actions"] as List<dynamic>;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Seu resultado"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: "Início",
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.home_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            _ScoreHeroCard(
              score: generalScore,
              label: scoreLabel(generalScore),
              color: scoreColor(generalScore),
              summary: recommendation["summary"].toString(),
            ),
            const SizedBox(height: 20),
            _FocusCard(
              focus: recommendation["main_focus"].toString(),
            ),
            const SizedBox(height: 20),
            _SectionTitle(
              title: "Ações para hoje",
              subtitle: "Pequenos passos práticos, sem cobrança excessiva.",
            ),
            const SizedBox(height: 12),
            ...actions.map(
              (action) => _ActionCard(text: action.toString()),
            ),
            const SizedBox(height: 22),
            _SectionTitle(
              title: "Suas 9 dimensões",
              subtitle: "Veja onde você está mais forte e onde pode cuidar melhor.",
            ),
            const SizedBox(height: 12),
            ...dimensions.map(
              (item) {
                final int score = item["score"] as int;

                return _DimensionBar(
                  label: item["label"].toString(),
                  status: item["status"].toString(),
                  score: score,
                  color: dimensionColor(score),
                );
              },
            ),
            const SizedBox(height: 22),
            _QuoteCard(
              quote: recommendation["quote"].toString(),
              author: recommendation["quote_author"].toString(),
            ),
            const SizedBox(height: 18),
            _SafetyCard(
              text: recommendation["safety_note"].toString(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  "Concluir",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreHeroCard extends StatelessWidget {
  final int score;
  final String label;
  final Color color;
  final String summary;

  const _ScoreHeroCard({
    required this.score,
    required this.label,
    required this.color,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 142,
            height: 142,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12,
                  backgroundColor: color.withOpacity(0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$score",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: color,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "/100",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B6F8A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            label,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2544),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF1F2544),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final String focus;

  const _FocusCard({
    required this.focus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6B4FD8),
            Color(0xFF42B8B0),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4FD8).withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.center_focus_strong_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Foco de hoje",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  focus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1F2544),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            height: 1.35,
            color: Color(0xFF6B6F8A),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String text;

  const _ActionCard({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF6B4FD8).withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF59B36A).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF59B36A),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.35,
                color: Color(0xFF1F2544),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DimensionBar extends StatelessWidget {
  final String label;
  final String status;
  final int score;
  final Color color;

  const _DimensionBar({
    required this.label,
    required this.status,
    required this.score,
    required this.color,
  });

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
    final double progress = score / 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2544),
                  ),
                ),
              ),
              Text(
                "$score/10",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: color.withOpacity(0.10),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusText(status),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B6F8A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final String quote;
  final String author;

  const _QuoteCard({
    required this.quote,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFF5B942).withOpacity(0.22),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.format_quote_rounded,
            color: Color(0xFFF5B942),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            quote,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Color(0xFF1F2544),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "— $author",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B6F8A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  final String text;

  const _SafetyCard({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8505B).withOpacity(0.07),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFE8505B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
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
