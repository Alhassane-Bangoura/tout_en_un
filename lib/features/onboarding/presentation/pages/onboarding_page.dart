import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import 'pre_signup_screen.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PreSignupScreen()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildScreen1(),
              _buildScreen2(),
              _buildScreen3(),
              _buildScreen4(),
            ],
          ),
          // Progress indicators
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => _buildDot(index)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppColors.primary : Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // Screen 1 — PROMESSE BRUTALE
  Widget _buildScreen1() {
    return _BaseOnboardingScreen(
      title: 'Crée ton business avec l’IA en 60 secondes',
      subtitle: 'La puissance de l\'intelligence artificielle au service de ton succès.',
      buttonText: 'Commencer',
      onPressed: _nextPage,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [AppColors.primary.withOpacity(0.1), Colors.transparent],
            radius: 0.8,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 80, color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                '💰 RÉSULTAT GARANTI',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Screen 2 — PROBLÈME (MIROIR)
  Widget _buildScreen2() {
    return _BaseOnboardingScreen(
      title: 'Pas d’idée ?\nPas de contenu ?\nPas de clients ?',
      subtitle: 'Tu es bloqué au stade de l\'envie ? On s\'occupe du reste.',
      buttonText: 'Oui, c’est moi',
      onPressed: _nextPage,
      child: Column(
        children: [
          _buildPainPoint('Idées floues', Icons.cloud_off),
          _buildPainPoint('Manque de temps', Icons.timer_off),
          _buildPainPoint('Budget limité', Icons.money_off),
        ],
      ),
    );
  }

  Widget _buildPainPoint(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.plusJakartaSans(color: Colors.white70)),
        ],
      ),
    );
  }

  // Screen 3 — SOLUTION (TON APP)
  Widget _buildScreen3() {
    return _BaseOnboardingScreen(
      title: 'Une seule app pour :\nidées + scripts +\nvidéos + logos',
      subtitle: 'Ton écosystème complet pour dominer ton marché.',
      buttonText: 'Voir comment ça marche',
      onPressed: _nextPage,
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildFeatureCard('IDÉES', Icons.lightbulb_outline, AppColors.primary),
          _buildFeatureCard('SCRIPTS', Icons.description_outlined, AppColors.secondary),
          _buildFeatureCard('VIDÉOS', Icons.videocam_outlined, AppColors.tertiary),
          _buildFeatureCard('LOGOS', Icons.brush_outlined, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Screen 4 — DÉMO FAKE
  Widget _buildScreen4() {
    return _BaseOnboardingScreen(
      title: 'Déjà prêt à l\'emploi',
      subtitle: 'Regarde la magie opérer en quelques secondes.',
      buttonText: 'Créer le mien',
      onPressed: _nextPage,
      child: _FakeDemoWidget(),
    );
  }
}

class _BaseOnboardingScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;
  final Widget child;

  const _BaseOnboardingScreen({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          child,
          const Spacer(),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: onPressed,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  buttonText.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _FakeDemoWidget extends StatefulWidget {
  @override
  State<_FakeDemoWidget> createState() => _FakeDemoWidgetState();
}

class _FakeDemoWidgetState extends State<_FakeDemoWidget> with SingleTickerProviderStateMixin {
  int _step = 0; // 0: Input, 1: Loading, 2: Result

  @override
  void initState() {
    super.initState();
    _playDemo();
  }

  void _playDemo() async {
    while (mounted) {
      setState(() => _step = 0);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() => _step = 1);
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      setState(() => _step = 2);
      await Future.delayed(const Duration(seconds: 4));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _buildStepContent(),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_step == 0) {
      return Column(
        key: const ValueKey('step0'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadge('UTILISATEUR', Colors.white38),
          const SizedBox(height: 12),
          Text(
            'Créer une vidéo pour vendre du miel artisanal...',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else if (_step == 1) {
      return Center(
        key: const ValueKey('step1'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 20),
            Text('Génération par l\'IA...', style: GoogleFonts.plusJakartaSans(color: AppColors.primary)),
          ],
        ),
      );
    } else {
      return Column(
        key: const ValueKey('step2'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadge('RÉSULTAT IA', AppColors.primary),
          const SizedBox(height: 12),
          Text(
            '\"Imaginez l\'or liquide coulant lentement... Le miel pur de nos montagnes...\"',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15, fontStyle: FontStyle.italic),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text('Script optimisé pour TikTok', style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 11)),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: GoogleFonts.spaceGrotesk(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
