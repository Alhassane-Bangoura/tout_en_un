import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/pages/auth_page.dart';

class PreSignupScreen extends StatefulWidget {
  const PreSignupScreen({super.key});

  @override
  State<PreSignupScreen> createState() => _PreSignupScreenState();
}

class _PreSignupScreenState extends State<PreSignupScreen> {
  final TextEditingController _controller = TextEditingController();

  void _generateNow() {
    if (_controller.text.trim().isEmpty) return;
    
    // Redirection vers AuthPage avec le message du "Paywall Psychologique"
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const AuthPage(
          showGateMessage: 'Crée ton compte pour voir le résultat',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: _Glow(color: AppColors.primary)),
          
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 40),
                          const SizedBox(height: 24),
                          Text(
                            'Que veux-tu créer ?',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Idée, business, produit...',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white38,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 48),
                          TextField(
                            controller: _controller,
                            autofocus: true,
                            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 20),
                            decoration: InputDecoration(
                              hintText: 'Ex: Un restaurant de sushis à Kankan',
                              hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white10),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.all(24),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          GestureDetector(
                            onTap: _generateNow,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  'GÉNÉRER MAINTENANT',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  const _Glow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.05)),
    );
  }
}
