import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tout_en_un/core/theme/app_colors.dart';
import 'package:tout_en_un/core/supabase/supabase_service.dart';
import 'package:tout_en_un/features/tiktok_generator/data/models/tiktok_models.dart';
import 'tiktok_input_page.dart';
import 'package:tout_en_un/core/widgets/app_loading_page.dart';
import 'tiktok_result_page.dart';

enum GeneratorStep { input, loading, result }

class TiktokGeneratorWizard extends StatefulWidget {
  const TiktokGeneratorWizard({super.key});

  @override
  State<TiktokGeneratorWizard> createState() => _TiktokGeneratorWizardState();
}

class _TiktokGeneratorWizardState extends State<TiktokGeneratorWizard> {
  GeneratorStep _currentStep = GeneratorStep.input;
  TiktokScriptModel? _generatedScript;
  TiktokRequestModel? _latestRequest;
  final SupabaseService _supabaseService = SupabaseService();

  // Real generation logic
  Future<void> _startGeneration(TiktokRequestModel request) async {
    setState(() {
      _latestRequest = request;
      _currentStep = GeneratorStep.loading;
    });

    try {
      final script = await _supabaseService.generateTiktokScript(request);

      if (mounted) {
        if (script != null) {
          setState(() {
            _generatedScript = script;
            _currentStep = GeneratorStep.result;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentStep = GeneratorStep.input;
        });
        
        String message = 'Erreur lors de la génération.';
        if (e.toString().contains('Crédits insuffisants')) {
          message = '⚠️ Crédits insuffisants. Veuillez recharger votre compte.';
        } else if (e.toString().contains('Erreur API')) {
          message = '❌ L\'IA est temporairement indisponible. Réessayez plus tard.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onGenerationComplete() {
    // Handled in _startGeneration
  }

  void _reset() {
    setState(() {
      _currentStep = GeneratorStep.input;
      _generatedScript = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glows (Screen 2 style)
          if (_currentStep == GeneratorStep.loading) ...[
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withOpacity(0.05),
                ),
              ),
            ),
          ],

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _buildCurrentStep(),
                  ),
                ),
              ],
            ),
          ),

          // Floating Live Generation Badge (Screen 2 detail)
          if (_currentStep == GeneratorStep.loading)
            Positioned(
              bottom: 100,
              right: 24,
              child: _buildLiveBadge(),
            ),

          // Bottom Navigation
          if (_currentStep != GeneratorStep.loading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNav(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 28),
              const SizedBox(width: 8),
              Text(
                'MONEY MACHINE AI',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          if (_currentStep != GeneratorStep.loading)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
                image: const DecorationImage(
                  image: NetworkImage('https://i.pravatar.cc/150?u=a'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case GeneratorStep.input:
        return TiktokInputPage(onStartGenerating: _startGeneration);
      case GeneratorStep.loading:
        return AppLoadingPage(
          onComplete: _onGenerationComplete,
          icon: Icons.movie_edit,
          title: 'Création du script...',
          subtitle: 'Votre vidéo virale est en préparation...',
          statusMessages: [
            'Analyse du produit...',
            'Création du hook...',
            'Écriture du script...',
            'Finalisation...',
          ],
        );
      case GeneratorStep.result:
        return TiktokResultPage(
          script: _generatedScript!,
          onRegenerate: () {
            if (_latestRequest != null) {
              _startGeneration(_latestRequest!);
            }
          },
          onCreateAnother: _reset,
        );
    }
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 12,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=b'),
          ),
          const SizedBox(width: 8),
          Text(
            'LIVE GENERATION',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.construction, 'Build', _currentStep == GeneratorStep.input),
          _buildNavItem(Icons.movie_edit, 'Scripts', _currentStep == GeneratorStep.result),
          _buildNavItem(Icons.account_balance_wallet_rounded, 'Vault', false),
          _buildNavItem(Icons.query_stats_rounded, 'Insights', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
