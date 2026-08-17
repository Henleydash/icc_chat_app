import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'theme.dart';

/// Avatar circulaire : affiche la photo si disponible, sinon les initiales
/// sur un fond dégradé (dérivé de façon stable du texte fourni).
class AppAvatar extends StatelessWidget {
  final String label; // texte servant à générer les initiales/couleur
  final String? photoUrl;
  final double size;

  const AppAvatar({super.key, required this.label, this.photoUrl, this.size = 44});

  Color _colorFor(String s) {
    final hash = s.codeUnits.fold<int>(0, (a, b) => a + b);
    return AppColors.avatarPalette[hash % AppColors.avatarPalette.length];
  }

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (c, u) => _fallback(),
          errorWidget: (c, u, e) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: _colorFor(label), shape: BoxShape.circle),
      child: Text(
        _initials(label),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

/// Bandeau d'erreur / info réutilisable sur les formulaires.
class FormNotice extends StatelessWidget {
  final String text;
  final bool isError;
  const FormNotice({super.key, required this.text, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.blue;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 13, height: 1.4)),
    );
  }
}

/// Petit badge de nombre non lu, façon puce orange.
class UnreadDot extends StatelessWidget {
  final int count;
  const UnreadDot({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(100)),
      constraints: const BoxConstraints(minWidth: 20),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Indicateur de chargement plein écran, sobre et cohérent avec la charte.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2.6),
      );
}
