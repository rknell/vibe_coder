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
      content:
          'I\'ll demonstrate by calling multiple functions to show you how tool calls work.',
      name: 'Assistant',
      toolCalls: [
        {
          'id': 'call_demo_001',
          'type': 'function',
          'function': {
            'name': 'memory_search',
            'arguments': '{"query": "UI examples", "limit": 3}'
          },
        },
        {
          'id': 'call_demo_002',
          'type': 'function',
          'function': {
            'name': 'filesystem_list_directory',
            'arguments': '{"path": "/home/user/examples"}'
          },
        },
        {
          'id': 'call_demo_003',
          'type': 'function',
          'function': {
            'name': 'calculate_sum',
            'arguments': '{"numbers": [1, 2, 3, 4, 5]}'
          },
        },
      ],
      reasoningContent:
          'The user wants to see tool calls, so I should demonstrate multiple function calls. I\'ll search memory, list files, and do a calculation to show different types of tools.',
    ),
    ChatMessage(
      role: MessageRole.tool,
      content: 'Found 2 UI examples: MessagingUI, ToolCallDisplay',
      toolCallId: 'call_demo_001',
    ),
    ChatMessage(
      role: MessageRole.tool,
      content: 'Directory contents: example1.dart, example2.dart, demo.md',
      toolCallId: 'call_demo_002',
    ),
    ChatMessage(
      role: MessageRole.tool,
      content: 'Sum calculation result: 15',
      toolCallId: 'call_demo_003',
    ),
    ChatMessage(
      role: MessageRole.assistant,
      content:
          'Perfect! As you can see above, the tool calls were executed successfully:\n• Memory search found UI examples\n• Directory listing showed example files\n• Calculation computed the sum as 15\n\nThe tool calls section shows up as expandable cards with the tool names and status indicators!',
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
              (() {
                final content = message.content;
                if (content != null) {
                  return Text(content);
                }
                return const SizedBox.shrink();
              })(),
              const SizedBox(height: 8),
            ],
            if (message.toolCalls != null) ...[
              const Text('Tool Calls:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              (() {
                final toolCalls = message.toolCalls;
                if (toolCalls != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: toolCalls
                        .map((call) =>
                            Text('• ${call['function']?['name'] ?? 'Unknown'}'))
                        .toList(),
                  );
                }
                return const SizedBox.shrink();
              })(),
              const SizedBox(height: 8),
            ],
            if (message.reasoningContent != null) ...[
              const Text('Reasoning:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              (() {
                final reasoningContent = message.reasoningContent;
                if (reasoningContent != null) {
                  return Text(reasoningContent);
                }
                return const SizedBox.shrink();
              })(),
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
