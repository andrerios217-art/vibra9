import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";
import "../../auth/screens/login_screen.dart";
import "../../auth/screens/register_screen.dart";

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int currentPage = 0;

  final pages = const [
    _OnboardingPageData(
      icon: Icons.favorite_rounded,
      title: "Conheça seu momento",
      text:
          "Faça um check-in rápido em 9 dimensões e entenda como está seu equilíbrio hoje.",
      color: Color(0xFF6B4FD8),
    ),
    _OnboardingPageData(
      icon: Icons.checklist_rounded,
      title: "Transforme em ação",
      text:
          "Receba pequenas ações práticas para cuidar do seu foco, energia, emoções e rotina.",
      color: Color(0xFF59B36A),
    ),
    _OnboardingPageData(
      icon: Icons.insights_rounded,
      title: "Acompanhe sua evolução",
      text:
          "Veja seu histórico, gráficos e padrões ao longo do tempo, sem misticismo exagerado.",
      color: Color(0xFF42B8B0),
    ),
  ];

  Future<void> finishOnboarding({required bool createAccount}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("onboarding_seen", true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => createAccount ? const RegisterScreen() : const LoginScreen(),
      ),
    );
  }

  void nextPage() {
    if (currentPage < pages.length - 1) {
      controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      finishOnboarding(createAccount: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => finishOnboarding(createAccount: false),
                  child: const Text("Entrar"),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() => currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final page = pages[index];

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            color: page.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(42),
                            boxShadow: [
                              BoxShadow(
                                color: page.color.withOpacity(0.12),
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Icon(
                            page.icon,
                            size: 68,
                            color: page.color,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 31,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1F2544),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.45,
                            color: Color(0xFF6B6F8A),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (index) {
                  final active = index == currentPage;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 26 : 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF6B4FD8)
                          : const Color(0xFF6B4FD8).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: nextPage,
                  child: Text(
                    isLast ? "Criar minha conta" : "Continuar",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => finishOnboarding(createAccount: false),
                child: const Text("Já tenho conta"),
              ),
              const SizedBox(height: 8),
              const Text(
                "O Vibra9 oferece orientações gerais de bem-estar e autoconhecimento. Não substitui acompanhamento profissional.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
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

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });
}
