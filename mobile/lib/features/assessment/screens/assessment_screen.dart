import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";
import "../../../core/widgets/app_button.dart";
import "../../result/screens/result_screen.dart";

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  bool loading = true;
  bool sending = false;

  int currentIndex = 0;

  List<dynamic> questions = [];
  Map<String, double> scores = {};

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    try {
      final response = await ApiClient.get(
        "/assessment/questions",
        auth: true,
      );

      final loadedQuestions = response["questions"] as List<dynamic>;
      final Map<String, double> initialScores = {};

      for (final question in loadedQuestions) {
        initialScores[question["question_id"].toString()] = 5;
      }

      if (!mounted) return;

      setState(() {
        questions = loadedQuestions;
        scores = initialScores;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll("Exception: ", "")),
        ),
      );
    }
  }

  void nextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      sendAssessment();
    }
  }

  void previousQuestion() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
    }
  }

  Future<void> sendAssessment() async {
    setState(() => sending = true);

    try {
      final answers = questions.map((question) {
        final questionId = question["question_id"].toString();
        final score = scores[questionId] ?? 5;

        return {
          "question_id": questionId,
          "dimension": question["dimension"],
          "score": score.round(),
        };
      }).toList();

      final assessmentResponse = await ApiClient.post(
        "/assessment",
        auth: true,
        body: {
          "answers": answers,
        },
      );

      final recommendationResponse = await ApiClient.post(
        "/recommendations",
        auth: true,
        body: {
          "assessment_id": assessmentResponse["assessment_id"],
        },
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            assessment: assessmentResponse,
            recommendation: recommendationResponse,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll("Exception: ", "")),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  String dimensionName(String value) {
    switch (value) {
      case "clareza_mental":
        return "Clareza mental";
      case "estado_emocional":
        return "Estado emocional";
      case "proposito_pessoal":
        return "Propósito pessoal";
      case "energia_diaria":
        return "Energia diária";
      case "corpo_habitos":
        return "Corpo e hábitos";
      case "comunicacao":
        return "Comunicação";
      case "relacoes":
        return "Relações";
      case "rotina_foco":
        return "Rotina e foco";
      case "seguranca_financeira":
        return "Segurança financeira";
      default:
        return value;
    }
  }

  String scoreText(int score) {
    if (score <= 2) {
      return "Muito baixo";
    }

    if (score <= 4) {
      return "Baixo";
    }

    if (score <= 6) {
      return "Médio";
    }

    if (score <= 8) {
      return "Bom";
    }

    return "Muito bom";
  }

  Color scoreColor(int score) {
    if (score <= 4) {
      return const Color(0xFFE8505B);
    }

    if (score <= 7) {
      return const Color(0xFFF5B942);
    }

    return const Color(0xFF59B36A);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text("Não foi possível carregar as perguntas."),
        ),
      );
    }

    final question = questions[currentIndex];
    final questionId = question["question_id"].toString();
    final currentScore = scores[questionId] ?? 5;
    final roundedScore = currentScore.round();
    final progress = (currentIndex + 1) / questions.length;
    final isLast = currentIndex == questions.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Avaliação diária"),
      ),
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
                        value: progress,
                        minHeight: 10,
                        backgroundColor: const Color(0xFF6B4FD8).withOpacity(0.10),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF6B4FD8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${currentIndex + 1}/${questions.length}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6B4FD8),
                    ),
                  ),
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
                    border: Border.all(
                      color: const Color(0xFF6B4FD8).withOpacity(0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B4FD8).withOpacity(0.08),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B4FD8).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          dimensionName(question["dimension"].toString()),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF6B4FD8),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        question["text"].toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 25,
                          height: 1.25,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1F2544),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: 118,
                        height: 118,
                        decoration: BoxDecoration(
                          color: scoreColor(roundedScore).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(38),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "$roundedScore",
                              style: TextStyle(
                                fontSize: 42,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                color: scoreColor(roundedScore),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              scoreText(roundedScore),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: scoreColor(roundedScore),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      Slider(
                        value: currentScore,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: roundedScore.toString(),
                        onChanged: sending
                            ? null
                            : (value) {
                                setState(() {
                                  scores[questionId] = value;
                                });
                              },
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Nada",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B6F8A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            "Muito",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B6F8A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (currentIndex > 0)
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: sending ? null : previousQuestion,
                          child: const Text(
                            "Voltar",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (currentIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: currentIndex > 0 ? 1 : 2,
                    child: AppButton(
                      text: isLast ? "Ver resultado" : "Próxima",
                      loading: sending,
                      onPressed: nextQuestion,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

