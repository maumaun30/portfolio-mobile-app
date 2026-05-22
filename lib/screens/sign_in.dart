import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../auth/auth_provider.dart';
import '../theme/tokens.dart';
import '../widgets/section_label.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final loading = auth.isLoading;
    final error = auth.hasError ? auth.error.toString() : null;

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTokens.accent, width: 1.4),
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTokens.accent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Center(child: SectionLabel('Sign in')),
              const SizedBox(height: 10),
              Text(
                'Portfolio CMS',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: AppTokens.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Admin access via GitHub OAuth.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: AppTokens.inkDim),
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: loading
                    ? null
                    : () => ref.read(authControllerProvider.notifier).signIn(),
                icon: const Icon(LucideIcons.logIn, size: 18),
                label: Text(loading ? 'Authorizing…' : 'Continue with GitHub'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: loading
                    ? null
                    : () => ref.read(authControllerProvider.notifier).devSignIn(),
                child: const Text('Dev: skip auth'),
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTokens.danger10,
                    borderRadius: BorderRadius.circular(AppTokens.inputRadius),
                    border: Border.all(
                      color: AppTokens.danger.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(
                      color: AppTokens.danger,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
