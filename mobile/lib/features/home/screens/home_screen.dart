import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";
import "../../../core/services/token_storage.dart";
import "../../../core/widgets/app_logo.dart";
import "../../achievements/screens/achievements_screen.dart";
import "../../assessment/screens/assessment_screen.dart";
import "../../auth/screens/login_screen.dart";
import "../../breathing/screens/breathing_screen.dart";
import "../../deep_checkin/screens/deep_checkin_screen.dart";
import "../../history/screens/history_screen.dart";
import "../../patterns/screens/patterns_screen.dart";
import "../../patterns/screens/recurring_patterns_screen.dart";
import "../../reflection/screens/reflection_screen.dart";
import "../../ritual/screens/ritual_screen.dart";
import "../../today/screens/today_screen.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String name = "";
  bool loadingSummary = true;
  Map<String, dynamic>? latestAssessment;

  @override
  void initState() {
    super.initState();
    loadName();
    loadSummary();
  }

  Future<void> loadName() async {
    final storedName = await TokenStorage.getName();

    if (!mounted) return;

    setState(() => name = storedName ?? "você");
  }

  Future<void> loadSummary() async {
    try {
      final response = await ApiClient.get(
        "/history",
        auth: true,
      );

      final items = response["items"] as List<dynamic>;

      if (!mounted) return;

      setState(() {
        latestAssessment =
            items.isNotEmpty ? Map<String, dynamic>.from(items.first) : null;
        loadingSummary = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => loadingSummary = false);
    }
  }

  Future<void> logout() async {
    await TokenStorage.clear();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void openToday() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TodayScreen()),
    ).then((_) => loadSummary());
  }

  void openAssessment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AssessmentScreen()),
    ).then((_) => loadSummary());
  }

  void openDeepCheckin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeepCheckinScreen()),
    );
  }

  void openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  void openPatterns() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PatternsScreen()),
    );
  }

  void openRecurringPatterns() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecurringPatternsScreen()),
    );
  }

  void openRitual() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RitualScreen()),
    );
  }

  void openBreathing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BreathingScreen()),
    );
  }

  void openReflection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReflectionScreen()),
    );
  }

  void openAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AchievementsScreen()),
    );
  }

  Color scoreColor(int score) {
    if (score <= 40) return const Color(0xFFE8505B);
    if (score <= 70) return const Color(0xFFF5B942);
    return const Color(0xFF59B36A);
  }

  String scoreLabel(int score) {
    if (score <= 40) return "Pede cuidado";
    if (score <= 70) return "Em desenvolvimento";
    return "Bom equilíbrio";
  }

  String focusLabel() {
    final item = latestAssessment;

    if (item == null) return "Faça seu primeiro check-up";

    final dimensions = item["dimensions"] as List<dynamic>;

    if (dimensions.isEmpty) return "Rotina";

    final sorted = [...dimensions]..sort(
        (a, b) => (a["score"] as int).compareTo(b["score"] as int),
      );

    return sorted.first["label"].toString();
  }

  @override
  Widget build(BuildContext context) {
    final score = latestAssessment?["general_score"] as int?;
    final color = score == null ? const Color(0xFF6B4FD8) : scoreColor(score);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Vibra9"),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: "Sair",
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadSummary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                "Olá, $name",
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2544),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Seu painel de bem-estar diário.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B6F8A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              _TodayHeroCard(
                loading: loadingSummary,
                score: score,
                color: color,
                scoreLabel: score == null ? "Sem avaliação ainda" : scoreLabel(score),
                focus: focusLabel(),
                onTap: openToday,
                onAssessment: openAssessment,
              ),
              const SizedBox(height: 22),
              const Text(
                "Ações rápidas",
                style: TextStyle(
                  fontSize: 22,
                  color: Color(0xFF1F2544),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 700 ? 3 : 2;
                  final ratio = width >= 700 ? 1.25 : 0.92;

                  final items = [
                    _HomeAction(
                      title: "Avaliação",
                      subtitle: "9 dimensões",
                      icon: Icons.favorite_rounded,
                      color: const Color(0xFF6B4FD8),
                      onTap: openAssessment,
                    ),
                    _HomeAction(
                      title: "Check-up ampliado",
                      subtitle: "profundo",
                      icon: Icons.psychology_alt_rounded,
                      color: const Color(0xFF2E236C),
                      onTap: openDeepCheckin,
                    ),
                    _HomeAction(
                      title: "Ritual",
                      subtitle: "3 ações",
                      icon: Icons.checklist_rounded,
                      color: const Color(0xFF59B36A),
                      onTap: openRitual,
                    ),
                    _HomeAction(
                      title: "Reflexão",
                      subtitle: "diário breve",
                      icon: Icons.edit_note_rounded,
                      color: const Color(0xFF42B8B0),
                      onTap: openReflection,
                    ),
                    _HomeAction(
                      title: "Pausa",
                      subtitle: "60 segundos",
                      icon: Icons.air_rounded,
                      color: const Color(0xFF42B8B0),
                      onTap: openBreathing,
                    ),
                    _HomeAction(
                      title: "Conquistas",
                      subtitle: "sequência",
                      icon: Icons.emoji_events_rounded,
                      color: const Color(0xFFF5B942),
                      onTap: openAchievements,
                    ),
                    _HomeAction(
                      title: "Histórico",
                      subtitle: "resultados",
                      icon: Icons.history_rounded,
                      color: const Color(0xFF2E236C),
                      onTap: openHistory,
                    ),
                    _HomeAction(
                      title: "Mapa",
                      subtitle: "padrões",
                      icon: Icons.account_tree_rounded,
                      color: const Color(0xFF6B4FD8),
                      onTap: openPatterns,
                    ),
                    _HomeAction(
                      title: "Recorrências",
                      subtitle: "padrões",
                      icon: Icons.repeat_rounded,
                      color: const Color(0xFF42B8B0),
                      onTap: openRecurringPatterns,
                    ),
                  ];

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: ratio,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return _HomeTile(action: item);
                    },
                  );
                },
              ),
              const SizedBox(height: 18),
              const _SafetyMiniNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayHeroCard extends StatelessWidget {
  final bool loading;
  final int? score;
  final Color color;
  final String scoreLabel;
  final String focus;
  final VoidCallback onTap;
  final VoidCallback onAssessment;

  const _TodayHeroCard({
    required this.loading,
    required this.score,
    required this.color,
    required this.scoreLabel,
    required this.focus,
    required this.onTap,
    required this.onAssessment,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (score == null) {
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
              color: const Color(0xFF6B4FD8).withOpacity(0.20),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: AppLogo(size: 48),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Comece pelo seu momento de hoje",
              style: TextStyle(
                fontSize: 25,
                height: 1.15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Faça uma avaliação rápida e receba seu foco do dia.",
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6B4FD8),
                ),
                onPressed: onAssessment,
                child: const Text(
                  "Fazer avaliação",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(34),
      child: InkWell(
        borderRadius: BorderRadius.circular(34),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: color.withOpacity(0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: score! / 100,
                      strokeWidth: 10,
                      backgroundColor: color.withOpacity(0.10),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    Center(
                      child: Text(
                        "${score!}",
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
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Seu momento",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6F8A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      scoreLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 23,
                        height: 1.12,
                        color: Color(0xFF1F2544),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Foco: $focus",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Color(0xFF6B6F8A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Abrir Hoje",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HomeAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _HomeTile extends StatelessWidget {
  final _HomeAction action;

  const _HomeTile({
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: action.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: action.color.withOpacity(0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: action.color.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 29,
                ),
              ),
              const Spacer(),
              Text(
                action.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.12,
                  color: Color(0xFF1F2544),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                action.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B6F8A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyMiniNote extends StatelessWidget {
  const _SafetyMiniNote();

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




