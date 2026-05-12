import "dart:math" as math;
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";
import "../../../core/services/api_client.dart";

class RitualScreen extends StatefulWidget {
  const RitualScreen({super.key});

  @override
  State<RitualScreen> createState() => _RitualScreenState();
}

class _RitualScreenState extends State<RitualScreen> {
  bool loading = true;
  List<String> actions = [];
  List<bool> completed = [];

  @override
  void initState() {
    super.initState();
    loadRitual();
  }

  String todayKey() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, "0");
    final d = now.day.toString().padLeft(2, "0");
    return "ritual_$y$m$d";
  }

  Future<void> loadRitual() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Carrega ações primeiro
      final response = await ApiClient.get("/history", auth: true);
      final items = response["items"] as List<dynamic>;

      List<String> loadedActions;
      if (items.isEmpty) {
        loadedActions = [
          "Faça uma avaliação rápida para descobrir seu foco de hoje.",
          "Reserve 1 minuto para respirar antes da próxima tarefa.",
          "Escolha uma pequena ação de cuidado para repetir amanhã.",
        ];
      } else {
        final latest = Map<String, dynamic>.from(items.first);
        final weakest = weakestDimension(latest);
        loadedActions = suggestedActionsFor(weakest);
      }

      // Inicializa completed com tamanho correto
      final loadedCompleted = List<bool>.generate(
        loadedActions.length,
        (i) => prefs.getBool("${todayKey()}_$i") ?? false,
      );

      if (!mounted) return;
      setState(() {
        actions = loadedActions;
        completed = loadedCompleted;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final fallback = [
        "Beba um copo de água com calma.",
        "Organize uma pequena prioridade para hoje.",
        "Faça uma pausa curta sem tela.",
      ];
      final prefs = await SharedPreferences.getInstance();
      final loadedCompleted = List<bool>.generate(
        fallback.length,
        (i) => prefs.getBool("${todayKey()}_$i") ?? false,
      );
      setState(() {
        actions = fallback;
        completed = loadedCompleted;
        loading = false;
      });
    }
  }

  String weakestDimension(Map<String, dynamic> item) {
    final dimensions = item["dimensions"] as List<dynamic>;
    if (dimensions.isEmpty) return "rotina_foco";
    final sorted = [...dimensions]..sort((a, b) => (a["score"] as int).compareTo(b["score"] as int));
    return sorted.first["dimension"].toString();
  }

  List<String> suggestedActionsFor(String dimension) {
    switch (dimension) {
      case "clareza_mental":
        return [
          "Liste apenas 3 prioridades para hoje.",
          "Feche uma aba ou distração antes de começar.",
          "Anote uma decisão que precisa ser simplificada.",
        ];
      case "estado_emocional":
        return [
          "Nomeie a emoção principal que você sente agora.",
          "Faça uma pausa sem tela por 3 minutos.",
          "Escreva uma frase gentil para si mesmo.",
        ];
      case "proposito_pessoal":
        return [
          "Escolha uma ação pequena que tenha sentido para você.",
          "Relembre uma coisa que você valoriza.",
          "Evite comparar seu ritmo com o de outras pessoas.",
        ];
      case "energia_diaria":
        return [
          "Reduza o ritmo e escolha só o essencial.",
          "Beba água e faça uma pausa breve.",
          "Evite cobrar produtividade máxima hoje.",
        ];
      case "corpo_habitos":
        return [
          "Beba um copo de água agora.",
          "Alongue o corpo por 3 minutos.",
          "Planeje dormir um pouco mais cedo.",
        ];
      case "comunicacao":
        return [
          "Respire antes de responder uma mensagem difícil.",
          "Escreva o que quer dizer antes de falar.",
          "Faça uma pergunta antes de presumir intenção.",
        ];
      case "relacoes":
        return [
          "Envie uma mensagem simples a alguém confiável.",
          "Observe qual relação drenou sua energia hoje.",
          "Defina um limite saudável em uma interação.",
        ];
      case "rotina_foco":
        return [
          "Escolha uma única tarefa para concluir agora.",
          "Use 20 minutos de foco sem interrupção.",
          "Remova uma distração do ambiente.",
        ];
      case "seguranca_financeira":
        return [
          "Anote um gasto pequeno de hoje.",
          "Evite uma compra por impulso nas próximas 24h.",
          "Revise uma assinatura ou gasto recorrente.",
        ];
      default:
        return [
          "Faça uma pausa curta sem tela.",
          "Organize uma pequena prioridade.",
          "Registre uma coisa boa do dia.",
        ];
    }
  }

  Future<void> toggleItem(int index) async {
    if (index < 0 || index >= completed.length) return;
    final prefs = await SharedPreferences.getInstance();
    final newValue = !completed[index];
    setState(() => completed[index] = newValue);
    await prefs.setBool("${todayKey()}_$index", newValue);
  }

  int completedCount() => completed.where((item) => item).length;

  @override
  Widget build(BuildContext context) {
    final total = actions.length;
    final done = completedCount();
    final progress = total > 0 ? done / total : 0.0;
    final allDone = total > 0 && done == total;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(title: const Text("Ritual do dia")),
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
                        SizedBox(
                          width: 110, height: 110,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CustomPaint(
                                painter: _ArcPainter(
                                  value: progress,
                                  color: allDone ? const Color(0xFF59B36A) : const Color(0xFF6B4FD8),
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "$done/$total",
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: allDone ? const Color(0xFF59B36A) : const Color(0xFF6B4FD8),
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      total == 1 ? "ação" : "ações",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: (allDone ? const Color(0xFF59B36A) : const Color(0xFF6B4FD8)).withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Pequenas ações, grande consistência",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1F2544)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Complete o ritual de hoje sem buscar perfeição.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF6B6F8A)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...List.generate(actions.length, (index) {
                    return _RitualItem(
                      text: actions[index],
                      completed: index < completed.length ? completed[index] : false,
                      onTap: () => toggleItem(index),
                    );
                  }),
                  const SizedBox(height: 12),
                  if (allDone) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF59B36A).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF59B36A).withOpacity(0.25)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.celebration_rounded, color: Color(0xFF59B36A), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Ritual concluído. O objetivo é consistência, não intensidade.",
                              style: TextStyle(
                                fontSize: 13, height: 1.5,
                                fontWeight: FontWeight.w600, color: Color(0xFF1F2544),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF59B36A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text("Voltar para o início",
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value;
  final Color color;
  _ArcPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const sw = 11.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - sw) / 2;
    final bg = Paint()..color = color.withOpacity(0.12)..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round;
    final fg = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.75, math.pi * 1.5, false, bg);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.75, math.pi * 1.5 * value, false, fg);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.value != value || old.color != color;
}

class _RitualItem extends StatelessWidget {
  final String text;
  final bool completed;
  final VoidCallback onTap;

  const _RitualItem({
    required this.text,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: completed
                    ? const Color(0xFF59B36A).withOpacity(0.25)
                    : const Color(0xFF6B4FD8).withOpacity(0.10),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: completed ? const Color(0xFF59B36A) : const Color(0xFF6B6F8A),
                  size: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: completed ? const Color(0xFF6B6F8A) : const Color(0xFF1F2544),
                      decoration: completed ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
