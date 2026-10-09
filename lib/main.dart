import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final brightness = await ThemeController.load();
  AppTokens.use(paletteFor(brightness));
  runApp(ProviderScope(
    overrides: [
      themeControllerProvider
          .overrideWith((ref) => ThemeController(brightness)),
    ],
    child: const PortfolioAdminApp(),
  ));
}

void _applySystemChrome() {
  final iconBrightness =
      AppTokens.isDark ? Brightness.light : Brightness.dark;
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: AppTokens.palette.brightness, // iOS
      systemNavigationBarColor: AppTokens.bg,
      systemNavigationBarIconBrightness: iconBrightness,
    ),
  );
}

class PortfolioAdminApp extends ConsumerStatefulWidget {
  const PortfolioAdminApp({super.key});

  @override
  ConsumerState<PortfolioAdminApp> createState() => _PortfolioAdminAppState();
}

class _PortfolioAdminAppState extends ConsumerState<PortfolioAdminApp> {
  @override
  void initState() {
    super.initState();
    _applySystemChrome();
  }

  /// Most widgets read [AppTokens] directly instead of `Theme.of`, so they
  /// don't rebuild when the ThemeData changes. Swap the palette, then mark
  /// the whole tree dirty — keeps route/form state, unlike re-keying.
  void _onThemeChanged(Brightness b) {
    AppTokens.use(paletteFor(b));
    _applySystemChrome();
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Brightness>(themeControllerProvider, (_, b) => _onThemeChanged(b));
    final brightness = ref.watch(themeControllerProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Mau Portfolio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(paletteFor(brightness)),
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
    );
  }
}
