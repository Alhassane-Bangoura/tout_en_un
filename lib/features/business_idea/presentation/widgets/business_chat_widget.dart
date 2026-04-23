import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aibusiness/core/theme/app_colors.dart';
import 'package:aibusiness/core/supabase/supabase_service.dart';
import 'package:aibusiness/features/business_idea/data/models/business_idea_models.dart';

import 'package:aibusiness/features/home/data/models/activity_model.dart';

class BusinessChatWidget extends StatefulWidget {
  final ActivityModel activity;
  final VoidCallback? onClose; // Ajout d'une callback de fermeture

  const BusinessChatWidget({
    super.key, 
    required this.activity,
    this.onClose,
  });

  @override
  State<BusinessChatWidget> createState() => _BusinessChatWidgetState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});

  Map<String, dynamic> toJson() => {'text': text, 'isUser': isUser};
  factory _ChatMessage.fromJson(Map<String, dynamic> json) => 
      _ChatMessage(text: json['text'], isUser: json['isUser']);
}

class _BusinessChatWidgetState extends State<BusinessChatWidget> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  late BusinessIdeaModel _idea;

  @override
  void initState() {
    super.initState();
    _idea = BusinessIdeaModel.fromJson(widget.activity.metadata!);
    _loadHistory();
  }

  void _loadHistory() {
    final history = widget.activity.metadata?['chat_history'] as List?;
    if (history != null && history.isNotEmpty) {
      for (var item in history) {
        _messages.add(_ChatMessage.fromJson(Map<String, dynamic>.from(item)));
      }
    } else {
      _messages.add(_ChatMessage(
        text: '👋 Bonjour ! Je suis votre mentor business. Vous avez une question sur votre idée **${_idea.title}** ? Stratégie, financement, clients... parlons-en concrètement.',
        isUser: false,
      ));
    }
  }

  Future<void> _saveHistory() async {
    final List<Map<String, dynamic>> historyJson = _messages.map((m) => m.toJson()).toList();
    final newMetadata = Map<String, dynamic>.from(widget.activity.metadata!);
    newMetadata['chat_history'] = historyJson;
    await _service.updateActivityMetadata(widget.activity.id, newMetadata);
  }

  Future<void> _sendMessage({String? customQuestion}) async {
    final question = customQuestion ?? _inputController.text.trim();
    if (question.isEmpty || _isTyping) return;

    if (customQuestion == null) _inputController.clear();

    setState(() {
      _messages.add(_ChatMessage(text: question, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();
    await _saveHistory();

    try {
      final budget = widget.activity.metadata?['budget'] ?? 'Non spécifié';
      final city = widget.activity.metadata?['city'] ?? 'Non spécifiée';
      
      // Extraction de l'historique récent (5 derniers messages) pour la continuité
      final recentHistory = _messages.length > 5 
          ? _messages.sublist(_messages.length - 5) 
          : _messages;
      final historyText = recentHistory.map((m) => "${m.isUser ? 'Client' : 'Mentor'}: ${m.text}").join("\n");

      final contextPrompt = '''
CONTEXTE BUSINESS INITIAL :
Sujet : ${_idea.title}
Cœur du projet : ${_idea.description}
Budget initial : $budget
Ville : $city

HISTORIQUE DE LA CONVERSATION (MÉMOIRE) :
$historyText

NOUVELLE INTERACTION DE L'UTILISATEUR : "$question"

!!! MISSION DU MENTOR SÉNIOR (ACCOMPAGNEMENT PAS-À-PAS) !!!
1. RÔLE : Tu es son mentor personnel. L'utilisateur est un VRAI DÉBUTANT. Sois patient, extrêmement clair, et guide-le étape par étape.
2. MÉMOIRE ACTIVÉE : Lis attentivement l'HISTORIQUE ci-dessus. Si l'utilisateur te fait un compte-rendu d'une action qu'il a réalisée, félicite-le RAPIDEMENT et AMÉLIORE IMMÉDIATEMENT la stratégie globale pour qu'il passe à l'étape suivante. Ne reviens pas en arrière.
3. ORIENTÉ ACTION : Ne donne jamais plus de 2 tâches à faire à la fois. S'il ne sait pas par quoi commencer, donne-lui UNE SEULE tâche ultra-simple pour sa première journée.
4. RÉALITÉ TERRAIN : Cite des fournisseurs, des quartiers ou des astuces hyper-concrètes pour $city en Guinée.
5. DISCIPLINE ET ENCOURAGEMENT : Pousse-le toujours vers l'avant.

Format de réponse STRICTEMENT ATTENDU EN JSON :
{
  "hook": "Ta réponse de mentor (200-400 caractères), encourageante, qui prend en compte l'historique et lui donne la prochaine étape stratégique très précise.",
  "body": [], "cta": "", "instructions": [], "alternativeHooks": []
}
''';

      final response = await _service.getClient().functions.invoke(
        'smart-api',
        body: {
          'type': 'video', 
          'product': contextPrompt,
          'audience': 'Entrepreneur local',
          'style': 'Mentor Expert. IGNORE TOTALEMENT LA CONSIGNE "TikTok" ET LE FORMAT "hook" STANDARD. RUPTURE DE CONTEXTE: TU *DOIS* ÊTRE LE MENTOR ET METTRE TA RÉPONSE HUMAINE DANS LE CHAMP "hook" ET LAISSER LE RESTE VIDE.',
        },
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        final answer = data['hook'] ?? 'Je n\'ai pas pu formuler de réponse. Pouvez-vous préciser ?';
        setState(() {
          _messages.add(_ChatMessage(text: answer, isUser: false));
          _isTyping = false;
        });
        await _saveHistory();
      } else {
        throw Exception();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: '❌ Problème de connexion. Réessayez dans un instant.', isUser: false));
          _isTyping = false;
        });
      }
    }
    _scrollToBottom();
  }

  void _generateReport() {
    _sendMessage(customQuestion: "Analyse notre conversation et donne-moi un bilan stratégique avec 3 piliers de discipline pour faire exploser ce business.");
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 40, spreadRadius: 10)
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bar supérieure
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
              ),
              _buildHeader(),
              const Divider(color: Colors.white10, height: 1),
              // Messages
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) return _buildTypingIndicator();
                      return _buildMessage(_messages[index]);
                    },
                  ),
                ),
              ),
              // Input Bar
              _buildInputBar(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MENTOR IA SÉNIOR', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                Text('Analyse stratégique en cours', style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          _buildBilanButton(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 22),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildBilanButton() {
    return GestureDetector(
      onTap: _generateReport,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.primary, size: 14),
            const SizedBox(width: 6),
            Text('BILAN', style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: TextField(
                controller: _inputController,
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Posez votre question business...',
                  hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              height: 48, width: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(_ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.primary : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 20),
          ),
        ),
        child: Text(
          msg.text, 
          style: GoogleFonts.plusJakartaSans(
            color: msg.isUser ? Colors.black : Colors.white, 
            fontSize: 13, 
            height: 1.5,
            fontWeight: msg.isUser ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => _TypingDot(delay: i * 200)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}


class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});
  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
