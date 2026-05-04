import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  final controller = TextEditingController();

  bool loading = true;
  bool saved = false;

  @override
  void initState() {
    super.initState();
    loadReflection();
  }

  String todayKey() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, "0");
    final d = now.day.toString().padLeft(2, "0");

    return "reflection_$y$m$d";
  }

  Future<void> loadReflection() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(todayKey()) ?? "";

    if (!mounted) return;

    setState(() {
      controller.text = value;
      loading = false;
      saved = value.trim().isNotEmpty;
    });
  }

  Future<void> saveReflection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(todayKey(), controller.text.trim());

    if (!mounted) return;

    setState(() => saved = controller.text.trim().isNotEmpty);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reflexão salva."),
      ),
    );
  }

  Future<void> clearReflection() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Limpar reflexão?"),
          content: const Text(
            "Isso vai apagar sua reflexão de hoje neste dispositivo.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Limpar"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(todayKey());

    controller.clear();

    if (!mounted) return;

    setState(() => saved = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Reflexão do dia"),
        actions: [
          IconButton(
            tooltip: "Limpar",
            onPressed: clearReflection,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: const Color(0xFF6B4FD8).withOpacity(0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B4FD8).withOpacity(0.08),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4FD8).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: Color(0xFF6B4FD8),
                            size: 50,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Escreva para organizar",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1F2544),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Uma reflexão curta ajuda a perceber padrões sem transformar tudo em problema.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: Color(0xFF6B6F8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _PromptCard(
                    title: "Perguntas-guia",
                    questions: [
                      "O que mais ocupou minha mente hoje?",
                      "Qual pequena ação pode deixar meu dia mais leve?",
                      "O que eu preciso aceitar sem me cobrar tanto?",
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    minLines: 9,
                    maxLines: 14,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText:
                          "Escreva livremente. Exemplo: Hoje percebi que...",
                      alignLabelWithHint: true,
                      labelText: "Minha reflexão",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) {
                      if (saved) {
                        setState(() => saved = false);
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: saveReflection,
                      icon: Icon(
                        saved
                            ? Icons.check_circle_rounded
                            : Icons.save_rounded,
                      ),
                      label: Text(
                        saved ? "Salvo" : "Salvar reflexão",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Esta reflexão fica salva localmente neste dispositivo. Em uma versão futura, ela pode ser sincronizada com sua conta mediante consentimento.",
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
    );
  }
}

class _PromptCard extends StatelessWidget {
  final String title;
  final List<String> questions;

  const _PromptCard({
    required this.title,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFF5B942).withOpacity(0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFF5B942),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2544),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...questions.map(
            (question) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "• ",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFF5B942),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Color(0xFF1F2544),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
