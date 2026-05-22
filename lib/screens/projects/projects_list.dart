import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../api/projects_api.dart';
import '../../models/project.dart';
import '../../theme/tokens.dart';
import '../../widgets/cover_thumb.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/screen_scaffold.dart';
import '../../widgets/section_label.dart';
import '../../widgets/status_badge.dart';

class ProjectsListScreen extends ConsumerWidget {
  const ProjectsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectsListProvider);

    return ScreenScaffold(
      title: 'Projects',
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.search, size: 18),
          onPressed: () => context.push('/search'),
        ),
      ],
      floatingActionButton: async.maybeWhen(
        data: (_) => _NewProjectFab(),
        orElse: () => null,
      ),
      child: async.when(
        loading: () => const _LoadingList(),
        error: (e, _) => ErrorPanel(
          title: "Couldn't load projects",
          description:
              'The request failed. Check your connection, then try again.',
          errorCode: e.toString(),
          onRetry: () => ref.invalidate(projectsListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: LucideIcons.briefcase,
              title: 'No projects yet',
              description:
                  "The catalog is empty. Create your first entry — it'll appear on your portfolio immediately.",
              action: FilledButton.icon(
                onPressed: () => context.push('/projects/new'),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Create project'),
              ),
            );
          }
          return RefreshIndicator(
            color: AppTokens.accent,
            backgroundColor: AppTokens.surface,
            onRefresh: () => ref.refresh(projectsListProvider.future),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _SubBar(count: items.length)),
                SliverList.separated(
                  itemBuilder: (ctx, i) => _ProjectRow(project: items[i]),
                  separatorBuilder: (_, __) =>
                      Divider(color: AppTokens.line, height: 1),
                  itemCount: items.length,
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SubBar extends StatelessWidget {
  const _SubBar({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppTokens.gutter, 12, AppTokens.gutter, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTokens.line)),
      ),
      child: Row(
        children: [
          SectionLabel('Catalog · $count items'),
          const Spacer(),
          Text(
            'SORT: MANUAL',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              letterSpacing: 0.04 * 11,
              color: AppTokens.inkDim,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(LucideIcons.chevronDown,
              size: 12, color: AppTokens.inkDim),
        ],
      ),
    );
  }
}

class _ProjectRow extends ConsumerWidget {
  const _ProjectRow({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(project.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: AppTokens.danger10,
        child: const Icon(LucideIcons.trash2,
            color: AppTokens.danger, size: 18),
      ),
      confirmDismiss: (_) async {
        // Defer to the editor's confirm sheet — swipe-to-delete just navigates.
        context.push('/projects/${project.id}');
        return false;
      },
      child: InkWell(
        onTap: () => context.push('/projects/${project.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.gutter, vertical: 13),
          child: Row(
            children: [
              CoverThumb(
                imageUrl: project.featuredImage,
                fallbackText: project.name,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTokens.ink,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            project.slug ?? project.domain,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: AppTokens.inkMuted,
                              letterSpacing: -0.01 * 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: project.status,
                          tone: project.isPublished
                              ? BadgeTone.published
                              : BadgeTone.draft,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.gripVertical,
                  size: 18, color: AppTokens.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      separatorBuilder: (_, __) => Divider(color: AppTokens.line, height: 1),
      itemCount: 7,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.gutter, vertical: 13),
        child: Row(
          children: [
            _Shimmer(width: 48, height: 48, radius: 8),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Shimmer(widthFactor: 0.6, height: 13),
                  const SizedBox(height: 8),
                  _Shimmer(widthFactor: 0.35, height: 10),
                ],
              ),
            ),
            _Shimmer(width: 14, height: 14, radius: 3),
          ],
        ),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({
    this.width,
    this.widthFactor,
    required this.height,
    this.radius = 4,
  });
  final double? width;
  final double? widthFactor;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final w = width ??
        (widthFactor != null
            ? MediaQuery.of(context).size.width * widthFactor!
            : double.infinity);
    return Container(
      width: w,
      height: height,
      decoration: BoxDecoration(
        color: AppTokens.surfaceHi,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _NewProjectFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          right: 4, bottom: MediaQuery.of(context).padding.bottom * 0.5),
      child: FilledButton.icon(
        onPressed: () => context.push('/projects/new'),
        icon: const Icon(LucideIcons.plus, size: 16),
        label: const Text('New project'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
      ),
    );
  }
}
