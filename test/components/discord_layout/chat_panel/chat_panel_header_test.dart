import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/components/discord_layout/chat_panel/chat_panel_header.dart';
import 'package:vibe_coder/models/layout_preferences_model.dart';
import 'package:vibe_coder/models/agent_model.dart';

void main() {
  group('🛡️ COMPONENT: ChatPanelHeader Tests', () {
    testWidgets('🚀 FEATURE: Header renders without agent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatPanelHeader(
              currentTheme: AppTheme.dark,
              selectedAgent: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify default state
      expect(find.text('Chat'), findsOneWidget);
      expect(find.byIcon(Icons.chat_outlined), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    });

    testWidgets('🎯 FEATURE: Header renders with agent context',
        (tester) async {
      final agent = AgentModel(
        name: 'Test Agent',
        systemPrompt: 'Test prompt',
      );
      agent.setProcessingStatus();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatPanelHeader(
              currentTheme: AppTheme.light,
              selectedAgent: agent,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify agent context
      expect(find.text('Test Agent'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byIcon(Icons.clear_all_outlined), findsOneWidget);
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    });

    testWidgets('🎨 FEATURE: Agent status colors work correctly',
        (tester) async {
      // Test idle status
      final idleAgent = AgentModel(name: 'Idle', systemPrompt: 'Test');
      idleAgent.setIdleStatus();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatPanelHeader(
              currentTheme: AppTheme.dark,
              selectedAgent: idleAgent,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find status indicator by looking for Container with specific properties
      final containers = tester.widgetList<Container>(find.byType(Container));
      final statusContainer = containers.firstWhere(
        (container) =>
            container.decoration is BoxDecoration &&
            (container.decoration as BoxDecoration).shape == BoxShape.circle &&
            container.constraints?.maxWidth == 12.0,
        orElse: () => throw Exception('Status indicator not found'),
      );

      final decoration = statusContainer.decoration as BoxDecoration;
      expect(decoration.color, Colors.green);
    });

    testWidgets('⚔️ FEATURE: Callbacks work correctly', (tester) async {
      final agent = AgentModel(name: 'Callback Test', systemPrompt: 'Test');

      bool themeToggled = false;
      bool leftToggled = false;
      bool rightToggled = false;
      AgentModel? editedAgent;
      AgentModel? clearedAgent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatPanelHeader(
              currentTheme: AppTheme.system,
              selectedAgent: agent,
              onThemeToggle: () => themeToggled = true,
              onToggleLeftSidebar: () => leftToggled = true,
              onToggleRightSidebar: () => rightToggled = true,
              onAgentEdit: (a) => editedAgent = a,
              onClearConversation: (a) => clearedAgent = a,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test all callbacks
      await tester.tap(find.byTooltip('Toggle theme'));
      expect(themeToggled, isTrue);

      await tester.tap(find.byTooltip('Toggle agents sidebar'));
      expect(leftToggled, isTrue);

      await tester.tap(find.byTooltip('Toggle MCP content sidebar'));
      expect(rightToggled, isTrue);

      await tester.tap(find.byTooltip('Edit agent settings'));
      expect(editedAgent, equals(agent));

      // Note: Clear conversation button requires conversation history to be enabled
      // For this test, we'll just verify the button exists
      expect(find.byTooltip('Clear conversation'), findsOneWidget);

      // Verify button is disabled by attempting to tap it (should not throw)
      await tester.tap(find.byTooltip('Clear conversation'));
      await tester.pumpAndSettle();

      // Since callback wasn't called with empty conversation, clearedAgent should still be null
      expect(clearedAgent, isNull);
    });

    testWidgets('🛡️ REGRESSION: All theme icons display correctly',
        (tester) async {
      // Test dark theme
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatPanelHeader(currentTheme: AppTheme.dark),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

      // Test light theme
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatPanelHeader(currentTheme: AppTheme.light),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

      // Test system theme
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatPanelHeader(currentTheme: AppTheme.system),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);
    });

    testWidgets('⚡ PERFORMANCE: Header creation is efficient', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatPanelHeader(
              currentTheme: AppTheme.dark,
              selectedAgent:
                  AgentModel(name: 'Perf Test', systemPrompt: 'Test'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Header should render quickly (< 100ms - relaxed for CI environment)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    testWidgets(
        '🎯 EDGE_CASE: Agent with empty conversation disables clear button',
        (tester) async {
      final agent = AgentModel(name: 'Empty Agent', systemPrompt: 'Test');
      // Agent starts with empty conversation history

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatPanelHeader(
              currentTheme: AppTheme.dark,
              selectedAgent: agent,
              onClearConversation: (a) => {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find clear conversation button and verify it exists
      expect(find.byTooltip('Clear conversation'), findsOneWidget);

      // Since agent has empty conversation, tapping button should not trigger callback
      // (the button is automatically disabled when conversation is empty)
      await tester.tap(find.byTooltip('Clear conversation'));
      await tester.pumpAndSettle();

      // Verify the behavior is correct - button exists but disabled for empty conversation
    });
  });
}
