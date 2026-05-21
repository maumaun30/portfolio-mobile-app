import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';

/// Renders a simpleicons.org brand SVG (already raster-tinted to ink by
/// the CDN). Falls back to a mono initial badge if the icon 404s.
class SimpleIcon extends StatelessWidget {
  const SimpleIcon({
    super.key,
    required this.slug,
    required this.fallbackLabel,
    this.size = 36,
  });

  final String slug;
  final String fallbackLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: AppTokens.line),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          'https://cdn.simpleicons.org/$slug/efe6d4',
          width: size * 0.55,
          height: size * 0.55,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Text(
            fallbackLabel.isEmpty
                ? '?'
                : fallbackLabel.substring(0, 1).toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w600,
              color: AppTokens.ink,
              letterSpacing: -0.04 * size * 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
