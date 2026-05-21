import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../api/keywords_api.dart';
import '../../models/keyword.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/screen_scaffold.dart';
import '../../widgets/section_label.dart';

class KeywordsListScreen extends ConsumerStatefulWidget {
  const KeywordsListScreen({super.key});

  @override
  ConsumerState<KeywordsListScreen> createState() =>
      _KeywordsListScreenState();
}

class _KeywordsListScreenState extends ConsumerState<KeywordsListScreen> {
  bool _generating = false;
  String? _generatingForId;

  Future<void> _generate({String? keywordId, String? term}) async {
    setState(() {
      _generating = true;
      _generatingForId = keywordId;
    });
    try {
      final res = await ref
          .read(keywordsApiProvider)
          .generate(keywordId: keywordId);
      ref.invalidate(keywordsListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTokens.surface,
          duration: const Duration(seconds: 4),
          content: Text(
            'Published: ${res.slug.isEmpty ? res.keyword : res.slug}',
            style: const TextStyle(color: AppTokens.ink),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTokens.surface,
          duration: const Duration(seconds: 6),
          content: Text(
            'Generate failed: $e',
            style: const TextStyle(color: AppTokens.danger),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _generating = false;
          _generatingForId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(keywordsListProvider);

    return ScreenScaffold(
      title: 'Keywords',
      floatingActionButton: async.maybeWhen(
        data: (_) => Padding(
          padding: EdgeInsets.only(
              right: 4,
              bottom: MediaQuery.of(context).padding.bottom * 0.5),
          child: FilledButton.icon(
            onPressed: () => context.push('/keywords/new'),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Add term'),
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
          title: "Couldn't load keywords",
          description: e.toString(),
          onRetry: () => ref.invalidate(keywordsListProvider),
        ),
        data: (items) {
          final active = items.where((k) => k.enabled).length;
          return RefreshIndicator(
            color: AppTokens.accent,
            backgroundColor: AppTokens.surface,
            onRefresh: () => ref.refresh(keywordsListProvider.future),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroCta(
                    active: active,
                    generating: _generating && _generatingForId == null,
                    onTap: _generating ? null : () => _generate(),
                  ),
                ),
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: LucideIcons.tag,
                      title: 'No keywords yet',
                      description:
                          'Add a term and the cron + Generate now button will turn it into a blog post.',
                      action: FilledButton.icon(
                        onPressed: () => context.push('/keywords/new'),
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: const Text('Add keyword'),
                      ),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: _TermsHeader(
                      total: items.length,
                      active: active,
                    ),
                  ),
                  SliverList.separated(
                    itemBuilder: (ctx, i) => _Row(
                      keyword: items[i],
                      generating:
                          _generating && _generatingForId == items[i].id,
                      busy: _generating,
                      onGenerate: () =>
                          _generate(keywordId: items[i].id, term: items[i].term),
                      onToggle: (next) async {
                        try {
                          await ref
                              .read(keywordsApiProvider)
                              .update(items[i].id, enabled: next);
                          ref.invalidate(keywordsListProvider);
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTokens.surface,
                              content: Text(
                                'Toggle failed: $e',
                                style:
                                    const TextStyle(color: AppTokens.danger),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    separatorBuilder: (_, __) =>
                        Divider(color: AppTokens.line, height: 1),
                    itemCount: items.length,
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroCta extends StatelessWidget {
  const _HeroCta({
    required this.active,
    required this.generating,
    required this.onTap,
  });
  final int active;
  final bool generating;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppTokens.gutter, 18, AppTokens.gutter, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTokens.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Auto-blog'),
          const SizedBox(height: 12),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              decoration: BoxDecoration(
                color: AppTokens.accent10,
                borderRadius: BorderRadius.circular(AppTokens.cardRadius),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTokens.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: generating
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTokens.onAccent,
                            ),
                          )
                        : const Icon(
                            LucideIcons.sparkles,
                            size: 20,
                            color: AppTokens.onAccent,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          generating ? 'Generating post…' : 'Generate now',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.ink,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          generating
                              ? 'Picking a term · drafting · publishing.'
                              : '$active active term${active == 1 ? '' : 's'} ready · ~30 s.',
                          style: const TextStyle(
                              fontSize: 12, color: AppTokens.inkDim),
                        ),
                      ],
                    ),
                  ),
                  if (!generating)
                    const Icon(LucideIcons.chevronRight,
                        size: 16, color: AppTokens.accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsHeader extends StatelessWidget {
  const _TermsHeader({required this.total, required this.active});
  final int total;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTokens.gutter, 14, AppTokens.gutter, 8),
      child: Row(
        children: [
          SectionLabel('Terms · $total'),
          const Spacer(),
          Text(
            '$active ACTIVE',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              letterSpacing: 0.04 * 11,
              color: AppTokens.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.keyword,
    required this.generating,
    required this.busy,
    required this.onGenerate,
    required this.onToggle,
  });
  final Keyword keyword;
  final bool generating;
  final bool busy;
  final VoidCallback onGenerate;
  final ValueChanged<bool> onToggle;

  String get _last {
    final dt = keyword.lastUsedAt;
    if (dt == null) return 'NEVER';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m AGO';
    if (diff.inHours < 24) return '${diff.inHours}h AGO';
    if (diff.inDays == 1) return 'YESTERDAY';
    if (diff.inDays < 30) return '${diff.inDays}d AGO';
    return dt.toIso8601String().substring(0, 10).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/keywords/${keyword.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.gutter, vertical: 14),
        child: Row(
          children: [
            Icon(LucideIcons.hash,
                size: 16,
                color: keyword.enabled
                    ? AppTokens.accent
                    : AppTokens.inkMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    keyword.term.toLowerCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.ink,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'LAST $_last',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      letterSpacing: 0.04 * 10.5,
                      color: AppTokens.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Per-row "Generate now" — disabled when keyword off or globally busy.
            Opacity(
              opacity: keyword.enabled ? 1 : 0.4,
              child: InkWell(
                onTap: (busy || !keyword.enabled) ? null : onGenerate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: AppTokens.line),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: generating
                      ? const Padding(
                          padding: EdgeInsets.all(7),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTokens.accent,
                          ),
                        )
                      : const Icon(LucideIcons.sparkles,
                          size: 14, color: AppTokens.inkDim),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Switch(
              value: keyword.enabled,
              onChanged: busy ? null : onToggle,
              activeColor: AppTokens.onAccent,
              activeTrackColor: AppTokens.accent,
              inactiveThumbColor: AppTokens.inkMuted,
              inactiveTrackColor: AppTokens.surfaceHi,
              trackOutlineColor:
                  WidgetStateProperty.resolveWith((_) => AppTokens.line),
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
      padding: const EdgeInsets.symmetric(vertical: 18),
      separatorBuilder: (_, __) => Divider(color: AppTokens.line, height: 1),
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.gutter, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppTokens.surfaceHi,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 13,
                    width: 160,
                    color: AppTokens.surfaceHi,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 80,
                    color: AppTokens.surfaceHi,
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
