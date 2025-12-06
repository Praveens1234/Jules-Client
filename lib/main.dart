import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jules_client/screens/onboarding_screen.dart';
import 'package:jules_client/screens/dashboard_screen.dart';
import 'package:jules_client/services/storage_service.dart';
import 'package:jules_client/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: JulesApp()));
}

class JulesApp extends ConsumerWidget {
  const JulesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initStatus = ref.watch(initializationProvider);

    return MaterialApp(
      title: 'Jules Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: initStatus.when(
        data: (isLoggedIn) => isLoggedIn ? const DashboardScreen() : const OnboardingScreen(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      ),
    );
  }
}

final initializationProvider = FutureProvider<bool>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  final apiKey = await storage.getApiKey();
  return apiKey != null && apiKey.isNotEmpty;
});
