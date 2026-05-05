import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
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

  DateTime? parseDate(String value) {
    return DateTime.tryParse(value)?.toLocal();
  }

  String dateKey(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, "0");
    final d = date.day.toString().padLeft(2, "0");

    return "$y-$m-$d";
  }

  int currentStreak() {
    if (items.isEmpty) return 0;

    final uniqueDays = <String>{};

    for (final item in items) {
      final parsed = parseDate(item["created_at"].toString());

      if (parsed != null) {
        uniqueDays.add(dateKey(parsed));
      }
    }

    if (uniqueDays.isEmpty) return 0;

    var cursor = DateTime.now();
    var streak = 0;

    for (int i = 0; i < 365; i++) {
      final key = dateKey(cursor);

      if (uniqueDays.contains(key)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        if (streak == 0) {
          cursor = cursor.subtract(const Duration(days: 1));
          continue;
        }

        break;
      }
    }

    return streak;
  }

  int bestScore() {
    if (items.isEmpty) return 0;

    return items
        .map((item) => item["general_score"] as int)
        .reduce((a, b) => a > b ? a : b);
  }

  int averageScore() {
    if (items.isEmpty) return 0;

    final total = items.fold<int>(
      0,
      (sum, item) => sum + (item["general_score"] as int),
    );

    return (total / items.length).round();
  }

  bool hasHighDimension() {
    for (final item in items) {
      final dimensions = item["dimensions"] as List<dynamic>;

      for (final dimension in dimensions) {
        if ((dimension["score"] as int) >= 9) {
          return true;
        }
      }
    }

    return false;
  }

  bool hasLowRecovery() {
    if (items.length < 2) return false;

    final ordered = [...items].reversed.toList();

    for (int i = 1; i < ordered.length; i++) {
      final previous = ordered[i - 1]["general_score"] as int;
      final current = ordered[i]["general_score"] as int;

      if (previous <= 40 && current >= 60) {
        return true;
      }
    }

    return false;
  }

  List<Achievement> achievements() {
    final total = items.length;
    final streak = currentStreak();
    final best = bestScore();
    final average = averageScore();

    return [
      Achievement(
        title: "Primeiro check-in",
        description: "Faça sua primeira avaliação.",
        icon: Icons.favorite_rounded,
        color: const Color(0xFF6B4FD8),
        unlocked: total >= 1,
        progress: total >= 1 ? 1 : 0,
        target: 1,
      ),
      Achievement(
        title: "Consistência inicial",
        description: "Complete 3 avaliações.",
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF59B36A),
        unlocked: total >= 3,
        progress: total.clamp(0, 3),
        target: 3,
      ),
      Achievement(
        title: "Jornada em andamento",
        description: "Complete 7 avaliações.",
        icon: Icons.route_rounded,
        color: const Color(0xFF42B8B0),
        unlocked: total >= 7,
        progress: total.clamp(0, 7),
        target: 7,
      ),
      Achievement(
        title: "Sequência de 3 dias",
        description: "Faça check-in por 3 dias seguidos.",
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFF5B942),
        unlocked: streak >= 3,
        progress: streak.clamp(0, 3),
        target: 3,
      ),
      Achievement(
        title: "Bom equilíbrio",
        description: "Alcance índice geral de 80 ou mais.",
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFF6B4FD8),
        unlocked: best >= 80,
        progress: best.clamp(0, 80),
        target: 80,
      ),
      Achievement(
        title: "Força em destaque",
        description: "Tenha uma dimensão com nota 9 ou 10.",
        icon: Icons.bolt_rounded,
        color: const Color(0xFFF5B942),
        unlocked: hasHighDimension(),
        progress: hasHighDimension() ? 1 : 0,
        target: 1,
      ),
      Achievement(
        title: "Retomada",
        description: "Saia de um momento de atenção para um resultado melhor.",
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF59B36A),
        unlocked: hasLowRecovery(),
        progress: hasLowRecovery() ? 1 : 0,
        target: 1,
      ),
      Achievement(
        title: "Média estável",
        description: "Mantenha média geral acima de 70.",
        icon: Icons.balance_rounded,
        color: const Color(0xFF42B8B0),
        unlocked: total >= 3 && average >= 70,
        progress: average.clamp(0, 70),
        target: 70,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final streak = currentStreak();
    final total = items.length;
    final best = bestScore();
    final unlocked = achievements().where((item) => item.unlocked).length;
    final allAchievements = achievements();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Conquistas"),
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadHistory,
                child: ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    Container(
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
                            Icons.emoji_events_rounded,
                            color: Colors.white,
                            size: 46,
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            "Sua consistência importa",
                            style: TextStyle(
                              fontSize: 26,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Conquistas ajudam a visualizar pequenos avanços, sem cobrança excessiva.",
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: _HeaderMetric(
                                  value: "$streak",
                                  label: "dias seguidos",
                                ),
                              ),
                              Expanded(
                                child: _HeaderMetric(
                                  value: "$total",
                                  label: "avaliações",
                                ),
                              ),
                              Expanded(
                                child: _HeaderMetric(
                                  value: "$unlocked",
                                  label: "conquistas",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _SmallStatCard(
                            title: "Melhor índice",
                            value: "$best",
                            icon: Icons.arrow_upward_rounded,
                            color: const Color(0xFF59B36A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SmallStatCard(
                            title: "Desbloqueadas",
                            value: "$unlocked/${allAchievements.length}",
                            icon: Icons.lock_open_rounded,
                            color: const Color(0xFF6B4FD8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      "Conquistas",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2544),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...allAchievements.map(
                      (achievement) => _AchievementCard(
                        achievement: achievement,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "As conquistas são incentivos leves para consistência. Elas não representam diagnóstico ou obrigação de desempenho.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
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

class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool unlocked;
  final int progress;
  final int target;

  const Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlocked,
    required this.progress,
    required this.target,
  });
}

class _HeaderMetric extends StatelessWidget {
  final String value;
  final String label;

  const _HeaderMetric({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SmallStatCard({
    required this.title,
    required this.value,
    required this.icon,
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
          color: color.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 30,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B6F8A),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    final color = achievement.unlocked
        ? achievement.color
        : const Color(0xFF6B6F8A);

    final progress = achievement.target == 0
        ? 0.0
        : (achievement.progress / achievement.target).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: color.withOpacity(0.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              achievement.unlocked
                  ? achievement.icon
                  : Icons.lock_outline_rounded,
              color: color,
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF1F2544),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF6B6F8A),
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: color.withOpacity(0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (achievement.unlocked)
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF59B36A),
            ),
        ],
      ),
    );
  }
}

