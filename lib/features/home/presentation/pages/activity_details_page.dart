import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:tout_en_un/core/theme/app_colors.dart';
import 'package:tout_en_un/features/home/data/models/activity_model.dart';
import 'package:tout_en_un/features/tiktok_generator/data/models/tiktok_models.dart';
import 'package:tout_en_un/features/business_idea/data/models/business_idea_models.dart';
import 'package:tout_en_un/features/marketing_post/data/models/marketing_post_models.dart';

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
        return _BusinessIdeaResultView(idea: idea);

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

class _BusinessIdeaResultView extends StatelessWidget {
  final BusinessIdeaModel idea;

  const _BusinessIdeaResultView({required this.idea});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                Text(idea.title, style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(idea.description, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoRow('Profit Estimé', idea.estimatedProfit, AppColors.secondary),
          const SizedBox(height: 32),
          Text('ÉTAPES DE LANCEMENT', style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...idea.steps.map((s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('• $s', style: GoogleFonts.plusJakartaSans(color: Colors.white70)))),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: "${idea.title}\n\n${idea.description}\n\nProfit: ${idea.estimatedProfit}\n\nÉtapes:\n${idea.steps.join('\n')}"));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Idée copiée !')));
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('COPIER LE CONCEPT'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.plusJakartaSans(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
