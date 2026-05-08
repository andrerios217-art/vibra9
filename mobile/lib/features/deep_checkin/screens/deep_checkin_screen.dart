import "dart:async";
import "../../../core/services/api_client.dart";
import "package:flutter/material.dart";

class DeepCheckinScreen extends StatefulWidget {
  const DeepCheckinScreen({super.key});

  @override
  State<DeepCheckinScreen> createState() => _DeepCheckinScreenState();
}

class _DeepCheckinScreenState extends State<DeepCheckinScreen> {
  String step = "intro";
  int index = 0;

  final List<int> answers = [];
  final List<int> followAnswers = [];

  bool savingDeepCheckin = false;
  String? savedDeepCheckinId;

  final List<_QuestionItem> questions = const [
    // Energia (2)
    _QuestionItem("Tenho conseguido manter um bom ritmo ao longo do dia.", "Energia", false),
    _QuestionItem("Sinto que meu corpo tem pedido pausas com frequência.", "Energia", true),
    // Foco (2)
    _QuestionItem("Consigo manter o foco no que estou fazendo.", "Foco", false),
    _QuestionItem("Minha mente tem parecido mais cheia do que o normal.", "Foco", true),
    // Emocional (2)
    _QuestionItem("Consigo retomar meu estado depois de momentos difíceis.", "Emocional", false),
    _QuestionItem("Pequenas coisas têm pesado mais do que deveriam.", "Emocional", true),
    // Rotina (2)
    _QuestionItem("Sinto que as coisas têm andado no meu dia.", "Rotina", false),
    _QuestionItem("Tenho tido dificuldade para dar andamento no que preciso.", "Rotina", true),
    // Clareza (2)
    _QuestionItem("Tenho clareza básica sobre minha vida prática.", "Clareza", false),
    _QuestionItem("Preocupações do dia a dia têm ocupado minha cabeça.", "Clareza", true),
    // Relações (3 — reduzido de 6)
    _QuestionItem("Minhas relações próximas têm sido tranquilas.", "Relações", false),
    _QuestionItem("Tenho sentido necessidade de me resguardar em alguns vínculos.", "Relações", true),
    _QuestionItem("Sinto troca genuína nas minhas relações.", "Relações", false),
    // Pertencimento (1)
    _QuestionItem("Sinto que faço parte de algum ambiente ou grupo.", "Pertencimento", false),
    // Propósito (2)
    _QuestionItem("Sinto que meus dias têm algum sentido.", "Propósito", false),
    _QuestionItem("Tenho me sentido meio sem direção.", "Propósito", true),
    // Sobrecarga (1)
    _QuestionItem("Tenho me sentido sobrecarregado(a) com frequência.", "Sobrecarga", true),
    // Equilíbrio (1)
    _QuestionItem("Sinto minha vida relativamente equilibrada.", "Equilíbrio", false),
    // Flexibilidade (1)
    _QuestionItem("Consigo me adaptar quando o dia muda de forma inesperada.", "Flexibilidade", false),
    // Leveza (1)
    _QuestionItem("Tenho tido momentos leves no meio da rotina.", "Leveza", false),
    // Evolução (1)
    _QuestionItem("Percebo algum avanço no que faço ou sou.", "Evolução", false),
    // Organização (1)
    _QuestionItem("Sinto algum nível de organização no meu dia.", "Organização", false),
    // Limites (1)
    _QuestionItem("Consigo manter limites de forma natural.", "Limites", false),
  ];

  final List<String> followUp = const [
    "Às vezes sinto muitas coisas acontecendo ao mesmo tempo na minha cabeça.",
    "Tenho sentido um certo cansaço mental ao longo dos dias.",
    "Nem sempre consigo manter foco por muito tempo.",
    "Tenho dificuldade em relaxar mentalmente.",
    "Algumas decisões simples demoram mais do que deveriam.",
    "Tenho dificuldade em concluir tarefas que começo.",
    "Sinto que não consigo desacelerar facilmente.",
    "Minha mente parece sempre ocupada com algo.",
    "Tenho dificuldade em organizar meus pensamentos.",
    "Sinto que carrego mais do que consigo processar.",
  ];

  void handleAnswer(int value) {
    if (step == "main") {
      answers.add(value);
      if (answers.length == questions.length) {
        setState(() { step = "loading"; index = 0; });
        Timer(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          setState(() { step = "follow"; index = 0; });
        });
      } else {
        setState(() => index++);
      }
      return;
    }

