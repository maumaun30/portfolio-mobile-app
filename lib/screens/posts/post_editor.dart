import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../api/posts_api.dart';
import '../../models/post.dart';
import '../../theme/tokens.dart';
import '../../widgets/confirm_sheet.dart';
import '../../widgets/cover_thumb.dart';
import '../../widgets/error_state.dart';
import '../../widgets/image_upload_sheet.dart';
import '../../widgets/section_label.dart';

class PostEditorScreen extends ConsumerWidget {
  const PostEditorScreen({super.key, this.id});
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (id == null) return const _Editor(post: null);
    final async = ref.watch(postByIdProvider(id!));
    return async.when(
      data: (p) => _Editor(post: p),
      loading: () => const Scaffold(
        backgroundColor: AppTokens.bg,
        body: Center(
            child: CircularProgressIndicator(color: AppTokens.accent)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTokens.bg,
        appBar: AppBar(title: const Text('Edit post')),
        body: ErrorPanel(
          title: "Couldn't load post",
          description: e.toString(),
          onRetry: () => ref.invalidate(postByIdProvider(id!)),
        ),
      ),
    );
  }
}

enum _BodyTab { write, preview }

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.post});
  final Post? post;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final TextEditingController _title;
  late final TextEditingController _slug;
  late final TextEditingController _excerpt;
  late final TextEditingController _body;
  late final TextEditingController _coverImage;
  late PostType _type;
  late bool _publish;
  bool _slugTouched = false;
  bool _dirty = false;
  bool _saving = false;
  String? _slugError;
  String? _saveError;
  _BodyTab _tab = _BodyTab.write;

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    _title = TextEditingController(text: p?.title ?? '');
    _slug = TextEditingController(text: p?.slug ?? '');
    _excerpt = TextEditingController(text: p?.excerpt ?? '');
    _body = TextEditingController(text: p?.body ?? '');
    _coverImage = TextEditingController(text: p?.coverImage ?? '');
    _type = p?.type ?? PostType.blog;
    _publish = (p?.status ?? 'published') == 'published';
    _slugTouched = (p?.slug ?? '').isNotEmpty;

    _title.addListener(() {
      if (!_slugTouched) {
        _slug.text = _slugify(_title.text);
      }
      _markDirty();
    });
    _slug.addListener(() {
      _slugTouched = _slug.text.isNotEmpty;
      final s = _slug.text;
      setState(() {
        _slugError = s.isEmpty || RegExp(r'^[a-z0-9-]+$').hasMatch(s)
            ? null
            : 'Lowercase, hyphen-separated.';
      });
      _markDirty();
    });
    for (final c in [_excerpt, _body, _coverImage]) {
      c.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _slug, _excerpt, _body, _coverImage]) {
      c.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  String _slugify(String input) => input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '')
      .replaceAll(RegExp(r'-{2,}'), '-');

  bool get _isCreate => widget.post == null;
  bool get _canSave =>
      _title.text.trim().isNotEmpty &&
      _slug.text.trim().isNotEmpty &&
      _slugError == null;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final api = ref.read(postsApiProvider);
    final payload = <String, dynamic>{
      'type': _type.apiValue,
      'slug': _slug.text.trim(),
      'title': _title.text.trim(),
      'excerpt': _excerpt.text.trim(),
      'coverImage': _coverImage.text.trim(),
      'body': _body.text,
      'status': _publish ? 'published' : 'draft',
    };
    try {
      if (_isCreate) {
        await api.create(payload);
      } else {
        await api.update(widget.post!.id, payload);
      }
      ref.invalidate(postsListProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saveError = e.toString();
          _saving = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final p = widget.post;
    if (p == null) return;
    final confirmed = await ConfirmDeleteSheet.show(
      context,
      title: 'Delete this post?',
      description: 'It will be removed from your portfolio immediately.',
      confirmText: p.slug,
    );
    if (confirmed != true) return;
    try {
      await ref.read(postsApiProvider).delete(p.id);
      ref.invalidate(postsListProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTokens.surface,
          content: Text('Delete failed: $e',
              style: const TextStyle(color: AppTokens.danger)),
        ),
      );
    }
  }

  Future<void> _replaceCover() async {
    final url = await ImageUploadSheet.show(context, folder: 'posts');
    if (url != null && url.isNotEmpty) {
      setState(() => _coverImage.text = url);
      _markDirty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        title: Text(_isCreate ? 'New entry' : 'Edit post'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x, size: 20),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTokens.line),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppTokens.gutter, 18, AppTokens.gutter, 24),
        children: [
          SectionLabel(_isCreate ? 'New entry' : 'Editing entry'),
          const SizedBox(height: 14),
          _CoverCard(
            imageUrl: _coverImage.text,
            fallbackText: _title.text,
            onReplace: _replaceCover,
          ),
          const SizedBox(height: 14),
          _Label('TITLE'),
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            decoration: const InputDecoration(hintText: 'Post title'),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('TYPE'),
                    const SizedBox(height: 8),
                    _TypeDropdown(
                      value: _type,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _type = v);
                        _markDirty();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('STATUS'),
                    const SizedBox(height: 8),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppTokens.surface,
                        borderRadius:
                            BorderRadius.circular(AppTokens.inputRadius),
                        border: Border.all(color: AppTokens.line),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _publish ? 'PUBLISHED' : 'DRAFT',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                letterSpacing: 0.04 * 11,
                                color: _publish
                                    ? AppTokens.accent
                                    : AppTokens.inkDim,
                              ),
                            ),
                          ),
                          Switch(
                            value: _publish,
                            onChanged: (v) {
                              setState(() => _publish = v);
                              _markDirty();
                            },
                            activeColor: AppTokens.onAccent,
                            activeTrackColor: AppTokens.accent,
                            inactiveThumbColor: AppTokens.inkMuted,
                            inactiveTrackColor: AppTokens.surfaceHi,
                            trackOutlineColor:
                                WidgetStateProperty.resolveWith(
                                    (_) => AppTokens.line),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Label('SLUG'),
              const Spacer(),
              if (!_slugTouched)
                Text(
                  'AUTO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    letterSpacing: 0.04 * 10.5,
                    color: AppTokens.inkMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _slug,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 13, color: AppTokens.ink),
            decoration: InputDecoration(
              hintText: 'auto-from-title',
              errorText: _slugError,
            ),
          ),
          const SizedBox(height: 14),
          _Label('EXCERPT'),
          const SizedBox(height: 8),
          TextField(
            controller: _excerpt,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Short summary shown on listings.',
            ),
          ),
          const SizedBox(height: 22),
          _BodyTabs(
            tab: _tab,
            onChange: (t) => setState(() => _tab = t),
          ),
          const SizedBox(height: 10),
          if (_tab == _BodyTab.write)
            TextField(
              controller: _body,
              maxLines: 14,
              minLines: 10,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                color: AppTokens.ink,
                height: 1.6,
              ),
              decoration: const InputDecoration(
                hintText: '# Title\n\nWrite in markdown…',
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(minHeight: 240),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(AppTokens.inputRadius),
                border: Border.all(color: AppTokens.line),
              ),
              child: _body.text.trim().isEmpty
                  ? Text(
                      'Nothing to preview yet.',
                      style: TextStyle(color: AppTokens.inkMuted),
                    )
                  : MarkdownBody(
                      data: _body.text,
                      styleSheet: _markdownStyle(),
                      selectable: true,
                    ),
            ),
          if (_saveError != null) ...[
            const SizedBox(height: 18),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTokens.danger10,
                borderRadius: BorderRadius.circular(AppTokens.inputRadius),
                border: Border.all(color: AppTokens.danger.withOpacity(0.3)),
              ),
              child: Text(
                _saveError!,
                style: const TextStyle(
                    color: AppTokens.danger, fontSize: 12.5),
              ),
            ),
          ],
          if (!_isCreate) ...[
            const SizedBox(height: 28),
            const SectionLabel('Danger zone'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _delete,
              icon: const Icon(LucideIcons.trash2, size: 15),
              label: const Text('Delete post…'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTokens.danger,
                side: const BorderSide(color: AppTokens.danger),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTokens.inputRadius),
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: _BottomBar(
        publish: _publish,
        onTogglePublish: (v) {
          setState(() => _publish = v);
          _markDirty();
        },
        saving: _saving,
        canSave: _canSave && (_isCreate || _dirty),
        label: _saving
            ? 'Saving…'
            : (_slugError != null
                ? 'Fix 1 error'
                : (_publish ? 'Save & publish' : 'Save draft')),
        onSave: _save,
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle() => MarkdownStyleSheet(
        p: const TextStyle(
            color: AppTokens.inkDim, fontSize: 14, height: 1.6),
        h1: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: AppTokens.ink,
        ),
        h2: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: AppTokens.ink,
        ),
        h3: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppTokens.ink,
        ),
        strong: const TextStyle(
            color: AppTokens.ink, fontWeight: FontWeight.w600),
        em: const TextStyle(color: AppTokens.ink, fontStyle: FontStyle.italic),
        a: const TextStyle(
            color: AppTokens.accent, decoration: TextDecoration.underline),
        listBullet: const TextStyle(color: AppTokens.inkDim, fontSize: 14),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: AppTokens.accent, width: 2),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12),
        blockquote: const TextStyle(
            color: AppTokens.ink,
            fontStyle: FontStyle.italic,
            fontSize: 14,
            height: 1.5),
        code: GoogleFonts.jetBrainsMono(
          color: AppTokens.ink,
          backgroundColor: AppTokens.surfaceHi,
          fontSize: 12,
        ),
        codeblockDecoration: BoxDecoration(
          color: AppTokens.surfaceHi,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTokens.line),
        ),
        codeblockPadding: const EdgeInsets.all(12),
      );
}

