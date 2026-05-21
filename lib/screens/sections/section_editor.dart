import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../api/sections_api.dart';
import '../../theme/tokens.dart';
import '../../widgets/error_state.dart';
import '../../widgets/section_label.dart';
import '../../widgets/submit_bar.dart';
import 'sections_list.dart';

class SectionEditorScreen extends ConsumerWidget {
  const SectionEditorScreen({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = sectionEntries.firstWhere(
      (s) => s.id == name,
      orElse: () => SectionEntry(
        id: name,
        label: name,
        sub: '— UNKNOWN',
        icon: LucideIcons.fileQuestion,
      ),
    );
    final async = ref.watch(sectionPayloadProvider(name));
    return async.when(
      data: (payload) => _Editor(entry: entry, initial: payload),
      loading: () => Scaffold(
        backgroundColor: AppTokens.bg,
        appBar: AppBar(title: Text(entry.label)),
        body: const Center(
            child: CircularProgressIndicator(color: AppTokens.accent)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTokens.bg,
        appBar: AppBar(title: Text(entry.label)),
        body: ErrorPanel(
          title: "Couldn't load section",
          description: e.toString(),
          onRetry: () => ref.invalidate(sectionPayloadProvider(name)),
        ),
      ),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.entry, required this.initial});
  final SectionEntry entry;
  final dynamic initial;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final TextEditingController _ctl;
  late String _originalText;
  bool _saving = false;
  List<String> _errors = const [];

  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  void initState() {
    super.initState();
    _originalText = _encoder.convert(widget.initial ?? <String, dynamic>{});
    _ctl = TextEditingController(text: _originalText)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  bool get _dirty => _ctl.text != _originalText;

  String? _localJsonError() {
    final t = _ctl.text.trim();
    if (t.isEmpty) return 'Empty payload — must be a JSON object.';
    try {
      jsonDecode(t);
      return null;
    } on FormatException catch (e) {
      return 'Invalid JSON: ${e.message}';
    }
  }

  Future<void> _save() async {
    final localErr = _localJsonError();
    if (localErr != null) {
      setState(() => _errors = [localErr]);
      return;
    }
    setState(() {
      _saving = true;
      _errors = const [];
    });
    try {
      final decoded = jsonDecode(_ctl.text);
      await ref
          .read(sectionsApiProvider)
          .save(widget.entry.id, decoded);
      ref.invalidate(sectionPayloadProvider(widget.entry.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTokens.surface,
            duration: const Duration(seconds: 2),
            content: Text(
              '${widget.entry.label} saved',
              style: const TextStyle(color: AppTokens.ink),
            ),
          ),
        );
        setState(() {
          _originalText = _ctl.text;
          _saving = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errors = issuesFromDioError(e);
        _saving = false;
      });
    }
  }

  void _reformat() {
    try {
      final decoded = jsonDecode(_ctl.text);
      _ctl.text = _encoder.convert(decoded);
      setState(() => _errors = const []);
    } on FormatException catch (e) {
      setState(() => _errors = ['Invalid JSON: ${e.message}']);
    }
  }

  void _revert() {
    _ctl.text = _originalText;
    setState(() => _errors = const []);
  }

  @override
  Widget build(BuildContext context) {
    final localErr = _localJsonError();
    final canSave = _dirty && localErr == null && !_saving;

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        title: Text(widget.entry.label),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Reformat JSON',
            icon: const Icon(LucideIcons.alignLeft, size: 18),
            onPressed: _reformat,
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(LucideIcons.copy, size: 18),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _ctl.text));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTokens.surface,
                  duration: Duration(seconds: 1),
                  content: Text('Copied',
                      style: TextStyle(color: AppTokens.ink)),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTokens.line),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTokens.gutter, 16, AppTokens.gutter, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(widget.entry.sub.replaceAll('— ', '')),
                const SizedBox(height: 8),
                Text(
                  'JSON payload',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: AppTokens.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Server-side Zod validates this on save. Schema mismatches return field-level errors below.',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: AppTokens.inkDim,
                      height: 1.5),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTokens.gutter, 8, AppTokens.gutter, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTokens.surface,
                  borderRadius:
                      BorderRadius.circular(AppTokens.inputRadius),
                  border: Border.all(color: AppTokens.line),
                ),
                child: TextField(
                  controller: _ctl,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12.5,
                    color: AppTokens.ink,
                    height: 1.55,
                  ),
                  decoration: const InputDecoration(
                    filled: false,
                    contentPadding: EdgeInsets.all(14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: '{ ... }',
                  ),
                ),
              ),
            ),
          ),
          if (_errors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTokens.gutter, 4, AppTokens.gutter, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTokens.danger10,
                  borderRadius:
                      BorderRadius.circular(AppTokens.inputRadius),
                  border:
                      Border.all(color: AppTokens.danger.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_errors.length} error${_errors.length == 1 ? '' : 's'}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        letterSpacing: 0.04 * 11,
                        color: AppTokens.danger,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._errors.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '· $e',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: AppTokens.danger,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SubmitBar(
        label: _saving
            ? 'Saving…'
            : (localErr != null
                ? 'Fix JSON'
                : (_dirty ? 'Save section' : 'No changes')),
        onPressed: canSave ? _save : null,
        secondaryLabel: _dirty ? 'Revert' : null,
        onSecondary: _dirty ? _revert : null,
      ),
    );
  }
}
