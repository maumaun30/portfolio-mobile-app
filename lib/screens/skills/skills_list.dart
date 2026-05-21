import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../api/skills_api.dart';
import '../../models/skill.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/screen_scaffold.dart';
import '../../widgets/section_label.dart';
import '../../widgets/simpleicon.dart';

class SkillsListScreen extends ConsumerStatefulWidget {
  const SkillsListScreen({super.key});

  @override
  ConsumerState<SkillsListScreen> createState() => _SkillsListScreenState();
}

class _SkillsListScreenState extends ConsumerState<SkillsListScreen> {
  bool _reordering = false;

  Future<void> _persistReorder(List<Skill> next) async {
    final api = ref.read(skillsApiProvider);
    // Only PATCH rows whose sort actually changed — keeps the request count
    // proportional to the move, not the full list size.
    final changes = <Future<void>>[];
    for (var i = 0; i < next.length; i++) {
      if (next[i].sort != i) {
        changes.add(api.update(next[i].id, sort: i).then((_) => null));
      }
    }
    try {
      await Future.wait(changes);
      ref.invalidate(skillsListProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTokens.surface,
          content: Text('Reorder failed: $e',
              style: const TextStyle(color: AppTokens.danger)),
        ),
      );
      ref.invalidate(skillsListProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(skillsListProvider);

    return ScreenScaffold(
      title: 'Skills',
      actions: [
        async.maybeWhen(
          data: (items) => IconButton(
            icon: Icon(
              _reordering ? LucideIcons.check : LucideIcons.arrowUpDown,
              size: 18,
              color: _reordering ? AppTokens.accent : AppTokens.ink,
            ),
            onPressed: items.isEmpty
                ? null
                : () => setState(() => _reordering = !_reordering),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
      floatingActionButton: async.maybeWhen(
        data: (_) => Padding(
          padding: EdgeInsets.only(
              right: 4,
              bottom: MediaQuery.of(context).padding.bottom * 0.5),
          child: FilledButton.icon(
            onPressed: () => context.push('/skills/new'),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('New skill'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
          ),
        ),
        orElse: () => null,
      ),
      child: async.when(
        loading: () => const _Loading(),
        error: (e, _) => ErrorPanel(
          title: "Couldn't load skills",
          description: e.toString(),
          onRetry: () => ref.invalidate(skillsListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: LucideIcons.sparkles,
              title: 'No skills yet',
              description:
                  'Add the stacks you work in. Slugs must match a simpleicons.org brand.',
              action: FilledButton.icon(
                onPressed: () => context.push('/skills/new'),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('New skill'),
              ),
            );
          }
          return RefreshIndicator(
            color: AppTokens.accent,
            backgroundColor: AppTokens.surface,
            onRefresh: () => ref.refresh(skillsListProvider.future),
            child: Column(
              children: [
                _SubBar(count: items.length, reordering: _reordering),
                Expanded(
                  child: _reordering
                      ? _Reorderable(
                          items: items,
                          onReorder: _persistReorder,
                        )
                      : _StaticList(items: items),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SubBar extends StatelessWidget {
  const _SubBar({required this.count, required this.reordering});
  final int count;
  final bool reordering;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppTokens.gutter, 12, AppTokens.gutter, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTokens.line)),
      ),
      child: Row(
        children: [
          SectionLabel('Catalog · $count items'),
          const Spacer(),
          Text(
            reordering ? 'DRAG TO REORDER' : 'HOLD ↕ FOR REORDER',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              letterSpacing: 0.04 * 11,
              color: reordering ? AppTokens.accent : AppTokens.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticList extends StatelessWidget {
  const _StaticList({required this.items});
  final List<Skill> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length + 1,
      separatorBuilder: (_, __) => Divider(color: AppTokens.line, height: 1),
      itemBuilder: (ctx, i) {
        if (i == items.length) return const SizedBox(height: 88);
        final s = items[i];
        return InkWell(
          onTap: () => context.push('/skills/${s.id}'),
          child: _Row(skill: s, trailing: null),
        );
      },
    );
  }
}

class _Reorderable extends StatefulWidget {
  const _Reorderable({required this.items, required this.onReorder});
  final List<Skill> items;
  final Future<void> Function(List<Skill>) onReorder;

  @override
  State<_Reorderable> createState() => _ReorderableState();
}

class _ReorderableState extends State<_Reorderable> {
  late List<Skill> _local;

  @override
  void initState() {
    super.initState();
    _local = List<Skill>.from(widget.items);
  }

  @override
  void didUpdateWidget(covariant _Reorderable old) {
    super.didUpdateWidget(old);
    if (!identical(old.items, widget.items)) {
      _local = List<Skill>.from(widget.items);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: _local.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final moved = _local.removeAt(oldIndex);
          _local.insert(newIndex, moved);
        });
        widget.onReorder(_local);
      },
      itemBuilder: (ctx, i) {
        final s = _local[i];
        return Container(
          key: ValueKey(s.id),
          decoration: BoxDecoration(
            color: AppTokens.bg,
            border: Border(bottom: BorderSide(color: AppTokens.line)),
          ),
          child: _Row(
            skill: s,
            trailing: ReorderableDragStartListener(
              index: i,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Icon(LucideIcons.gripVertical,
                    size: 18, color: AppTokens.inkDim),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.skill, required this.trailing});
  final Skill skill;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.gutter, vertical: 13),
      child: Row(
        children: [
          SimpleIcon(slug: skill.slug, fallbackLabel: skill.label),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.ink,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'simpleicons.org / ${skill.slug}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: AppTokens.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else
            const Icon(LucideIcons.chevronRight,
                size: 16, color: AppTokens.inkMuted),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 60),
      itemCount: 8,
      separatorBuilder: (_, __) => Divider(color: AppTokens.line, height: 1),
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.gutter, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTokens.surfaceHi,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 13, width: 140, color: AppTokens.surfaceHi),
                  const SizedBox(height: 6),
                  Container(height: 11, width: 200, color: AppTokens.surfaceHi),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
