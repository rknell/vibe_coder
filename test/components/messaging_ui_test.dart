import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/components/messaging_ui.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';

void main() {
  group('MessagingUI', () {
    testWidgets('displays empty state when no messages',
        (WidgetTester tester) async {
      // Arrange
      const messagesUI = MessagingUI(messages: []);

      // Act
      await tester
          .pumpWidget(const MaterialApp(home: Scaffold(body: messagesUI)));

      // Assert
      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.byIcon(Icons.chat_outlined), findsOneWidget);
    });

    testWidgets('displays messages in correct order',
        (WidgetTester tester) async {
      // Arrange
      final messages = [
        ChatMessage(role: MessageRole.user, content: 'First message'),
        ChatMessage(role: MessageRole.assistant, content: 'Second message'),
        ChatMessage(role: MessageRole.user, content: 'Third message'),
      ];
      final messagesUI = MessagingUI(messages: messages);

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: messagesUI)));

      // Assert - Check that all messages are displayed
      expect(find.text('First message'), findsOneWidget);
      expect(find.text('Second message'), findsOneWidget);
      expect(find.text('Third message'), findsOneWidget);

      // Verify messages are in correct order (oldest to newest)
      // Use SelectableText instead of Text since MessageContent uses SelectableText
      final messageWidgets =
          tester.widgetList<SelectableText>(find.byType(SelectableText));
      final messageTexts = messageWidgets
          .where((widget) => [
                'First message',
                'Second message',
                'Third message'
              ].contains(widget.data))
          .map((widget) => widget.data)
          .toList();

      expect(
          messageTexts, ['First message', 'Second message', 'Third message']);
    });

    testWidgets('calls onMessageTap when message is tapped',
        (WidgetTester tester) async {
      // Arrange
      final message =
          ChatMessage(role: MessageRole.user, content: 'Test message');
      ChatMessage? tappedMessage;

      final messagesUI = MessagingUI(
        messages: [message],
        onMessageTap: (msg) => tappedMessage = msg,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: messagesUI)));

      // Tap on the GestureDetector area - find the Container inside MessageBubble
      // and tap on an area that doesn't have SelectableText
      final containerFinder = find.descendant(
        of: find.byType(MessageBubble),
        matching: find.byType(Container),
      );
      await tester.tap(containerFinder.first, warnIfMissed: false);
      await tester.pump();

      // Assert
      expect(tappedMessage, equals(message));
    });

    testWidgets('displays timestamps when enabled',
        (WidgetTester tester) async {
      // Arrange
      final message =
          ChatMessage(role: MessageRole.user, content: 'Test message');
      final messagesUI = MessagingUI(
        messages: [message],
        showTimestamps: true,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: messagesUI)));

      // Assert
      // Look for timestamp pattern (HH:MM:SS format) in SelectableText widgets
      // The timestamp is displayed by MessageTimestamp component using SelectableText
      expect(
          find.byWidgetPredicate((widget) =>
              widget is SelectableText &&
              widget.data != null &&
              RegExp(r'\d{2}:\d{2}:\d{2}').hasMatch(widget.data!)),
          findsOneWidget);
    });
  });

  group('MessageBubble', () {
    testWidgets('displays user message with correct styling',
        (WidgetTester tester) async {
      // Arrange
      final message =
          ChatMessage(role: MessageRole.user, content: 'User message');

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MessageBubble(
              message: message,
              showTimestamps: false,
              theme: MessagingTheme.defaultTheme(context),
            ),
          ),
        ),
      ));

      // Assert
      expect(find.text('User message'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('displays assistant message with correct styling',
        (WidgetTester tester) async {
      // Arrange
      final message = ChatMessage(
          role: MessageRole.assistant, content: 'Assistant response');

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MessageBubble(
              message: message,
              showTimestamps: false,
              theme: MessagingTheme.defaultTheme(context),
            ),
          ),
        ),
      ));

      // Assert
      expect(find.text('Assistant response'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('displays system message with correct styling',
        (WidgetTester tester) async {
      // Arrange
      final message =
          ChatMessage(role: MessageRole.system, content: 'System instruction');

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MessageBubble(
              message: message,
              showTimestamps: false,
              theme: MessagingTheme.defaultTheme(context),
            ),
          ),
        ),
      ));

      // Assert
      expect(find.text('System instruction'), findsOneWidget);
      // System messages don't show avatars
      expect(find.byIcon(Icons.settings), findsNothing);
    });

    testWidgets('displays tool message with correct styling',
        (WidgetTester tester) async {
      // Arrange
      final message =
          ChatMessage(role: MessageRole.tool, content: 'Tool output');

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MessageBubble(
              message: message,
              showTimestamps: false,
              theme: MessagingTheme.defaultTheme(context),
            ),
          ),
        ),
      ));

      // Assert
      expect(find.text('Tool output'), findsOneWidget);
      expect(find.byIcon(Icons.build), findsOneWidget);
    });

    testWidgets('displays message with name', (WidgetTester tester) async {
      // Arrange
      final message = ChatMessage(
        role: MessageRole.user,
        content: 'Message content',
        name: 'John Doe',
      );

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MessageBubble(
              message: message,
              showTimestamps: false,
              theme: MessagingTheme.defaultTheme(context),
            ),
          ),
        ),
      ));

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Message content'), findsOneWidget);
    });

    testWidgets('displays tool calls when present',
        (WidgetTester tester) async {
      // Arrange
      final message = ChatMessage(
        role: MessageRole.assistant,
        content: 'I will call a function',
        toolCalls: [
          {
            'function': {'name': 'test_function'},
          },
        ],
      );

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MessageBubble(
              message: message,
              showTimestamps: false,
              theme: MessagingTheme.defaultTheme(context),
            ),
          ),
        ),
      ));

      // Assert
      // The new MessageToolCallsEnhanced component shows "Tool Call" instead of "Tool Calls:"
      expect(find.textContaining('Tool Call'), findsOneWidget);
      expect(find.text('test_function'), findsOneWidget);
    });

    testWidgets('displays reasoning content when present',
        (WidgetTester tester) async {
      // Arrange
      final message = ChatMessage(
        role: MessageRole.assistant,
        content: 'Response',
        reasoningContent: 'This is my reasoning process',
      );

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MessageBubble(
              message: message,
              showTimestamps: false,
              theme: MessagingTheme.defaultTheme(context),
            ),
          ),
        ),
      ));

      // Assert
      expect(find.text('Reasoning:'), findsOneWidget);
      expect(find.text('This is my reasoning process'), findsOneWidget);
    });

    testWidgets('handles null content gracefully', (WidgetTester tester) async {
      // Arrange
      final message = ChatMessage(role: MessageRole.tool, content: null);

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MessageBubble(
              message: message,
              showTimestamps: false,
              theme: MessagingTheme.defaultTheme(context),
            ),
          ),
        ),
      ));

      // Assert
      // Should not crash and should still show the avatar
      expect(find.byIcon(Icons.build), findsOneWidget);
    });
  });

  group('MessagingTheme', () {
    testWidgets('applies custom theme correctly', (WidgetTester tester) async {
      // Arrange
      const customTheme = MessagingTheme(
        systemMessageColor: Colors.red,
        userMessageColor: Colors.blue,
        assistantMessageColor: Colors.green,
        toolMessageColor: Colors.orange,
        messageTextStyle: TextStyle(fontSize: 20),
      );

      final message =
          ChatMessage(role: MessageRole.user, content: 'Test message');
      final messagesUI = MessagingUI(
        messages: [message],
        theme: customTheme,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: messagesUI)));

      // Assert
      expect(find.text('Test message'), findsOneWidget);
      // Note: Testing specific colors in widgets is complex in Flutter tests
      // This test ensures the theme is applied without crashes
    });

    test('creates default theme with correct values', () {
      // Test the theme structure without needing a BuildContext
      const theme = MessagingTheme(
        systemMessageColor: Colors.grey,
        userMessageColor: Colors.blue,
        assistantMessageColor: Colors.green,
        toolMessageColor: Colors.orange,
      );

      expect(theme.systemMessageColor, Colors.grey);
      expect(theme.userMessageColor, Colors.blue);
      expect(theme.assistantMessageColor, Colors.green);
      expect(theme.toolMessageColor, Colors.orange);
      expect(theme.messagePadding, 12.0);
      expect(theme.messageSpacing, 12.0);
    });
  });

  group('Edge Cases', () {
    testWidgets('handles empty message list', (WidgetTester tester) async {
      // Arrange
      const messagesUI = MessagingUI(messages: []);

      // Act
      await tester
          .pumpWidget(const MaterialApp(home: Scaffold(body: messagesUI)));

      // Assert
      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('handles very long message content',
        (WidgetTester tester) async {
      // Arrange
      final longMessage =
          'This is a very long message that should wrap properly and not cause any overflow issues in the UI. ' *
              10;
      final message = ChatMessage(role: MessageRole.user, content: longMessage);
      final messagesUI = MessagingUI(messages: [message]);

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: messagesUI)));

      // Assert
      expect(
          find.textContaining('This is a very long message'), findsOneWidget);
    });

    testWidgets('handles message with all fields populated',
        (WidgetTester tester) async {
      // Arrange
      final message = ChatMessage(
        role: MessageRole.assistant,
        content: 'Complete message',
        name: 'Assistant',
        reasoningContent: 'My reasoning',
        toolCalls: [
          {
            'function': {'name': 'example_function'}
          },
        ],
      );

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MessageBubble(
              message: message,
              showTimestamps: true,
              theme: MessagingTheme.defaultTheme(context),
            ),
          ),
        ),
      ));

      // Assert
      expect(find.text('Assistant'), findsOneWidget);
      expect(find.text('Complete message'), findsOneWidget);
      expect(find.text('Reasoning:'), findsOneWidget);
      expect(find.text('My reasoning'), findsOneWidget);
      // The new MessageToolCallsEnhanced component shows "Tool Call" instead of "Tool Calls:"
      expect(find.textContaining('Tool Call'), findsOneWidget);
      expect(find.text('example_function'), findsOneWidget);
    });
  });

  group('MessagingUI Enhanced Functionality Tests', () {
    late List<ChatMessage> testMessages;
    late List<String> sentMessages;

    setUp(() {
      testMessages = [
        ChatMessage(role: MessageRole.user, content: 'Test message 1'),
        ChatMessage(role: MessageRole.assistant, content: 'Test response 1'),
      ];
      sentMessages = [];
    });

    // PERF: Widget creation complexity O(1) - simple constructor calls
    testWidgets('creates MessagingUI with enhanced features',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessagingUI(
            messages: testMessages,
            onSendMessage: (message) => sentMessages.add(message),
          ),
        ),
      ));

      expect(find.byType(MessagingUI), findsOneWidget);
      expect(find.text('Ctrl+Enter to send'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays helper text for keyboard shortcut',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessagingUI(
            messages: testMessages,
            onSendMessage: (message) => sentMessages.add(message),
          ),
        ),
      ));

      expect(find.text('Ctrl+Enter to send'), findsOneWidget);

      final tooltip = find.byTooltip('Send message (Ctrl+Enter)');
      expect(tooltip, findsOneWidget);
    });

    testWidgets('text field expands with multiline input',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessagingUI(
            messages: testMessages,
            onSendMessage: (message) => sentMessages.add(message),
          ),
        ),
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.minLines, equals(1));
      expect(textField.maxLines, equals(10));
      expect(textField.keyboardType, equals(TextInputType.multiline));
      expect(textField.textInputAction, equals(TextInputAction.newline));
    });

    testWidgets('sends message on Ctrl+Enter key combination',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessagingUI(
            messages: testMessages,
            onSendMessage: (message) => sentMessages.add(message),
          ),
        ),
      ));

      // Enter text
      await tester.enterText(find.byType(TextField), 'Test multiline message');
      await tester.pump();

      // Simulate Ctrl+Enter
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      expect(sentMessages, contains('Test multiline message'));
    });

    testWidgets('clears text field after sending message',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessagingUI(
            messages: testMessages,
            onSendMessage: (message) => sentMessages.add(message),
          ),
        ),
      ));

      // Enter text
      await tester.enterText(find.byType(TextField), 'Message to be cleared');
      await tester.pump();

      // Send via button
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify text is cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
    });

    testWidgets('auto-scrolls to bottom when new message added',
        (WidgetTester tester) async {
      final scrollableMessages = List.generate(20,
          (i) => ChatMessage(role: MessageRole.user, content: 'Message $i'));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return MessagingUI(
                messages: scrollableMessages,
                onSendMessage: (message) {
                  setState(() {
                    scrollableMessages.add(
                        ChatMessage(role: MessageRole.user, content: message));
                  });
                },
              );
            },
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Find the ListView
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // Add a new message
      await tester.enterText(find.byType(TextField), 'New bottom message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify the new message is visible (would be at bottom after auto-scroll)
      expect(find.text('New bottom message'), findsOneWidget);
    });

    testWidgets(
        'scrolls to bottom when message count increases via message length tracking',
        (WidgetTester tester) async {
      // Create initial messages to fill ListView
      final initialMessages = List.generate(30,
          (i) => ChatMessage(role: MessageRole.user, content: 'Message $i'));

      List<ChatMessage> currentMessages = List.from(initialMessages);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return MessagingUI(
                messages: currentMessages,
                onSendMessage: (message) {
                  setState(() {
                    currentMessages.add(
                        ChatMessage(role: MessageRole.user, content: message));
                  });
                },
              );
            },
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Find the ListView inside MessagingUI and get its scroll controller
      final listView = tester.widget<ListView>(find.byType(ListView));
      final scrollController = listView.controller!;

      // Scroll to top
      scrollController.jumpTo(0);
      await tester.pumpAndSettle();

      // Verify we're at the top
      expect(scrollController.offset, equals(0));

      // Add new message - this should trigger auto-scroll to bottom
      await tester.enterText(
          find.byType(TextField), 'Latest message at bottom');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify scroll position is at bottom (maxScrollExtent)
      // PERF: O(1) validation - single scroll position check
      expect(
          scrollController.offset,
          greaterThanOrEqualTo(
              scrollController.position.maxScrollExtent - 100));

      // Verify new message is visible at bottom
      expect(find.text('Latest message at bottom'), findsOneWidget);
    });

    testWidgets('does not auto-scroll when message count unchanged',
        (WidgetTester tester) async {
      final messages = List.generate(30,
          (i) => ChatMessage(role: MessageRole.user, content: 'Message $i'));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return MessagingUI(
                messages: messages,
              );
            },
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Find the ListView and get its scroll controller
      final listView = tester.widget<ListView>(find.byType(ListView));
      final scrollController = listView.controller!;
      final middlePosition = scrollController.position.maxScrollExtent / 2;

      scrollController.jumpTo(middlePosition);
      await tester.pumpAndSettle();

      // Trigger rebuild without changing message count
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return MessagingUI(
                messages: messages, // Same messages
              );
            },
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Verify scroll position unchanged
      expect(scrollController.offset, closeTo(middlePosition, 10));
    });

    testWidgets('handles empty message input correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessagingUI(
            messages: testMessages,
            onSendMessage: (message) => sentMessages.add(message),
          ),
        ),
      ));

      // Try to send empty message
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(sentMessages, isEmpty);
    });

    testWidgets('handles whitespace-only message correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessagingUI(
            messages: testMessages,
            onSendMessage: (message) => sentMessages.add(message),
          ),
        ),
      ));

      // Enter whitespace only
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(sentMessages, isEmpty);
    });

    testWidgets('populates text field from inputText prop',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessagingUI(
            messages: testMessages,
            inputText: 'Pre-populated text',
            onSendMessage: (message) => sentMessages.add(message),
          ),
        ),
      ));

      expect(find.text('Pre-populated text'), findsOneWidget);
    });

    testWidgets('updates text field when inputText prop changes',
        (WidgetTester tester) async {
      String currentInputText = 'Initial text';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return MessagingUI(
                messages: testMessages,
                inputText: currentInputText,
                onSendMessage: (message) => sentMessages.add(message),
              );
            },
          ),
        ),
      ));

      expect(find.text('Initial text'), findsOneWidget);

      // Update the inputText prop
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessagingUI(
            messages: testMessages,
            inputText: 'Updated text',
            onSendMessage: (message) => sentMessages.add(message),
          ),
        ),
      ));

      expect(find.text('Updated text'), findsOneWidget);
    });

    testWidgets('disables send functionality when onSendMessage is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessagingUI(
            messages: testMessages,
            onSendMessage: null,
          ),
        ),
      ));

      final iconButtonFinder = find.byType(IconButton);
      final iconButton = tester.widget<IconButton>(iconButtonFinder);
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('shows/hides input field based on showInput prop',
        (WidgetTester tester) async {
      // Test with showInput: false
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessagingUI(
            messages: testMessages,
            showInput: false,
          ),
        ),
      ));

      expect(find.byType(TextField), findsNothing);

      // Test with showInput: true (default)
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessagingUI(
            messages: testMessages,
            showInput: true,
          ),
        ),
      ));

      expect(find.byType(TextField), findsOneWidget);
    });

    group('Focus Management Tests', () {
      testWidgets('maintains focus after sending message',
          (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: MessagingUI(
              messages: testMessages,
              onSendMessage: (message) => sentMessages.add(message),
            ),
          ),
        ));

        // Focus the text field
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        // Enter and send message
        await tester.enterText(find.byType(TextField), 'Focus test message');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Verify text field is still focused
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.focusNode!.hasFocus, isTrue);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles very long message input',
          (WidgetTester tester) async {
        final longMessage = 'A' * 1000; // 1000 character message

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: MessagingUI(
              messages: testMessages,
              onSendMessage: (message) => sentMessages.add(message),
            ),
          ),
        ));

        await tester.enterText(find.byType(TextField), longMessage);
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(sentMessages, contains(longMessage));
      });

      testWidgets('handles rapid message sending', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: MessagingUI(
              messages: testMessages,
              onSendMessage: (message) => sentMessages.add(message),
            ),
          ),
        ));

        // Send multiple messages rapidly
        for (int i = 0; i < 5; i++) {
          await tester.enterText(find.byType(TextField), 'Rapid message $i');
          await tester.tap(find.byIcon(Icons.send));
          await tester.pump();
        }

        await tester.pumpAndSettle();
        expect(sentMessages.length, equals(5));
      });
    });
  });
}
