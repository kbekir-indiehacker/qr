import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/providers/data_providers.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const ProviderScope(child: BusinessCardApp()));
}

class BusinessCardApp extends ConsumerWidget {
  const BusinessCardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final theme = ref.watch(themeDataProvider);
    
    return MaterialApp(
      title: 'Business Card App',
      theme: theme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MainScreen(),
    );
  }
}
