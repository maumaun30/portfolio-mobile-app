import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../api/projects_api.dart';
import '../../models/project.dart';
import '../../theme/tokens.dart';
import '../../widgets/confirm_sheet.dart';
import '../../widgets/cover_thumb.dart';
import '../../widgets/error_state.dart';
import '../../widgets/image_upload_sheet.dart';
import '../../widgets/section_label.dart';
import '../../widgets/submit_bar.dart';

/// Editor for both create (id == null) and edit flows.
class ProjectEditorScreen extends ConsumerWidget {
  const ProjectEditorScreen({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (id == null) {
      return const _Editor(project: null);
    }
    final async = ref.watch(projectByIdProvider(id!));
    return async.when(
      data: (p) => _Editor(project: p),
      loading: () => const Scaffold(
        backgroundColor: AppTokens.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppTokens.accent),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTokens.bg,
        appBar: AppBar(title: const Text('Edit project')),
        body: ErrorPanel(
          title: "Couldn't load project",
          description: e.toString(),
          onRetry: () => ref.invalidate(projectByIdProvider(id!)),
        ),
      ),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.project});
  final Project? project;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _domain;
  late final TextEditingController _link;
  late final TextEditingController _description;
  late final TextEditingController _featuredImage;
  late List<String> _stacks;
  late bool _isPublished;
  late bool _isCurrent;
  bool _slugTouched = false;
  bool _dirty = false;
  bool _saving = false;
  String? _slugError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _name = TextEditingController(text: p?.name ?? '');
    _slug = TextEditingController(text: p?.slug ?? '');
    _domain = TextEditingController(text: p?.domain ?? '');
    _link = TextEditingController(text: p?.link ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _featuredImage = TextEditingController(text: p?.featuredImage ?? '');
    _stacks = List<String>.from(p?.stacks ?? const []);
    _isPublished = (p?.status ?? 'published') == 'published';
    _isCurrent = p?.isCurrent ?? false;
    _slugTouched = (p?.slug ?? '').isNotEmpty;

    _name.addListener(() {
      if (!_slugTouched) {
        _slug.text = _slugify(_name.text);
      }
      _markDirty();
    });
    _slug.addListener(() {
      _slugTouched = _slug.text.isNotEmpty;
      _validateSlug();
      _markDirty();
    });
    for (final c in [_domain, _link, _description, _featuredImage]) {
      c.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _slug,
      _domain,
      _link,
      _description,
      _featuredImage,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _validateSlug() {
    final s = _slug.text;
    if (s.isEmpty) {
      setState(() => _slugError = null);
      return;
    }
    final valid = RegExp(r'^[a-z0-9-]+$').hasMatch(s);
    setState(() {
      _slugError =
          valid ? null : 'Slugs must be lowercase, hyphen-separated.';
    });
  }

  String _slugify(String input) => input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '')
      .replaceAll(RegExp(r'-{2,}'), '-');

  bool get _isCreate => widget.project == null;

  bool get _canSave => _name.text.trim().isNotEmpty && _slugError == null;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final api = ref.read(projectsApiProvider);
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'slug': _slug.text.trim().isEmpty ? null : _slug.text.trim(),
      'domain': _domain.text.trim(),
      'link': _link.text.trim(),
      'featuredImage': _featuredImage.text.trim(),
      'description': _description.text.trim(),
      'stacks': _stacks,
      'status': _isPublished ? 'published' : 'draft',
      'isCurrent': _isCurrent,
    };
    try {
      if (_isCreate) {
        await api.create(payload);
      } else {
        await api.update(widget.project!.id, payload);
      }
      ref.invalidate(projectsListProvider);
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
    final p = widget.project;
    if (p == null) return;
    final confirmed = await ConfirmDeleteSheet.show(
      context,
      title: 'Delete this project?',
      description:
          'It will be removed from your portfolio. This can\'t be undone.',
      confirmText: p.slug ?? p.name,
    );
    if (confirmed != true) return;

    try {
      await ref.read(projectsApiProvider).delete(p.id);
      ref.invalidate(projectsListProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTokens.surface,
            content: Text(
              'Delete failed: $e',
              style: const TextStyle(color: AppTokens.ink),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        title: Text(_isCreate ? 'New project' : 'Edit project'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTokens.line),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppTokens.gutter, 20, AppTokens.gutter, 24),
        children: [
          SectionLabel(_isCreate ? 'New entry' : 'Editing entry'),
          const SizedBox(height: 8),
          Text(
            _name.text.isEmpty ? 'Untitled project' : _name.text,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: _name.text.isEmpty ? AppTokens.inkDim : AppTokens.ink,
            ),
          ),
          const SizedBox(height: 22),
          _CoverCard(
            imageUrl: _featuredImage.text,
            fallbackText: _name.text,
            onReplace: () async {
              final url =
                  await ImageUploadSheet.show(context, folder: 'projects');
              if (url != null && url.isNotEmpty) {
                setState(() => _featuredImage.text = url);
                _markDirty();
              }
            },
          ),
          const SizedBox(height: 22),
          _LabeledField(
            label: 'Name',
            controller: _name,
            hint: 'Project title',
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: 'Slug',
            controller: _slug,
            mono: true,
            hint: 'auto-from-name',
            hintNote: _slugTouched ? null : 'AUTO FROM NAME',
            errorText: _slugError,
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: 'Domain',
            controller: _domain,
            hint: 'example.com',
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: 'Link',
            controller: _link,
            hint: 'https://…',
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: 'Description',
            controller: _description,
            multiline: true,
            hint: 'Brief description',
          ),
          const SizedBox(height: 14),
          _StacksField(
            stacks: _stacks,
            onChanged: (next) {
              setState(() => _stacks = next);
              _markDirty();
            },
          ),
          const SizedBox(height: 18),
          _ToggleRowGroup(
            children: [
              _ToggleRow(
                label: 'Status',
                value: _isPublished ? 'PUBLISHED' : 'DRAFT',
                on: _isPublished,
                onChanged: (v) {
                  setState(() => _isPublished = v);
                  _markDirty();
                },
              ),
              _ToggleRow(
                label: 'Is current',
                sub: 'Featured first on home',
                on: _isCurrent,
                onChanged: (v) {
                  setState(() => _isCurrent = v);
                  _markDirty();
                },
              ),
            ],
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
              label: const Text('Delete project…'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTokens.danger,
                side: const BorderSide(color: AppTokens.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.inputRadius),
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SubmitBar(
        label: _saving
            ? 'Saving…'
            : (_slugError != null
                ? 'Fix 1 error'
                : (_isCreate ? 'Create project' : 'Save changes')),
        onPressed:
            (_saving || !_canSave || (!_dirty && !_isCreate)) ? null : _save,
      ),
    );
  }
}

// ───────────────────────────────────────── components

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'COVER IMAGE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTokens.inkDim,
                letterSpacing: 0.04 * 12,
              ),
            ),
            const Spacer(),
            Text(
              '1600 × 900',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.5,
                letterSpacing: 0.04 * 10.5,
                color: AppTokens.inkMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
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
                    fallbackText: fallbackText,
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(LucideIcons.image,
                                size: 13, color: AppTokens.ink),
                            SizedBox(width: 6),
                            Text(
                              'Replace',
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
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.hintNote,
    this.errorText,
    this.multiline = false,
    this.mono = false,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? hintNote;
  final String? errorText;
  final bool multiline;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTokens.inkDim,
                letterSpacing: 0.04 * 12,
              ),
            ),
            const Spacer(),
            if (hintNote != null)
              Text(
                hintNote!,
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
          controller: controller,
          maxLines: multiline ? 4 : 1,
          style: mono
              ? GoogleFonts.jetBrainsMono(fontSize: 13, color: AppTokens.ink)
              : null,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}

class _StacksField extends StatefulWidget {
  const _StacksField({required this.stacks, required this.onChanged});
  final List<String> stacks;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_StacksField> createState() => _StacksFieldState();
}

class _StacksFieldState extends State<_StacksField> {
  final _ctl = TextEditingController();
  final _focus = FocusNode();

