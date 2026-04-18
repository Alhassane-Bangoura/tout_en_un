import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tout_en_un/core/theme/app_colors.dart';

class HomeHeaderWidget extends StatelessWidget {
  final String? name;
  const HomeHeaderWidget({super.key, this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BONJOUR, ${name?.toUpperCase() ?? 'ENTREPRENEUR'} !',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.onBackground,
              fontSize: 44,
              fontWeight: FontWeight.bold,
              height: 1.1,
              letterSpacing: -1.0,
            ),
            children: [
              const TextSpan(text: 'Prêt à créer du\n'),
              TextSpan(
                text: 'contenu',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const TextSpan(text: ' qui\nvend ?'),
            ],
          ),
        ),
      ],
    );
  }
}
