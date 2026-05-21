import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';

/// Editorial "— LABEL" micro-caps in mono — used as a quiet headline above
/// most screen titles. Mirrors the web admin's SectionLabel component.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.prefix = '—'});

  final String text;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$prefix  ${text.toUpperCase()}',
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.06 * 10.5,
        color: AppTokens.inkMuted,
      ),
    );
  }
}
