import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../api/api_client.dart';
import '../auth/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../site.dart';
import '../theme/theme_controller.dart';
import '../theme/tokens.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/section_label.dart';

const _appVersion = '0.1.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(authControllerProvider).value;
    final signedIn = token != null && token.isNotEmpty;
    final isDark = ref.watch(themeControllerProvider) == Brightness.dark;

    return ScreenScaffold(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppTokens.gutter, 18, AppTokens.gutter, 24),
        children: [
          const SectionLabel('Account'),
          const SizedBox(height: 10),
          _Group(
            children: [
              _Row(
                icon: LucideIcons.userCircle,
                label: 'Signed in',
                value: signedIn ? 'GITHUB' : 'NOT SIGNED IN',
                tone: signedIn ? AppTokens.accent : AppTokens.inkMuted,
              ),
              _Row(
                icon: LucideIcons.key,
                label: 'API token',
                value: signedIn ? _maskToken(token) : '—',
                mono: true,
                onTap: signedIn
                    ? () async {
                        await Clipboard.setData(
                            ClipboardData(text: token));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTokens.surface,
                            duration: Duration(seconds: 1),
                            content: Text(
                              'Token copied',
                              style: TextStyle(color: AppTokens.ink),
                            ),
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionLabel('Environment'),
          const SizedBox(height: 10),
          _Group(
            children: [
              _Row(
                icon: LucideIcons.server,
                label: 'API base URL',
                value: apiBaseUrl,
                mono: true,
              ),
              _Row(
                icon: LucideIcons.smartphone,
                label: 'App version',
                value: 'v$_appVersion',
                mono: true,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionLabel('Appearance'),
          const SizedBox(height: 10),
          _Group(
            children: [
              _Row(
                icon: isDark ? LucideIcons.moon : LucideIcons.sun,
                label: 'Dark mode',
                value: isDark ? 'GOLD NOIR' : 'PAPER LIGHT',
                tone: AppTokens.accent,
                trailing: Switch(
                  value: isDark,
                  activeColor: AppTokens.onAccent,
                  activeTrackColor: AppTokens.accent,
                  inactiveThumbColor: AppTokens.inkMuted,
                  inactiveTrackColor: AppTokens.surfaceHi,
                  trackOutlineColor:
                      WidgetStatePropertyAll(AppTokens.line),
                  onChanged: (v) => ref
                      .read(themeControllerProvider.notifier)
                      .set(v ? Brightness.dark : Brightness.light),
                ),
                onTap: () =>
                    ref.read(themeControllerProvider.notifier).toggle(),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionLabel('Links'),
          const SizedBox(height: 10),
          _Group(
            children: [
              _Row(
                icon: LucideIcons.palette,
                label: 'Design system',
                trailing: Icon(LucideIcons.chevronRight,
                    size: 16, color: AppTokens.inkMuted),
                onTap: () => context.push('/design-system'),
              ),
              _Row(
                icon: LucideIcons.globe,
                label: 'Visit portfolio',
                value: Uri.parse(siteUrl).host.replaceFirst('www.', ''),
                mono: true,
                trailing: Icon(LucideIcons.externalLink,
                    size: 16, color: AppTokens.inkMuted),
                onTap: () => _open(context, siteUrl),
              ),
              _Row(
                icon: LucideIcons.externalLink,
                label: 'Open admin on web',
                value: 'BROWSER',
                onTap: () => _open(context, '$siteUrl/admin'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (signedIn)
            OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context, ref),
              icon: const Icon(LucideIcons.logOut, size: 16),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTokens.danger,
                side: BorderSide(color: AppTokens.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.inputRadius),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      barrierColor: AppTokens.scrim,
      builder: (ctx) => _SignOutSheet(),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

class _SignOutSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
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
          Text(
            'Sign out?',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTokens.ink,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "We'll forget your API token. You can sign back in with GitHub anytime.",
            style: TextStyle(
                fontSize: 13, color: AppTokens.inkDim, height: 1.5),
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
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTokens.danger,
                    foregroundColor: const Color(0xFFFFECE4),
                  ),
                  child: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
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
                Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: Divider(color: AppTokens.line, height: 1),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.value,
    this.tone,
    this.mono = false,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String? value;
  final Color? tone;
  final bool mono;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTokens.inkDim),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.ink,
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: mono
                        ? GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            letterSpacing: 0.02 * 11,
                            color: tone ?? AppTokens.inkMuted,
                          )
                        : TextStyle(
                            fontSize: 11.5,
                            color: tone ?? AppTokens.inkMuted,
                          ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
    if (onTap == null) return body;
    return InkWell(onTap: onTap, child: body);
  }
}

String _maskToken(String token) {
  if (token.length <= 8) return token;
  return '${token.substring(0, 4)}…${token.substring(token.length - 4)}';
}
