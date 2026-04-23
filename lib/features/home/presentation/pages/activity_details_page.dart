import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:aibusiness/core/theme/app_colors.dart';
import 'package:aibusiness/core/supabase/supabase_service.dart';
import 'package:aibusiness/features/home/data/models/activity_model.dart';
import 'package:aibusiness/features/tiktok_generator/data/models/tiktok_models.dart';
import 'package:aibusiness/features/business_idea/data/models/business_idea_models.dart';
import 'package:aibusiness/features/incubator/presentation/pages/incubator_dashboard.dart';
import 'package:aibusiness/features/marketing_post/data/models/marketing_post_models.dart';
import 'package:aibusiness/features/business_idea/presentation/widgets/business_chat_widget.dart';

class ActivityDetailsPage extends StatelessWidget {
  final ActivityModel activity;

  const ActivityDetailsPage({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          activity.title.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (activity.metadata == null) {
      return const Center(child: Text('Aucune donnée disponible', style: TextStyle(color: Colors.white)));
    }

    switch (activity.type) {
      case 'video':
        final script = TiktokScriptModel(
          hook: activity.metadata!['hook'] ?? '',
          cta: activity.metadata!['cta'] ?? '',
          body: (activity.metadata!['body'] as List? ?? []).map((b) => ScriptPart(
            timestamp: b['timestamp'] ?? '',
            content: b['content'] ?? '',
          )).toList(),
          alternativeHooks: List<String>.from(activity.metadata!['alternativeHooks'] ?? []),
          instructions: List<String>.from(activity.metadata!['instructions'] ?? []),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TiktokResultPageContent(script: script),
        );
      
      case 'idea':
        final idea = BusinessIdeaModel.fromJson(activity.metadata!);
        return _BusinessIdeaResultView(idea: idea, activity: activity);

      case 'marketing':
        final post = MarketingPostModel.fromJson(activity.metadata!);
        return _MarketingPostResultView(post: post);

      default:
        return Center(child: Text('Type inconnu : ${activity.type}', style: const TextStyle(color: Colors.white)));
    }
  }
}

// Since TiktokResultPage was a full page with SingleChildScrollView, 
// let's extract its content into a separate widget or reuse it.
// I'll create a "Content" version of the result views.

class TiktokResultPageContent extends StatelessWidget {
  final TiktokScriptModel script;

  const TiktokResultPageContent({super.key, required this.script});

