import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

class HelpSafetyScreen extends StatelessWidget {
  const HelpSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(title: const Text("Ajuda e segurança")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const _HeroCard(),
            const SizedBox(height: 16),
            const _SectionCard(
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
            const SizedBox(height: 12),
            const _SectionCard(
              icon: Icons.block_rounded,
              color: Color(0xFFE8505B),
              title: "O que o Vibra9 NÃO faz",
              items: [
                "Não realiza diagnóstico médico ou psicológico.",
                "Não substitui terapia, consulta médica ou acompanhamento profissional.",
                "Não deve ser usado em situação de emergência.",
                "Não promete cura, transformação garantida ou resultado clínico.",
              ],
            ),
            const SizedBox(height: 12),
            const _SectionCard(
              icon: Icons.health_and_safety_rounded,
              color: Color(0xFF59B36A),
              title: "Quando buscar ajuda profissional",
              items: [
                "Se sentir sofrimento intenso ou persistente.",
                "Se estiver com dificuldade de realizar tarefas básicas.",
                "Se pensamentos negativos estiverem frequentes ou difíceis de controlar.",
                "Se houver risco de machucar a si mesmo ou outra pessoa.",
              ],
            ),
            const SizedBox(height: 12),
            const _EmergencyCard(),
            const SizedBox(height: 12),
            const _EmergencyContactsCard(),
            const SizedBox(height: 12),
            const _FaqCard(),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6B4FD8), Color(0xFF42B8B0)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_rounded, color: Colors.white, size: 40),
          SizedBox(height: 14),
          Text(
            "Use o Vibra9 com consciência",
            style: TextStyle(fontSize: 22, height: 1.2, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          SizedBox(height: 6),
          Text(
            "O app é uma ferramenta de bem-estar e autoconhecimento. Ele ajuda a observar padrões, mas não substitui cuidado profissional.",
            style: TextStyle(fontSize: 13, height: 1.5, color: Colors.white70),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, color: color, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item,
                      style: const TextStyle(
                        fontSize: 13, height: 1.5,
                        color: Color(0xFF1F2544), fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8505B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8505B).withOpacity(0.20)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFE8505B), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Em situação de emergência ou sofrimento intenso, procure ajuda imediata. Veja contatos disponíveis abaixo.",
              style: TextStyle(
                fontSize: 13, height: 1.5,
                color: Color(0xFF1F2544), fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactsCard extends StatelessWidget {
  const _EmergencyContactsCard();

  Future<void> _call(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openSite(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8505B).withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.phone_in_talk_rounded, color: Color(0xFFE8505B), size: 22),
              SizedBox(width: 10),
              Text(
                "Contatos de emergência (Brasil)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2544)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ContactTile(
            title: "CVV — Centro de Valorização da Vida",
            subtitle: "Apoio emocional gratuito, 24h",
            phone: "188",
            onCall: () => _call("188"),
            onOpenSite: () => _openSite("https://cvv.org.br"),
          ),
          _ContactTile(
            title: "SAMU — Emergência médica",
            subtitle: "Atendimento de urgência 24h",
            phone: "192",
            onCall: () => _call("192"),
          ),
          _ContactTile(
            title: "Polícia Militar",
            subtitle: "Risco imediato ou violência",
            phone: "190",
            onCall: () => _call("190"),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String phone;
  final VoidCallback onCall;
  final VoidCallback? onOpenSite;

  const _ContactTile({
    required this.title,
    required this.subtitle,
    required this.phone,
    required this.onCall,
    this.onOpenSite,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8505B).withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B6F8A))),
                  const SizedBox(height: 4),
                  Text(phone,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFE8505B))),
                ],
              ),
            ),
            if (onOpenSite != null)
              IconButton(
                onPressed: onOpenSite,
                icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFF6B4FD8), size: 20),
                tooltip: "Abrir site",
              ),
            IconButton(
              onPressed: onCall,
              icon: const Icon(Icons.call_rounded, color: Color(0xFFE8505B), size: 22),
              tooltip: "Ligar",
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF6B4FD8).withOpacity(0.10)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Perguntas frequentes",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2544)),
          ),
          SizedBox(height: 12),
          _FaqItem(
            question: "O resultado é um diagnóstico?",
            answer: "Não. O resultado é uma leitura de bem-estar baseada nas respostas do usuário.",
          ),
          _FaqItem(
            question: "Preciso fazer todos os dias?",
            answer: "Não é obrigatório, mas a consistência melhora o histórico e a percepção de padrões.",
          ),
          _FaqItem(
            question: "Meus dados podem ser apagados?",
            answer: "Sim. No Perfil, você pode excluir sua conta e os dados associados.",
          ),
          _FaqItem(
            question: "Posso exportar meus dados?",
            answer: "Sim. No Perfil, em Exportar meus dados, você pode copiar uma exportação em JSON.",
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2544))),
          const SizedBox(height: 3),
          Text(answer,
            style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF6B6F8A))),
        ],
      ),
    );
  }
}
