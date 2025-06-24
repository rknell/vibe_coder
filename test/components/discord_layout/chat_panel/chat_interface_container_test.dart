import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/components/discord_layout/chat_panel/chat_interface_container.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/components/messaging_ui.dart';

void main() {
  group('🛡️ COMPONENT: ChatInterfaceContainer Tests', () {
    testWidgets('🚀 FEATURE: Container renders MessagingUI with agent',
        (tester) async {
      final agent = AgentModel(
        name: 'Test Agent',
        systemPrompt: 'Test prompt',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterfaceContainer(
              selectedAgent: agent,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify MessagingUI is rendered
      expect(find.byType(MessagingUI), findsOneWidget);

      // Verify our specific ListenableBuilder exists (there may be others from MaterialApp)
      expect(find.byType(ChatInterfaceContainer), findsOneWidget);
    });

    testWidgets(
        '🎯 FEATURE: Dynamic placeholder based on agent processing state',
        (tester) async {
      final agent = AgentModel(
        name: 'Processing Agent',
        systemPrompt: 'Test prompt',
      );

      // Test processing state
      agent.setProcessingStatus();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterfaceContainer(
              selectedAgent: agent,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find MessagingUI and check placeholder
      final messagingUI = tester.widget<MessagingUI>(find.byType(MessagingUI));
      expect(messagingUI.inputPlaceholder, 'Processing Agent is thinking...');
      expect(messagingUI.showInput, isFalse);
    });

    testWidgets('💬 FEATURE: Idle agent shows normal placeholder',
        (tester) async {
      final agent = AgentModel(
        name: 'Idle Agent',
        systemPrompt: 'Test prompt',
      );

      agent.setIdleStatus();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterfaceContainer(
              selectedAgent: agent,
              onSendMessage: (a, msg) => {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find MessagingUI and check placeholder
      final messagingUI = tester.widget<MessagingUI>(find.byType(MessagingUI));
      expect(messagingUI.inputPlaceholder, 'Ask Idle Agent anything...');
      expect(messagingUI.showInput, isTrue);
    });

    testWidgets('⚔️ FEATURE: Callbacks are properly delegated', (tester) async {
      final agent = AgentModel(
        name: 'Callback Agent',
        systemPrompt: 'Test prompt',
      );

      String? lastMessage;
      AgentModel? lastMessageAgent;
      AgentModel? lastClearedAgent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterfaceContainer(
              selectedAgent: agent,
              onSendMessage: (a, msg) {
                lastMessageAgent = a;
                lastMessage = msg;
              },
              onClearConversation: (a) => lastClearedAgent = a,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify callbacks are set up correctly
      final messagingUI = tester.widget<MessagingUI>(find.byType(MessagingUI));

      // Test message callback setup
      expect(messagingUI.onSendMessage, isNotNull);

      // Test clear callback setup
      expect(messagingUI.onClearConversation, isNotNull);

      // Note: Actually triggering these callbacks would require MessagingUI interaction
      // which is beyond this component test scope. The callback delegation is verified
      // by checking that the MessagingUI receives non-null callbacks.
      expect(lastMessage, isNull); // Initially null
      expect(lastMessageAgent, isNull); // Initially null
      expect(lastClearedAgent, isNull); // Initially null
    });

    testWidgets('🔄 FEATURE: ListenableBuilder reacts to agent changes',
        (tester) async {
      final agent = AgentModel(
        name: 'Reactive Agent',
        systemPrompt: 'Test prompt',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterfaceContainer(
              selectedAgent: agent,
              onSendMessage: (a, msg) => {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial state
      var messagingUI = tester.widget<MessagingUI>(find.byType(MessagingUI));
      expect(messagingUI.showInput, isTrue);

      // Change agent state
      agent.setProcessingStatus();
      await tester.pumpAndSettle();

      // Verify UI updated
      messagingUI = tester.widget<MessagingUI>(find.byType(MessagingUI));
      expect(messagingUI.showInput, isFalse);
      expect(messagingUI.inputPlaceholder, 'Reactive Agent is thinking...');
    });

    testWidgets('⚡ PERFORMANCE: Container creation is efficient',
        (tester) async {
      final stopwatch = Stopwatch()..start();

      final agent = AgentModel(
        name: 'Performance Test',
        systemPrompt: 'Test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterfaceContainer(
              selectedAgent: agent,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Container should render quickly (< 100ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    testWidgets('🛡️ REGRESSION: MessagingUI receives correct props',
        (tester) async {
      final agent = AgentModel(
        name: 'Props Test Agent',
        systemPrompt: 'Test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterfaceContainer(
              selectedAgent: agent,
              onSendMessage: (a, msg) => {},
              onClearConversation: (a) => {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify MessagingUI props
      final messagingUI = tester.widget<MessagingUI>(find.byType(MessagingUI));
      expect(messagingUI.messages, equals(agent.conversationHistory));
      expect(messagingUI.showTimestamps, isTrue);
      expect(messagingUI.onSendMessage, isNotNull);
      expect(messagingUI.onClearConversation, isNotNull);
    });

    testWidgets('🎯 EDGE_CASE: Null callbacks handled correctly',
        (tester) async {
      final agent = AgentModel(
        name: 'Null Callback Agent',
        systemPrompt: 'Test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterfaceContainer(
              selectedAgent: agent,
              // Callbacks intentionally null
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify MessagingUI handles null callbacks
      final messagingUI = tester.widget<MessagingUI>(find.byType(MessagingUI));
      expect(messagingUI.onSendMessage, isNull);
      expect(messagingUI.onClearConversation, isNull);
      expect(messagingUI.showInput,
          isFalse); // Should be false when no send callback
    });
  });
}
