import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Sticky bottom save bar — used by every editor screen.
/// Caller supplies the label and the onPressed; pass null to disable.
class SubmitBar extends StatelessWidget {
  const SubmitBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTokens.gutter,
        12,
        AppTokens.gutter,
        12 + media.padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTokens.bg,
        border: Border(top: BorderSide(color: AppTokens.line)),
      ),
      child: Row(
        children: [
          if (secondaryLabel != null) ...[
            Expanded(
              flex: 0,
              child: OutlinedButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel!),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: FilledButton(
              onPressed: onPressed,
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
