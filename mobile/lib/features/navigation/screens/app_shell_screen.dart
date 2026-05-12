import "package:flutter/material.dart";
import "../../home/screens/home_screen.dart";
import "../../practices/screens/practices_screen.dart";
import "../../history/screens/evolution_screen.dart";
import "../../profile/screens/profile_screen.dart";

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int currentIndex = 0;
  DateTime? _lastBackPressed;

  // Cada tela é instanciada com Key única para forçar reload quando reabre
  late final List<Widget> screens = const [
    HomeScreen(key: PageStorageKey("home")),
    PracticesScreen(key: PageStorageKey("practices")),
    EvolutionScreen(key: PageStorageKey("evolution")),
    ProfileScreen(key: PageStorageKey("profile")),
  ];

  Future<bool> _onWillPop() async {
    if (currentIndex != 0) {
      setState(() => currentIndex = 0);
      return false;
    }
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pressione voltar novamente para sair"),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF6B4FD8).withOpacity(0.12),
          surfaceTintColor: Colors.white,
          onDestinationSelected: (index) {
            setState(() => currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Color(0xFF6B6F8A)),
              selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF6B4FD8)),
              label: "Início",
            ),
            NavigationDestination(
              icon: Icon(Icons.spa_outlined, color: Color(0xFF6B6F8A)),
              selectedIcon: Icon(Icons.spa_rounded, color: Color(0xFF6B4FD8)),
              label: "Práticas",
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined, color: Color(0xFF6B6F8A)),
              selectedIcon: Icon(Icons.insights_rounded, color: Color(0xFF6B4FD8)),
              label: "Evolução",
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: Color(0xFF6B6F8A)),
              selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF6B4FD8)),
              label: "Perfil",
            ),
          ],
        ),
      ),
    );
  }
}
