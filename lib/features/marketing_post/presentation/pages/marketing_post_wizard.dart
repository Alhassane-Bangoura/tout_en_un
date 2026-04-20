import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aibusiness/core/theme/app_colors.dart';
import 'package:aibusiness/core/supabase/supabase_service.dart';
import 'package:aibusiness/features/marketing_post/data/models/marketing_post_models.dart';
import 'package:aibusiness/features/tiktok_generator/presentation/widgets/generator_widgets.dart';
import 'package:aibusiness/core/widgets/app_loading_page.dart';
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => setState(() => _generatedPost = null),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 14),
                const SizedBox(width: 4),
                Text('SUCCESS AI', style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text(
              'TON MESSAGE\nEST PRÊT !',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Optimisé pour la conversion et la viralité.',
              style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Result Card (Glassmorphism)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.03),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Headline with Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'HOT',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          post.headline, 
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white, 
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Main Content
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      post.content, 
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.9), 
                        fontSize: 15, 
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CTA Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CALL TO ACTION:', style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        const SizedBox(height: 8),
                        Text(
                          post.cta, 
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.secondary, 
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hashtags
                  Wrap(
                    spacing: 8, 
                    runSpacing: 8,
                    children: post.hashtags.map((h) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(h, style: GoogleFonts.robotoMono(color: AppColors.primary.withOpacity(0.7), fontSize: 11)),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: "${post.headline}\n\n${post.content}\n\n${post.cta}\n\n${post.hashtags.join(' ')}"));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Message copié dans le presse-papier !'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, color: Colors.black, size: 20),
              label: Text('COPIER LE MESSAGE', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, 
                foregroundColor: Colors.black, 
                minimumSize: const Size(double.infinity, 64), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => setState(() => _generatedPost = null),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 64), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                'CRÉER UN AUTRE MESSAGE', 
                style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
