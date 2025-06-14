// NOTE: This class depends on fixes to the DeepSeekApiClient in api_client.dart
// It cannot be used until those fixes are applied.
//
// Key issues that need to be fixed in api_client.dart:
// 1. Add the ToolCall class to properly handle tool calls in the API response
// 2. Fix the _roleFromString helper method for converting role strings to enum values
// 3. Fix the DeepSeekApiException class and its subclasses
// 4. Fix the ChatCompletionChoice.fromJson method to properly convert finish_reason strings to FinishReason enum values
// 5. Fix the error handling in createChatCompletion to properly catch and handle JSON parsing errors

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:vibe_coder/ai_agent/agent.dart';
import 'package:vibe_coder/ai_agent/services/api_client.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/tool_choice.dart';
// BaseTool removed - now using MCP integration
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:vibe_coder/ai_agent/models/chat_completion_request.dart';
import 'package:vibe_coder/services/services.dart';
import 'mcp_function_bridge.dart';

/// Manages multi-round conversations with the DeepSeek Chat API.
///
/// This class provides a way to maintain conversation history across
/// multiple API calls, ensuring context is preserved throughout
/// a multi-turn interaction.
///
/// IMPORTANT: This class can be instantiated multiple times to manage
/// multiple concurrent conversations, each with its own history and settings.
/// Each instance is completely independent.
class ConversationManager {
  /// The API client used to make requests to the DeepSeek API
  late final DeepSeekApiClient _apiClient;

  /// The conversation history, including both user and assistant messages
  final List<ChatMessage> _messages = [];

  /// Store reasoning content separately to preserve it for the user
  /// but exclude it from subsequent API calls
  final Map<int, String?> _reasoningContent = {};

  /// MCP tools are now handled by the Agent's MCPManager
  /// Tools and tool choice removed - using MCP integration instead

  // Temporary stubs to maintain compatibility during migration
  List<dynamic>? _tools;
  dynamic _toolChoice;

  /// Logger for this conversation manager
  final Logger _logger;

  /// The model to use for chat completions
  final String model;

  /// Temperature setting for generation
  final double temperature;

  /// Maximum tokens to generate
  final int? maxTokens;

  final String name;

  final String id;

  Agent agent;

  /// Creates a new [ConversationManager] with the specified settings.
  ///
  /// [apiClient] is required for making requests to the DeepSeek API.
  /// [name] provides a unique identifier for this conversation (defaults to a timestamp)
  /// [model] specifies which model to use (default is 'deepseek-chat').
  /// [temperature] controls the randomness of the output (default is 0.7).
  /// [maxTokens] limits the total length of the generated response.
  /// [logger] allows providing a custom logger (if not provided, one will be created)
  ConversationManager(
      {required this.name,
      this.model = 'deepseek-chat',
      this.temperature = 0.7,
      this.maxTokens,
      required this.agent})
      : id = name,
        _logger = services.logging(name),
        _apiClient = DeepSeekApiClient();

  /// Gets a copy of the current conversation history.
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Gets the number of messages in the conversation.
  int get messageCount => _messages.length;

  /// Gets the complete conversation history including all messages
  List<ChatMessage> getHistory() {
    return List.unmodifiable(_messages);
  }

  /// Gets a copy of the conversation messages prepared for API requests,
  /// with reasoningContent fields removed to prevent API errors.
  List<ChatMessage> get apiReadyMessages {
    final apiMessages = <ChatMessage>[];

    for (var i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      // Create a new message without reasoningContent
      apiMessages.add(ChatMessage(
        role: message.role,
        content: message.content,
        name: message.name,
        prefix: message.prefix,
        toolCalls: message.toolCalls,
        toolCallId: message.toolCallId,
        // No reasoningContent
      ));
    }

    return apiMessages;
  }