    if (step == "follow") {
      followAnswers.add(value);
      if (followAnswers.length == followUp.length) {
        setState(() => step = "result");
        saveDeepCheckin(); // chamado apenas uma vez
      } else {
        setState(() => index++);
      }
    }
  }

  Future<void> saveDeepCheckin() async {
    if (savingDeepCheckin || savedDeepCheckinId != null) return;
    savingDeepCheckin = true;
    try {
      final dimensions = dimensionScores().entries.map((entry) {
        return {"label": entry.key, "score": entry.value};
      }).toList();
      final response = await ApiClient.post(
        "/deep-checkin",
        auth: true,
        body: {
          "general_score": finalScore(),
          "overload_score": overloadScore(),
          "dimensions": dimensions,
          "answers": answers,
          "follow_answers": followAnswers,
        },
      );
      savedDeepCheckinId = response["assessment_id"]?.toString();
      try {
        await ApiClient.post("/patterns/backfill", auth: true, body: {});
      } catch (_) {}
    } catch (_) {
    } finally {
      savingDeepCheckin = false;
    }
  }

  void restart() {
    setState(() {
      step = "intro";
      index = 0;
      answers.clear();
      followAnswers.clear();
      savingDeepCheckin = false;
      savedDeepCheckinId = null;
    });
  }

  int adjustedScore(_QuestionItem question, int answer) {
    return question.reverse ? 6 - answer : answer;
  }

  int mainScore() {
    if (answers.isEmpty) return 0;
    int total = 0;
    for (int i = 0; i < answers.length; i++) {
      total += adjustedScore(questions[i], answers[i]);
    }
    return ((total / (answers.length * 5)) * 100).round();
  }

  int overloadScore() {
    if (followAnswers.isEmpty) return 0;
    final total = followAnswers.fold<int>(0, (sum, value) => sum + value);
    return ((total / (followAnswers.length * 5)) * 100).round();
  }

  int finalScore() {
    final base = mainScore();
    final overload = overloadScore();
    return ((base * 0.75) + ((100 - overload) * 0.25)).round();
  }

  Map<String, int> dimensionScores() {
    final Map<String, List<int>> grouped = {};
    for (int i = 0; i < answers.length; i++) {
      final question = questions[i];
      grouped.putIfAbsent(question.dimension, () => []);
      grouped[question.dimension]!.add(adjustedScore(question, answers[i]));
    }
    final Map<String, int> result = {};
    grouped.forEach((dimension, values) {
      final total = values.fold<int>(0, (sum, value) => sum + value);
      result[dimension] = ((total / (values.length * 5)) * 100).round();
    });
    return result;
  }

  String resultTitle(int score) {
    if (score <= 40) return "Momento pedindo cuidado";
    if (score <= 70) return "Momento em reorganização";
    return "Momento com bom equilíbrio";
  }

  String resultText(int score) {
    if (score <= 40) {
      return "Seu resultado indica sinais de sobrecarga e necessidade de simplificar o dia. O mais importante agora é reduzir estímulos, escolher poucas prioridades e criar uma pequena pausa antes de agir.";
    }
    if (score <= 70) {
      return "Seu momento mistura recursos positivos com alguns pontos de desgaste. Há sinais de funcionamento, mas também necessidade de reorganizar energia, foco e limites.";
    }
    return "Seu resultado indica um bom nível de equilíbrio geral. A recomendação é manter consistência, preservar pausas e continuar observando os sinais do corpo, da mente e das relações.";
  }

  String mainAction(int score) {
    if (score <= 40) {
      return "Antes da próxima tarefa, faça uma pausa de 2 minutos sem tela e escolha apenas uma coisa essencial.";
    }
    if (score <= 70) {
      return "Escolha uma prioridade real para hoje e proteja 20 minutos sem interrupção.";
    }
    return "Use seu bom momento para concluir uma pendência pequena e reforçar uma rotina saudável.";
  }

  Color scoreColor(int score) {
    if (score <= 40) return const Color(0xFFE8505B);
    if (score <= 70) return const Color(0xFFF5B942);
    return const Color(0xFF59B36A);
  }

  @override
  Widget build(BuildContext context) {
    if (step == "intro") {
      return _IntroStep(onStart: () {
        setState(() { step = "main"; index = 0; });
      });
    }
    if (step == "loading") {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F5FF),
        body: SafeArea(child: Center(child: _LoadingCard())),
      );
    }
    if (step == "follow") {
      return _QuestionStep(
        title: "Só mais algumas perguntas",
        subtitle: "Essas perguntas ajudam a entender sua carga mental.",
        question: followUp[index],
        current: index + 1,
        total: followUp.length,
        onAnswer: handleAnswer,
      );
    }
    if (step == "result") {
      final score = finalScore();
      final dimensions = dimensionScores();
      return _ResultStep(
        score: score,
        color: scoreColor(score),
        title: resultTitle(score),
        text: resultText(score),
        action: mainAction(score),
        overload: overloadScore(),
        dimensions: dimensions,
        onRestart: restart,
      );
    }
    final question = questions[index];
    return _QuestionStep(
      title: "Check-up ampliado",
      subtitle: index == 0 ? "Como você se sente no dia a dia?" : question.dimension,
      question: question.text,
      current: index + 1,
      total: questions.length,
      onAnswer: handleAnswer,
    );
  }
}

class _QuestionItem {
  final String text;
  final String dimension;
  final bool reverse;
  const _QuestionItem(this.text, this.dimension, this.reverse);
}

