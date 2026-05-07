import "package:flutter/material.dart";
import "../../../core/services/api_client.dart";

class TermsScreen extends StatefulWidget {
  final bool showAcceptButton;
  const TermsScreen({super.key, this.showAcceptButton = false});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool loading = true;
  Map<String, dynamic>? terms;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await ApiClient.get("/lgpd/terms");
      if (!mounted) return;
      setState(() { terms = response; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString().replaceAll("Exception: ", ""); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text("Termos de Uso"),
        backgroundColor: const Color(0xFFF8F5FF),
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Color(0xFFE8505B))))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(22),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF42B8B0), Color(0xFF6B4FD8)]),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.gavel_rounded, color: Colors.white, size: 36),
                                const SizedBox(height: 12),
                                Text(terms!["title"].toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                                const SizedBox(height: 6),
                                Text("Versão ${terms!["version"]} · Atualizada em ${terms!["updated_at"]}", style: const TextStyle(fontSize: 12, color: Colors.white70)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ...(terms!["sections"] as List<dynamic>).map((s) {
                            final section = Map<String, dynamic>.from(s);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF42B8B0).withOpacity(0.12)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(section["title"].toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF42B8B0))),
                                  const SizedBox(height: 8),
                                  Text(section["content"].toString(), style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF4A4A6A))),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    if (widget.showAcceptButton)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF42B8B0),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text("Li e aceito os termos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
