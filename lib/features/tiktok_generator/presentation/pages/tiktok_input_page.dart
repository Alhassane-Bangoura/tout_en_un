import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aibusiness/core/theme/app_colors.dart';
import 'package:aibusiness/features/tiktok_generator/data/models/tiktok_models.dart';
import '../widgets/generator_widgets.dart';

class TiktokInputPage extends StatefulWidget {
  final Function(TiktokRequestModel) onStartGenerating;

  const TiktokInputPage({
    super.key,
    required this.onStartGenerating,
  });

  @override
  State<TiktokInputPage> createState() => _TiktokInputPageState();
}

class _TiktokInputPageState extends State<TiktokInputPage> {
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _audienceController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  String _selectedStyle = 'Sérieux';

  @override
  void dispose() {
    _productController.dispose();
    _audienceController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 24, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Section
          Text(
            'Créer une vidéo\nqui vend',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.onSurface,
              fontSize: 44,
              fontWeight: FontWeight.bold,
              height: 1.1,
              letterSpacing: -2.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Réponds à 4 questions et génère ton script',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.onSurfaceVariant,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 48),

          // Glass Form Container
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.outlineVariant.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.03),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                GeneratorTextField(
                  label: '01. Que veux-tu vendre?',
                  hint: 'Ex: formation, produit, service...',
                  example: 'Ex: formation Instagram, t-shirt, service freelance',
                  controller: _productController,
                ),
                const SizedBox(height: 32),
                GeneratorTextField(
                  label: '02. À qui?',
                  hint: 'Ex: étudiants, entrepreneurs...',
                  example: 'Ex: étudiants, mamans, entrepreneurs',
                  controller: _audienceController,
                ),
                const SizedBox(height: 32),
                StyleSelector(
                  options: const ['Fun', 'Sérieux', 'Motivation'],
                  selectedOption: _selectedStyle,
                  onSelected: (style) => setState(() => _selectedStyle = style),
                ),
                const SizedBox(height: 32),
                GeneratorTextField(
                  label: '04. DÉTAILS SUPPLÉMENTAIRES',
                  hint: 'Ex: Met l\'accent sur la qualité...',
                  example: 'Ex: Parle de la promo, du lieu de vente...',
                  controller: _detailsController,
                  maxLines: 3,
                ),
                const SizedBox(height: 40),
                
                // Primary CTA
                InkWell(
                  onTap: () {
                    if (_productController.text.isNotEmpty) {
                      widget.onStartGenerating(
                        TiktokRequestModel(
                          product: _productController.text,
                          targetAudience: _audienceController.text.isEmpty 
                              ? "Tout le monde" 
                              : _audienceController.text,
                          style: _selectedStyle,
                          details: _detailsController.text.isEmpty ? null : _detailsController.text,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez entrer ce que vous voulez vendre')),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: AppColors.velocityGradient,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Générer ma vidéo',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.auto_awesome, color: Colors.black, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Stats Section
          Row(
            children: const [
              Expanded(
                child: StatInsightCard(
                  icon: Icons.trending_up,
                  iconColor: AppColors.secondary,
                  label: 'Potentiel Viral',
                  value: '84%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatInsightCard(
                  icon: Icons.timer_outlined,
                  iconColor: AppColors.tertiary,
                  label: 'Temps de Gen',
                  value: '12s',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
