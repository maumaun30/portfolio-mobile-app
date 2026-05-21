import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTokens.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: PortfolioAdminApp()));
}

class PortfolioAdminApp extends ConsumerWidget {
  const PortfolioAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Portfolio CMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      routerConfig: router,
    );
  }
}
