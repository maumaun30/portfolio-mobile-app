import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/tokens.dart';
import 'section_label.dart';

class _NavItem {
  const _NavItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

const _items = <_NavItem>[
  _NavItem('Dashboard', LucideIcons.layoutDashboard, '/'),
  _NavItem('Projects', LucideIcons.folderKanban, '/projects'),
  _NavItem('Skills', LucideIcons.sparkles, '/skills'),
  _NavItem('Posts', LucideIcons.fileText, '/posts'),
  _NavItem('Keywords', LucideIcons.tag, '/keywords'),
  _NavItem('Sections', LucideIcons.layoutTemplate, '/sections'),
];

const _secondary = <_NavItem>[
  _NavItem('Notifications', LucideIcons.bell, '/notifications'),
  _NavItem('Search', LucideIcons.search, '/search'),
  _NavItem('Design system', LucideIcons.palette, '/design-system'),
  _NavItem('Settings', LucideIcons.settings, '/settings'),
];

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute =
        GoRouterState.of(context).uri.path == '' ? '/' : GoRouterState.of(context).uri.path;
    final media = MediaQuery.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppTokens.gutter,
                16,
                AppTokens.gutter,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Studio'),
                  const SizedBox(height: 8),
                  Text(
                    'Portfolio CMS',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Maurico Maun',
                    style: TextStyle(fontSize: 12, color: AppTokens.inkDim),
                  ),
                ],
              ),
            ),
            Divider(color: AppTokens.line, height: 1),
            const SizedBox(height: 8),
            ..._items.map((i) => _Row(item: i, active: i.route == currentRoute)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.gutter),
              child: const SectionLabel('Tools'),
            ),
            const SizedBox(height: 6),
            ..._secondary
                .map((i) => _Row(item: i, active: i.route == currentRoute)),
            const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppTokens.gutter,
                12,
                AppTokens.gutter,
                12 + media.padding.bottom * 0.5,
              ),
              child: Text(
                'v0.1.0',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  color: AppTokens.inkMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.active});
  final _NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        context.go(item.route);
      },
      child: Stack(
        children: [
          if (active)
            Positioned(
              left: 0,
              top: 6,
              bottom: 6,
              child: Container(width: 3, color: AppTokens.accent),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.gutter,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: active ? AppTokens.accent : AppTokens.inkDim,
                ),
                const SizedBox(width: 14),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: active ? AppTokens.ink : AppTokens.inkDim,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
