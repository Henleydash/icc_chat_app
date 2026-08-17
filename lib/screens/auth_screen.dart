import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets.dart';

/// Écran de connexion : un seul bouton "Se connecter avec Google". Firebase
/// Auth + Google gèrent la sécurité et l'unicité du compte ; l'app crée
/// simplement le profil Firestore correspondant au premier lancement.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  bool _loading = false;
  String? _error;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.signInWithGoogle();
      // La navigation vers l'app se fait automatiquement via le
      // StreamBuilder sur authStateChanges dans main.dart.
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Une erreur est survenue. Réessaie.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('{', style: GoogleFonts.jetBrainsMono(fontSize: 22, color: AppColors.orange)),
                    const SizedBox(width: 6),
                    Text('IN ', style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    Text('CRYPT ', style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.blue)),
                    Text('Chat', style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.orange)),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(gradient: kBrandGradient, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 22),
                Text(
                  'Bienvenue',
                  style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.navy),
                ),
                const SizedBox(height: 10),
                Text(
                  "Connecte-toi avec ton compte Google pour discuter avec ta promotion, rejoindre des groupes et suivre les publications.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 34),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _handleGoogleSignIn,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.blue),
                          )
                        : const _GoogleGlyph(),
                    label: Text(
                      _loading ? 'Connexion en cours...' : 'Continuer avec Google',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.navy),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.line, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                if (_error != null) FormNotice(text: _error!, isError: true),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF233066)),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          "Ton compte Google sert uniquement à te connecter en sécurité — ton nom et ta photo pourront être visibles par ta promotion.",
                          style: TextStyle(fontSize: 12, color: Color(0xFF233066), height: 1.5),
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
}

/// Petit logo "G" multicolore façon Google, pour ne dépendre d'aucun
/// paquet d'icônes tiers supplémentaire.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }
}
