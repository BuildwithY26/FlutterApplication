import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safely initialize Firebase if configuration exists
  try {
    await Firebase.initializeApp();
    
    // Enable offline persistence with unlimited cache
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e (Running in local-ready mode)');
  }

  runApp(
    const ProviderScope(
      child: AiKnowledgeBaseApp(),
    ),
  );
}

class AiKnowledgeBaseApp extends ConsumerWidget {
  const AiKnowledgeBaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'AI Response Knowledge Base',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light,
      home: const DashboardScreen(),
    );
  }
}
