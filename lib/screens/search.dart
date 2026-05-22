import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../api/search_api.dart';
import '../models/search_hit.dart';
import '../theme/tokens.dart';
import '../widgets/empty_state.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/section_label.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _q = '';
  bool _loading = false;
  Object? _error;
  List<SearchHit> _hits = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 240), () => _run(value));
  }

  Future<void> _run(String value) async {
    final q = value.trim();
    setState(() {
      _q = q;
      _error = null;
      if (q.length < 2) {
        _hits = const [];
        _loading = false;
        return;
      }
      _loading = true;
    });
    if (q.length < 2) return;

    try {
      final hits = await ref.read(searchApiProvider).query(q);
      if (!mounted || _ctl.text.trim() != q) return; // stale response
      setState(() {
        _hits = hits;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
        _hits = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Search',
      child: Column(
        children: [
          _SearchField(
            controller: _ctl,
            focus: _focus,
            onChanged: _onChanged,
            onClear: () {
              _ctl.clear();
              _onChanged('');
              _focus.requestFocus();
            },
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_q.length < 2) {
      return EmptyState(
        icon: LucideIcons.search,
        title: 'Search everything',
        description:
            'Projects, posts, skills, and keywords. Type 2+ characters.',
        footnote: 'Hint · slug or title both work',
      );
    }
    if (_loading && _hits.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTokens.accent),
      );
    }
    if (_error != null) {
      return EmptyState(
        icon: LucideIcons.alertTriangle,
        title: "Search failed",
        description: _error.toString(),
      );
    }
    if (_hits.isEmpty) {
      return EmptyState(
        icon: LucideIcons.searchX,
        title: 'No matches',
        description: 'Nothing matched "$_q". Try a shorter term.',
      );
    }

    final groups = _groupByKind(_hits);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: groups.length,
      itemBuilder: (ctx, i) => _GroupView(group: groups[i]),
    );
  }
}

// ─────────────────────────── search field

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focus,
    required this.onChanged,
    required this.onClear,
  });
  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTokens.gutter, 12, AppTokens.gutter, 12),
      child: TextField(
        controller: controller,
        focusNode: focus,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search projects, posts, skills…',
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 8),
            child: Icon(LucideIcons.search,
                size: 18, color: AppTokens.inkDim),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: ValueListenableBuilder(
            valueListenable: controller,
            builder: (_, v, __) => v.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(LucideIcons.x,
                        size: 16, color: AppTokens.inkDim),
                    onPressed: onClear,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── grouping

class _Group {
  _Group(this.kind, this.hits);
  final HitKind kind;
  final List<SearchHit> hits;

  String get label => switch (kind) {
        HitKind.project => 'Projects',
        HitKind.post => 'Posts',
        HitKind.skill => 'Skills',
        HitKind.keyword => 'Keywords',
        HitKind.unknown => 'Other',
      };
}

List<_Group> _groupByKind(List<SearchHit> hits) {
  const order = [
    HitKind.project,
    HitKind.post,
    HitKind.skill,
    HitKind.keyword,
    HitKind.unknown,
  ];
  final map = <HitKind, List<SearchHit>>{};
  for (final h in hits) {
    (map[h.kind] ??= []).add(h);
  }
  return order
      .where((k) => map[k]?.isNotEmpty == true)
      .map((k) => _Group(k, map[k]!))
      .toList();
}

// ─────────────────────────── group + row

class _GroupView extends StatelessWidget {
  const _GroupView({required this.group});
  final _Group group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTokens.gutter, 14, AppTokens.gutter, 8),
          child: SectionLabel(group.label),
        ),
        for (var i = 0; i < group.hits.length; i++) ...[
          _Row(hit: group.hits[i]),
          if (i < group.hits.length - 1)
            Padding(
              padding: const EdgeInsets.only(left: 60),
              child: Divider(color: AppTokens.line, height: 1),
            ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.hit});
  final SearchHit hit;

  IconData get _icon => switch (hit.kind) {
        HitKind.project => LucideIcons.folderKanban,
        HitKind.post => LucideIcons.fileText,
        HitKind.skill => LucideIcons.sparkles,
        HitKind.keyword => LucideIcons.tag,
        HitKind.unknown => LucideIcons.dot,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(hit.href),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.gutter, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTokens.surface,
                border: Border.all(color: AppTokens.line),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_icon, size: 15, color: AppTokens.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.ink,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hit.sub,
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
            const Icon(LucideIcons.chevronRight,
                size: 14, color: AppTokens.inkMuted),
          ],
        ),
      ),
    );
  }
}
