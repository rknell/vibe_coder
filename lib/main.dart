import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vibe_coder/screens/discord_home_screen.dart';
import 'package:vibe_coder/services/services.dart';
import 'package:vibe_coder/models/layout_preferences_model.dart';
import 'package:logging/logging.dart';

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
///    - 💥 Kill Shot: Full service initialization chain with proper error handling
///
/// PERF: O(1) initialization - async services and dotenv loading
/// SECURITY: Environment variables loaded from secure .env file
/// ARCHITECTURAL: Complete service initialization before app startup
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  final logger = Logger('Main');
  logger.info('🚀 VIBE CODER: Starting application initialization');

  try {
    // Load environment variables from .env file
    await dotenv.load(fileName: ".env");
    logger.info('✅ ENVIRONMENT: Loaded configuration from .env file');
  } catch (e) {
    // Handle missing .env file gracefully - fall back to system environment
    logger.warning('⚠️ ENVIRONMENT: Could not load .env file: $e');
    logger.info('🔄 ENVIRONMENT: Falling back to system environment variables');
  }

  try {
    // Initialize all services in proper sequence
    logger.info('🔄 SERVICES: Starting service initialization chain');
    await services.initialize();
    logger.info('✅ SERVICES: All services initialized successfully');

    // Verify critical services
    if (!services.configurationService.isInitialized) {
      throw Exception('Configuration service failed to initialize');
    }
    if (!services.mcpService.isInitialized) {
      logger.warning(
          '⚠️ MCP SERVICE: Not initialized - some features may be limited');
    }
    if (!services.agentService.isInitialized) {
      throw Exception('Agent service failed to initialize');
    }

    logger.info('🎯 INITIALIZATION: Complete - starting application');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    logger.severe(
        '💥 FATAL ERROR: Service initialization failed', e, stackTrace);
    // Show error screen instead of crashing
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to Start VibeCoder',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $e',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Retry initialization
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
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
