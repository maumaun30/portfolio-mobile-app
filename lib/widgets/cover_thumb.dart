import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';

/// Square cover thumbnail. Renders an image if provided, otherwise a
/// deterministic tonal placeholder with the initial letter — matches the
/// design's CoverThumb component.
class CoverThumb extends StatelessWidget {
  const CoverThumb({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    this.size = 48,
    this.radius = 8,
  });

  final String? imageUrl;
  final String fallbackText;
  final double size;
  final double radius;

  static const _palettes = <List<Color>>[
    [Color(0xFF5E3424), Color(0xFF2A1812)], // rust
    [Color(0xFF1F3550), Color(0xFF0F1B2A)], // cobalt
    [Color(0xFF2F4730), Color(0xFF152018)], // moss
    [Color(0xFF50492A), Color(0xFF1E1B0F)], // olive
    [Color(0xFF4A2A47), Color(0xFF1E0E1C)], // plum
    [Color(0xFF6B5436), Color(0xFF2A2114)], // sand
  ];

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
          loadingBuilder: (ctx, child, prog) =>
              prog == null ? child : _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final initial = fallbackText.isEmpty
        ? '?'
        : fallbackText.trim().substring(0, 1).toUpperCase();
    final idx = initial.codeUnitAt(0) % _palettes.length;
    final palette = _palettes[idx];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.4),
          radius: 0.9,
          colors: palette,
        ),
        border: Border.all(color: AppTokens.line),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w600,
          color: AppTokens.ink.withOpacity(0.85),
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
