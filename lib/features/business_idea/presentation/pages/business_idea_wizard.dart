import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aibusiness/core/theme/app_colors.dart';
import 'package:aibusiness/core/supabase/supabase_service.dart';
import 'package:aibusiness/features/home/data/models/activity_model.dart';
import 'package:aibusiness/features/business_idea/data/models/business_idea_models.dart';
import 'package:aibusiness/features/business_idea/presentation/widgets/business_chat_widget.dart';
import 'package:aibusiness/core/widgets/app_loading_page.dart';

// Liste complète des villes et zones de Guinée
const List<String> _guineaCities = [
  'Conakry',
  'Kindia',
  'Boké',
  'Labé',
  'Mamou',
  'Faranah',
  'Kankan',
  'N\'Zérékoré',
  'Guéckédou',
  'Macenta',
  'Kissidougou',
  'Siguiri',
  'Kouroussa',
  'Dinguiraye',
  'Télimélé',
  'Fria',
  'Coyah',
  'Dubréka',
  'Forécariah',
  'Boffa',
  'Koundara',
  'Gaoual',
  'Lélouma',
  'Pita',
  'Mali',
  'Dalaba',
  'Tougué',
  'Dabola',
  'Kérouané',
  'Mandiana',
  'Beyla',
  'Lola',
  'Yomou',
  'Zone Rurale',
];

const List<String> _niches = [
  'Commerce',
  'Services',
  'Agriculture',
  'Digital',
  'Restauration',
  'Élevage',
  'Transport',
  'Artisanat',
  'Santé',
  'Éducation',
];

class BusinessIdeaWizard extends StatefulWidget {
  const BusinessIdeaWizard({super.key});

  @override
  State<BusinessIdeaWizard> createState() => _BusinessIdeaWizardState();
}

