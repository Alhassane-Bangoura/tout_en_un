import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aibusiness/core/theme/app_colors.dart';
import 'package:aibusiness/core/supabase/supabase_service.dart';
import 'package:aibusiness/features/home/data/models/activity_model.dart';
import 'package:aibusiness/features/business_idea/data/models/business_idea_models.dart';
import 'package:aibusiness/features/business_idea/presentation/widgets/business_chat_widget.dart';

class BusinessIdeaHistoryPage extends StatefulWidget {
  const BusinessIdeaHistoryPage({super.key});

  @override
  State<BusinessIdeaHistoryPage> createState() => _BusinessIdeaHistoryPageState();
}

class _BusinessIdeaHistoryPageState extends State<BusinessIdeaHistoryPage> {
  final SupabaseService _service = SupabaseService();
  List<ActivityModel> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    final all = await _service.getRecentActivities();
    setState(() {
      _activities = all.where((a) => a.type == 'idea').toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'HISTORIQUE DES IDÉES',
          style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: _loadActivities,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activities.isEmpty
              ? _buildEmptyState()
              : _buildActivityList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Aucune idée générée', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          Text('Vos idées business apparaîtront ici', style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return _buildActivityCard(activity, index);
      },
    );
  }

  Widget _buildActivityCard(ActivityModel activity, int index) {
    // Reconstruire le modèle depuis les metadata
    BusinessIdeaModel? idea;
    if (activity.metadata != null) {
      try {
        idea = BusinessIdeaModel.fromJson(Map<String, dynamic>.from(activity.metadata!));
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text('${index + 1}', style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontWeight: FontWeight.bold))),
          ),
          title: Text(
            activity.title ?? 'Idée Business',
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            _formatDate(activity.createdAt),
            style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 12),
          ),
          trailing: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38),
          children: [
            if (idea != null) _buildIdeaDetails(idea) else _buildSimpleSummary(activity),
            if (idea != null) _buildProgressSection(activity, idea),
            if (idea != null) _buildStrategyChatButton(context, activity),
          ],
        ),
      ),
    );
  }

  Widget _buildIdeaDetails(BusinessIdeaModel idea) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white10),
        Text(idea.description, style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 13, height: 1.5)),
        const SizedBox(height: 12),
        if (idea.aiConclusion.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    idea.aiConclusion,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.85), fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text('📈 ${idea.estimatedProfit}', style: GoogleFonts.plusJakartaSans(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }


  Widget _buildSimpleSummary(ActivityModel activity) {
    return Text(
      activity.resultSummary ?? '',
      style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 13),
    );
  }

  Widget _buildProgressSection(ActivityModel activity, BusinessIdeaModel idea) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        
        // --- NOUVEAU : PLAN D'ACTION 30 JOURS ---
        if (idea.actionPlan30Days.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: AppColors.secondary, size: 16),
              const SizedBox(width: 8),
              Text('STRATÉGIE 30 JOURS', style: GoogleFonts.spaceGrotesk(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary.withOpacity(0.1)),
            ),
            child: Column(
              children: idea.actionPlan30Days.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6, height: 6,
                      decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step,
                        style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],

        Text('ÉTAPES DE LANCEMENT', style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        ...idea.steps.map((step) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white24, size: 16),
                const SizedBox(width: 12),
                Expanded(child: Text(step, style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStrategyChatButton(BuildContext context, ActivityModel activity) {
    // Reconstruire l'idée pour vérifier si elle existe (mais on passe l'activité au chat)
    return Column(
      children: [
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => BusinessChatWidget(
                activity: activity,
                onClose: () => Navigator.pop(context),
              ),
            ),
            icon: const Icon(Icons.psychology_rounded, size: 18, color: Colors.black),
            label: Text('Obtenir une Stratégie', style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
  }
}
