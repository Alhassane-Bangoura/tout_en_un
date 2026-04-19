import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tout_en_un/core/theme/app_colors.dart';
import 'package:tout_en_un/core/supabase/supabase_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  File? _imageFile;
  final _supabaseService = SupabaseService();
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (_isLogin) {
        // Sign In
        try {
          await _supabaseService.signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
        } on AuthException catch (e) {
          if (e.message.contains('Email not confirmed')) {
            throw AuthException('Veuillez confirmer votre e-mail avant de vous connecter. Vérifiez votre boîte de réception.');
          }
          rethrow;
        }
      } else {
        // Sign Up
        if (_passwordController.text != _confirmPasswordController.text) {
          throw Exception('Les mots de passe ne correspondent pas');
        }

        await _supabaseService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _fullNameController.text.trim(),
        );
        
        // Upload avatar if selected
        if (_imageFile != null) {
          await _supabaseService.uploadAvatar(_imageFile!);
        }

        // Déconnexion forcée pour exiger une reconnexion manuelle
        await _supabaseService.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compte créé avec succès ! Veuillez vous connecter pour continuer.'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 4),
            ),
          );
          setState(() {
            _isLogin = true;
            _passwordController.clear();
            _confirmPasswordController.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Une erreur est survenue';
        
        if (e is AuthException) {
          errorMessage = e.message;
          if (errorMessage.contains('Invalid login credentials')) {
            errorMessage = 'Email ou mot de passe incorrect';
          } else if (errorMessage.contains('already registered') || 
                     errorMessage.contains('already exists') || 
                     errorMessage.contains('already in use')) {
            errorMessage = 'Cet email est déjà lié à un compte. Connectez-vous plutôt.';
          }
        } else {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: _Glow(color: AppColors.primary)),
          Positioned(bottom: -100, left: -100, child: _Glow(color: AppColors.secondary)),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(),
                    const SizedBox(height: 48),
                    if (!_isLogin) _buildAvatarPicker(),
                    const SizedBox(height: 32),
                    if (!_isLogin) ...[
                      _buildTextField(label: 'Nom Complet', controller: _fullNameController, icon: Icons.person_outline),
                      const SizedBox(height: 20),
                    ],
                    _buildTextField(label: 'Email', controller: _emailController, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Mot de passe', 
                      controller: _passwordController, 
                      icon: Icons.lock_outline, 
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ce champ est requis';
                        if (!_isLogin) {
                          if (value.length < 8) return 'Minimum 8 caractères';
                          if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Une majuscule requise';
                          if (!RegExp(r'[a-z]').hasMatch(value)) return 'Une minuscule requise';
                          if (!RegExp(r'[0-9]').hasMatch(value)) return 'Un chiffre requis';
                          if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) return 'Un caractère spécial requis';
                        }
                        return null;
                      },
                    ),
                    if (!_isLogin) ...[
                      const SizedBox(height: 20),
                      _buildTextField(
                        label: 'Confirmer mot de passe', 
                        controller: _confirmPasswordController, 
                        icon: Icons.lock_clock_outlined, 
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        validator: (value) {
                          if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 48),
                    _buildSubmitButton(),
                    const SizedBox(height: 24),
                    _buildToggleText(),
                  ],
                ),
              ),
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 32),
            const SizedBox(width: 8),
            Text(
              'AB BUSINESS AI',
              style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          _isLogin ? 'Bon retour parmi nous !' : 'Crée ton compte pro',
          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.1),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? 'Connecte-toi pour accéder à tes outils IA.' : 'Rejoins l\'élite du business en Afrique.',
          style: GoogleFonts.plusJakartaSans(color: AppColors.onSurfaceVariant, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildAvatarPicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : null,
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
            ),
            child: _imageFile == null ? const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 40) : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2.0)),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? obscureText : false,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
            suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                ) 
              : null,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            hintText: 'Entrer votre ${label.toLowerCase()}',
            hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.onSurfaceVariant.withOpacity(0.5), fontSize: 14),
          ),
          validator: validator ?? (value) => value == null || value.isEmpty ? 'Ce champ est requis' : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
        shadowColor: AppColors.primary.withOpacity(0.3),
      ),
      child: Text(
        _isLogin ? 'SE CONNECTER' : 'CRÉER MON COMPTE',
        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildToggleText() {
    return Center(
      child: TextButton(
        onPressed: () => setState(() => _isLogin = !_isLogin),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(color: AppColors.onSurfaceVariant, fontSize: 14),
            children: [
              TextSpan(text: _isLogin ? 'Pas encore de compte ? ' : 'Déjà un compte ? '),
              TextSpan(text: _isLogin ? 'Inscris-toi' : 'Connecte-toi', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
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
