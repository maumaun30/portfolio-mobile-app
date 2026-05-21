import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/tokens.dart';

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({
    super.key,
    required this.title,
    required this.description,
    this.errorCode,
    this.onRetry,
  });

  final String title;
  final String description;
  final String? errorCode;
  final VoidCallback? onRetry;

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
                color: AppTokens.danger10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                color: AppTokens.danger,
                size: 28,
              ),
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
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw, size: 15),
                label: const Text('Try again'),
              ),
            ],
            if (errorCode != null) ...[
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTokens.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTokens.line),
                ),
                child: Text(
                  errorCode!,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    letterSpacing: 0.02 * 10.5,
                    color: AppTokens.inkMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
