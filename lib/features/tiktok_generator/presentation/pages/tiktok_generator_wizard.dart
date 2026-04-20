import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aibusiness/core/theme/app_colors.dart';
import 'package:aibusiness/core/supabase/supabase_service.dart';
import 'package:aibusiness/features/tiktok_generator/data/models/tiktok_models.dart';
import 'package:aibusiness/features/home/data/models/activity_model.dart';
import 'package:aibusiness/features/home/data/models/profile_model.dart';
import 'tiktok_input_page.dart';
import 'package:aibusiness/core/widgets/app_loading_page.dart';
import 'tiktok_result_page.dart';

enum GeneratorStep { input, loading, result, vault, insights }

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
  ProfileModel? _profile;
  List<ActivityModel> _videoHistory = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _supabaseService.getProfile();
    if (mounted) {
      setState(() => _profile = profile);
    }
  }

  Future<void> _loadHistory() async {
    if (_videoHistory.isNotEmpty) return; // Déjà chargé
    
    setState(() => _isLoadingHistory = true);
    try {
      final activities = await _supabaseService.getRecentActivities();
      // Filtrer uniquement par type 'video'
      final filtered = activities.where((a) => a.type == 'video').toList();
      
      if (mounted) {
        setState(() {
          _videoHistory = filtered;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  // Real generation logic
  Future<void> _startGeneration(TiktokRequestModel request) async {
    setState(() {
      _latestRequest = request;
      _currentStep = GeneratorStep.loading;
    });

    try {
      final result = await _supabaseService.generateTiktokScript(request);

      if (mounted) {
        if (result != null) {
          setState(() {
            _generatedScript = result['script'] as TiktokScriptModel?;
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 26),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'MONEY MACHINE AI',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (_currentStep != GeneratorStep.loading)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
              ),
              child: ClipOval(
                child: _profile?.avatarUrl != null
                    ? Image.network(
                        _profile!.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                      )
                    : const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
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
      case GeneratorStep.vault:
        return _buildVaultStep();
      case GeneratorStep.insights:
        return _buildInsightsStep();
    }
  }

  Widget _buildVaultStep() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_videoHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_rounded, color: AppColors.primary.withOpacity(0.2), size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'AUCUNE VIDÉO TROUVÉE',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Générez votre premier script pour le voir ici.',
              style: GoogleFonts.plusJakartaSans(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VAULT PRIVÉ',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                '${_videoHistory.length} VIDÉOS',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._videoHistory.map((activity) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
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
                    setState(() {
                      _generatedScript = script;
                      _currentStep = GeneratorStep.result;
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.movie_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.title.toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${activity.createdAt.day}/${activity.createdAt.month}/${activity.createdAt.year} • AI Generated',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInsightsStep() {
    final int totalScripts = _videoHistory.length;
    final int totalCredits = totalScripts * 10;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ANALYSE DE PERFORMANCE',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 32),
          
          // Triple Stats Row (Example of improvement)
          _buildInsightCard(
            label: 'SCRIPTS GÉNÉRÉS', 
            value: '$totalScripts', 
            icon: Icons.auto_awesome_motion_rounded, 
            color: AppColors.primary,
            trend: '+12%',
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            label: 'CRÉDITS INVESTIS', 
            value: '$totalCredits', 
            icon: Icons.bolt_rounded, 
            color: AppColors.secondary,
            trend: 'Optimisé',
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            label: 'VIRALITÉ MOYENNE', 
            value: '84%', 
            icon: Icons.auto_graph_rounded, 
            color: AppColors.tertiary,
            trend: 'Haut',
          ),

          const SizedBox(height: 32),
          
          // Future section hint
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                const Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 32),
                const SizedBox(height: 12),
                Text(
                  'Bientôt : Prédictions de revenus IA',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Analysez le ROI de vos scripts en temps réel.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String label, 
    required String value, 
    required IconData icon, 
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white, 
                        fontSize: 28, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          trend,
                          style: GoogleFonts.plusJakartaSans(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          _buildNavItem(
            Icons.construction, 
            'Build', 
            _currentStep == GeneratorStep.input,
            onTap: () => setState(() => _currentStep = GeneratorStep.input),
          ),
          _buildNavItem(
            Icons.movie_edit, 
            'Scripts', 
            _currentStep == GeneratorStep.result,
            onTap: () {
              if (_generatedScript != null) {
                setState(() => _currentStep = GeneratorStep.result);
              }
            },
          ),
          _buildNavItem(
            Icons.account_balance_wallet_rounded, 
            'Vault', 
            _currentStep == GeneratorStep.vault,
            onTap: () {
              setState(() => _currentStep = GeneratorStep.vault);
              _loadHistory();
            },
          ),
          _buildNavItem(
            Icons.query_stats_rounded, 
            'Insights', 
            _currentStep == GeneratorStep.insights,
            onTap: () {
              setState(() => _currentStep = GeneratorStep.insights);
              _loadHistory();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
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
        ),
      ),
    );
  }
}
