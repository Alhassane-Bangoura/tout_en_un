import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tout_en_un/core/theme/app_colors.dart';
import 'package:tout_en_un/core/supabase/supabase_service.dart';
import 'package:tout_en_un/features/marketing_post/data/models/marketing_post_models.dart';
import 'package:tout_en_un/features/tiktok_generator/presentation/widgets/generator_widgets.dart';
import 'package:tout_en_un/core/widgets/app_loading_page.dart';
import 'package:flutter/services.dart';

class MarketingPostWizard extends StatefulWidget {
  const MarketingPostWizard({super.key});

  @override
  State<MarketingPostWizard> createState() => _MarketingPostWizardState();
}

class _MarketingPostWizardState extends State<MarketingPostWizard> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;
  MarketingPostModel? _generatedPost;

  final TextEditingController _productController = TextEditingController();
  final TextEditingController _platformController = TextEditingController();
  String _selectedTone = 'Persuasif';

  Future<void> _generate() async {
    if (_productController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez entrer le produit')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = MarketingPostRequestModel(
        product: _productController.text,
        platform: _platformController.text.isEmpty ? 'WhatsApp/FB' : _platformController.text,
        tone: _selectedTone,
      );
      
      final post = await _supabaseService.generateMarketingPost(request);
      
      if (mounted) {
        setState(() {
          _generatedPost = post;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().contains('Crédits') ? 'Crédits insuffisants' : 'Erreur de génération')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppLoadingPage(
        onComplete: () {},
        icon: Icons.campaign_rounded,
        title: 'Création du message...',
        subtitle: 'L\'IA rédige votre post de vente viral...',
        statusMessages: [
          'Analyse du produit...',
          'Choix du ton...',
          'Rédaction du post...',
          'Optimisation CTA...',
        ],
      );
    }
    if (_generatedPost != null) return _buildResultPage();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text('MARKETING POST AI', style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vends tes produits\nplus rapidement', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, height: 1.1)),
            const SizedBox(height: 40),
            GeneratorTextField(label: '01. Ton Produit / Service', hint: 'Ex: Formation, Vêtements, Coaching...', example: 'Ex: Savon artisanal, coaching business', controller: _productController),
            const SizedBox(height: 32),
            GeneratorTextField(label: '02. Quelle plateforme ?', hint: 'Ex: WhatsApp, Facebook, Instagram...', example: 'Ex: Statut WhatsApp, Pub Facebook', controller: _platformController),
            const SizedBox(height: 32),
            _buildToneSelector(),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _generate,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              child: Text('GÉNÉRER MON MESSAGE', style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToneSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('03. TON DU MESSAGE', style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2.0)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Persuasif', 'Amical', 'Urgence', 'Professionnel'].map((tone) {
            bool isSelected = _selectedTone == tone;
            return InkWell(
              onTap: () => setState(() => _selectedTone = tone),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: isSelected ? AppColors.primary : AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)),
                child: Text(tone, style: GoogleFonts.plusJakartaSans(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultPage() {
    final post = _generatedPost!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _generatedPost = null))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.1))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(post.headline, style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 20),
                   Text(post.content, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, height: 1.5)),
                   const SizedBox(height: 20),
                   Text(post.cta, style: GoogleFonts.plusJakartaSans(color: AppColors.secondary, fontSize: 18, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                   const SizedBox(height: 24),
                   Wrap(spacing: 8, children: post.hashtags.map((h) => Text(h, style: GoogleFonts.robotoMono(color: AppColors.primary, fontSize: 12))).toList()),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: "${post.headline}\n\n${post.content}\n\n${post.cta}\n\n${post.hashtags.join(' ')}"));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copié !')));
              },
              icon: const Icon(Icons.copy_rounded, color: Colors.black),
              label: Text('COPIER LE MESSAGE', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => setState(() => _generatedPost = null),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), side: const BorderSide(color: AppColors.outlineVariant)),
              child: Text('NOUVEAU MESSAGE', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
