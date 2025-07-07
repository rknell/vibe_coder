import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vibe_coder/ai_agent/services/conversation_manager.dart';
import 'package:vibe_coder/ai_agent/agent.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:logging/logging.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';

void main() {
  group('🔄 ConversationManager Tool Refresh Tests', () {
    late ConversationManager conversationManager;
    late Agent agent;
    late AgentModel agentModel;

    setUpAll(() async {
      // Initialize test environment ONCE
      TestWidgetsFlutterBinding.ensureInitialized();

      // Load environment variables for tests
      await dotenv.load(fileName: '.env');
    });

    setUp(() {
      // Create test agent and conversation manager
      agentModel = AgentModel(
        id: 'test-agent',
        name: 'Test Agent',
        systemPrompt: 'You are a test agent',
      );

      agent = Agent(agentModel: agentModel);

      conversationManager = ConversationManager(
        name: 'test-conversation',
        agent: agent,
      );
    });

    test('🛡️ REGRESSION: Tool refresh does not block conversation flow', () {
      // This test ensures that tool refresh happens in background without blocking
      final stopwatch = Stopwatch()..start();

      // Add a user message to trigger updateUserContext()
      conversationManager.addUserMessage('Test message');

      // updateUserContext() should complete instantly (background refresh)
      conversationManager.updateUserContext();

      stopwatch.stop();

      // Tool refresh should be non-blocking (< 100ms)
      // This prevents conversation delays while ensuring tool freshness
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Tool refresh should not block conversation flow');
    });

    test('🔄 FEATURE: updateUserContext executes without errors', () {
      // This test verifies that the new tool refresh functionality doesn't break existing flow

      // updateUserContext should execute without throwing errors
      expect(() => conversationManager.updateUserContext(), returnsNormally,
          reason: 'Tool refresh integration should not break context updates');

      // Should work with null agent as well (defensive programming)
      final managerWithoutAgent = ConversationManager(
        name: 'test-no-agent',
        agent: null,
      );
      expect(() => managerWithoutAgent.updateUserContext(), returnsNormally,
          reason: 'Should handle null agent gracefully');
    });

    test('🛡️ ROBUSTNESS: Multiple context updates remain performant', () {
      // This test ensures multiple rapid context updates don't cause performance issues
      final stopwatch = Stopwatch()..start();

      // Multiple rapid context updates should remain fast
      for (int i = 0; i < 10; i++) {
        conversationManager.updateUserContext();
      }

      stopwatch.stop();

      // Multiple calls should still be fast (background operations)
      expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Background refresh should not accumulate blocking delays');
    });

    test('🧪 FEATURE: Tool refresh integrates with message workflow', () {
      // This test verifies tool refresh works within normal conversation flow

      // Normal conversation workflow with tool refresh integration
      conversationManager.addSystemMessage('You are a helpful assistant');
      conversationManager.updateUserContext(); // Should trigger tool refresh

      conversationManager.addUserMessage('Hello, can you help me?');
      conversationManager
          .updateUserContext(); // Should trigger tool refresh again

      // Verify messages are preserved (tool refresh doesn't affect message history)
      expect(conversationManager.messageCount, equals(2),
          reason: 'Tool refresh should not affect message history');

      final messages = conversationManager.messages;
      expect(messages[0].content, contains('You are a helpful assistant'));
      expect(messages[1].content, equals('Hello, can you help me?'));
    });

    test('🎯 ARCHITECTURAL: Null agent handling follows warrior protocol', () {
      // This test verifies null safety protocols are followed

      final nullAgentManager = ConversationManager(
        name: 'null-agent-test',
        agent: null,
      );

      // Should handle null agent without throwing (warrior protocol: null safety)
      expect(() => nullAgentManager.updateUserContext(), returnsNormally,
          reason:
              'Null agent should be handled gracefully with warrior protocol');
    });
  });

  group('🛡️ REGRESSION: Sequential Tool Calls Processing', () {
    late ConversationManager conversationManager;
    late Agent agent;
    late AgentModel agentModel;

    setUp(() {
      // Configure logging for tests
      Logger.root.level = Level.INFO;
      Logger.root.onRecord.listen((record) {
        // ignore: avoid_print
        print('${record.level.name}: ${record.time}: ${record.message}');
      });

      // Create test agent and conversation manager
      agentModel = AgentModel(
        id: 'test-agent-sequential',
        name: 'Test Agent Sequential',
        systemPrompt: 'You are a test agent for sequential tool calls',
      );

      agent = Agent(agentModel: agentModel);

      conversationManager = ConversationManager(
        name: 'test-conversation-sequential',
        agent: agent,
      );
    });

    test('🛡️ REGRESSION: Sequential tool calls detection and tracking', () {
      // This test verifies the fix for the issue where the second tool call
      // in a sequence (like notepad write → read) wasn't being processed

      // Simulate first message with tool calls
      conversationManager.addUserMessage('Test sequential tool calls');

      // Add assistant message with first tool call (write)
      final firstToolCall = {
        'id': 'call_1',
        'type': 'function',
        'function': {
          'name': 'notepad_notepad_write',
          'arguments': '{"content": "test content"}'
        }
      };

      conversationManager.addAssistantMessage(
        '', // Empty content when tool calls are present
        toolCalls: [firstToolCall],
      );

      // Verify first tool call is detected
      expect(conversationManager.hasUnprocessedToolCalls, isTrue);
      expect(conversationManager.lastToolCalls, hasLength(1));
      expect(conversationManager.lastToolCalls![0]['id'], equals('call_1'));

      // Add tool response for first call
      final toolMessage1 = ChatMessage(
        role: MessageRole.tool,
        content: 'Notepad updated successfully.',
        toolCallId: 'call_1',
        contextId: 'notepad_write',
      );
      conversationManager
          .addUserMessage(toolMessage1.content!); // Simulate tool response

      // Add second assistant message with second tool call (read)
      final secondToolCall = {
        'id': 'call_2',
        'type': 'function',
        'function': {'name': 'notepad_notepad_read', 'arguments': '{}'}
      };

      conversationManager.addAssistantMessage(
        '', // Empty content when tool calls are present
        toolCalls: [secondToolCall],
      );

      // Verify second tool call is detected
      expect(conversationManager.hasUnprocessedToolCalls, isTrue);
      expect(conversationManager.lastToolCalls, hasLength(1));
      expect(conversationManager.lastToolCalls![0]['id'], equals('call_2'));

      // Add tool response for second call
      final toolMessage2 = ChatMessage(
        role: MessageRole.tool,
        content: 'This is a test message to verify the notepad functionality.',
        toolCallId: 'call_2',
        contextId: 'notepad_read',
      );
      conversationManager
          .addUserMessage(toolMessage2.content!); // Simulate tool response

      // Verify conversation flow
      expect(conversationManager.messageCount, greaterThan(3));
      final messages = conversationManager.messages;
      expect(messages[0].role, equals(MessageRole.user));
      expect(messages[1].role, equals(MessageRole.assistant));
      expect(messages[1].toolCalls, hasLength(1));
    });

    test('🔄 TOOL PROCESSING: hasUnprocessedToolCalls detection', () {
      // Test the hasUnprocessedToolCalls getter works correctly

      // Initially no tool calls
      expect(conversationManager.hasUnprocessedToolCalls, isFalse);

      // Add message without tool calls
      conversationManager.addUserMessage('Test without tools');
      conversationManager.addAssistantMessage('Response without tools');
      expect(conversationManager.hasUnprocessedToolCalls, isFalse);

      // Add message with tool calls
      final toolCall = {
        'id': 'call_test',
        'type': 'function',
        'function': {'name': 'test_tool', 'arguments': '{}'}
      };

      conversationManager.addAssistantMessage(
        '',
        toolCalls: [toolCall],
      );

      // Should detect unprocessed tool calls
      expect(conversationManager.hasUnprocessedToolCalls, isTrue);
      expect(conversationManager.lastToolCalls, hasLength(1));
      expect(conversationManager.lastToolCalls![0]['id'], equals('call_test'));
    });

    test('🎯 TOOL TRACKING: lastToolCalls getter functionality', () {
      // Test the lastToolCalls getter works correctly

      // Initially no tool calls
      expect(conversationManager.lastToolCalls, isNull);

      // Add non-assistant message
      conversationManager.addUserMessage('User message');
      expect(conversationManager.lastToolCalls, isNull);

      // Add assistant message without tool calls
      conversationManager.addAssistantMessage('Assistant response');
      expect(conversationManager.lastToolCalls, isNull);

      // Add assistant message with tool calls
      final toolCalls = [
        {
          'id': 'call_1',
          'type': 'function',
          'function': {'name': 'tool_1', 'arguments': '{}'}
        },
        {
          'id': 'call_2',
          'type': 'function',
          'function': {'name': 'tool_2', 'arguments': '{}'}
        }
      ];

      conversationManager.addAssistantMessage(
        '',
        toolCalls: toolCalls,
      );

      // Should return the tool calls
      expect(conversationManager.lastToolCalls, hasLength(2));
      expect(conversationManager.lastToolCalls![0]['id'], equals('call_1'));
      expect(conversationManager.lastToolCalls![1]['id'], equals('call_2'));
    });
  });

  group('🛡️ SYSTEM PROMPT PERSISTENCE: Conversation Clearing', () {
    late ConversationManager conversationManager;
    late Agent agent;
    late AgentModel agentModel;

    setUp(() {
      // Create test agent and conversation manager
      agentModel = AgentModel(
        id: 'test-agent-system',
        name: 'Test Agent System',
        systemPrompt: 'You are a helpful coding assistant',
      );

      agent = Agent(agentModel: agentModel);

      conversationManager = ConversationManager(
        name: 'test-conversation-system',
        agent: agent,
      );
    });

    test('🛡️ REGRESSION: System messages persist when conversation is cleared', () {
      // This test verifies that system prompts are preserved during conversation clearing
      // This was a critical bug where system messages were being lost

      // Add system message (stored as MessageRole.assistant with contextId: "system")
      conversationManager.addSystemMessage('You are a helpful coding assistant');
      
      // Add some conversation messages
      conversationManager.addUserMessage('Hello, can you help me with coding?');
      conversationManager.addAssistantMessage('Of course! I can help you with coding.');
      conversationManager.addUserMessage('What is the best way to learn Flutter?');
      conversationManager.addAssistantMessage('Flutter is great! Start with the official docs.');

      // Verify we have messages including system message
      expect(conversationManager.messageCount, equals(5));
      
      // Verify system message is present
      final messages = conversationManager.messages;
      final systemMessage = messages.firstWhere(
        (msg) => msg.contextId == 'system',
        orElse: () => throw Exception('System message not found'),
      );
      expect(systemMessage.content, contains('You are a helpful coding assistant'));

      // Clear the conversation
      conversationManager.clearConversation();

      // Verify system message persists
      expect(conversationManager.messageCount, equals(1),
          reason: 'Only system message should remain after clearing');
      
      final remainingMessages = conversationManager.messages;
      expect(remainingMessages.length, equals(1));
      expect(remainingMessages[0].contextId, equals('system'));
      expect(remainingMessages[0].content, contains('You are a helpful coding assistant'));
    });

    test('🛡️ REGRESSION: Context messages persist when conversation is cleared', () {
      // This test verifies that context messages are also preserved during clearing

      // Add system message
      conversationManager.addSystemMessage('You are a helpful assistant');
      
      // Add context message
      conversationManager.addContext('project', 'Current project: VibeCoder Flutter app');
      
      // Add conversation messages
      conversationManager.addUserMessage('What should I work on next?');
      conversationManager.addAssistantMessage('Based on your project context, I suggest...');

      // Verify we have messages including system and context
      expect(conversationManager.messageCount, equals(4));

      // Clear the conversation
      conversationManager.clearConversation();

      // Verify both system and context messages persist
      expect(conversationManager.messageCount, equals(2),
          reason: 'System and context messages should remain after clearing');
      
      final remainingMessages = conversationManager.messages;
      expect(remainingMessages.any((msg) => msg.contextId == 'system'), isTrue);
      expect(remainingMessages.any((msg) => msg.contextId == 'project'), isTrue);
    });

    test('🛡️ REGRESSION: Regular conversation messages are properly cleared', () {
      // This test verifies that regular user/assistant messages are actually cleared

      // Add system message
      conversationManager.addSystemMessage('You are a helpful assistant');
      
      // Add regular conversation
      conversationManager.addUserMessage('Hello');
      conversationManager.addAssistantMessage('Hi there!');
      conversationManager.addUserMessage('How are you?');
      conversationManager.addAssistantMessage('I\'m doing well, thanks!');

      // Verify we have 5 messages (1 system + 4 conversation)
      expect(conversationManager.messageCount, equals(5));

      // Clear the conversation
      conversationManager.clearConversation();

      // Verify only system message remains
      expect(conversationManager.messageCount, equals(1));
      
      final remainingMessages = conversationManager.messages;
      expect(remainingMessages.length, equals(1));
      expect(remainingMessages[0].contextId, equals('system'));
      
      // Verify no regular conversation messages remain
      expect(remainingMessages.any((msg) => msg.contextId == null), isFalse);
    });

    test('🎯 ARCHITECTURAL: Reasoning content is properly cleared', () {
      // This test verifies that reasoning content is cleared as expected

      // Add system message
      conversationManager.addSystemMessage('You are a helpful assistant');
      
      // Add assistant message with reasoning content
      conversationManager.addAssistantMessage(
        'Here is my response',
        reasoningContent: 'Let me think about this step by step...',
      );

      // Verify reasoning content exists
      expect(conversationManager.getReasoningContent(1), isNotNull);

      // Clear the conversation
      conversationManager.clearConversation();

      // Verify reasoning content is cleared
      expect(conversationManager.getReasoningContent(1), isNull);
      
      // Verify system message still exists
      expect(conversationManager.messageCount, equals(1));
    });
  });
}
