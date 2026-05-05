import "package:flutter/material.dart";

class PracticesScreen extends StatefulWidget {
  const PracticesScreen({super.key});

  @override
  State<PracticesScreen> createState() => _PracticesScreenState();
}

class _PracticesScreenState extends State<PracticesScreen> {
  String selectedCategory = "Todos";

  final categories = const [
    "Todos",
    "Mental",
    "Emocional",
    "Corpo",
    "Foco",
    "Relações",
    "Organização",
  ];

  final practices = const [
    PracticeItem(
      category: "Mental",
      title: "Descarrego mental",
      duration: "5 min",
      icon: Icons.psychology_rounded,
      color: Color(0xFF6B4FD8),
      description:
          "Escreva tudo que está ocupando sua mente, sem organizar. Depois escolha apenas uma prioridade.",
      steps: [
        "Pegue papel ou bloco de notas.",
        "Escreva tudo que vier à mente por 3 minutos.",
        "Circule apenas uma coisa que pode ser feita hoje.",
      ],
    ),
    PracticeItem(
      category: "Emocional",
      title: "Nomear para acalmar",
      duration: "3 min",
      icon: Icons.favorite_rounded,
      color: Color(0xFFE8505B),
      description:
          "Dar nome ao que você sente ajuda a reduzir confusão interna e aumenta clareza.",
      steps: [
        "Pergunte: o que estou sentindo agora?",
        "Escolha uma palavra simples: cansaço, medo, irritação, tristeza, alegria.",
        "Complete: eu percebo que estou sentindo...",
      ],
    ),
    PracticeItem(
      category: "Corpo",
      title: "Reset físico leve",
      duration: "4 min",
      icon: Icons.accessibility_new_rounded,
      color: Color(0xFF59B36A),
      description:
          "Uma sequência curta para sair do automático e voltar ao corpo.",
      steps: [
        "Alongue pescoço e ombros lentamente.",
        "Beba um copo de água.",
        "Respire fundo três vezes antes de voltar à rotina.",
      ],
    ),
    PracticeItem(
      category: "Foco",
      title: "Bloco de 20 minutos",
      duration: "20 min",
      icon: Icons.timer_rounded,
      color: Color(0xFFF5B942),
      description:
          "Uma prática simples para avançar sem depender de motivação perfeita.",
      steps: [
        "Escolha uma única tarefa.",
        "Remova uma distração visível.",
        "Trabalhe por 20 minutos sem trocar de atividade.",
      ],
    ),
    PracticeItem(
      category: "Relações",
      title: "Mensagem de presença",
      duration: "2 min",
      icon: Icons.people_alt_rounded,
      color: Color(0xFF42B8B0),
      description:
          "Fortaleça vínculo com uma ação pequena e realista.",
      steps: [
        "Escolha uma pessoa confiável.",
        "Envie uma mensagem simples.",
        "Não cobre resposta imediata.",
      ],
    ),
    PracticeItem(
      category: "Organização",
      title: "Uma pendência a menos",
      duration: "10 min",
      icon: Icons.task_alt_rounded,
      color: Color(0xFF2E236C),
      description:
          "Reduza ruído prático resolvendo uma pequena pendência.",
      steps: [
        "Escolha uma pendência pequena.",
        "Defina o primeiro passo.",
        "Conclua ou agende com clareza.",
      ],
    ),
    PracticeItem(
      category: "Emocional",
      title: "Pausa sem tela",
      duration: "5 min",
      icon: Icons.phone_disabled_rounded,
      color: Color(0xFFE8505B),
      description:
          "Uma pausa curta para diminuir estímulo e recuperar presença.",
      steps: [
        "Coloque o celular longe por 5 minutos.",
        "Observe sua respiração sem tentar controlar.",
        "Volte escolhendo uma ação simples.",
      ],
    ),
    PracticeItem(
      category: "Mental",
      title: "Três prioridades",
      duration: "4 min",
      icon: Icons.format_list_numbered_rounded,
      color: Color(0xFF6B4FD8),
      description:
          "Troque excesso de planejamento por uma escolha mais clara.",
      steps: [
        "Liste tudo que gostaria de fazer.",
        "Escolha apenas três itens.",
        "Marque um deles como prioridade principal.",
      ],
    ),
    PracticeItem(
      category: "Corpo",
      title: "Caminhada curta",
      duration: "10 min",
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF59B36A),
      description:
          "Movimento leve pode ajudar a destravar energia e humor.",
      steps: [
        "Caminhe em ritmo confortável.",
        "Evite usar a caminhada para resolver tudo mentalmente.",
        "Ao final, perceba como está seu corpo.",
      ],
    ),
  ];

  List<PracticeItem> get filteredPractices {
    if (selectedCategory == "Todos") {
      return practices;
    }

    return practices
        .where((practice) => practice.category == selectedCategory)
        .toList();
  }

  void openPractice(PracticeItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeDetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredPractices;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Práticas"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFF6B4FD8).withOpacity(0.10),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.spa_rounded,
                      color: Color(0xFF6B4FD8),
                      size: 38,
                    ),
                    SizedBox(height: 14),
                    Text(
                      "Biblioteca de cuidado",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2544),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Práticas simples para mente, emoções, corpo e rotina.",
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Color(0xFF6B6F8A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 54,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final active = selectedCategory == category;

                  return ChoiceChip(
                    selected: active,
                    label: Text(category),
                    onSelected: (_) {
                      setState(() => selectedCategory = category);
                    },
                    selectedColor: const Color(0xFF6B4FD8).withOpacity(0.16),
                    labelStyle: TextStyle(
                      color: active
                          ? const Color(0xFF6B4FD8)
                          : const Color(0xFF6B6F8A),
                      fontWeight: FontWeight.w800,
                    ),
                    side: BorderSide(
                      color: active
                          ? const Color(0xFF6B4FD8).withOpacity(0.30)
                          : Colors.transparent,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(22),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = filtered[index];

                  return _PracticeCard(
                    item: item,
                    onTap: () => openPractice(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PracticeItem {
  final String category;
  final String title;
  final String duration;
  final IconData icon;
  final Color color;
  final String description;
  final List<String> steps;

  const PracticeItem({
    required this.category,
    required this.title,
    required this.duration,
    required this.icon,
    required this.color,
    required this.description,
    required this.steps,
  });
}

class _PracticeCard extends StatelessWidget {
  final PracticeItem item;
  final VoidCallback onTap;

  const _PracticeCard({
    required this.item,
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
              color: item.color.withOpacity(0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: item.color.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF1F2544),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${item.category} • ${item.duration}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6F8A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color(0xFF6B6F8A),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6B6F8A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PracticeDetailScreen extends StatelessWidget {
  final PracticeItem item;

  const PracticeDetailScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: Text(item.category),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: item.color.withOpacity(0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withOpacity(0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.color,
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F2544),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${item.category} • ${item.duration}",
                    style: TextStyle(
                      fontSize: 14,
                      color: item.color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Color(0xFF6B6F8A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              "Como fazer",
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1F2544),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(item.steps.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: item.color.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            color: item.color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.steps[index],
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2544),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Prática concluída. Bom trabalho."),
                    ),
                  );

                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  "Concluir prática",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Use como orientação geral de bem-estar. Não substitui acompanhamento profissional.",
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

