import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tout_en_un/core/theme/app_colors.dart';
import 'package:tout_en_un/core/supabase/supabase_service.dart';
import 'package:tout_en_un/features/home/data/models/profile_model.dart';
import 'package:tout_en_un/features/home/data/models/activity_model.dart';
import 'package:tout_en_un/features/auth/presentation/pages/auth_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tout_en_un/features/tiktok_generator/presentation/pages/tiktok_generator_wizard.dart';
import 'package:tout_en_un/features/business_idea/presentation/pages/business_idea_wizard.dart';
import 'package:tout_en_un/features/marketing_post/presentation/pages/marketing_post_wizard.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/action_card_widget.dart';
import '../widgets/recent_activity_widget.dart';
import '../widgets/credits_display_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseService _supabaseService = SupabaseService();
  
  ProfileModel? _profile;
  List<ActivityModel> _recentItems = [];
  int _totalActions = 0;
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final profile = await _supabaseService.getProfile();
    final activities = await _supabaseService.getRecentActivities();
    final totalActions = await _supabaseService.getTotalActivitiesCount();
    
    if (mounted) {
      setState(() {
        _profile = profile;
        _recentItems = activities;
        _totalActions = totalActions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBackgroundAccent(),
          SafeArea(
            child: Column(
              children: [
                _buildTopAppBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildCurrentPage(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavBar(),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildBackgroundAccent() {
    return Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withOpacity(0.03),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildHistoryContent();
      case 2:
        return _buildProfileContent();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      key: const ValueKey('home_content'),
      onRefresh: _loadData,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            HomeHeaderWidget(name: _profile?.fullName),
            const SizedBox(height: 48),
            ActionCardWidget(
              title: 'Créer une vidéo qui vend',
              subtitle: 'Script + hook + CTA en 10 secondes',
              ctaLabel: 'Créer maintenant',
              icon: Icons.video_library_rounded,
              size: ActionCardSize.primary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TiktokGeneratorWizard())).then((_) => _loadData()),
            ),
            const SizedBox(height: 24),
            ActionCardWidget(
              title: 'Trouver une idée rentable',
              subtitle: 'Adaptée à ton budget et ta ville',
              ctaLabel: 'Générer idée',
              icon: Icons.lightbulb_rounded,
              accentColor: AppColors.secondary,
              size: ActionCardSize.secondary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BusinessIdeaWizard())).then((_) => _loadData()),
            ),
            const SizedBox(height: 16),
            ActionCardWidget(
              title: 'Vendre mon produit',
              subtitle: 'Message prêt pour WhatsApp et Facebook',
              ctaLabel: 'Créer message',
              icon: Icons.campaign_rounded,
              accentColor: AppColors.tertiary,
              size: ActionCardSize.secondary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketingPostWizard())).then((_) => _loadData()),
            ),
            const SizedBox(height: 48),
            _buildRecentActivityHeader(),
            const SizedBox(height: 16),
            RecentActivityWidget(items: _recentItems),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Activités récentes',
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _currentIndex = 1),
          child: Text(
            'TOUT VOIR',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Text(
                'HISTORIQUE',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _recentItems.length,
              itemBuilder: (context, index) {
                return RecentActivityWidget(items: [_recentItems[index]]);
              },
            ),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildProfileContent() {
    final user = Supabase.instance.client.auth.currentUser;
    final joinDate = _profile?.updatedAt != null 
        ? '${_profile!.updatedAt!.day}/${_profile!.updatedAt!.month}/${_profile!.updatedAt!.year}'
        : 'Récemment';

    return SingleChildScrollView(
      key: const ValueKey('profile_content'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          _buildProfileAvatar(),
          const SizedBox(height: 24),
          Text(
            _profile?.fullName ?? user?.userMetadata?['full_name'] ?? 'Utilisateur',
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(
            user?.email ?? '',
            style: GoogleFonts.plusJakartaSans(color: AppColors.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 40),
          _buildInfoGrid(joinDate),
          const SizedBox(height: 32),
          _buildSyncButton(),
          const SizedBox(height: 16),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    return TextButton.icon(
      onPressed: _loadData,
      icon: const Icon(Icons.sync_rounded, color: AppColors.primary),
      label: Text(
        'SYNCHRONISER MON PROFIL',
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 3),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: ClipOval(
        child: _profile?.avatarUrl != null
            ? Image.network(
                _profile!.avatarUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
                },
                errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.person_rounded, color: AppColors.primary, size: 70),
              )
            : const Icon(Icons.person_rounded, color: AppColors.primary, size: 70),
      ),
    );
  }

  Widget _buildInfoGrid(String joinDate) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            'TOTAL ACTIONS',
            '$_totalActions',
            Icons.bolt_rounded,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            'INSCRIPTION',
            joinDate,
            Icons.calendar_today_rounded,
            AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(color: AppColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      onPressed: () => _supabaseService.signOut(),
      icon: const Icon(Icons.logout_rounded, size: 20),
      label: Text('SE DÉCONNECTER', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        foregroundColor: Colors.redAccent,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        side: const BorderSide(color: Colors.redAccent, width: 1.5),
        elevation: 0,
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.token_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'AB BUSINESS AI',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
            ],
          ),
          CreditsDisplayWidget(credits: _profile?.credits ?? 0),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.1)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_filled, 'Accueil'),
          _buildNavItem(1, Icons.history_rounded, 'Historique'),
          _buildNavItem(2, Icons.person_rounded, 'Profil'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    Color color = isSelected ? AppColors.primary : AppColors.onSurfaceVariant;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                color: color,
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

