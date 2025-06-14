import 'package:flutter/material.dart';
import 'package:vibe_coder/components/messaging_ui.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';

/// Example screen demonstrating how to use the MessagingUI component.
///
/// This example shows various message types and features including:
/// - System messages
/// - User messages
/// - Assistant messages with tool calls and reasoning
/// - Tool messages
/// - Message interaction callbacks
/// - Custom theming
class MessagingUIExampleScreen extends StatefulWidget {
  const MessagingUIExampleScreen({super.key});

  @override
  State<MessagingUIExampleScreen> createState() =>
      _MessagingUIExampleScreenState();
}

class _MessagingUIExampleScreenState extends State<MessagingUIExampleScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      role: MessageRole.system,
      content:
          'You are a helpful AI assistant. Please provide accurate and helpful responses.',
    ),
    ChatMessage(
      role: MessageRole.user,
      content: 'Hello! Can you help me understand how this messaging UI works?',
      name: 'User',
    ),
    ChatMessage(
      role: MessageRole.assistant,
      content:
          'Hello! I\'d be happy to help you understand the messaging UI. This interface displays chat messages with different styling based on the message role.',
      name: 'Assistant',
    ),
    ChatMessage(
      role: MessageRole.user,
      content: 'Can you show me an example with tool calls?',
      name: 'User',
    ),
    ChatMessage(
      role: MessageRole.assistant,
      content: 'I\'ll demonstrate by calling a function.',
      name: 'Assistant',
      toolCalls: [
        {
          'function': {'name': 'calculate_sum'},
          'type': 'function',
          'id': 'call_1',
        },
        {
          'function': {'name': 'get_weather'},
          'type': 'function',
          'id': 'call_2',
        },
      ],
      reasoningContent:
          'The user wants to see tool calls, so I should demonstrate calling functions. I\'ll call both a calculation function and a weather function to show multiple tool calls.',
    ),
    ChatMessage(
      role: MessageRole.tool,
      content: 'Function calculate_sum returned: 42',
      toolCallId: 'call_1',
    ),
    ChatMessage(
      role: MessageRole.tool,
      content:
          'Function get_weather returned: {"temperature": 22, "condition": "sunny"}',
      toolCallId: 'call_2',
    ),
    ChatMessage(
      role: MessageRole.assistant,
      content:
          'As you can see, the tool calls were executed successfully! The sum calculation returned 42, and the weather is 22°C and sunny.',
      name: 'Assistant',
    ),
  ];

  bool _showTimestamps = false;
  MessagingTheme? _customTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messaging UI Example'),
        actions: [
          IconButton(
            icon: Icon(_showTimestamps
                ? Icons.access_time
                : Icons.access_time_outlined),
            onPressed: () => setState(() => _showTimestamps = !_showTimestamps),
            tooltip: 'Toggle Timestamps',
          ),
          IconButton(
            icon: Icon(
                _customTheme != null ? Icons.palette : Icons.palette_outlined),
            onPressed: _toggleCustomTheme,
            tooltip: 'Toggle Custom Theme',
          ),
        ],
      ),
      body: MessagingUI(
        messages: _messages,
        showTimestamps: _showTimestamps,
        theme: _customTheme,
        onMessageTap: _onMessageTap,
      ),
    );
  }

  void _onMessageTap(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Message Details - ${message.role.name.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.name != null) ...[
              Text('Name: ${message.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],
            if (message.content != null) ...[
              const Text('Content:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(message.content!),
              const SizedBox(height: 8),
            ],
            if (message.toolCalls != null) ...[
              const Text('Tool Calls:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...message.toolCalls!.map((call) =>
                  Text('• ${call['function']?['name'] ?? 'Unknown'}')),
              const SizedBox(height: 8),
            ],
            if (message.reasoningContent != null) ...[
              const Text('Reasoning:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(message.reasoningContent!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleCustomTheme() {
    setState(() {
      if (_customTheme == null) {
        _customTheme = const MessagingTheme(
          systemMessageColor: Colors.orange,
          userMessageColor: Colors.deepPurple,
          assistantMessageColor: Colors.teal,
          toolMessageColor: Colors.brown,
          messageTextStyle: TextStyle(fontSize: 16),
        );
      } else {
        _customTheme = null;
      }
    });
  }
}
