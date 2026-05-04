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
  List<bool> completed = [false, false, false];

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

      completed = [
        prefs.getBool("${todayKey()}_0") ?? false,
        prefs.getBool("${todayKey()}_1") ?? false,
        prefs.getBool("${todayKey()}_2") ?? false,
      ];

      final response = await ApiClient.get(
        "/history",
        auth: true,
      );

      final items = response["items"] as List<dynamic>;

      if (items.isEmpty) {
        actions = [
          "Faça uma avaliação rápida para descobrir seu foco de hoje.",
          "Reserve 1 minuto para respirar antes da próxima tarefa.",
          "Escolha uma pequena ação de cuidado para repetir amanhã.",
        ];
      } else {
        final latest = Map<String, dynamic>.from(items.first);
        final weakest = weakestDimension(latest);

        actions = suggestedActionsFor(weakest);
      }

      if (!mounted) return;

      setState(() => loading = false);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        actions = [
          "Beba um copo de água com calma.",
          "Organize uma pequena prioridade para hoje.",
          "Faça uma pausa curta sem tela.",
        ];
        loading = false;
      });
    }
  }

  String weakestDimension(Map<String, dynamic> item) {
    final dimensions = item["dimensions"] as List<dynamic>;

    if (dimensions.isEmpty) return "rotina_foco";

    final sorted = [...dimensions]..sort(
        (a, b) => (a["score"] as int).compareTo(b["score"] as int),
      );

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
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      completed[index] = !completed[index];
    });

    await prefs.setBool("${todayKey()}_$index", completed[index]);
  }

  int completedCount() {
    return completed.where((item) => item).length;
  }

  @override
  Widget build(BuildContext context) {
    final progress = completedCount() / 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Ritual do dia"),
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
                        SizedBox(
                          width: 122,
                          height: 122,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 11,
                                backgroundColor:
                                    const Color(0xFF6B4FD8).withOpacity(0.10),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6B4FD8),
                                ),
                              ),
                              Center(
                                child: Text(
                                  "${completedCount()}/3",
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF6B4FD8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Pequenas ações, grande consistência",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1F2544),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Complete o ritual de hoje sem buscar perfeição.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: Color(0xFF6B6F8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  ...List.generate(actions.length, (index) {
                    return _RitualItem(
                      text: actions[index],
                      completed: completed[index],
                      onTap: () => toggleItem(index),
                    );
                  }),
                  const SizedBox(height: 18),
                  if (completedCount() == 3)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF59B36A).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.celebration_rounded,
                            color: Color(0xFF59B36A),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Ritual concluído. O objetivo é consistência, não intensidade.",
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F2544),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: completed
                  ? const Color(0xFF59B36A).withOpacity(0.20)
                  : const Color(0xFF6B4FD8).withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                completed
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: completed
                    ? const Color(0xFF59B36A)
                    : const Color(0xFF6B6F8A),
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: completed
                        ? const Color(0xFF6B6F8A)
                        : const Color(0xFF1F2544),
                    decoration:
                        completed ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
