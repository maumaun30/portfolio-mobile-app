import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/tokens.dart';

/// Destructive-action confirm bottom sheet.
/// Requires the user to retype `slug` (or any identifier) before the
/// confirm button enables.
class ConfirmDeleteSheet extends StatefulWidget {
  const ConfirmDeleteSheet({
    super.key,
    required this.title,
    required this.description,
    required this.confirmText,
    this.confirmLabel = 'Delete',
  });

  final String title;
  final String description;

  /// The string the user must type verbatim to enable the confirm button.
  final String confirmText;
  final String confirmLabel;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String description,
    required String confirmText,
    String confirmLabel = 'Delete',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      barrierColor: const Color.fromRGBO(10, 9, 7, 0.7),
      builder: (_) => ConfirmDeleteSheet(
        title: title,
        description: description,
        confirmText: confirmText,
        confirmLabel: confirmLabel,
      ),
    );
  }

  @override
  State<ConfirmDeleteSheet> createState() => _ConfirmDeleteSheetState();
}

class _ConfirmDeleteSheetState extends State<ConfirmDeleteSheet> {
  late final TextEditingController _ctl;
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController()
      ..addListener(() {
        final m = _ctl.text == widget.confirmText;
        if (m != _matches) setState(() => _matches = m);
      });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        padding:
            EdgeInsets.fromLTRB(22, 12, 22, 24 + mq.padding.bottom * 0.5),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          border: Border(top: BorderSide(color: AppTokens.lineStrong)),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 4, bottom: 18),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.lineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTokens.danger10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.trash2,
                      color: AppTokens.danger, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTokens.inkDim,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTokens.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTokens.line),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle,
                      size: 13, color: AppTokens.inkMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Type the identifier to confirm',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppTokens.inkMuted,
                        letterSpacing: 0.02 * 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctl,
              autofocus: true,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                color: AppTokens.ink,
              ),
              decoration: InputDecoration(hintText: widget.confirmText),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _matches
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTokens.danger,
                      foregroundColor: const Color(0xFFFFECE4),
                      disabledBackgroundColor: AppTokens.surfaceHi,
                      disabledForegroundColor: AppTokens.inkMuted,
                    ),
                    child: Text(widget.confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
