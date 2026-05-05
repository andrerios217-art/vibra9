import "package:flutter/material.dart";

class HelpSafetyScreen extends StatelessWidget {
  const HelpSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Ajuda e segurança"),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: const [
            _HeroCard(),
            SizedBox(height: 20),
            _SectionCard(
              icon: Icons.info_outline_rounded,
              color: Color(0xFF6B4FD8),
              title: "O que o Vibra9 faz",
              items: [
                "Ajuda você a fazer check-ins de bem-estar.",
                "Organiza sua percepção em 9 dimensões.",
                "Mostra histórico, evolução e práticas simples.",
                "Oferece orientações gerais de autocuidado.",
              ],
            ),
            SizedBox(height: 14),
            _SectionCard(
              icon: Icons.block_rounded,
              color: Color(0xFFE8505B),
              title: "O que o Vibra9 não faz",
              items: [
                "Não realiza diagnóstico médico ou psicológico.",
                "Não substitui terapia, consulta médica ou acompanhamento profissional.",
                "Não deve ser usado em situação de emergência.",
                "Não promete cura, transformação garantida ou resultado clínico.",
              ],
            ),
            SizedBox(height: 14),
            _SectionCard(
              icon: Icons.health_and_safety_rounded,
              color: Color(0xFF59B36A),
              title: "Quando buscar ajuda profissional",
              items: [
                "Se você sentir sofrimento intenso ou persistente.",
                "Se estiver com dificuldade de realizar tarefas básicas.",
                "Se pensamentos negativos estiverem frequentes ou difíceis de controlar.",
                "Se houver risco de machucar a si mesmo ou outra pessoa.",
              ],
            ),
            SizedBox(height: 14),
            _EmergencyCard(),
            SizedBox(height: 14),
            _FaqCard(),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6B4FD8),
            Color(0xFF42B8B0),
          ],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4FD8).withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_rounded,
            color: Colors.white,
            size: 48,
          ),
          SizedBox(height: 18),
          Text(
            "Use o Vibra9 com consciência",
            style: TextStyle(
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "O app é uma ferramenta de bem-estar e autoconhecimento. Ele ajuda a observar padrões, mas não substitui cuidado profissional.",
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;

  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: color.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2544),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: color,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
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

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8505B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE8505B).withOpacity(0.18),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFE8505B),
            size: 30,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Em situação de emergência, risco imediato ou sofrimento intenso, procure serviços de emergência da sua região ou uma pessoa de confiança imediatamente.",
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF1F2544),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF6B4FD8).withOpacity(0.10),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Perguntas frequentes",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2544),
            ),
          ),
          SizedBox(height: 14),
          _FaqItem(
            question: "O resultado é um diagnóstico?",
            answer:
                "Não. O resultado é uma leitura de bem-estar baseada nas respostas do usuário.",
          ),
          _FaqItem(
            question: "Preciso fazer todos os dias?",
            answer:
                "Não é obrigatório, mas a consistência melhora o histórico e a percepção de padrões.",
          ),
          _FaqItem(
            question: "Meus dados podem ser apagados?",
            answer:
                "Sim. No Perfil, você pode excluir sua conta e os dados associados.",
          ),
          _FaqItem(
            question: "Posso exportar meus dados?",
            answer:
                "Sim. No Perfil, a opção Exportar meus dados permite copiar uma exportação em JSON.",
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2544),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Color(0xFF6B6F8A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

