import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tout_en_un/core/theme/app_colors.dart';

class CreditsDisplayWidget extends StatelessWidget {
  final int credits;

  const CreditsDisplayWidget({
    super.key,
    required this.credits,
  });

  @override
  Widget build(BuildContext context) {
    // Current credits / total cap (e.g. 160)
    final double progress = (credits / 500).clamp(0.0, 1.0);
    final int possibleActions = (credits / 10).floor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Text(
                '$credits crédits restants',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                '≈ $possibleActions actions possibles',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 96,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.velocityGradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
