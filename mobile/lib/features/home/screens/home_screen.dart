import "package:flutter/material.dart";
import "../../../core/services/token_storage.dart";
import "../../achievements/screens/achievements_screen.dart";
import "../../assessment/screens/assessment_screen.dart";
import "../../auth/screens/login_screen.dart";
import "../../breathing/screens/breathing_screen.dart";
import "../../history/screens/evolution_screen.dart";
import "../../history/screens/history_screen.dart";
import "../../practices/screens/practices_screen.dart";
import "../../profile/screens/profile_screen.dart";
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

  @override
  void initState() {
    super.initState();
    loadName();
  }

  Future<void> loadName() async {
    final storedName = await TokenStorage.getName();

    if (mounted) {
      setState(() => name = storedName ?? "você");
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
    );
  }

  void openAssessment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AssessmentScreen()),
    );
  }

  void openEvolution() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EvolutionScreen()),
    );
  }

  void openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
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

  void openPractices() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PracticesScreen()),
    );
  }

  void openAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AchievementsScreen()),
    );
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Vibra9"),
        actions: [
          IconButton(
            onPressed: openProfile,
            icon: const Icon(Icons.person_rounded),
            tooltip: "Perfil",
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: "Sair",
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
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
              ),
            ),
            const SizedBox(height: 24),
            Container(
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
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.spa_rounded,
                    color: Colors.white,
                    size: 42,
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
                    "Check-in, foco, ritual, reflexão, práticas e pausa guiada.",
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
                      onPressed: openToday,
                      child: const Text(
                        "Abrir Hoje",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.04,
              children: [
                _HomeTile(
                  title: "Avaliação",
                  subtitle: "9 dimensões",
                  icon: Icons.favorite_rounded,
                  color: const Color(0xFF6B4FD8),
                  onTap: openAssessment,
                ),
                _HomeTile(
                  title: "Ritual",
                  subtitle: "3 ações",
                  icon: Icons.checklist_rounded,
                  color: const Color(0xFF59B36A),
                  onTap: openRitual,
                ),
                _HomeTile(
                  title: "Práticas",
                  subtitle: "biblioteca",
                  icon: Icons.spa_rounded,
                  color: const Color(0xFF6B4FD8),
                  onTap: openPractices,
                ),
                _HomeTile(
                  title: "Reflexão",
                  subtitle: "diário breve",
                  icon: Icons.edit_note_rounded,
                  color: const Color(0xFF42B8B0),
                  onTap: openReflection,
                ),
                _HomeTile(
                  title: "Pausa",
                  subtitle: "60 segundos",
                  icon: Icons.air_rounded,
                  color: const Color(0xFF42B8B0),
                  onTap: openBreathing,
                ),
                _HomeTile(
                  title: "Evolução",
                  subtitle: "gráfico",
                  icon: Icons.insights_rounded,
                  color: const Color(0xFFF5B942),
                  onTap: openEvolution,
                ),
                _HomeTile(
                  title: "Conquistas",
                  subtitle: "sequência",
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFFF5B942),
                  onTap: openAchievements,
                ),
                _HomeTile(
                  title: "Histórico",
                  subtitle: "resultados",
                  icon: Icons.history_rounded,
                  color: const Color(0xFF2E236C),
                  onTap: openHistory,
                ),
                _HomeTile(
                  title: "Perfil",
                  subtitle: "conta",
                  icon: Icons.person_rounded,
                  color: const Color(0xFFE8505B),
                  onTap: openProfile,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HomeTile({
    required this.title,
    required this.subtitle,
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
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 29,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF1F2544),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
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