  @override
  Widget build(BuildContext context) {
    // Reuse the UI logic from TiktokResultPage but without the action buttons at the bottom 
    // or with a "Copy Only" button.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 24, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHookSection(script.hook),
          const SizedBox(height: 16),
          _buildBodySection(script.body),
          const SizedBox(height: 16),
          _buildCtaSection(script.cta),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _copyTiktok(context, script),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('COPIER LE SCRIPT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  void _copyTiktok(BuildContext context, TiktokScriptModel script) {
    final text = "HOOK: ${script.hook}\n\nBODY:\n${script.body.map((p) => "[${p.timestamp}] ${p.content}").join('\n')}\n\nCTA: ${script.cta}";
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Script copié !')));
  }

  Widget _buildHookSection(String hook) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("L'ACCROCHE (HOOK)", style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Text('"$hook"', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBodySection(List<ScriptPart> body) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: body.map((part) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(part.timestamp, style: GoogleFonts.robotoMono(color: AppColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(child: Text(part.content, style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCtaSection(String cta) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.secondary.withOpacity(0.2))),
      child: Text('"$cta"', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
    );
  }
}

class _BusinessIdeaResultView extends StatefulWidget {
  final BusinessIdeaModel idea;
  final ActivityModel activity;

  const _BusinessIdeaResultView({required this.idea, required this.activity});

  @override
  State<_BusinessIdeaResultView> createState() => _BusinessIdeaResultViewState();
}

class _BusinessIdeaResultViewState extends State<_BusinessIdeaResultView> {
  bool _showChat = false;
  bool _isLaunching = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.idea.title, style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(widget.idea.description, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildInfoRow('Profit Estimé', _sanitizeCurrency(widget.idea.estimatedProfit), AppColors.secondary),
                const SizedBox(height: 32),
                Text('ÉTAPES DE LANCEMENT', style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...widget.idea.steps.map((s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('• $s', style: GoogleFonts.plusJakartaSans(color: Colors.white70)))),
                const SizedBox(height: 32),
                
                // Bouton Incubateur (Nouveau)
                ElevatedButton.icon(
                  onPressed: _isLaunching ? null : () => _startIncubationFromDetails(context, widget.idea),
                  icon: _isLaunching 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Icon(Icons.rocket_launch_rounded, color: Colors.black),
                  label: Text(_isLaunching ? 'LANCEMENT...' : 'LANCER DANS L\'INCUBATEUR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFA3),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Bouton Chat
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showChat = !_showChat),
                  icon: const Icon(Icons.psychology_rounded, color: Colors.black),
                  label: const Text('CONTINUER LA DISCUSSION (IA)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showChat ? Colors.white24 : AppColors.primary, 
                    foregroundColor: _showChat ? Colors.white : Colors.black, 
                    minimumSize: const Size(double.infinity, 54), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                const SizedBox(height: 12),
                
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: "${widget.idea.title}\n\n${widget.idea.description}\n\nProfit: ${widget.idea.estimatedProfit}\n\nÉtapes:\n${widget.idea.steps.join('\n')}"));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Idée copiée !')));
                  },
                  icon: const Icon(Icons.copy_rounded, color: Colors.white54),
                  label: const Text('COPIER LE CONCEPT'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54, 
                    minimumSize: const Size(double.infinity, 54), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    side: const BorderSide(color: Colors.white12),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showChat)
          BusinessChatWidget(
            activity: widget.activity,
            onClose: () => setState(() => _showChat = false),
          ),
      ],
    );
  }

  String _sanitizeCurrency(String text) {
    return text
        .replaceAll(RegExp(r'FCFA|CFA|Franc CFA|XOF|XAF', caseSensitive: false), 'GNF')
        .replaceAll(RegExp(r'Dollar|Euro|€|\$', caseSensitive: false), 'GNF'); // Fallback pour les tests
  }

  Future<void> _startIncubationFromDetails(BuildContext context, BusinessIdeaModel idea) async {
    setState(() => _isLaunching = true);
    final service = SupabaseService();
    
    // Récupérer les infos depuis les métadonnées de l'activité ou le profil
    final String budget = widget.activity.metadata?['budget'] ?? "Plus de 1M";
    final String city = widget.activity.metadata?['city'] ?? "Conakry";
    final String? skills = widget.activity.metadata?['skills'];
    final String? fears = widget.activity.metadata?['fears'];
    final String? time = widget.activity.metadata?['availableTime'];

    final request = BusinessIdeaRequestModel(
      budget: budget, 
      city: city,
      niche: idea.title,
      businessIdea: '${idea.title} - ${idea.description}',
      skills: skills,
      fears: fears,
      availableTime: time,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Lancement de l'Incubateur...")),
    );

    try {
      final result = await service.startIncubation(request);
      if (mounted && result != null && result['id'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => IncubatorDashboard(initialProjectId: result['id'])),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.plusJakartaSans(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_sanitizeCurrency(value), style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _MarketingPostResultView extends StatelessWidget {
  final MarketingPostModel post;

  const _MarketingPostResultView({required this.post});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.headline, style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text(post.content, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, height: 1.5)),
                const SizedBox(height: 20),
                Text(post.cta, style: GoogleFonts.plusJakartaSans(color: AppColors.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Wrap(spacing: 8, children: post.hashtags.map((h) => Text(h, style: GoogleFonts.robotoMono(color: AppColors.primary, fontSize: 12))).toList()),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: "${post.headline}\n\n${post.content}\n\n${post.cta}\n\n${post.hashtags.join(' ')}"));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post copié !')));
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('COPIER LE MESSAGE'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
          ),
        ],
      ),
    );
  }
}
