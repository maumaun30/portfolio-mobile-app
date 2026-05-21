import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTokens.accent, width: 1.4),
              ),
              child: Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTokens.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Portfolio CMS',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTokens.ink,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
