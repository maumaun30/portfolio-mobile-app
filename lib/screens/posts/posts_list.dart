import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../api/posts_api.dart';
import '../../models/post.dart';
import '../../theme/tokens.dart';
import '../../widgets/cover_thumb.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/screen_scaffold.dart';
import '../../widgets/status_badge.dart';

class PostsListScreen extends ConsumerStatefulWidget {
  const PostsListScreen({super.key});

  @override
  ConsumerState<PostsListScreen> createState() => _PostsListScreenState();
}

class _PostsListScreenState extends ConsumerState<PostsListScreen> {
  PostType? _filter; // null → All

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(postsListProvider);

    return ScreenScaffold(
      title: 'Posts',
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.search, size: 18),
          onPressed: () => context.push('/search'),
        ),
      ],
      floatingActionButton: async.maybeWhen(
        data: (_) => Padding(
          padding: EdgeInsets.only(
              right: 4,
              bottom: MediaQuery.of(context).padding.bottom * 0.5),
          child: FilledButton.icon(
            onPressed: () => context.push('/posts/new'),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('New post'),
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
          title: "Couldn't load posts",
          description: e.toString(),
          onRetry: () => ref.invalidate(postsListProvider),
        ),
        data: (items) {
          final all = items.length;
          final blog =
              items.where((p) => p.type == PostType.blog).length;
          final cs = items.where((p) => p.type == PostType.caseStudy).length;
          final filtered = _filter == null
              ? items
              : items.where((p) => p.type == _filter).toList();

          return RefreshIndicator(
            color: AppTokens.accent,
            backgroundColor: AppTokens.surface,
            onRefresh: () => ref.refresh(postsListProvider.future),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Chips(
                    selected: _filter,
                    counts: {null: all, PostType.blog: blog, PostType.caseStudy: cs},
                    onChange: (next) => setState(() => _filter = next),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: LucideIcons.fileText,
                      title: 'No posts yet',
                      description: _filter == null
                          ? "Write your first post — blog or case study."
                          : "No ${_filter!.label.toLowerCase()} posts yet.",
                      action: FilledButton.icon(
                        onPressed: () => context.push('/posts/new'),
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: const Text('New post'),
                      ),
                    ),
                  )
                else
                  SliverList.separated(
                    itemBuilder: (ctx, i) => _Row(post: filtered[i]),
                    separatorBuilder: (_, __) =>
                        Divider(color: AppTokens.line, height: 1),
                    itemCount: filtered.length,
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.selected,
    required this.counts,
    required this.onChange,
  });
  final PostType? selected;
  final Map<PostType?, int> counts;
  final ValueChanged<PostType?> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTokens.line)),
      ),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            count: counts[null] ?? 0,
            active: selected == null,
            onTap: () => onChange(null),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Blog',
            count: counts[PostType.blog] ?? 0,
            active: selected == PostType.blog,
            onTap: () => onChange(PostType.blog),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Case study',
            count: counts[PostType.caseStudy] ?? 0,
            active: selected == PostType.caseStudy,
            onTap: () => onChange(PostType.caseStudy),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppTokens.accent10 : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
            color: active ? Colors.transparent : AppTokens.line),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active ? AppTokens.accent : AppTokens.inkDim,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  letterSpacing: 0.04 * 10,
                  color: active ? AppTokens.accent : AppTokens.inkDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.post});
  final Post post;

  String get _date {
    final dt = post.publishedAt ?? post.updatedAt;
    final mo = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][dt.month - 1];
    return '$mo ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/posts/${post.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.gutter, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoverThumb(
              imageUrl: post.coverImage,
              fallbackText: post.title,
              size: 56,
              radius: 6,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '— ${post.type.label.toUpperCase()}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          letterSpacing: 0.06 * 10.5,
                          color: AppTokens.inkMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· $_date',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          letterSpacing: 0.04 * 10.5,
                          color: AppTokens.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.ink,
                      letterSpacing: -0.15,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StatusBadge(
                    label: post.status,
                    tone: post.isPublished
                        ? BadgeTone.published
                        : BadgeTone.draft,
                  ),
                ],
              ),
            ),
          ],
        ),
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
      separatorBuilder: (_, __) => Divider(color: AppTokens.line, height: 1),
      itemCount: 5,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.gutter, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTokens.surfaceHi,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 10, width: 100, color: AppTokens.surfaceHi),
                  const SizedBox(height: 8),
                  Container(height: 14, width: double.infinity, color: AppTokens.surfaceHi),
                  const SizedBox(height: 8),
                  Container(height: 14, width: 200, color: AppTokens.surfaceHi),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
