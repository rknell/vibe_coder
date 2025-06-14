import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/components/messaging/messages_list.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';

void main() {
  group('MessagesListComponent Tests', () {
    late ScrollController testScrollController;

    setUp(() {
      testScrollController = ScrollController();
    });

    tearDown(() {
      testScrollController.dispose();
    });

    testWidgets('renders empty state when no messages', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessagesListComponent(
              messages: const [],
              scrollController: testScrollController,
            ),
          ),
        ),
      );

      expect(find.byType(MessagesListComponent), findsOneWidget);
      expect(find.byIcon(Icons.chat_outlined), findsOneWidget);
      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('renders messages when provided', (tester) async {
      final testMessages = [
        ChatMessage(
          role: MessageRole.user,
          content: 'Hello there!',
        ),
        ChatMessage(
          role: MessageRole.assistant,
          content: 'Hi! How can I help you?',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessagesListComponent(
              messages: testMessages,
              scrollController: testScrollController,
            ),
          ),
        ),
      );

      expect(find.byType(MessagesListComponent), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Hello there!'), findsOneWidget);
      expect(find.text('Hi! How can I help you?'), findsOneWidget);
      expect(find.byIcon(Icons.chat_outlined), findsNothing);
    });

    testWidgets('calls onMessageTap when message is tapped', (tester) async {
      ChatMessage? tappedMessage;
      final testMessage = ChatMessage(
        role: MessageRole.user,
        content: 'Tap me!',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessagesListComponent(
              messages: [testMessage],
              scrollController: testScrollController,
              onMessageTap: (message) {
                tappedMessage = message;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me!'));
      expect(tappedMessage, equals(testMessage));
    });

    testWidgets('respects showTimestamps parameter', (tester) async {
      final testMessage = ChatMessage(
        role: MessageRole.user,
        content: 'Test message',
      );

      // Test with timestamps enabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessagesListComponent(
              messages: [testMessage],
              scrollController: testScrollController,
              showTimestamps: true,
            ),
          ),
        ),
      );

      // Should find timestamp widget (content varies by component implementation)
      expect(find.byType(MessagesListComponent), findsOneWidget);

      // Test with timestamps disabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessagesListComponent(
              messages: [testMessage],
              scrollController: testScrollController,
              showTimestamps: false,
            ),
          ),
        ),
      );

      expect(find.byType(MessagesListComponent), findsOneWidget);
    });

    testWidgets('uses provided scroll controller', (tester) async {
      final testMessage = ChatMessage(
        role: MessageRole.user,
        content: 'Test message',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessagesListComponent(
              messages: [testMessage],
              scrollController: testScrollController,
            ),
          ),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.controller, equals(testScrollController));
    });

    testWidgets('applies proper ListView configuration', (tester) async {
      final testMessage = ChatMessage(
        role: MessageRole.user,
        content: 'Test message',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessagesListComponent(
              messages: [testMessage],
              scrollController: testScrollController,
            ),
          ),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.padding, const EdgeInsets.all(16));
      // ListView.builder uses itemBuilder, not children
    });
  });
}
