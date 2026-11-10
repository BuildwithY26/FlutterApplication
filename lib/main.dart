import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase when keys are provided
  try {
    if (DefaultFirebaseOptions.web.apiKey != 'YOUR_API_KEY') {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Enable offline persistence with unlimited cache
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Sign in anonymously for secure Firestore session
      try {
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously();
        }
      } catch (authErr) {
        debugPrint('Anonymous auth notice: $authErr');
      }

      debugPrint('Firebase connected with offline persistence enabled.');
    } else {
      debugPrint('Running with in-memory persistence. To connect Firebase, update lib/firebase_options.dart');
    }
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
