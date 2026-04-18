import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tout_en_un/core/theme/app_colors.dart';

class AppLoadingPage extends StatefulWidget {
  final VoidCallback onComplete;
  final List<String> statusMessages;
  final IconData icon;
  final String title;
  final String subtitle;

  const AppLoadingPage({
    super.key,
    required this.onComplete,
    required this.statusMessages,
    this.icon = Icons.bolt_rounded,
    this.title = 'Génération en cours...',
    this.subtitle = 'Nos algorithmes préparent le contenu parfait pour vous.',
  });

  @override
  State<AppLoadingPage> createState() => _AppLoadingPageState();
}

class _AppLoadingPageState extends State<AppLoadingPage> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  
  int _statusIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Status rotation timer
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          if (_statusIndex < widget.statusMessages.length - 1) {
            _statusIndex++;
          } else {
            timer.cancel();
            widget.onComplete();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading Indicator Section
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceContainerHighest, width: 6),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotationController,
                    child: const SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: 0.75,
                        strokeWidth: 6,
                        color: AppColors.primaryDim,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ),
                  ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.05).animate(
                      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                    ),
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                        ],
                      ),
                      child: Icon(widget.icon, color: AppColors.primary, size: 48),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 60),

            Text(
              widget.title,
              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1.0),
            ),
            
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   _PingDot(),
                  const SizedBox(width: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      widget.statusMessages[_statusIndex].toUpperCase(),
                      key: ValueKey(widget.statusMessages[_statusIndex]),
                      style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2.0),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.9), fontSize: 18, fontWeight: FontWeight.w600, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _PingDot extends StatefulWidget {
  @override
  State<_PingDot> createState() => _PingDotState();
}

class _PingDotState extends State<_PingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: _controller,
          child: Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.5), shape: BoxShape.circle)),
        ),
        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
      ],
    );
  }
}
