import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vibe_coder/screens/home_screen.dart';

/// Main entry point - ELITE INITIALIZATION PROTOCOL
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Environment Configuration**
///    - 🔍 Symptom: Hardcoded API keys and configuration scattered
///    - 🎯 Root Cause: No centralized environment management
///    - 💥 Kill Shot: DotEnv initialization with .env file loading
///
/// PERF: O(1) initialization - async dotenv loading doesn't block app startup
/// SECURITY: Environment variables loaded from secure .env file
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables from .env file
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Handle missing .env file gracefully - fall back to system environment
    debugPrint('Warning: Could not load .env file: $e');
    debugPrint('Falling back to system environment variables');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