class _IntroStep extends StatelessWidget {
  final VoidCallback onStart;
  const _IntroStep({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(title: const Text("Check-up ampliado")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.12)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4FD8).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(Icons.psychology_alt_rounded, color: Color(0xFF6B4FD8), size: 54),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    "Um cuidado mais profundo para o seu dia",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, height: 1.2, fontWeight: FontWeight.w700, color: Color(0xFF1F2544)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Responda perguntas sobre energia, foco, emoções, relações e rotina para entender melhor seu momento atual.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF6B6F8A)),
                  ),
                  const SizedBox(height: 24),
                  const _IntroInfoCard(icon: Icons.visibility_rounded, title: "Mais clareza", text: "Identifique sinais de sobrecarga e desequilíbrio."),
                  const _IntroInfoCard(icon: Icons.auto_awesome_rounded, title: "Mais consciência", text: "Perceba como áreas da vida influenciam seu bem-estar."),
                  const _IntroInfoCard(icon: Icons.favorite_rounded, title: "Mais cuidado", text: "Receba uma orientação simples para hoje."),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: FilledButton(
                      onPressed: onStart,
                      child: const Text("Começar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Este check-in é uma ferramenta de bem-estar e autoconhecimento. Não substitui acompanhamento profissional.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF6B6F8A)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _IntroInfoCard({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFFF8F5FF), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B4FD8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
                const SizedBox(height: 3),
                Text(text, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF6B6F8A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final String question;
  final int current;
  final int total;
  final ValueChanged<int> onAnswer;

  const _QuestionStep({
    required this.title, required this.subtitle, required this.question,
    required this.current, required this.total, required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final progress = current / total;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress, minHeight: 8,
                        backgroundColor: const Color(0xFF6B4FD8).withOpacity(0.10),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B4FD8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text("$current/$total", style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6B4FD8))),
                ],
              ),
              const SizedBox(height: 26),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.10)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B4FD8).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(subtitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B4FD8))),
                      ),
                      const Spacer(),
                      Text(
                        question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, height: 1.3, fontWeight: FontWeight.w700, color: Color(0xFF1F2544)),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (i) {
                          final value = i + 1;
                          return _LikertButton(value: value, onTap: () => onAnswer(value));
                        }),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text("Discordo", style: TextStyle(fontSize: 11, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w600))),
                          Expanded(child: Text("Neutro", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w600))),
                          Expanded(child: Text("Concordo", textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ],
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

class _LikertButton extends StatelessWidget {
  final int value;
  final VoidCallback onTap;
  const _LikertButton({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52, height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          side: const BorderSide(color: Color(0xFF6B4FD8)),
          foregroundColor: const Color(0xFF6B4FD8),
        ),
        child: Text("$value", style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(26),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(34)),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 22),
          Text("Analisando seu momento...", textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
          SizedBox(height: 8),
          Text("Estamos organizando suas respostas em uma leitura simples de bem-estar.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF6B6F8A))),
        ],
      ),
    );
  }
}

class _ResultStep extends StatelessWidget {
  final int score;
  final Color color;
  final String title;
  final String text;
  final String action;
  final int overload;
  final Map<String, int> dimensions;
  final VoidCallback onRestart;

  const _ResultStep({
    required this.score, required this.color, required this.title, required this.text,
    required this.action, required this.overload, required this.dimensions, required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = dimensions.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final focus = sorted.isNotEmpty ? sorted.first.key : "Rotina";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(title: const Text("Resultado ampliado")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: color.withOpacity(0.14)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 132, height: 132,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: score / 100, strokeWidth: 12,
                          backgroundColor: color.withOpacity(0.10),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                        Center(child: Text("$score", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: color))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(title, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
                  const SizedBox(height: 10),
                  Text(text, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF4A4A6A))),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _FocusCard(focus: focus, action: action),
            const SizedBox(height: 18),
            _OverloadCard(overload: overload),
            const SizedBox(height: 18),
            const Text("Dimensões percebidas",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
            const SizedBox(height: 12),
            ...sorted.map((entry) => _DimensionLine(label: entry.key, score: entry.value)),
            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Refazer check-up", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final String focus;
  final String action;
  const _FocusCard({required this.focus, required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF6B4FD8), borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.center_focus_strong_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Campo para cuidar agora", style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
                Text(focus, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(action, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverloadCard extends StatelessWidget {
  final int overload;
  const _OverloadCard({required this.overload});

  @override
  Widget build(BuildContext context) {
    final color = overload >= 70
        ? const Color(0xFFE8505B)
        : overload >= 40
            ? const Color(0xFFF5B942)
            : const Color(0xFF59B36A);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.speed_rounded, color: color, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Carga mental percebida",
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B6F8A), fontWeight: FontWeight.w500)),
                Text("$overload/100", style: TextStyle(fontSize: 22, color: color, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DimensionLine extends StatelessWidget {
  final String label;
  final int score;
  const _DimensionLine({required this.label, required this.score});

  Color get color {
    if (score <= 40) return const Color(0xFFE8505B);
    if (score <= 70) return const Color(0xFFF5B942);
    return const Color(0xFF59B36A);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF1F2544), fontWeight: FontWeight.w600))),
              Text("$score", style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 100, minHeight: 7,
              backgroundColor: color.withOpacity(0.10),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
