import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';

enum BadgeTone { published, draft, accent, danger }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final BoxBorder? border;
    switch (tone) {
      case BadgeTone.published:
      case BadgeTone.accent:
        bg = AppTokens.accent10;
        fg = AppTokens.accent;
        border = null;
        break;
      case BadgeTone.draft:
        bg = Colors.transparent;
        fg = AppTokens.inkDim;
        border = Border.all(color: AppTokens.line);
        break;
      case BadgeTone.danger:
        bg = AppTokens.danger10;
        fg = AppTokens.danger;
        border = null;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: border,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.06 * 10,
          color: fg,
        ),
      ),
    );
  }
}
