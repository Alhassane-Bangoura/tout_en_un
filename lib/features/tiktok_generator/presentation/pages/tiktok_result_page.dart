import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:tout_en_un/core/theme/app_colors.dart';
import 'package:tout_en_un/features/tiktok_generator/data/models/tiktok_models.dart';

class TiktokResultPage extends StatelessWidget {
  final TiktokScriptModel script;
  final VoidCallback onRegenerate;
  final VoidCallback onCreateAnother;

  const TiktokResultPage({
    super.key,
    required this.script,
    required this.onRegenerate,
    required this.onCreateAnother,
  });

  void _copyToClipboard(BuildContext context) {
    final fullText = '''
HOOK:
${script.hook}

SCRIPT:
${script.body.map((p) => "[${p.timestamp}] ${p.content}").join('\n')}

CTA:
${script.cta}
''';
    Clipboard.setData(ClipboardData(text: fullText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Script copié !',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 24, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Text(
            'TIKTOK GENERATOR',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.onSurface,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
              children: const [
                TextSpan(text: 'Script prêt à\n'),
                TextSpan(text: 'générer des ventes.', style: TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
          
          const SizedBox(height: 40),

          // Bento Layout Sections
          _buildHookSection(),
          const SizedBox(height: 16),
          _buildBodySection(),
          const SizedBox(height: 16),
          _buildCtaSection(),
          
          const SizedBox(height: 48),

          // Instructions Section
          _buildInstructionsSection(),
          
          const SizedBox(height: 40),

          // Alternative Hooks
          _buildAlternativeHooks(),

          const SizedBox(height: 48),

          // Action Buttons
          ElevatedButton(
            onPressed: () => _copyToClipboard(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 8,
              shadowColor: AppColors.primary.withOpacity(0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.content_copy_rounded, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Copier tout',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRegenerate,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text('Regénérer'.toUpperCase()),
                  style: _outlineButtonStyle(AppColors.secondary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCreateAnother,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('Nouvelle vidéo'.toUpperCase()),
                  style: _outlineButtonStyle(Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHookSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.anchor_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "L'ACCROCHE (HOOK)",
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '"${script.hook}"',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.movie_edit, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                "CORPS DU SCRIPT",
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            children: script.body.map((part) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    part.timestamp,
                    style: GoogleFonts.robotoMono(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      part.content,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.onSurface.withOpacity(0.9),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_rounded, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                "APPEL À L'ACTION",
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.secondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"${script.cta}"',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Comment utiliser ce script',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...List.generate(script.instructions.length, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    script.instructions[index],
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildAlternativeHooks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Hooks Alternatifs',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...script.alternativeHooks.map((h) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.05)),
            ),
            child: Text(
              '"$h"',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        )),
      ],
    );
  }

  ButtonStyle _outlineButtonStyle(Color color) {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      foregroundColor: color,
      side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      textStyle: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
      ),
    );
  }
}
