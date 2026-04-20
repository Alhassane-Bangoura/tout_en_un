import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:aibusiness/core/theme/app_colors.dart';
import 'package:aibusiness/features/tiktok_generator/data/models/tiktok_models.dart';

class TiktokResultPage extends StatefulWidget {
  final TiktokScriptModel script;
  final VoidCallback onRegenerate;
  final VoidCallback onCreateAnother;

  const TiktokResultPage({
    super.key,
    required this.script,
    required this.onRegenerate,
    required this.onCreateAnother,
  });

  @override
  State<TiktokResultPage> createState() => _TiktokResultPageState();
}

class _TiktokResultPageState extends State<TiktokResultPage> {
  bool _showExportStructure = false;
  bool _justSaved = false;

  @override
  void initState() {
    super.initState();
    // Simulation du feedback de sauvegarde automatique demandée
    _triggerSaveFeedback();
  }

  void _triggerSaveFeedback() {
    setState(() => _justSaved = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _justSaved = false);
    });
  }

  void _copyToClipboard(BuildContext context) {
    final fullText = '''
🚀 HOOK (Accroche):
${widget.script.hook}

🎬 SCRIPT DÉTAILLÉ:
${widget.script.body.map((p) => "[${p.timestamp}] ${p.content}").join('\n')}

🎯 CALL TO ACTION:
${widget.script.cta}
''';
    Clipboard.setData(ClipboardData(text: fullText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
            const SizedBox(width: 12),
            Text(
              'Script copié ✅',
              style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TIKTOK GENERATOR',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              if (_justSaved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.save_rounded, color: Colors.greenAccent, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Sauvegardé ✅',
                        style: GoogleFonts.plusJakartaSans(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // --- DASHBOARD DE VIRALITÉ ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  Colors.transparent
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Row(
              children: [
                // Jauge de Score
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: widget.script.viralScore / 100,
                        strokeWidth: 8,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        color: AppColors.primary,
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 18)),
                            Text(
                              '${widget.script.viralScore}',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VIRALITÉ ESTIMÉE',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.script.viralReason.isNotEmpty 
                            ? widget.script.viralReason 
                            : 'L\'algorithme va adorer la structure de ce script et son accroche très dynamique.',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),


          // Action Buttons Top
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(context),
                  icon: const Icon(Icons.content_copy_rounded, size: 18),
                  label: const Text('COPIER LE SCRIPT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerHighest,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showExportStructure = !_showExportStructure),
                  icon: Icon(_showExportStructure ? Icons.close_rounded : Icons.ios_share_rounded, size: 18),
                  label: Text(_showExportStructure ? 'FERMER' : 'EXPORTER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),

          if (_showExportStructure) ...[
            const SizedBox(height: 24),
            _buildExportStructure(),
          ],
          
          const SizedBox(height: 40),

          // Bento Layout Sections
          _buildHookSection(),
          const SizedBox(height: 16),
          _buildBodySection(),
          const SizedBox(height: 16),
          _buildCtaSection(),
          
          const SizedBox(height: 48),

          // Tools Section
          Text(
            'OUTILS DE CRÉATION',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          _buildToolButtons(),

          const SizedBox(height: 48),

          // Option Logo
          _buildLogoOption(),

          const SizedBox(height: 48),

          // Instructions Section
          _buildInstructionsSection(),
          
          const SizedBox(height: 48),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onRegenerate,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text('Regénérer'.toUpperCase()),
                  style: _outlineButtonStyle(AppColors.secondary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onCreateAnother,
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

  Widget _buildExportStructure() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.movie_filter_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                '🎬 STRUCTURE VIDÉO PRÊTE',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSceneRow(1, 'Hook (Accroche)', widget.script.hook),
          _buildSceneDivider(),
          _buildSceneRow(2, 'Context / Problème', widget.script.body.isNotEmpty ? widget.script.body[0].content : ''),
          _buildSceneDivider(),
          _buildSceneRow(3, 'Solution / Démonstration', widget.script.body.length > 1 ? widget.script.body[1].content : ''),
          _buildSceneDivider(),
          _buildSceneRow(4, 'Call To Action', widget.script.cta),
          
          const SizedBox(height: 32),
          Text(
            'IMPORTER DANS VOTRE ÉDITEUR :',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.onSurfaceVariant,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniTool('CapCut', Icons.video_library_rounded),
              _buildMiniTool('Canva', Icons.auto_awesome_mosaic_rounded),
              _buildMiniTool('TikTok', Icons.music_note_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSceneRow(int num, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scene $num ($title):',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSceneDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 1,
      color: Colors.white.withOpacity(0.05),
    );
  }

  Widget _buildMiniTool(String name, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(name, style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildToolButtons() {
    return Row(
      children: [
        _buildToolAction('CapCut', Icons.video_call_rounded, const Color(0xFF00C4CC)),
        const SizedBox(width: 12),
        _buildToolAction('Canva', Icons.palette_rounded, const Color(0xFF00C4CC)),
        const SizedBox(width: 12),
        _buildToolAction('TikTok', Icons.play_circle_outline_rounded, Colors.white),
      ],
    );
  }

  Widget _buildToolAction(String name, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(name, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoOption() {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redirection vers le générateur de logo...'))
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.draw_rounded, color: AppColors.secondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Besoin d\'un logo ?',
                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Générer une identité visuelle pour ce business',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
          ],
        ),
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
            '"${widget.script.hook}"',
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
            children: widget.script.body.map((part) => Padding(
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
            '"${widget.script.cta}"',
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
        ...List.generate(widget.script.instructions.length, (index) => Padding(
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
                    widget.script.instructions[index],
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
