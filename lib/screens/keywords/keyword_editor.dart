import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../api/keywords_api.dart';
import '../../models/keyword.dart';
import '../../theme/tokens.dart';
import '../../widgets/confirm_sheet.dart';
import '../../widgets/error_state.dart';
import '../../widgets/section_label.dart';
import '../../widgets/submit_bar.dart';

class KeywordEditorScreen extends ConsumerWidget {
  const KeywordEditorScreen({super.key, this.id});
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (id == null) return const _Editor(keyword: null);
    final async = ref.watch(keywordByIdProvider(id!));
    return async.when(
      data: (k) => _Editor(keyword: k),
      loading: () => const Scaffold(
        backgroundColor: AppTokens.bg,
        body: Center(
            child: CircularProgressIndicator(color: AppTokens.accent)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTokens.bg,
        appBar: AppBar(title: const Text('Edit keyword')),
        body: ErrorPanel(
          title: "Couldn't load keyword",
          description: e.toString(),
          onRetry: () => ref.invalidate(keywordByIdProvider(id!)),
        ),
      ),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.keyword});
  final Keyword? keyword;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final TextEditingController _term;
  late bool _enabled;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _term = TextEditingController(text: widget.keyword?.term ?? '');
    _enabled = widget.keyword?.enabled ?? true;
  }

  @override
  void dispose() {
    _term.dispose();
    super.dispose();
  }

  bool get _isCreate => widget.keyword == null;

  Future<void> _save() async {
    final term = _term.text.trim();
    if (term.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final api = ref.read(keywordsApiProvider);
      if (_isCreate) {
        await api.create(term: term, enabled: _enabled);
      } else {
        await api.update(widget.keyword!.id,
            term: term, enabled: _enabled);
      }
      ref.invalidate(keywordsListProvider);
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
    final k = widget.keyword;
    if (k == null) return;
    final confirmed = await ConfirmDeleteSheet.show(
      context,
      title: 'Delete this keyword?',
      description:
          'The cron will stop generating posts for this term. Existing posts are not affected.',
      confirmText: k.term,
    );
    if (confirmed != true) return;
    try {
      await ref.read(keywordsApiProvider).delete(k.id);
      ref.invalidate(keywordsListProvider);
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
    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        title: Text(_isCreate ? 'New keyword' : 'Edit keyword'),
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
            _term.text.isEmpty ? 'Untitled' : _term.text.toLowerCase(),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: _term.text.isEmpty ? AppTokens.inkDim : AppTokens.ink,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'TERM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTokens.inkDim,
              letterSpacing: 0.04 * 12,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _term,
            autofocus: _isCreate,
            decoration: const InputDecoration(
              hintText: 'drizzle orm performance',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          Text(
            'A short topic phrase Claude will turn into a blog post.',
            style: TextStyle(
                fontSize: 11.5, color: AppTokens.inkMuted),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.inputRadius),
              border: Border.all(color: AppTokens.line),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enabled',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTokens.ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Eligible for the weekly cron pick.',
                        style: TextStyle(
                            fontSize: 11.5, color: AppTokens.inkMuted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
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
                style:
                    const TextStyle(color: AppTokens.danger, fontSize: 12.5),
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
              label: const Text('Delete keyword…'),
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
            : (_isCreate ? 'Create keyword' : 'Save changes'),
        onPressed:
            (_saving || _term.text.trim().isEmpty) ? null : _save,
      ),
    );
  }
}
