import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";
import "core/services/token_storage.dart";
import "core/theme/app_theme.dart";
import "features/auth/screens/login_screen.dart";
import "features/home/screens/home_screen.dart";
import "features/onboarding/screens/onboarding_screen.dart";

void main() {
  runApp(const Vibra9App());
}

class Vibra9App extends StatelessWidget {
  const Vibra9App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Vibra9",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SessionGate(),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  bool loading = true;
  bool logged = false;
  bool onboardingSeen = false;

  @override
  void initState() {
    super.initState();
    checkSession();
  }

  Future<void> checkSession() async {
    final token = await TokenStorage.getToken();
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      logged = token != null;
      onboardingSeen = prefs.getBool("onboarding_seen") ?? false;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F5FF),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (logged) {
      return const HomeScreen();
    }

    if (!onboardingSeen) {
      return const OnboardingScreen();
    }

    return const LoginScreen();
  }
}