  void _add(String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    if (widget.stacks.contains(v)) {
      _ctl.clear();
      return;
    }
    widget.onChanged([...widget.stacks, v]);
    _ctl.clear();
  }

  void _remove(String value) {
    widget.onChanged(widget.stacks.where((s) => s != value).toList());
  }

  @override
  void dispose() {
    _ctl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'STACKS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTokens.inkDim,
            letterSpacing: 0.04 * 12,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _focus.requestFocus(),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            constraints: const BoxConstraints(minHeight: 44),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.inputRadius),
              border: Border.all(color: AppTokens.line),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...widget.stacks.map((s) => _Chip(value: s, onRemove: () => _remove(s))),
                IntrinsicWidth(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 80),
                    child: TextField(
                      controller: _ctl,
                      focusNode: _focus,
                      textInputAction: TextInputAction.done,
                      onSubmitted: _add,
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 11.5, color: AppTokens.ink),
                      decoration: const InputDecoration(
                        hintText: 'Add…',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.value, required this.onRemove});
  final String value;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
      decoration: BoxDecoration(
        color: AppTokens.surfaceHi,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTokens.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11.5,
              color: AppTokens.ink,
              letterSpacing: -0.01 * 11.5,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(3),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: Icon(LucideIcons.x, size: 11, color: AppTokens.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRowGroup extends StatelessWidget {
  const _ToggleRowGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.inputRadius),
        border: Border.all(color: AppTokens.line),
      ),
      child: Column(
        children: List.generate(children.length, (i) {
          return Column(
            children: [
              children[i],
              if (i < children.length - 1)
                Divider(color: AppTokens.line, height: 1),
            ],
          );
        }),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    this.sub,
    this.value,
    required this.on,
    required this.onChanged,
  });
  final String label;
  final String? sub;
  final String? value;
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.ink,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppTokens.inkMuted),
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            Text(
              value!,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.5,
                letterSpacing: 0.04 * 10.5,
                color: on ? AppTokens.accent : AppTokens.inkMuted,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Switch(
            value: on,
            onChanged: onChanged,
            activeColor: AppTokens.onAccent,
            activeTrackColor: AppTokens.accent,
            inactiveThumbColor: AppTokens.inkMuted,
            inactiveTrackColor: AppTokens.surfaceHi,
            trackOutlineColor:
                WidgetStateProperty.resolveWith((_) => AppTokens.line),
          ),
        ],
      ),
    );
  }
}