class _BusinessIdeaWizardState extends State<BusinessIdeaWizard> with TickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;
  BusinessIdeaModel? _generatedIdea;
  ActivityModel? _latestActivity; // Stockage de l'activité pour le chat
  bool _showChat = false;

  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _ideaController = TextEditingController();
  String _selectedCity = 'Conakry';
  String _selectedNiche = 'Commerce';

  late AnimationController _fadeAnimController;
  late Animation<double> _fadeAnim;
  late AnimationController _scaleAnimController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _fadeAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeAnimController, curve: Curves.easeIn);
    _scaleAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _scaleAnimController, curve: Curves.elasticOut);
  }

  Future<void> _generate() async {
    if (_budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez entrer votre budget', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = BusinessIdeaRequestModel(
        budget: _budgetController.text,
        city: _selectedCity,
        niche: _selectedNiche,
        businessIdea: _ideaController.text.isEmpty ? null : _ideaController.text,
      );

      final result = await _supabaseService.generateBusinessIdea(request);

      if (mounted) {
        setState(() {
          _generatedIdea = result?['idea'] as BusinessIdeaModel?;
          _latestActivity = result?['activity'] as ActivityModel?;
          _isLoading = false;
          _showChat = false;
        });
        _fadeAnimController.forward(from: 0);
        _scaleAnimController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _generatedIdea = null;
      _latestActivity = null;
      _showChat = false;
    });
    _fadeAnimController.reset();
    _scaleAnimController.reset();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppLoadingPage(
        onComplete: () {},
        icon: Icons.lightbulb_rounded,
        title: 'Recherche d\'idées...',
        subtitle: 'Analyse de $_selectedCity et de votre budget...',
        statusMessages: [
          'Analyse du marché de $_selectedCity...',
          'Étude du secteur $_selectedNiche...',
          'Calcul du potentiel de profit...',
          'Génération du plan business...',
        ],
      );
    }

    if (_generatedIdea != null) return _buildResultPage();

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
          'BUSINESS IDEAS AI',
          style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trouve ton\nprochain business',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adapté à ta ville et à ton budget',
              style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 36),

            // Budget
            _buildSectionLabel('01. MON BUDGET (GNF/CFA)'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _budgetController,
              hint: 'Ex: 500.000 GNF, 1 Million...',
              icon: Icons.account_balance_wallet_rounded,
            ),
            const SizedBox(height: 28),

            // Ville dropdown
            _buildSectionLabel('02. MA VILLE EN GUINÉE'),
            const SizedBox(height: 12),
            _buildCityDropdown(),
            const SizedBox(height: 28),

            // Secteur d'activité
            _buildSectionLabel('03. SECTEUR D\'ACTIVITÉ'),
            const SizedBox(height: 12),
            _buildNicheSelector(),
            const SizedBox(height: 28),

            // Idée de départ (optionnel)
            _buildSectionLabel('04. MON IDÉE DE DÉPART (Optionnel)'),
            const SizedBox(height: 8),
            Text(
              'Décris ce que tu veux faire, l\'IA l\'améliorera pour toi',
              style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _ideaController,
              hint: 'Ex: Je veux ouvrir une boutique de vêtements...',
              icon: Icons.tips_and_updates_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 40),

            // Bouton générer
            _buildGenerateButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        color: AppColors.primary,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCity,
          dropdownColor: const Color(0xFF1A1A1A),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          isExpanded: true,
          items: _guineaCities.map((city) => DropdownMenuItem(
            value: city,
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(city, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14)),
              ],
            ),
          )).toList(),
          onChanged: (val) => setState(() => _selectedCity = val!),
        ),
      ),
    );
  }

  Widget _buildNicheSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _niches.map((niche) {
        bool isSelected = _selectedNiche == niche;
        return InkWell(
          onTap: () => setState(() => _selectedNiche = niche),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.white12,
              ),
            ),
            child: Text(
              niche,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(colors: [AppColors.primary, const Color(0xFF00C896)]),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: _generate,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            Text('GÉNÉRER MON IDÉE', style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // ========================
  // PAGE RÉSULTAT
  // ========================
  Widget _buildResultPage() {
    final idea = _generatedIdea!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _resetForm,
        ),
        title: Text('Ton Idée Business', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_rounded, color: _showChat ? AppColors.primary : Colors.white54),
            onPressed: () => setState(() => _showChat = !_showChat),
            tooltip: 'Chat avec l\'IA',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Score de viabilité
                    _buildViabilityScore(),
                    const SizedBox(height: 24),

                    // Titre + Description
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary.withOpacity(0.15), Colors.transparent],
                            begin: Alignment.topLeft,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('💡', style: TextStyle(fontSize: 24)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    idea.title.toUpperCase(),
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppColors.primary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              idea.description,
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Profit estimé
                    _buildProfitSection(idea.estimatedProfit),
                    const SizedBox(height: 28),

                    // MessageMotivant
                    _buildMotivationBanner(),
                    const SizedBox(height: 28),

                    // NOUVEAU: L'avantage IA
                    if (idea.aiConclusion.isNotEmpty) ...[
                      _buildAiAdvantage(idea.aiConclusion),
                      const SizedBox(height: 28),
                    ],

                    // Étapes
                    _buildStepsSection(idea.steps),
                    const SizedBox(height: 28),

                    // Points forts & Défis
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildProsCons('💪 Points Forts', idea.pros, Colors.greenAccent)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildProsCons('⚠️ Défis', idea.cons, Colors.orangeAccent)),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Bouton Chat
                    _buildChatCTA(),
                    const SizedBox(height: 16),

                    // Bouton Nouvelle Idée
                    OutlinedButton(
                      onPressed: _resetForm,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: Text('NOUVELLE IDÉE', style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Chat panel (affiché en bas si ouvert)
          if (_showChat && _latestActivity != null) 
            BusinessChatWidget(
              activity: _latestActivity!,
              onClose: () => setState(() => _showChat = false),
            ),
        ],
      ),
    );
  }

  Widget _buildViabilityScore() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Idée générée pour $_selectedCity', style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12)),
                Text('Secteur : $_selectedNiche • Budget : ${_budgetController.text}', style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
            ),
            child: Text('✅ Viable', style: GoogleFonts.plusJakartaSans(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitSection(String profit) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00C896).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00C896).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Text('📈', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PROFIT ESTIMÉ', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF00C896), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(profit, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF6C3EF5).withOpacity(0.2), const Color(0xFFE91E8C).withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🚀', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Chaque grand empire commence par une première étape ! Tu as tout pour réussir à $_selectedCity.',
              style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsSection(List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('🗺️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text('ÉTAPES DE LANCEMENT', style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), shape: BoxShape.circle),
                  child: Center(child: Text('${i + 1}', style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(step, style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProsCons(String title, List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          ...items.map((i) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('• $i', style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 12, height: 1.4)),
          )),
        ],
      ),
    );
  }

  Widget _buildChatCTA() {
    return GestureDetector(
      onTap: () => setState(() => _showChat = !_showChat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _showChat
                ? [AppColors.primary.withOpacity(0.3), AppColors.primary.withOpacity(0.1)]
                : [const Color(0xFF1A1A1A), const Color(0xFF252525)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _showChat ? AppColors.primary.withOpacity(0.5) : Colors.white12),
        ),
        child: Row(
          children: [
            Icon(Icons.psychology_rounded, color: _showChat ? AppColors.primary : Colors.white38, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Continuer avec le Conseiller IA', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Posez vos questions, obtenez une stratégie', style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Icon(_showChat ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAdvantage(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'L\'AVANTAGE DÉLOYAL IA',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _ideaController.dispose();
    _fadeAnimController.dispose();
    _scaleAnimController.dispose();
    super.dispose();
  }
}