  /// Gets the reasoning content for a specific message in the conversation.
  /// Returns null if there is no reasoning content for the specified index.
  String? getReasoningContent(int messageIndex) {
    if (messageIndex < 0 || messageIndex >= _messages.length) {
      throw RangeError('Message index out of range');
    }
    return _reasoningContent[messageIndex];
  }

  /// Gets the reasoning content for the last assistant message, if available.
  /// This is useful for extracting the chain of thought from the deepseek-reasoner model.
  String? get lastReasoningContent {
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == MessageRole.assistant) {
        return _reasoningContent[i];
      }
    }
    return null;
  }

  /// Tools are now handled by the Agent's MCPManager
  /// setTools method removed - MCP integration handles tool management

  /// Adds a context message to the conversation.
  ///
  /// Context messages provide additional information to the model.
  /// This method adds the context message at the beginning of the conversation,
  /// just before the first user or assistant message. Context messages are
  /// identified by having a contextId field set to "context".
  ///
  /// If a context message already exists in the conversation, its content
  /// will be replaced with the new context.
  ///
  /// [content] The context content to add to the conversation.
  void addContext(String contextId, String content) {
    var annotatedContent = """
```${contextId.toUpperCase()}
$content
```
""";
    var existingContext =
        _messages.firstWhereOrNull((item) => item.contextId == contextId);
    if (existingContext != null) {
      existingContext.content = annotatedContent;
    }
    var firstIndex = _messages.indexWhere(
        (item) => item.contextId == null && _messages.indexOf(item) != 0);
    var newMessage = ChatMessage(
        role: MessageRole.user,
        content: annotatedContent,
        contextId: contextId);
    if (firstIndex != -1) {
      // Insert at the specified index, pushing down existing items
      _messages.insert(firstIndex, newMessage);
      _logger.fine(
          'Added context message with ID "$contextId" at position $firstIndex');
    } else {
      // If no suitable position found, add to the end
      _messages.add(newMessage);
      _logger.fine(
          'Added context message with ID "$contextId" at the end of messages');
    }
  }

  void removeContext(String contextId) {
    _messages.removeWhere((item) => item.contextId == contextId);
  }

  /// Adds a system message to the conversation.
  ///
  /// System messages provide instructions or context to the model.
  /// Note that a conversation should have at most one system message,
  /// and it's most effective when placed at the start.
  ///
  /// NOTE: Currently this method creates a MessageRole.user instead of MessageRole.system
  /// because of compatibility issues with the API. This is by design.
  void addSystemMessage(String content) {
    _logger.fine('Adding system message');
    final message = ChatMessage(
      role: MessageRole.user,
      content: content,
    );
    _messages.add(message);
  }

  /// Adds a user message to the conversation.
  ///
  /// User messages contain the actual queries or inputs from the user.
  void addUserMessage(String content) {
    _logger.fine('Adding user message');
    final message = ChatMessage(
      role: MessageRole.user,
      content: content,
    );
    _messages.add(message);
  }

  /// Adds an assistant message to the conversation.
  ///
  /// Assistant messages are usually added automatically after receiving
  /// a response from the API, but this method allows for manual addition
  /// if needed.
  ///
  /// [reasoningContent] Optional chain of thought reasoning to store
  /// separately from the message (will not be sent in subsequent API calls).
  void addAssistantMessage(String content,
      {String? reasoningContent, List<Map<String, dynamic>>? toolCalls}) {
    _logger.fine('Adding assistant message');
    final message = ChatMessage(
      role: MessageRole.assistant,
      content: content,
      toolCalls: toolCalls,
    );
    _messages.add(message);

    // Store reasoning content separately if provided
    if (reasoningContent != null) {
      _reasoningContent[_messages.length - 1] = reasoningContent;
    }
  }

  /// Adds a tool response message to the conversation.
  ///
  /// Tool messages are created in response to tool calls from the model.
  /// Each tool message must reference the ID of the tool call it's responding to.
  ///
  /// [toolCallId] The ID of the tool call this message is responding to.
  /// [content] The result returned by the tool.
  void addToolMessage(String toolCallId, String content) {
    _logger.fine('Adding tool message for tool call ID: $toolCallId');

    final toolMessage = ChatMessage(
      role: MessageRole.tool,
      content: content,
      toolCallId: toolCallId,
    );

    _messages.add(toolMessage);
  }

  /// Returns true if the last message in the conversation contains tool calls that need to be processed.
  bool get hasUnprocessedToolCalls {
    if (_messages.isEmpty) return false;
    final lastMessage = _messages.last;
    return lastMessage.role == MessageRole.assistant &&
        lastMessage.toolCalls != null &&
        lastMessage.toolCalls!.isNotEmpty;
  }

  /// Gets the list of tool calls from the last assistant message, if any exist.
  List<Map<String, dynamic>>? get lastToolCalls {
    if (_messages.isEmpty) return null;
    final lastMessage = _messages.last;
    if (lastMessage.role != MessageRole.assistant) return null;
    return lastMessage.toolCalls;
  }

  /// Processes tool calls using the Agent's MCP integration.
  ///
  /// MCP tools are now handled at the Agent level through MCPManager.
  /// This method delegates tool processing to the Agent's MCP system.
  ///
  /// Returns true if tool calls were processed, false otherwise.
  Future<bool> processToolCalls() async {
    final toolCalls = lastToolCalls;
    if (toolCalls == null || toolCalls.isEmpty) {
      _logger.fine('No tool calls to process');
      return false;
    }

    _logger.fine('Processing ${toolCalls.length} tool calls via MCP');

    // Process each tool call through Agent's MCP system
    for (final toolCall in toolCalls) {
      try {
        // Extract tool call information
        if (!toolCall.containsKey('id') || !toolCall.containsKey('function')) {
          _logger.severe('Tool call missing required fields: $toolCall');
          continue;
        }

        final toolCallId = toolCall['id'] as String;
        final functionMap = toolCall['function'] as Map<String, dynamic>;
        final functionName = functionMap['name'] as String;
        final arguments = functionMap['arguments'] as String;

        _logger
            .fine('Processing MCP tool call: $functionName (ID: $toolCallId)');

        // Parse arguments
        Map<String, dynamic> argsMap;
        try {
          argsMap = jsonDecode(arguments) as Map<String, dynamic>;
        } catch (e) {
          _logger.warning('Failed to parse tool arguments: $e');
          _addToolErrorResponse(
              toolCallId, 'Error: Failed to parse arguments: $e');
          continue;
        }

        // 🔧 MCP FUNCTION CALLING: Convert API function name to MCP format and parse
        // CRITICAL: AI API sends function names like 'memory_read_graph' but MCP expects 'memory:read_graph'
        final mcpToolUniqueId =
            MCPFunctionBridge.fromApiFunctionName(functionName);

        String serverName;
        String actualToolName;

        if (mcpToolUniqueId.contains(':')) {
          // Format: serverName:toolName (proper MCP format)
          final parts = mcpToolUniqueId.split(':');
          serverName = parts[0];
          actualToolName = parts[1];
        } else {
          // Fallback: use existing logic to find server (should rarely happen)
          serverName =
              agent.mcpManager.findServerForTool(mcpToolUniqueId) ?? '';
          actualToolName = mcpToolUniqueId;
        }

        if (serverName.isEmpty) {
          _logger.warning(
              'Cannot find server for tool: $functionName (MCP format: $mcpToolUniqueId)');
          _addToolErrorResponse(
              toolCallId, 'Error: Server not found for tool "$functionName".');
          continue;
        }

        // 📝 TOOL CALL TRACKING: Register tool call for proper ID management
        MCPFunctionBridge.registerToolCall(
          toolCallId: toolCallId,
          toolName: actualToolName,
          serverName: serverName,
          arguments: argsMap,
        );

        // Call tool through Agent's MCP system
        try {
          final result = await agent.mcpManager.callTool(
            serverName: serverName,
            toolName: actualToolName,
            arguments: argsMap,
          );

          // Add successful tool response with proper tool_call_id
          _addToolResponse(toolCallId, result.content.first.text);

          // 🧹 CLEANUP: Complete tool call tracking
          MCPFunctionBridge.completeToolCall(toolCallId);
        } catch (e) {
          _logger.warning('MCP tool call failed: $functionName - $e');
          _addToolErrorResponse(
              toolCallId, 'Error: Tool "$functionName" failed: $e');

          // 🧹 CLEANUP: Complete tool call tracking even on failure
          MCPFunctionBridge.completeToolCall(toolCallId);
        }
      } catch (e, stackTrace) {
        _logger.severe('Error processing tool call: $e', e, stackTrace);
      }
    }

    // Validate all tool calls have responses
    _validateToolResponses();
    return true;
  }

  /// Adds a successful tool response to the conversation
  void _addToolResponse(String toolCallId, String response) {
    final toolMessage = ChatMessage(
      role: MessageRole.tool,
      content: response,
      toolCallId: toolCallId,
    );
    _messages.add(toolMessage);
  }

  /// Adds an error tool response to the conversation
  void _addToolErrorResponse(String toolCallId, String errorMessage) {
    final toolMessage = ChatMessage(
      role: MessageRole.tool,
      content: errorMessage,
      toolCallId: toolCallId,
    );
    _messages.add(toolMessage);
  }

  updateUserContext() {
    /// Updates or adds the relevant context from the agent before each send message call to ensure its relevant
    if (agent.notepad.isNotEmpty) {
      addContext("notepad", agent.notepad);
    } else {
      removeContext("notepad");
    }

    if (agent.toDoList.isNotEmpty) {
      addContext("to do list",
          agent.toDoList.take(5).map((item) => item).join("\n").toString());
    } else {
      removeContext("to do list");
    }

    if (agent.inbox.isNotEmpty) {
      addContext(
          'inbox', agent.inbox.take(5).map((item) => item.content).join('\n'));
    } else {
      removeContext("inbox");
    }

    // Add task completion rules as a context
    addContext("task_completion_rules", """
When processing inbox messages:
- Create TODO list tasks only if necessary to respond to the message
- If a message is informational or states something is COMPLETED, don't create unnecessary follow-up tasks
- Be specific and actionable when creating tasks
- Always create a todo list item to inform the sender once required actions are completed

When working on to-do tasks:
- Focus only on completing the specific task - do not create additional tasks unless absolutely necessary
- After completing a task, you MUST use the complete_todo_task tool to mark it as completed
- Use complete_todo_task with either the index parameter (e.g., complete_todo_task(index: 1)) or the task parameter
- If a task refers to sending information, mark it complete once sent
- If a task refers to reviewing something, mark it complete once reviewed and results communicated
""");

    // Add agent context files if they exist
    if (agent.contextFiles.isNotEmpty) {
      final fileContentBuilder = StringBuffer();

      // Process each file in the agent's context files list
      for (final filename in agent.contextFiles) {
        // TODO: Implement virtualFileService in new API
        // Read file content from shared storage
        // final content = services.virtualFileService.readFile(filename);
        const content = 'TODO: Implement file reading in new API';

        // Skip files that don't exist
        if (content.startsWith('Error:')) {
          _logger.warning('Failed to load context file "$filename": $content');
          continue;
        }

        fileContentBuilder.writeln("""
File: $filename
---
$content
---
""");
      }

      final contextContent = fileContentBuilder.toString();
      if (contextContent.isNotEmpty) {
        addContext("agent files", contextContent);
      } else {
        removeContext("agent files");
      }
    } else {
      removeContext("agent files");
    }
  }

  /// Sends the current conversation to the DeepSeek API and gets a response.
  ///
  /// The response is automatically added to the conversation history.
  /// Returns the content of the assistant's response.
  ///
  /// If tools are configured for this conversation, any tool calls in the response
  /// will be automatically processed, and a follow-up request will be sent with
  /// the tool results.
  ///
  /// [useBeta] can be set to true to use beta features like chat prefix completion.
  /// [isReasoner] set to true when using the deepseek-reasoner model, to properly handle chain of thought.
  /// Tools are now handled by Agent's MCP integration.
  /// [toolChoice] Controls which (if any) tool is called by the model.
  Future<String> sendMessage({
    bool useBeta = false,
    bool? isReasoner,
    ToolChoice? toolChoice,
  }) async {
    updateUserContext();
    if (_messages.isEmpty) {
      throw StateError(
          'Cannot send an empty conversation. Add at least one message first.');
    }

    // 🔧 MCP FUNCTION CALLING: Convert MCP tools to OpenAI function format
    final mcpTools = agent.getAvailableTools();
    final functions = MCPFunctionBridge.convertMCPToolsToFunctions(mcpTools);

    _logger.info(
        '🛠️ FUNCTION CALLING: Prepared ${functions.length} MCP functions for API');

    // Auto-set tool choice if functions are available
    final choice =
        toolChoice ?? (functions.isNotEmpty ? ToolChoice.auto : null);

    // Auto-detect if we're using the reasoner model if not specified
    final useReasoner = isReasoner ?? model.contains('reasoner');

    _logger.info('Sending conversation to API');

    // Validate that all tool calls have corresponding responses
    _validateToolResponses();

    // Use the clean messages list for API requests (without reasoningContent)
    final apiMessages = useReasoner ? apiReadyMessages : _messages;

    // Create the request with MCP functions
    final request = ChatCompletionRequest(
      model: model,
      messages: apiMessages,
      temperature: temperature,
      maxTokens: maxTokens,
      tools:
          functions.isNotEmpty ? functions : null, // 🔧 MCP TOOLS INTEGRATION
      toolChoice: choice,
    );

    if (useReasoner) {
      _logger.fine('Using deepseek-reasoner mode');
    }

    final response =
        await _apiClient.createChatCompletion(request, useBeta: useBeta);

    _logger.fine('Received API response');

    final assistantMessage = response.choices[0].message;
    final assistantContent = assistantMessage.content ?? '';
    final reasoningContent = assistantMessage.reasoningContent;

    // Create a clean message to add to history
    final newMessage = ChatMessage(
      role: MessageRole.assistant,
      content: assistantContent,
      name: assistantMessage.name,
      prefix: assistantMessage.prefix,
      toolCalls: assistantMessage.toolCalls,
      toolCallId: assistantMessage.toolCallId,
    );

    // Add the response to the conversation history
    _messages.add(newMessage);

    // Store reasoning content separately if present
    if (reasoningContent != null) {
      _reasoningContent[_messages.length - 1] = reasoningContent;
    }

    // Check if we received tool calls and process via MCP
    if (assistantMessage.toolCalls != null &&
        assistantMessage.toolCalls!.isNotEmpty) {
      // Process tool calls through Agent's MCP system
      final toolResponses = await processToolCalls();

      if (toolResponses) {
        // Send a follow-up message with the tool results
        return await sendMessage(
          useBeta: useBeta,
          isReasoner: isReasoner,
          toolChoice: toolChoice,
        );
      }
    }

    return assistantContent;
  }

  /// Gets the reasoning content for the last response from the API.
  /// This is particularly useful when using the deepseek-reasoner model.
  ///
  /// Returns the reasoning content or null if not available.
  String? getLastResponseReasoning() {
    return lastReasoningContent;
  }

  /// Sends a user message to the API and gets a response in one step.
  ///
  /// This is a convenience method that:
  /// 1. Adds the user message to the conversation
  /// 2. Sends the updated conversation to the API
  /// 3. Returns the assistant's response
  ///
  /// [userMessage] is the content of the user's message.
  /// [useBeta] can be set to true to use beta features.
  /// [isReasoner] set to true when using the deepseek-reasoner model.
  /// Tools are now handled by Agent's MCP integration.
  /// [toolChoice] Controls which tools can be called.
  Future<String> sendUserMessageAndGetResponse(
    String userMessage, {
    bool useBeta = false,
    bool? isReasoner,
    ToolChoice? toolChoice,
  }) async {
    addUserMessage(userMessage);

    return await sendMessage(
      useBeta: useBeta,
      isReasoner: isReasoner,
      toolChoice: toolChoice,
    );
  }

  /// Clears the conversation history, starting a new conversation.
  void clearConversation() {
    _logger.fine('[$id] Clearing conversation history');
    _messages.clear();
    _reasoningContent.clear();
  }

  /// Creates a copy of this conversation manager with the same history and settings.
  ///
  /// This is useful for creating a branch of the conversation that can diverge
  /// from the original.
  ///
  /// [newId] Optional new ID for the copied conversation manager.
  /// [logger] Optional new logger for the copied conversation manager.
  ConversationManager copy({String? newId, Logger? logger}) {
    final copy = ConversationManager(
        name: newId ?? '${id}_copy_${DateTime.now().millisecondsSinceEpoch}',
        model: model,
        temperature: temperature,
        agent: agent,
        maxTokens: maxTokens);

    // Copy all messages without reasoningContent
    for (var i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      copy._messages.add(ChatMessage(
        role: message.role,
        content: message.content,
        name: message.name,
        prefix: message.prefix,
        toolCalls: message.toolCalls,
        toolCallId: message.toolCallId,
        // Don't include reasoningContent in the copied message
      ));

      // Copy reasoning content separately if it exists
      if (_reasoningContent.containsKey(i)) {
        copy._reasoningContent[i] = _reasoningContent[i];
      }
    }

    // Copy tools configuration
    if (_tools != null) {
      copy._tools = _tools;
      copy._toolChoice = _toolChoice;
    }

    return copy;
  }

  /// Exports the conversation history to a JSON string.
  ///
  /// This is useful for saving conversations or debugging.
  /// The export includes the reasoning content for messages that have it.
  String toJson() {
    final jsonData = {
      'id': id,
      'model': model,
      'messages': <Map<String, dynamic>>[],
    };

    for (var i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      final messageJson = {
        'role': message.role.toString().split('.').last,
        'content': message.content,
        if (message.name != null) 'name': message.name,
        if (message.toolCalls != null) 'tool_calls': message.toolCalls,
        if (message.toolCallId != null) 'tool_call_id': message.toolCallId,
      };

      // Include reasoning content in the export if available
      if (_reasoningContent.containsKey(i)) {
        messageJson['reasoning_content'] = _reasoningContent[i];
      }

      (jsonData['messages'] as List).add(messageJson);
    }

    return const JsonEncoder.withIndent('  ').convert(jsonData);
  }

  /// Validates that every tool call in the conversation has a corresponding tool response.
  ///
  /// The DeepSeek API requires that every tool_call_id in an assistant message has a
  /// corresponding tool message with that toolCallId before the next API call.
  ///
  /// This method checks for missing responses and throws an error if any are found.
  void _validateToolResponses() {
    // Skip excessive logging for validation

    // Find all assistant messages with tool calls
    final assistantIndices = <int>[];
    for (var i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      if (message.role == MessageRole.assistant &&
          message.toolCalls != null &&
          message.toolCalls!.isNotEmpty) {
        assistantIndices.add(i);
      }
    }

    if (assistantIndices.isEmpty) {
      return; // No tool calls to validate
    }

    // For each assistant message with tool calls, validate that all tools have responses
    for (final assistantIndex in assistantIndices) {
      final assistantMessage = _messages[assistantIndex];
      if (assistantMessage.toolCalls == null) continue;

      // Extract all tool call IDs and their order
      final toolCallIds = <String>[];
      final toolCallDetails =
          <String, String>{}; // id -> name mapping for better errors
      final toolCallOrder = <String, int>{}; // id -> order in the message

      for (var i = 0; i < assistantMessage.toolCalls!.length; i++) {
        final toolCall = assistantMessage.toolCalls![i];
        if (toolCall.containsKey('id')) {
          final id = toolCall['id'];
          if (id is String) {
            toolCallIds.add(id);
            toolCallOrder[id] = i;

            // Store function name for better error messages
            try {
              if (toolCall.containsKey('function')) {
                final functionMap =
                    toolCall['function'] as Map<String, dynamic>;
                if (functionMap.containsKey('name')) {
                  final name = functionMap['name'] as String;
                  toolCallDetails[id] = name;
                }
              }
            } catch (e) {
              toolCallDetails[id] = 'unknown';
            }
          }
        }
      }

      if (toolCallIds.isEmpty) {
        continue;
      }

      // Find all corresponding tool responses *immediately* following the assistant message
      final responseIds = <String>{};
      final responseIndices = <String, int>{}; // id -> message index
      final responseOrder = <String, int>{}; // id -> order of response

      var responseCount = 0;
      for (var i = assistantIndex + 1; i < _messages.length; i++) {
        final message = _messages[i];
        if (message.role == MessageRole.tool &&
            message.toolCallId != null &&
            toolCallIds.contains(message.toolCallId)) {
          final id = message.toolCallId!;
          // Ensure we don't add duplicate response IDs if the loop somehow continues incorrectly
          if (!responseIds.contains(id)) {
            responseIds.add(id);
            responseIndices[id] = i;
            responseOrder[id] = responseCount++;
          } else {
            _logger.warning(
                "Duplicate tool response ID '$id' found during validation. Breaking loop.");
            break; // Avoid potential infinite loops or incorrect state
          }
        } else {
          // Stop processing responses for this assistant message as soon as
          // a non-tool message or an unrelated tool message is encountered.
          break;
        }
      }

      // Check for missing responses
      final missingIds =
          toolCallIds.where((id) => !responseIds.contains(id)).toList();
      if (missingIds.isNotEmpty) {
        final missingDetails = missingIds.map((id) {
          final toolName = toolCallDetails[id] ?? 'unknown';
          return '$id ($toolName)';
        }).join(', ');

        throw StateError(
            'Missing tool responses for tool calls: $missingDetails. '
            'Each tool call must have a corresponding tool response.');
      }

      // Validate response order matches tool call order
      final orderedToolCalls = toolCallIds.toList()
        ..sort((a, b) => toolCallOrder[a]!.compareTo(toolCallOrder[b]!));
      final orderedResponses = responseIds.toList()
        ..sort((a, b) => responseOrder[a]!.compareTo(responseOrder[b]!));

      // Compare lists manually since we can't use listEquals
      bool listsMatch = orderedToolCalls.length == orderedResponses.length;
      if (listsMatch) {
        for (var i = 0; i < orderedToolCalls.length; i++) {
          if (orderedToolCalls[i] != orderedResponses[i]) {
            listsMatch = false;
            break;
          }
        }
      }

      if (!listsMatch) {
        throw StateError(
            'Tool responses must be in the same order as tool calls. '
            'Expected order: ${orderedToolCalls.join(', ')}. '
            'Actual order: ${orderedResponses.join(', ')}');
      }

      // Validate no other messages between tool calls and their responses
      final lastToolCallIndex = assistantIndex;
      final firstResponseIndex = responseIndices.values.reduce(min);
      if (firstResponseIndex - lastToolCallIndex > 1) {
        throw StateError(
            'Tool responses must immediately follow their tool calls. '
            'Found ${firstResponseIndex - lastToolCallIndex - 1} messages in between.');
      }
    }
  }
}
