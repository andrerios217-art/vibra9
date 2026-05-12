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
  bool isDirty = false;
  bool hasSavedContent = false;

  @override
  void initState() {
    super.initState();
    loadReflection();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
      isDirty = false;
      hasSavedContent = value.trim().isNotEmpty;
    });
  }

  Future<void> saveReflection() async {
    final text = controller.text.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(todayKey(), text);
    if (!mounted) return;
    setState(() {
      isDirty = false;
      hasSavedContent = text.isNotEmpty;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reflexão salva."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> clearReflection() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Limpar reflexão?"),
          content: const Text("Isso vai apagar sua reflexão de hoje neste dispositivo. Esta ação não pode ser desfeita."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE8505B)),
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
    setState(() {
      isDirty = false;
      hasSavedContent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSave = isDirty || (controller.text.trim().isNotEmpty && !hasSavedContent);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Reflexão do dia"),
        actions: [
          if (hasSavedContent)
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.10)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 76, height: 76,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4FD8).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.edit_note_rounded, color: Color(0xFF6B4FD8), size: 44),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Escreva para organizar",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1F2544)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Uma reflexão curta ajuda a perceber padrões sem transformar tudo em problema.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF6B6F8A)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _PromptCard(
                    title: "Perguntas-guia",
                    questions: [
                      "O que mais ocupou minha mente hoje?",
                      "Qual pequena ação pode deixar meu dia mais leve?",
                      "O que eu preciso aceitar sem me cobrar tanto?",
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    minLines: 9,
                    maxLines: 14,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: "Escreva livremente. Exemplo: Hoje percebi que...",
                      alignLabelWithHint: true,
                      labelText: "Minha reflexão",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) {
                      if (!isDirty) {
                        setState(() => isDirty = true);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4FD8),
                      ),
                      onPressed: canSave ? saveReflection : null,
                      icon: Icon(
                        canSave ? Icons.save_rounded : Icons.check_circle_rounded,
                      ),
                      label: Text(
                        canSave ? "Salvar reflexão" : "Salvo",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Esta reflexão fica salva localmente neste dispositivo. Em uma versão futura, ela poderá ser sincronizada com sua conta mediante consentimento.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, height: 1.5, color: Color(0xFF6B6F8A)),
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

  const _PromptCard({required this.title, required this.questions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5B942).withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF5B942), size: 20),
              const SizedBox(width: 10),
              Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
            ],
          ),
          const SizedBox(height: 12),
          ...questions.map(
            (question) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ",
                    style: TextStyle(fontSize: 14, color: Color(0xFFF5B942), fontWeight: FontWeight.w700)),
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF1F2544), fontWeight: FontWeight.w500),
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
