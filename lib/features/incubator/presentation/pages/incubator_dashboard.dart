import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/supabase/supabase_service.dart';

class IncubatorDashboard extends StatefulWidget {
  final String? initialProjectId;
  const IncubatorDashboard({super.key, this.initialProjectId});

  @override
  State<IncubatorDashboard> createState() => _IncubatorDashboardState();
}

class _IncubatorDashboardState extends State<IncubatorDashboard> with SingleTickerProviderStateMixin {
  final Color neonGreen = const Color(0xFF00FFA3);
  final Color darkSlate = const Color(0xFF0D0D0D); // Un noir très profond
  
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  String? projectId;
  String projectName = "Chargement...";
  double progressPercent = 0.0; 
  int currentWeek = 1;
  String psychologicalAdvice = "Votre mentor IA analyse votre projet...";
  String? mentorResponse;
  List<Map<String, dynamic>> tasks = [];
  bool _isReviewing = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadData();
  }

  Future<void> _loadData() async {
    Map<String, dynamic>? project;
    
    if (widget.initialProjectId != null) {
      project = await _supabaseService.getProjectById(widget.initialProjectId!);
    } else {
      project = await _supabaseService.getActiveIncubatorProject();
    }

    if (project != null) {
      final pId = project['id'];
      final loadedTasks = await _supabaseService.getIncubatorTasks(pId);
      final latestReport = await _supabaseService.getLatestMentorReport(pId);
      
      double totalWeight = loadedTasks.length.toDouble();
      double currentWeight = 0;
      for (var t in loadedTasks) {
        if (t['status'] == 'completed') currentWeight += 1.0;
        else if (t['status'] == 'in_progress') currentWeight += 0.5;
      }
      if (mounted) {
        setState(() {
          projectId = pId;
          projectName = project?['title'] ?? "Projet Actif";
          psychologicalAdvice = project?['psychological_profile']?['advice'] ?? "Plan d'action initial en cours.";
          mentorResponse = latestReport?['mentor_response'];
          tasks = loadedTasks;
          double currentWeight = 0;
          for (var t in loadedTasks) {
            if (t['status'] == 'completed') currentWeight += 1.0;
          }
          progressPercent = loadedTasks.isEmpty ? 0.0 : (currentWeight / loadedTasks.length);
          currentWeek = loadedTasks.isNotEmpty ? (loadedTasks.last['week_number'] ?? 1) : 1;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          projectName = "Aucun Projet Actif";
          psychologicalAdvice = "Générez ou sélectionnez une idée dans vos projets pour l'envoyer dans l'Incubateur.";
          tasks = [];
          progressPercent = 0.0;
          currentWeek = 1;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkSlate,
      body: Stack(
        children: [
          // Background Gradient très robuste (Sans BlurFilter qui plante sur Linux Native)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.8, -0.8),
                radius: 1.5,
                colors: [
                  neonGreen.withOpacity(0.08),
                  darkSlate,
                  darkSlate,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF00FFA3))),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildMentorPremiumCard(),
                      const SizedBox(height: 48),
                      _buildSectionTitle("VOS FOCUS DE LA SEMAINE", "SEMAINE $currentWeek"),
                      const SizedBox(height: 24),
                      if (tasks.isEmpty)
                        Text(
                          "Aucune tâche pour l'instant. Votre mentor prépare la charge de travail.",
                          style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontStyle: FontStyle.italic),
                        )
                      else
                        ...tasks.map((task) => _buildTaskCardSafe(task)).toList(),
                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
            ],
          ),
          
          // FAB
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: _buildCustomFAB(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 340.0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      stretch: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 20),
        title: Text(
          'Mission Control',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 2.0,
            shadows: [Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 10)]
          ),
        ),
        background: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progressPercent),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(180, 180),
                              painter: SolidProgressPainter(
                                progress: value,
                                color: neonGreen,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "INCUBATION",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: neonGreen.withOpacity(0.9),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "${(value * 100).toInt()}%",
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 46,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  projectName,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            color: neonGreen,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 1.0,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: neonGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: neonGreen.withOpacity(0.3)),
          ),
          child: Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              color: neonGreen,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMentorPremiumCard() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFF161618), // Gris foncé très propre
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: neonGreen.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: neonGreen.withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: neonGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: neonGreen.withOpacity(0.8 * _pulseController.value),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    ),
                  );
                }
              ),
              const SizedBox(width: 14),
              Text(
                "Analyse du Mentor IA",
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Icon(Icons.format_quote_rounded, color: neonGreen.withOpacity(0.3), size: 32),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            mentorResponse ?? psychologicalAdvice,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.85),
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCardSafe(Map<String, dynamic> task) {
    bool isCompleted = task['status'] == "completed";
    bool isInProgress = task['status'] == "in_progress";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (task['id'] == null) return;
            
            // 1. Calculer le nouvel état (Toggle Simple 2 états)
            String oldStatus = task['status'] ?? 'pending';
            String newStatus = oldStatus == 'completed' ? 'pending' : 'completed';

            // 2. Mise à jour LOCALE immédiate pour une UI fluide
            setState(() {
              task['status'] = newStatus;
              double totalW = tasks.length.toDouble();
              double currentW = 0;
              for (var t in tasks) {
                if (t['status'] == 'completed') currentW += 1.0;
              }
              progressPercent = totalW == 0 ? 0.0 : (currentW / totalW);
            });
            
            try {
              // 3. Sync avec la base de données
              await _supabaseService.updateTaskStatus(task['id'], newStatus);
            } catch (e) {
              // En cas d'erreur, revenir en arrière
              setState(() {
                task['status'] = oldStatus;
                // Re-calculer le pourcentage
                double totalW = tasks.length.toDouble();
                double currentW = 0;
                for (var t in tasks) {
                  if (t['status'] == 'completed') currentW += 1.0;
                }
                progressPercent = totalW == 0 ? 0.0 : (currentW / totalW);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Oups, erreur de synchro : $e"), backgroundColor: Colors.red),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          highlightColor: neonGreen.withOpacity(0.05),
          splashColor: neonGreen.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
               // Un gris solide pour être visible, pas transparent.
              color: isCompleted ? const Color(0xFF121212) : const Color(0xFF1E1E22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCompleted 
                    ? Colors.white.withOpacity(0.05) 
                    : (isInProgress ? neonGreen.withOpacity(0.7) : Colors.white.withOpacity(0.1)),
                width: isInProgress ? 2.0 : 1.5,
              ),
              boxShadow: isInProgress ? [
                BoxShadow(color: neonGreen.withOpacity(0.1), blurRadius: 15, spreadRadius: 1)
              ] : [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted ? neonGreen : (isInProgress ? neonGreen : Colors.white54),
                      width: 2,
                    ),
                    color: isCompleted ? neonGreen : Colors.transparent,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Color(0xFF0D0D0D), size: 16, weight: 900)
                      : (isInProgress
                          ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: neonGreen, shape: BoxShape.circle)))
                          : null),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'],
                        style: GoogleFonts.plusJakartaSans(
                          color: isCompleted ? Colors.white38 : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task['description'],
                        style: GoogleFonts.plusJakartaSans(
                          color: isCompleted ? Colors.white24 : Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomFAB() {
    bool allCompleted = tasks.isNotEmpty && tasks.every((t) => t['status'] == 'completed');
    bool isScaleUp = currentWeek >= 4 && allCompleted;

    return GestureDetector(
      onTap: () {
        if (projectId == null) return;
        if (!allCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("🚀 Mentor : Terminez vos focus (cochez-les) pour débloquer le bilan !", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.orangeAccent,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(20),
            ),
          );
          return;
        }
        _showWeeklyReportDialog();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          color: _isReviewing ? Colors.white24 : (allCompleted ? neonGreen : Colors.white10),
          boxShadow: allCompleted ? [
            BoxShadow(
              color: neonGreen.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isReviewing 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(isScaleUp ? Icons.auto_awesome_rounded : Icons.send_rounded, color: allCompleted ? const Color(0xFF0D0D0D) : Colors.white38, size: 26),
            const SizedBox(width: 12),
            Text(
              _isReviewing 
                  ? "ANALYSE EN COURS..." 
                  : (isScaleUp ? "PASSER AU SCALE-UP PRO" : "FAIRE MON COMPTE RENDU"),
              style: GoogleFonts.plusJakartaSans(
                color: allCompleted ? const Color(0xFF0D0D0D) : Colors.white38,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWeeklyReportDialog() {
    final TextEditingController reportController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: neonGreen.withOpacity(0.3))),
        title: Text(
          "BILAN SEMAINE $currentWeek",
          style: GoogleFonts.spaceGrotesk(color: neonGreen, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dites à votre mentor comment s'est passée votre semaine. Quels ont été vos succès ? Vos blocages ?",
              style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: reportController,
              maxLines: 4,
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Ex: J'ai réussi à contacter 3 clients, mais j'ai peur de relancer...",
                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 13),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ANNULER", style: GoogleFonts.plusJakartaSans(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reportController.text.trim().isEmpty) return;
              Navigator.pop(context);
              _submitReport(reportController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: neonGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("ENVOYER AU MENTOR", style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(String feedback) async {
    if (projectId == null) return;
    
    setState(() => _isReviewing = true);
    
    try {
      await _supabaseService.submitWeeklyReview(
        projectId: projectId!,
        userFeedback: feedback,
        currentWeek: currentWeek,
        previousTasks: tasks,
      );
      
      await _loadData();
      
      if (mounted) {
        setState(() => _isReviewing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Nouvelle stratégie reçue ! Semaine suivante débloquée.", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            backgroundColor: neonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isReviewing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}

/// Painter robuste pour l'anneau de progression (Compatible Linux/Desktop)
class SolidProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  SolidProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - 10;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress;
      
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Track arc
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweepAngle, false, progressPaint);
    
    // Dot à la fin
    final dotAngle = -math.pi / 2 + sweepAngle;
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);
    
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(dotX, dotY), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant SolidProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
