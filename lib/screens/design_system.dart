import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/section_label.dart';
import '../widgets/status_badge.dart';

class DesignSystemScreen extends StatelessWidget {
  const DesignSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Design system',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.gutter,
          18,
          AppTokens.gutter,
          32,
        ),
        children: [
          const SectionLabel('Foundations'),
          const SizedBox(height: 10),
          Text(
            'Tokens & components',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: AppTokens.ink,
            ),
          ),
          const SizedBox(height: 22),
          const SectionLabel('Color'),
          const SizedBox(height: 10),
          const _Swatch(name: 'bg', color: AppTokens.bg),
          const _Swatch(name: 'surface', color: AppTokens.surface),
          const _Swatch(name: 'surfaceHi', color: AppTokens.surfaceHi),
          const _Swatch(name: 'ink', color: AppTokens.ink),
          const _Swatch(name: 'inkDim', color: AppTokens.inkDim),
          const _Swatch(name: 'inkMuted', color: AppTokens.inkMuted),
          const _Swatch(name: 'accent', color: AppTokens.accent),
          const _Swatch(name: 'danger', color: AppTokens.danger),
          const SizedBox(height: 22),
          const SectionLabel('Type'),
          const SizedBox(height: 10),
          Text('Display 28/600 -0.6',
              style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.6,
                  color: AppTokens.ink)),
          const SizedBox(height: 6),
          Text('Title 22/600 -0.4',
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: AppTokens.ink)),
          const SizedBox(height: 6),
          Text('Body 15/1.5',
              style: GoogleFonts.inter(
                  fontSize: 15, color: AppTokens.ink, height: 1.5)),
          const SizedBox(height: 6),
          Text(
            '— LABEL · MONO 10.5',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              letterSpacing: 0.06 * 10.5,
              color: AppTokens.inkMuted,
            ),
          ),
          const SizedBox(height: 22),
          const SectionLabel('Buttons'),
          const SizedBox(height: 10),
          FilledButton(onPressed: () {}, child: const Text('Primary pill')),
          const SizedBox(height: 10),
          OutlinedButton(
              onPressed: () {}, child: const Text('Secondary outlined')),
          const SizedBox(height: 10),
          TextButton(onPressed: () {}, child: const Text('Tertiary text')),
          const SizedBox(height: 22),
          const SectionLabel('Status badges'),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 8,
            children: [
              StatusBadge(label: 'Published', tone: BadgeTone.published),
              StatusBadge(label: 'Draft', tone: BadgeTone.draft),
              StatusBadge(label: 'Error', tone: BadgeTone.danger),
            ],
          ),
          const SizedBox(height: 22),
          const SectionLabel('Inputs'),
          const SizedBox(height: 10),
          const TextField(
            decoration: InputDecoration(hintText: 'Title'),
          ),
          const SizedBox(height: 10),
          const TextField(
            maxLines: 4,
            decoration: InputDecoration(hintText: 'Excerpt'),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.inputRadius),
        border: Border.all(color: AppTokens.line),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: AppTokens.line),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12.5,
              color: AppTokens.ink,
            ),
          ),
          const Spacer(),
          Text(
            '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: AppTokens.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
