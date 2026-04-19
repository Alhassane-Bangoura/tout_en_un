import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tout_en_un/core/theme/app_colors.dart';
import 'package:tout_en_un/core/supabase/supabase_service.dart';
import 'package:tout_en_un/features/business_idea/data/models/business_idea_models.dart';
import 'package:tout_en_un/features/tiktok_generator/presentation/widgets/generator_widgets.dart';
import 'package:tout_en_un/core/widgets/app_loading_page.dart';

class BusinessIdeaWizard extends StatefulWidget {
  const BusinessIdeaWizard({super.key});

  @override
  State<BusinessIdeaWizard> createState() => _BusinessIdeaWizardState();
}

class _BusinessIdeaWizardState extends State<BusinessIdeaWizard> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;
  BusinessIdeaModel? _generatedIdea;

  final TextEditingController _budgetController = TextEditingController();
  final List<String> _guineaCities = ['Conakry', 'N\'Zérékoré', 'Kankan', 'Kindia', 'Labé', 'Boké', 'Guéckédou', 'Macenta', 'Mamou', 'Fria', 'Autre (à préciser)'];
  String _selectedCity = 'Conakry';
  String _selectedNiche = 'Commerce';

  Future<void> _generate() async {
    if (_budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre budget')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = BusinessIdeaRequestModel(
        budget: _budgetController.text,
        city: _selectedCity,
        niche: _selectedNiche,
      );
      
      final idea = await _supabaseService.generateBusinessIdea(request);
      
      if (mounted) {
        setState(() {
          _generatedIdea = idea;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 8)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppLoadingPage(
        onComplete: () {},
        icon: Icons.lightbulb_rounded,
        title: 'Recherche d\'idées...',
        subtitle: 'Nos algorithmes analysent votre zone et votre budget...',
        statusMessages: [
          'Analyse du budget...',
          'Étude de marché...',
          'Calcul du profit...',
          'Génération du plan...',
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
        title: Text('BUSINESS IDEAS AI', style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trouve ton\nprochain business', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, height: 1.1)),
            const SizedBox(height: 40),
            GeneratorTextField(label: '01. Ton Budget (Gnf/Cfa)', hint: 'Ex: 500.000 GNF', example: 'Ex: Petit budget, 1 Million, etc.', controller: _budgetController),
            const SizedBox(height: 32),
            _buildCitySelector(),
            const SizedBox(height: 32),
            _buildNicheSelector(),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _generate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text('GÉNÉRER MON IDÉE', style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('02. TA VILLE / ZONE', style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2.0)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCity,
              isExpanded: true,
              dropdownColor: AppColors.surfaceContainerHighest,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16),
              items: _guineaCities.map((city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCity = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNicheSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('03. SECTEUR D\'ACTIVITÉ', style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2.0)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Commerce', 'Services', 'Agriculture', 'Digital'].map((niche) {
            bool isSelected = _selectedNiche == niche;
            return InkWell(
              onTap: () => setState(() => _selectedNiche = niche),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(niche, style: GoogleFonts.plusJakartaSans(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultPage() {
    final idea = _generatedIdea!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _generatedIdea = null))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(idea.title.toUpperCase(), style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 12),
                   Text(idea.description, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(Icons.trending_up, 'Profit Estimé', AppColors.secondary),
            Text(idea.estimatedProfit, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            _buildSectionTitle(Icons.list_alt, 'Étapes de lancement', AppColors.primary),
            ...idea.steps.map((s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('• $s', style: GoogleFonts.plusJakartaSans(color: Colors.white70)))),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _buildProsCons('Points Forts', idea.pros, Colors.greenAccent)),
                const SizedBox(width: 16),
                Expanded(child: _buildProsCons('Défis', idea.cons, Colors.orangeAccent)),
              ],
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _generatedIdea = null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerHighest,
                      minimumSize: const Size(0, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text('RETOUR', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _showChatModal(context, idea),
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 20),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(0, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    label: Text('ÉCHANGER AVEC L\'IA', style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showChatModal(BuildContext context, BusinessIdeaModel idea) {
    List<Map<String, String>> chatMessages = [
      {'role': 'ai', 'content': 'Salut ! C\'est un excellent choix d\'idée de business. De quoi aimerais-tu parler ? (As-tu des questions sur le budget, les fournisseurs, ou la stratégie ?)'}
    ];
    final TextEditingController chatController = TextEditingController();
    bool isChatLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            
            Future<void> sendMessage() async {
              final text = chatController.text.trim();
              if (text.isEmpty) return;
              
              setModalState(() {
                chatMessages.add({'role': 'user', 'content': text});
                isChatLoading = true;
              });
              chatController.clear();

              try {
                final replyText = await _supabaseService.chatAboutBusinessIdea(
                  businessTitle: idea.title,
                  businessContext: idea.description,
                  question: text,
                );
                
                setModalState(() {
                  chatMessages.add({'role': 'ai', 'content': replyText});
                  isChatLoading = false;
                });
              } catch (e) {
                setModalState(() {
                  chatMessages.add({'role': 'ai', 'content': 'Désolé, une erreur est survenue : \$e'});
                  isChatLoading = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom, left: 16, right: 16, top: 24),
              child: SizedBox(
                height: MediaQuery.of(modalContext).size.height * 0.75,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Coach Business IA', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(modalContext)),
                      ],
                    ),
                    const Divider(color: Colors.white24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: chatMessages.length,
                        itemBuilder: (context, index) {
                          final msg = chatMessages[index];
                          final isUser = msg['role'] == 'user';
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(16),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(modalContext).size.width * 0.8),
                              decoration: BoxDecoration(
                                color: isUser ? AppColors.surfaceContainerHighest : AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                                  bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
                                ),
                                border: isUser ? null : Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Text(msg['content'] ?? '', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                            ),
                          );
                        },
                      ),
                    ),
                    if (isChatLoading)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Align(alignment: Alignment.centerLeft, child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: chatController,
                            style: GoogleFonts.plusJakartaSans(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Pose ta question ici...',
                              hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white54),
                              filled: true,
                              fillColor: AppColors.surfaceContainerHighest,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            onSubmitted: (_) => sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: AppColors.primary,
                          radius: 24,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.black),
                            onPressed: sendMessage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(IconData icon, String title, Color color) {
    return Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title.toUpperCase(), style: GoogleFonts.plusJakartaSans(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5))]);
  }

  Widget _buildProsCons(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...items.map((i) => Text('• $i', style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 12))),
      ],
    );
  }
}