// ───────────────────────────────────────── components

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppTokens.inkDim,
        letterSpacing: 0.04 * 12,
      ),
    );
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({
    required this.imageUrl,
    required this.fallbackText,
    required this.onReplace,
  });
  final String imageUrl;
  final String fallbackText;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          border: Border.all(color: AppTokens.line),
          borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => CoverThumb(
                  fallbackText: fallbackText,
                  size: double.infinity,
                  radius: AppTokens.cardRadius,
                ),
              )
            else
              CoverThumb(
                fallbackText: fallbackText.isEmpty ? '?' : fallbackText,
                size: double.infinity,
                radius: AppTokens.cardRadius,
              ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Material(
                color: const Color.fromRGBO(10, 9, 7, 0.7),
                shape: const StadiumBorder(
                  side: BorderSide(
                      color: Color.fromRGBO(239, 230, 212, 0.15)),
                ),
                child: InkWell(
                  onTap: onReplace,
                  customBorder: const StadiumBorder(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.image,
                            size: 13, color: AppTokens.ink),
                        SizedBox(width: 6),
                        Text(
                          'Replace cover',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTokens.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({required this.value, required this.onChanged});
  final PostType value;
  final ValueChanged<PostType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.inputRadius),
        border: Border.all(color: AppTokens.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PostType>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTokens.surface,
          icon: const Icon(LucideIcons.chevronDown,
              size: 16, color: AppTokens.inkDim),
          style: const TextStyle(fontSize: 14, color: AppTokens.ink),
          items: PostType.values
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.label),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _BodyTabs extends StatelessWidget {
  const _BodyTabs({required this.tab, required this.onChange});
  final _BodyTab tab;
  final ValueChanged<_BodyTab> onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'BODY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTokens.inkDim,
            letterSpacing: 0.04 * 12,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppTokens.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTokens.line),
          ),
          child: Row(
            children: [
              _SegBtn(
                label: 'Write',
                active: tab == _BodyTab.write,
                onTap: () => onChange(_BodyTab.write),
              ),
              _SegBtn(
                label: 'Preview',
                active: tab == _BodyTab.preview,
                onTap: () => onChange(_BodyTab.preview),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegBtn extends StatelessWidget {
  const _SegBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppTokens.accent10 : Colors.transparent,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: active ? AppTokens.accent : AppTokens.inkDim,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.publish,
    required this.onTogglePublish,
    required this.saving,
    required this.canSave,
    required this.label,
    required this.onSave,
  });
  final bool publish;
  final ValueChanged<bool> onTogglePublish;
  final bool saving;
  final bool canSave;
  final String label;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      padding:
          EdgeInsets.fromLTRB(16, 12, 16, 12 + mq.padding.bottom * 0.5),
      decoration: BoxDecoration(
        color: AppTokens.bg,
        border: Border(top: BorderSide(color: AppTokens.line)),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.pillRadius),
              border: Border.all(color: AppTokens.line),
            ),
            child: Row(
              children: [
                const Text(
                  'Publish',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.inkDim,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: publish,
                  onChanged: onTogglePublish,
                  activeColor: AppTokens.onAccent,
                  activeTrackColor: AppTokens.accent,
                  inactiveThumbColor: AppTokens.inkMuted,
                  inactiveTrackColor: AppTokens.surfaceHi,
                  trackOutlineColor: WidgetStateProperty.resolveWith(
                      (_) => AppTokens.line),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: (saving || !canSave) ? null : onSave,
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
