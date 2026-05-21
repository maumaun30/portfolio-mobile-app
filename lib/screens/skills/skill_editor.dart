import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../api/skills_api.dart';
import '../../models/skill.dart';
import '../../theme/tokens.dart';
import '../../widgets/confirm_sheet.dart';
import '../../widgets/error_state.dart';
import '../../widgets/section_label.dart';
import '../../widgets/simpleicon.dart';
import '../../widgets/submit_bar.dart';

class SkillEditorScreen extends ConsumerWidget {
  const SkillEditorScreen({super.key, this.id});
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (id == null) return const _Editor(skill: null);
    final async = ref.watch(skillByIdProvider(id!));
    return async.when(
      data: (s) => _Editor(skill: s),
      loading: () => const Scaffold(
        backgroundColor: AppTokens.bg,
        body: Center(
            child: CircularProgressIndicator(color: AppTokens.accent)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTokens.bg,
        appBar: AppBar(title: const Text('Edit skill')),
        body: ErrorPanel(
          title: "Couldn't load skill",
          description: e.toString(),
          onRetry: () => ref.invalidate(skillByIdProvider(id!)),
        ),
      ),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.skill});
  final Skill? skill;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final TextEditingController _slug;
  late final TextEditingController _label;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _slug = TextEditingController(text: widget.skill?.slug ?? '');
    _label = TextEditingController(text: widget.skill?.label ?? '');
    _slug.addListener(() => setState(() {}));
    _label.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _slug.dispose();
    _label.dispose();
    super.dispose();
  }

  bool get _isCreate => widget.skill == null;
  bool get _canSave =>
      _slug.text.trim().isNotEmpty && _label.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final api = ref.read(skillsApiProvider);
    try {
      if (_isCreate) {
        await api.create(
            slug: _slug.text.trim(), label: _label.text.trim());
      } else {
        await api.update(widget.skill!.id,
            slug: _slug.text.trim(), label: _label.text.trim());
      }
      ref.invalidate(skillsListProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final s = widget.skill;
    if (s == null) return;
    final confirmed = await ConfirmDeleteSheet.show(
      context,
      title: 'Delete this skill?',
      description: 'It will disappear from the home stacks list.',
      confirmText: s.slug,
    );
    if (confirmed != true) return;
    try {
      await ref.read(skillsApiProvider).delete(s.id);
      ref.invalidate(skillsListProvider);
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

  @override
  Widget build(BuildContext context) {
    final previewSlug = _slug.text.trim();
    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        title: Text(_isCreate ? 'New skill' : 'Edit skill'),
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
          const SizedBox(height: 14),
          // Live preview tile
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.cardRadius),
              border: Border.all(color: AppTokens.line),
            ),
            child: Row(
              children: [
                SimpleIcon(
                  slug: previewSlug.isEmpty ? 'github' : previewSlug,
                  fallbackLabel:
                      _label.text.isEmpty ? '?' : _label.text,
                  size: 44,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label.text.isEmpty ? 'Display label' : _label.text,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _label.text.isEmpty
                              ? AppTokens.inkDim
                              : AppTokens.ink,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        previewSlug.isEmpty
                            ? 'simpleicons.org / brand-slug'
                            : 'simpleicons.org / $previewSlug',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: AppTokens.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _Label('SIMPLE-ICONS SLUG'),
          const SizedBox(height: 8),
          TextField(
            controller: _slug,
            autocorrect: false,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 13, color: AppTokens.ink),
            decoration: const InputDecoration(
              hintText: 'nextdotjs',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Must match a brand slug at simpleicons.org (lowercase, no spaces).',
            style: TextStyle(
                fontSize: 11.5, color: AppTokens.inkMuted),
          ),
          const SizedBox(height: 14),
          _Label('DISPLAY LABEL'),
          const SizedBox(height: 8),
          TextField(
            controller: _label,
            decoration: const InputDecoration(hintText: 'Next.js'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 18),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTokens.danger10,
                borderRadius: BorderRadius.circular(AppTokens.inputRadius),
                border:
                    Border.all(color: AppTokens.danger.withOpacity(0.3)),
              ),
              child: Text(
                _error!,
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
              label: const Text('Delete skill…'),
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
      bottomNavigationBar: SubmitBar(
        label: _saving
            ? 'Saving…'
            : (_isCreate ? 'Create skill' : 'Save changes'),
        onPressed: (_saving || !_canSave) ? null : _save,
      ),
    );
  }
}

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
