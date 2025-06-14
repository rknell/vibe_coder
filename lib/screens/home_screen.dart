import 'package:flutter/material.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/components/messaging_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChatMessage> messages = [
    ChatMessage(
      role: MessageRole.system,
      content: 'You are a helpful AI assistant.',
    ),
    ChatMessage(
      role: MessageRole.user,
      content: 'Hello! Can you help me with Flutter development?',
    ),
    ChatMessage(
      role: MessageRole.assistant,
      content:
          'Of course! I\'d be happy to help you with Flutter development. What specific topic or issue would you like assistance with?',
    ),
    ChatMessage(
      role: MessageRole.user,
      content: 'I\'m trying to understand how to create custom widgets.',
    ),
    ChatMessage(
      role: MessageRole.assistant,
      content:
          'Great question! Custom widgets in Flutter are created by extending either StatelessWidget or StatefulWidget. Here\'s a basic example:\n\n```dart\nclass MyCustomWidget extends StatelessWidget {\n  @override\n  Widget build(BuildContext context) {\n    return Container(\n      child: Text(\'Hello World\'),\n    );\n  }\n}\n```\n\nWould you like me to explain the difference between StatelessWidget and StatefulWidget?',
    ),
  ];

  void _handleSendMessage(String messageText) {
    setState(() {
      messages.add(ChatMessage(
        role: MessageRole.user,
        content: messageText,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: MessagingUI(
        messages: messages,
        onSendMessage: _handleSendMessage,
        showTimestamps: true,
      ),
    );
  }
}
