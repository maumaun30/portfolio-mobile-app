import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/tokens.dart';
import '../../widgets/screen_scaffold.dart';
import '../../widgets/section_label.dart';

class SectionEntry {
  const SectionEntry({
    required this.id,
    required this.label,
    required this.sub,
    required this.icon,
  });
  final String id;
  final String label;
  final String sub;
  final IconData icon;
}

const sectionEntries = <SectionEntry>[
  SectionEntry(
    id: 'hero',
    label: 'Hero',
    sub: '— ABOVE THE FOLD',
    icon: LucideIcons.star,
  ),
  SectionEntry(
    id: 'colB',
    label: 'Column B',
    sub: '— LEFT-RAIL META',
    icon: LucideIcons.layout,
  ),
  SectionEntry(
    id: 'about',
    label: 'About',
    sub: '— BIO + CONTACT',
    icon: LucideIcons.user,
  ),
  SectionEntry(
    id: 'cta',
    label: 'CTA',
    sub: '— CONTACT BLOCK',
    icon: LucideIcons.send,
  ),
  SectionEntry(
    id: 'nav',
    label: 'Nav',
    sub: '— TOP MENU',
    icon: LucideIcons.menu,
  ),
  SectionEntry(
    id: 'footer',
    label: 'Footer',
    sub: '— BOTTOM LINKS',
    icon: LucideIcons.globe,
  ),
];

class SectionsListScreen extends StatelessWidget {
  const SectionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Page sections',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppTokens.gutter, 18, AppTokens.gutter, 24),
        children: [
          const SectionLabel('Editable · 6 blocks'),
          const SizedBox(height: 8),
          Text(
            'Per-section jsonb payloads. The server validates each save with Zod, so any error you see is a real schema mismatch.',
            style: TextStyle(
              fontSize: 13,
              color: AppTokens.inkDim,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          ...sectionEntries.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(AppTokens.cardRadius),
                onTap: () => context.push('/sections/${s.id}'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTokens.surface,
                    borderRadius:
                        BorderRadius.circular(AppTokens.cardRadius),
                    border: Border.all(color: AppTokens.line),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTokens.surfaceHi,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTokens.line),
                        ),
                        child:
                            Icon(s.icon, size: 16, color: AppTokens.accent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  s.label,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppTokens.ink,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '· ${s.id}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    letterSpacing: 0.04 * 10,
                                    color: AppTokens.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              s.sub,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.5,
                                letterSpacing: 0.04 * 10.5,
                                color: AppTokens.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight,
                          size: 16, color: AppTokens.inkMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
