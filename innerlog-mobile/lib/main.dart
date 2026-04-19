import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/offline_queue.dart';
import 'core/l10n/app_localizations.dart';
import 'core/providers.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };

    // Sync offline check-ins in background
    _syncOfflineCheckins();

    runApp(const ProviderScope(child: InnerLogApp()));
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrint('$stack');
  });
}

Future<void> _syncOfflineCheckins() async {
  try {
    final count = await OfflineQueue.syncAll();
    if (count > 0) {
      debugPrint('Synced $count offline check-ins');
    }
  } catch (_) {}
}

class InnerLogApp extends ConsumerWidget {
  const InnerLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'InnerLog',
      theme: innerLogTheme,
      darkTheme: innerLogDarkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      // Localization
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Global error widget replacement
        ErrorWidget.builder = (details) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('😵', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context).errorOccurred, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context).tryAgain, style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ),
        );
        return child ?? const SizedBox();
      },
    );
  }
}
