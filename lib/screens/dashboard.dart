import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../api/stats_api.dart';
import '../theme/tokens.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/section_label.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardStatsProvider);

    return ScreenScaffold(
      title: 'Dashboard',
      child: RefreshIndicator(
        color: AppTokens.accent,
        backgroundColor: AppTokens.surface,
        onRefresh: () => ref.refresh(dashboardStatsProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTokens.gutter,
            18,
            AppTokens.gutter,
            24,
          ),
          children: [
            const SectionLabel('Overview'),
            const SizedBox(height: 10),
            Text(
              'Studio',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.6,
                color: AppTokens.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              async.when(
                data: (s) =>
                    '${s.projects + s.posts + s.skills} entries across the portfolio',
                loading: () => 'Loading counts…',
                error: (_, __) => 'Counts unavailable — pull to retry',
              ),
              style: TextStyle(fontSize: 13, color: AppTokens.inkDim),
            ),
            const SizedBox(height: 22),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StatTile(
                  label: 'Projects',
                  value: async.maybeWhen(
                      data: (s) => '${s.projects}', orElse: () => '—'),
                  loading: async.isLoading,
                ),
                _StatTile(
                  label: 'Skills',
                  value: async.maybeWhen(
                      data: (s) => '${s.skills}', orElse: () => '—'),
                  loading: async.isLoading,
                ),
                _StatTile(
                  label: 'Posts',
                  value: async.maybeWhen(
                      data: (s) => '${s.posts}', orElse: () => '—'),
                  loading: async.isLoading,
                ),
                _StatTile(
                  label: 'Keywords',
                  value: async.maybeWhen(
                      data: (s) => '${s.keywords}', orElse: () => '—'),
                  loading: async.isLoading,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionLabel('Quick actions'),
            const SizedBox(height: 10),
            _QuickAction(
              icon: LucideIcons.plus,
              title: 'New project',
              subtitle: 'Add a portfolio entry',
              onTap: () => context.push('/projects/new'),
            ),
            const SizedBox(height: 10),
            _QuickAction(
              icon: LucideIcons.fileText,
              title: 'New post',
              subtitle: 'Write a blog or case study',
              onTap: () => context.push('/posts/new'),
            ),
            const SizedBox(height: 10),
            _QuickAction(
              icon: LucideIcons.sparkles,
              title: 'Generate blog',
              subtitle: 'Run the auto-blog now',
              onTap: () => context.push('/keywords'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.loading,
  });
  final String label;
  final String value;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: AppTokens.line),
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              letterSpacing: 0.06 * 10.5,
              color: AppTokens.inkMuted,
            ),
          ),
          loading
              ? Container(
                  height: 28,
                  width: 60,
                  decoration: BoxDecoration(
                    color: AppTokens.surfaceHi,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.8,
                    color: AppTokens.ink,
                  ),
                ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          border: Border.all(color: AppTokens.line),
          borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTokens.accent10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTokens.accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTokens.inkDim,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 18, color: AppTokens.inkMuted),
          ],
        ),
      ),
    );
  }
}
