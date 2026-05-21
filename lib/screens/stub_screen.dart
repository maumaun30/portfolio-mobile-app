import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/tokens.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/section_label.dart';

/// Placeholder for screens that haven't been implemented in this pass.
/// Keeps the drawer routes wired so the navigation shell is testable.
class StubScreen extends StatelessWidget {
  const StubScreen({
    super.key,
    required this.title,
    required this.label,
    required this.icon,
  });

  final String title;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: title,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTokens.accent10,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTokens.accent, size: 22),
              ),
              const SizedBox(height: 16),
              const SectionLabel('Coming next'),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This screen is part of the design but hasn’t been built yet. The nav shell, theme, and auth are in place.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppTokens.inkDim,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience factories for each route — keeps `router.dart` tidy.
class Stubs {
  static const projects = StubScreen(
      title: 'Projects',
      label: 'Projects list & editor',
      icon: LucideIcons.folderKanban);
  static const skills = StubScreen(
      title: 'Skills', label: 'Skills catalog', icon: LucideIcons.sparkles);
  static const posts = StubScreen(
      title: 'Posts', label: 'Posts & case studies', icon: LucideIcons.fileText);
  static const keywords = StubScreen(
      title: 'Keywords',
      label: 'Auto-blog keywords',
      icon: LucideIcons.tag);
  static const sections = StubScreen(
      title: 'Sections',
      label: 'Page sections editor',
      icon: LucideIcons.layoutTemplate);
  static const notifications = StubScreen(
      title: 'Notifications',
      label: 'Activity log',
      icon: LucideIcons.bell);
  static const search = StubScreen(
      title: 'Search',
      label: 'Search across content',
      icon: LucideIcons.search);
  static const settings = StubScreen(
      title: 'Settings',
      label: 'Preferences & sign out',
      icon: LucideIcons.settings);
}
