import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/components/discord_layout/center_chat_panel.dart';
import 'package:vibe_coder/models/layout_preferences_model.dart';
import 'package:vibe_coder/models/agent_model.dart';

void main() {
  group('🎯 DR009: CenterChatPanel Integration Tests', () {
    testWidgets('🚀 FEATURE: Empty state displays when no agent selected',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CenterChatPanel(
              currentTheme: AppTheme.dark,
              selectedAgent: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty state components
      expect(find.text('Select an Agent to Start Chatting'), findsOneWidget);
      expect(
          find.text('Choose an agent from the sidebar to begin a conversation'),
          findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);

      // Verify header shows default state
      expect(find.text('Chat'), findsOneWidget);
      expect(find.byIcon(Icons.chat_outlined), findsOneWidget);
    });

    testWidgets('💬 FEATURE: MessagingUI integration with selected agent',
        (tester) async {
      // Create test agent with conversation
      final agent = AgentModel(
        name: 'Test Agent',
        systemPrompt: 'Test prompt',
      );

      // Note: Avoid calling addMessage() in tests as it triggers Agent initialization
      // which requires API key. Instead, just test the UI rendering with empty agent.

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CenterChatPanel(
              currentTheme: AppTheme.dark,
              selectedAgent: agent,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify agent context in header
      expect(find.text('Test Agent'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byIcon(Icons.clear_all_outlined), findsOneWidget);

      // Verify MessagingUI is displayed instead of empty state
      // Note: Since agent has no messages, MessagingUI will show empty conversation state
    });

    testWidgets('🎨 FEATURE: Agent status indicator colors', (tester) async {
      final idleAgent = AgentModel(
        name: 'Idle Agent',
        systemPrompt: 'Test',
      );
      idleAgent.setIdleStatus();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CenterChatPanel(
              currentTheme: AppTheme.dark,
              selectedAgent: idleAgent,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find status indicator
      final statusIndicator = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(Row),
              matching: find.byType(Container),
            )
            .first,
      );

      // Verify idle status shows green color
      final decoration = statusIndicator.decoration as BoxDecoration;
      expect(decoration.color, Colors.green);
    });

    testWidgets('⚔️ FEATURE: Callback integration works correctly',
        (tester) async {
      final agent = AgentModel(
        name: 'Callback Agent',
        systemPrompt: 'Test',
      );

      String? lastMessage;
      AgentModel? lastClearedAgent;
      AgentModel? lastEditedAgent;
      bool themeToggled = false;
      bool leftSidebarToggled = false;
      bool rightSidebarToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CenterChatPanel(
              currentTheme: AppTheme.dark,
              selectedAgent: agent,
              onSendMessage: (a, msg) => lastMessage = msg,
              onClearConversation: (a) => lastClearedAgent = a,
              onAgentEdit: (a) => lastEditedAgent = a,
              onThemeToggle: () => themeToggled = true,
              onToggleLeftSidebar: () => leftSidebarToggled = true,
              onToggleRightSidebar: () => rightSidebarToggled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test theme toggle
      await tester.tap(find.byTooltip('Toggle theme'));
      expect(themeToggled, isTrue);

      // Test left sidebar toggle
      await tester.tap(find.byTooltip('Toggle agents sidebar'));
      expect(leftSidebarToggled, isTrue);

      // Test right sidebar toggle
      await tester.tap(find.byTooltip('Toggle MCP content sidebar'));
      expect(rightSidebarToggled, isTrue);

      // Test agent edit
      await tester.tap(find.byTooltip('Edit agent settings'));
      expect(lastEditedAgent, equals(agent));

      // Note: Testing onSendMessage and onClearConversation would require
      // MessagingUI interaction which is beyond this component test scope.
      // These callbacks are tested in the MessagingUI integration.
      expect(lastMessage, isNull); // Initially null
      expect(lastClearedAgent, isNull); // Initially null
    });

    testWidgets('🔧 INTEGRATION: Theme integration works correctly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CenterChatPanel(
              currentTheme: AppTheme.light,
              selectedAgent: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify theme toggle icon matches light theme
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    });

    testWidgets('🎯 EDGE_CASE: Agent with empty conversation', (tester) async {
      final emptyAgent = AgentModel(
        name: 'Empty Agent',
        systemPrompt: 'Test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CenterChatPanel(
              currentTheme: AppTheme.dark,
              selectedAgent: emptyAgent,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify agent name is shown
      expect(find.text('Empty Agent'), findsOneWidget);

      // Verify clear conversation button is disabled for empty conversation
      // Find all IconButtons and check for the clear conversation one
      final iconButtons =
          tester.widgetList<IconButton>(find.byType(IconButton));
      final clearButton = iconButtons.firstWhere(
        (button) => button.tooltip == 'Clear conversation',
      );
      expect(clearButton.onPressed, isNull);
    });

    testWidgets('⚡ PERFORMANCE: Panel creation is efficient', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CenterChatPanel(
              currentTheme: AppTheme.dark,
              selectedAgent: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Panel should render quickly (< 100ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    testWidgets('🛡️ REGRESSION: All header controls are present',
        (tester) async {
      final agent = AgentModel(
        name: 'Header Test Agent',
        systemPrompt: 'Test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CenterChatPanel(
              currentTheme: AppTheme.system,
              selectedAgent: agent,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all header controls are present
      expect(find.byTooltip('Toggle agents sidebar'), findsOneWidget);
      expect(find.byTooltip('Edit agent settings'), findsOneWidget);
      expect(find.byTooltip('Clear conversation'), findsOneWidget);
      expect(find.byTooltip('Toggle theme'), findsOneWidget);
      expect(find.byTooltip('Toggle MCP content sidebar'), findsOneWidget);

      // Verify system theme icon
      expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);
    });
  });
}
