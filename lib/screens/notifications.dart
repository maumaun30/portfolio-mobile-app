import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../api/activity_api.dart';
import '../models/activity.dart';
import '../theme/tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/section_label.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activityListProvider);

    return ScreenScaffold(
      title: 'Activity',
      child: async.when(
        loading: () => const _Loading(),
        error: (e, _) => ErrorPanel(
          title: "Couldn't load activity",
          description: e.toString(),
          onRetry: () => ref.invalidate(activityListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: LucideIcons.bell,
              title: 'Nothing yet',
              description:
                  'New posts, project edits, and auto-blog runs will appear here.',
            );
          }
          final grouped = _groupByBucket(items);
          return RefreshIndicator(
            color: AppTokens.accent,
            backgroundColor: AppTokens.surface,
            onRefresh: () => ref.refresh(activityListProvider.future),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: grouped.length,
              itemBuilder: (ctx, i) => _Group(
                label: grouped[i].label,
                items: grouped[i].items,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────── grouping

class _Bucket {
  _Bucket(this.label, this.items);
  final String label;
  final List<Activity> items;
}

List<_Bucket> _groupByBucket(List<Activity> entries) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final week = today.subtract(const Duration(days: 7));

  final t = <Activity>[];
  final y = <Activity>[];
  final w = <Activity>[];
  final older = <Activity>[];
  for (final e in entries) {
    final d = DateTime(e.at.year, e.at.month, e.at.day);
    if (d == today) {
      t.add(e);
    } else if (d == yesterday) {
      y.add(e);
    } else if (d.isAfter(week)) {
      w.add(e);
    } else {
      older.add(e);
    }
  }
  return [
    if (t.isNotEmpty) _Bucket('Today', t),
    if (y.isNotEmpty) _Bucket('Yesterday', y),
    if (w.isNotEmpty) _Bucket('This week', w),
    if (older.isNotEmpty) _Bucket('Earlier', older),
  ];
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.items});
  final String label;
  final List<Activity> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTokens.gutter, 14, AppTokens.gutter, 8),
          child: SectionLabel(label),
        ),
        ...List.generate(items.length, (i) {
          return Column(
            children: [
              _Row(activity: items[i]),
              if (i < items.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 64),
                  child: Divider(color: AppTokens.line, height: 1),
                ),
            ],
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────── row

class _Row extends StatelessWidget {
  const _Row({required this.activity});
  final Activity activity;

  ({IconData icon, Color tone}) _glyph() {
    switch (activity.kind) {
      case ActivityKind.postPublished:
        return (icon: LucideIcons.checkCircle2, tone: AppTokens.accent);
      case ActivityKind.postCreated:
        return (icon: LucideIcons.fileText, tone: AppTokens.inkDim);
      case ActivityKind.postUpdated:
        return (icon: LucideIcons.edit3, tone: AppTokens.inkDim);
      case ActivityKind.projectCreated:
        return (icon: LucideIcons.plus, tone: AppTokens.accent);
      case ActivityKind.projectUpdated:
        return (icon: LucideIcons.folderKanban, tone: AppTokens.inkDim);
      case ActivityKind.keywordGenerated:
        return (icon: LucideIcons.sparkles, tone: AppTokens.accent);
      case ActivityKind.unknown:
        return (icon: LucideIcons.activity, tone: AppTokens.inkDim);
    }
  }

  String get _time {
    final diff = DateTime.now().difference(activity.at);
    if (diff.inMinutes < 1) return 'JUST NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
    if (diff.inHours < 24) return '${diff.inHours}H AGO';
    if (diff.inDays == 1) return 'YESTERDAY';
    if (diff.inDays < 30) return '${diff.inDays}D AGO';
    return activity.at.toIso8601String().substring(0, 10).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final g = _glyph();
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.gutter, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: g.tone == AppTokens.accent
                  ? AppTokens.accent10
                  : AppTokens.surface,
              border: Border.all(color: AppTokens.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(g.icon, size: 16, color: g.tone),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.ink,
                    letterSpacing: -0.05,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _time,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
                        letterSpacing: 0.04 * 10.5,
                        color: AppTokens.inkMuted,
                      ),
                    ),
                    if (activity.sub.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '· ${activity.sub}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            letterSpacing: 0.04 * 10.5,
                            color: AppTokens.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── loading

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 18),
      separatorBuilder: (_, __) => const SizedBox(height: 0),
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.gutter, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTokens.surfaceHi,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 12, width: 220, color: AppTokens.surfaceHi),
                  const SizedBox(height: 8),
                  Container(
                      height: 10, width: 120, color: AppTokens.surfaceHi),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
