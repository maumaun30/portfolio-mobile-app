import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    this.footnote,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTokens.lineStrong,
                  style: BorderStyle.solid,
                ),
              ),
              child: Icon(icon, color: AppTokens.inkMuted, size: 26),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: AppTokens.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppTokens.inkDim,
                height: 1.5,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
            if (footnote != null) ...[
              const SizedBox(height: 12),
              Text(
                footnote!.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  letterSpacing: 0.04 * 10.5,
                  color: AppTokens.inkMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
