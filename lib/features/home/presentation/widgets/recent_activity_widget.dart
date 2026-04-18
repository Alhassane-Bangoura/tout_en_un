import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tout_en_un/core/theme/app_colors.dart';
import 'package:tout_en_un/features/home/data/models/activity_model.dart';
import 'package:tout_en_un/features/home/presentation/pages/activity_details_page.dart';

class RecentActivityWidget extends StatelessWidget {
  final List<ActivityModel> items;

  const RecentActivityWidget({
    super.key,
    required this.items,
  });

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Généré il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Généré il y a ${diff.inHours}h';
    return 'Généré il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.05)),
        ),
        child: Center(
          child: Text(
            'Aucune activité récente',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: items
          .map((item) => _ActivityTile(
                item: item,
                timestamp: _formatTimestamp(item.createdAt),
              ))
          .toList(),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityModel item;
  final String timestamp;

  const _ActivityTile({required this.item, required this.timestamp});

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailsPage(activity: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (item.type) {
      case 'video':
        icon = Icons.video_library_rounded;
        color = AppColors.primary;
        break;
      case 'idea':
        icon = Icons.lightbulb_rounded;
        color = AppColors.secondary;
        break;
      case 'marketing':
        icon = Icons.campaign_rounded;
        color = AppColors.tertiary;
        break;
      default:
        icon = Icons.description_rounded;
        color = AppColors.onSurfaceVariant;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDetails(context),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timestamp,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _navigateToDetails(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Text(
                      'REFAIRE',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
