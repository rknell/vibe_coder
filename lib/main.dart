import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vibe_coder/screens/discord_home_screen.dart';
import 'package:vibe_coder/services/services.dart';
import 'package:vibe_coder/models/layout_preferences_model.dart';

/// Main entry point - DISCORD-STYLE INITIALIZATION PROTOCOL
///
/// ## 🏆 MISSION ACCOMPLISHED
/// **DISCORD-STYLE THREE-PANEL LAYOUT** with real-time MCP integration,
/// agent-centric workflow, and professional theme system.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | DiscordHomeScreen | Complete Discord UI | Migration effort | CHOSEN - epic completion |
/// | LayoutService Integration | Theme persistence | Service dependency | CHOSEN - professional UX |
/// | Environment Loading | Secure config | File dependency | CHOSEN - production ready |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Discord Redesign Integration**
///    - 🔍 Symptom: Old HomeScreen still in use after epic completion
///    - 🎯 Root Cause: Main.dart not updated to use new DiscordHomeScreen
///    - 💥 Kill Shot: Switch to DiscordHomeScreen with LayoutService integration
///
/// 2. **Theme System Integration**
///    - 🔍 Symptom: Static theme without user preferences
///    - 🎯 Root Cause: No LayoutService integration for theme management
///    - 💥 Kill Shot: LayoutService initialization with theme coordination
///
/// 3. **Service Initialization**
///    - 🔍 Symptom: Services not available for Discord layout
///    - 🎯 Root Cause: Services initialization not coordinated with app startup
///    - 💥 Kill Shot: Services initialization before DiscordHomeScreen creation
///
/// PERF: O(1) initialization - async services and dotenv loading
/// SECURITY: Environment variables loaded from secure .env file
/// ARCHITECTURAL: LayoutService integration for theme persistence
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

  // Initialize services for Discord layout coordination
  // This ensures LayoutService is available for theme management
  try {
    final layoutService = services.layoutService;
    debugPrint(
        '🎨 Main: LayoutService initialized - Theme: ${layoutService.currentTheme}');
  } catch (e) {
    debugPrint('⚠️ Main: Services initialization issue: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: services.layoutService,
      builder: (context, child) {
        final layoutService = services.layoutService;
        final isDarkTheme = layoutService.currentTheme == AppTheme.dark;

        return MaterialApp(
          title: 'VibeCoder - Discord-Style AI Agent',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: isDarkTheme ? Brightness.dark : Brightness.light,
            ),
            useMaterial3: true,
          ),
          home: const DiscordHomeScreen(),
        );
      },
    );
  }
}
