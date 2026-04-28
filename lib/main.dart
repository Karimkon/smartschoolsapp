import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'core/services/api_service.dart';
import 'core/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A1628),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  ApiService().init();

  // Pre-load auth before runApp so the router sees the correct state immediately
  // and never needs to recreate itself when auth changes.
  final container = ProviderContainer();
  await container.read(authProvider.notifier).tryAutoLogin();

  runApp(UncontrolledProviderScope(container: container, child: const SmartSchoolsApp()));
}

class SmartSchoolsApp extends ConsumerWidget {
  const SmartSchoolsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Smart Schools',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
