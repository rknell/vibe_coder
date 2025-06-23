import 'package:logging/logging.dart';
import 'package:vibe_coder/ai_agent/services/conversation_manager.dart';
import 'package:vibe_coder/ai_agent/models/inbox_message.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:vibe_coder/ai_agent/models/mcp_models.dart' as legacy;
import 'package:vibe_coder/services/services.dart';
import 'package:vibe_coder/services/mcp_service.dart';
import 'dart:io';
import 'dart:convert';

class Agent {
  String systemPrompt;
  final ConversationManager conversation;
  String name;
  String notepad;
  final List<InboxMessage> inbox;
  final List<String> toDoList;
  final List<String> taskDetails;
  final Agent? supervisor;
  final List<String> contextFiles; // List of filenames to include in context

  // MCP Integration - now uses shared services architecture
  final String? mcpConfigPath;

  final Logger logger;

  Agent({
    required this.systemPrompt,
    required this.name,
    this.notepad = '',
    List<InboxMessage>? inbox,
    List<String>? toDoList,
    List<String>? taskDetails,
    this.supervisor,
    List<String>? contextFiles,
    this.mcpConfigPath,
  })  : inbox = inbox ?? [],
        toDoList = toDoList ?? [],
        taskDetails = taskDetails ?? [],
        contextFiles = contextFiles ?? [],
        logger = Logger(
            "AGENT-$name"), // WARRIOR PROTOCOL: Direct initialization eliminates late variable vulnerability
        conversation = ConversationManager(name: name, agent: null) {
    // WARRIOR PROTOCOL: Direct initialization eliminates late variable vulnerability

    // Set agent reference after construction to avoid circular dependency
    conversation.agent = this;

    logger.info('Agent "$name" initialized');
    logger.info('System prompt: $systemPrompt');

    // MCP is now handled by Services.mcpService - no per-agent initialization needed

    // Add system prompt and the inbox processing prompt
    final systemPromptAnnotated =
        "YOU ARE $name. \nRole play in the conversation as this person.\n$systemPrompt";
    conversation.addSystemMessage(systemPromptAnnotated);

    logger.info(
        'Agent constructor completed - MCP initialization will be done async');
  }

  /// Initialize MCP configuration - INSTANT since MCP is pre-initialized globally
  ///
  /// PERF: O(1) - instant validation, no network calls or initialization
  /// ARCHITECTURAL: Uses shared services.mcpService instead of per-agent connections
  Future<void> initializeMCP() async {
    logger.info(
        '⚡ AGENT MCP: Using shared services MCP infrastructure (INSTANT)');

    try {
      final mcpService = services.mcpService;

      if (!mcpService.isInitialized) {
        logger.warning(
            '⚠️ AGENT MCP: MCP service not initialized yet - deferring');
        return;
      }

      final toolCount = mcpService.getAllTools().length;
      final serverCount = mcpService.connectedServers.length;

      logger.info(
          '✅ AGENT MCP: Connected to shared MCP infrastructure (INSTANT)');
      logger.info('🔗 SERVERS: $serverCount connected servers');
      logger.info('🛠️ TOOLS: $toolCount available tools');

      if (toolCount == 0) {
        logger.warning('⚠️ NO TOOLS: No MCP tools available from service');
      }
    } catch (e, stackTrace) {
      logger.severe(
          '💥 AGENT MCP: Failed to access MCP service: $e', e, stackTrace);
      // Don't rethrow - agent can still function without MCP
      logger.warning('🛡️ AGENT DEGRADED: Continuing without MCP tools');
    }
  }

  /// Get all available MCP tools from service
  ///
  /// PERF: O(1) - direct access to shared MCP infrastructure
  List<MCPToolWithServer> getAvailableTools() {
    final mcpService = services.mcpService;
    if (!mcpService.isInitialized) {
      logger.warning('⚠️ AGENT: MCP service not initialized');
      return [];
    }
    return mcpService.getAllTools();
  }

  /// Call an MCP tool using service
  ///
  /// PERF: O(1) - direct delegation to shared connections
  Future<legacy.MCPToolCallResult> callMCPTool({
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    final mcpService = services.mcpService;
    if (!mcpService.isInitialized) {
      throw Exception('MCP service not initialized');
    }

    final serverName = mcpService.findServerForTool(toolName);
    if (serverName == null) {
      throw Exception('Tool not found: $toolName');
    }

    logger.info('Calling MCP tool: $toolName on server: $serverName');

    final result = await mcpService.callTool(
      serverId: _getServerIdByName(serverName),
      toolName: toolName,
      arguments: arguments,
    );

    logger.info('MCP tool call completed: $toolName');

    // Convert service result to expected format
    final content = result['content'] as List<dynamic>? ?? [];
    final textContent = content.isNotEmpty && content[0] is Map<String, dynamic>
        ? (content[0] as Map<String, dynamic>)['text'] as String? ?? ''
        : '';

    return legacy.MCPToolCallResult(
      content: [
        legacy.MCPTextContent(
          type: 'text',
          text: textContent,
        )
      ],
      isError: result['isError'] as bool? ?? false,
    );
  }

  /// Get server ID by name - helper method for service integration
  String _getServerIdByName(String serverName) {
    final mcpService = services.mcpService;
    final server = mcpService.getByName(serverName);
    return server?.id ?? serverName;
  }

  /// Get MCP resources from service
  ///
  /// PERF: O(1) - direct access to shared resources
  Future<List<legacy.MCPResource>> getAvailableResources() async {
    final mcpService = services.mcpService;
    if (!mcpService.isInitialized) {
      logger.warning('⚠️ AGENT: MCP service not initialized');
      return [];
    }

    final allResources = <legacy.MCPResource>[];
    for (final server in mcpService.connectedServers) {
      for (final resource in server.availableResources) {
        // Convert new MCPResource to legacy MCPResource
        allResources.add(legacy.MCPResource(
          uri: resource.uri,
          name: resource.name,
          description: resource.description,
          mimeType: resource.mimeType,
        ));
      }
    }

    return allResources;
  }

  /// Get MCP prompts from service
  ///
  /// PERF: O(1) - direct access to shared prompts
  Future<List<legacy.MCPPrompt>> getAvailablePrompts() async {
    final mcpService = services.mcpService;
    if (!mcpService.isInitialized) {
      logger.warning('⚠️ AGENT: MCP service not initialized');
      return [];
    }

    final allPrompts = <legacy.MCPPrompt>[];
    for (final server in mcpService.connectedServers) {
      for (final prompt in server.availablePrompts) {
        // Convert new MCPPrompt to legacy MCPPrompt
        allPrompts.add(legacy.MCPPrompt(
          name: prompt.name,
          description: prompt.description,
          arguments: prompt.arguments
              ?.map((arg) => legacy.MCPPromptArgument(
                    name: arg.name,
                    description: arg.description,
                    required: arg.required,
                  ))
              .toList(),
        ));
      }
    }

    return allPrompts;
  }

  /// Refresh all MCP servers using service
  ///
  /// PERF: O(n) where n = number of servers - delegates to shared service
  /// 🎯 WARRIOR ENHANCEMENT: Uses service for consistent refresh across all agents
  Future<void> refreshMCPWithConfig() async {
    logger.info('🔄 AGENT MCP: Requesting MCP refresh through service');

    try {
      final mcpService = services.mcpService;
      if (!mcpService.isInitialized) {
        logger.warning('⚠️ AGENT MCP: MCP service not initialized');
        return;
      }

      await mcpService.refreshAll();
      logger.info('✅ AGENT MCP: Service refresh completed successfully');
    } catch (e, stackTrace) {
      logger.severe('💥 AGENT MCP: Service refresh failed: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Adds a file to the agent's context files list
  ///
  /// This method adds a filename to the list of files that should be included
  /// in the agent's context.
  ///
  /// [filename] The name of the file to add to context
  ///
  /// Returns true if the file was added, false if it already exists in the list
  bool addFileToContext(String filename) {
    // Only add if not already in the list
    if (!contextFiles.contains(filename)) {
      contextFiles.add(filename);
      logger.fine('Added file "$filename" to context');
      return true;
    }

    logger.fine('File "$filename" already in context');
    return false;
  }

  /// Removes a file from the agent's context files list
  ///
  /// This method removes a filename from the list of files included in the agent's context.
  /// The file remains in the shared virtual file storage.
  ///
  /// [filename] The name of the file to remove from context
  ///
  /// Returns true if the file was removed, false if it wasn't in the context
  bool removeFileFromContext(String filename) {
    final removed = contextFiles.remove(filename);

    if (removed) {
      logger.fine('Removed file "$filename" from context');
    } else {
      logger.warning(
          'Attempted to remove non-existent file "$filename" from context');
    }

    return removed;
  }

  /// Returns true if the specified file is in the agent's context
  bool hasFileInContext(String filename) {
    return contextFiles.contains(filename);
  }

  /// Sends a message to another agent's inbox
  void sendMessage(Agent recipient, String content) {
    // Log the message being sent
    final inboxMessage = InboxMessage(
      content: content,
      sender: this,
    );
    recipient.inbox.add(inboxMessage);

    // Note: We don't add the user message to conversation history here
    // It will be added after the tool response is processed
  }

  /// Sends a message to the agent's supervisor if one exists
  ///
  /// This is a convenience method that checks if a supervisor is assigned
  /// and sends a message to them if so. If no supervisor is assigned,
  /// this method logs a warning and does nothing.
  ///
  /// [content] is the message content to send to the supervisor
  void sendMessageToSupervisor(String content) {
    var supervisor = this.supervisor;
    if (supervisor != null) {
      sendMessage(supervisor, content);
      logger.fine('Message sent to supervisor ${supervisor.name}: $content');
    } else {
      logger.warning(
          'Cannot send message to supervisor: No supervisor assigned for agent $name');
    }
  }

  Future<void> think() async {
    // Skip thinking process if both inbox and to-do list are empty
    logger.fine('Agent $name is thinking...');

    if (inbox.isEmpty && toDoList.isEmpty) {
      logger.fine('Nothing to process in inbox or to-do list');
      return;
    }

    if (inbox.isNotEmpty) {
      await processInboxItems();
    }

    if (toDoList.isNotEmpty) {
      await processToDoList();
    }

    // Process inbox messages and to-do items
    // This is where the agent would analyze its current state,
    // prioritize tasks, and determine next actions based on
    // inbox messages and to-do list items

    // The actual implementation would likely involve:
    // 1. Analyzing inbox messages
    // 2. Prioritizing to-do list items
    // 3. Using the conversation manager to process information
    // 4. Potentially using MCP tools to complete tasks
    // 5. Updating the notepad with new information
    // 6. Generating reports as needed
  }

  /// Processes items in the agent's to-do list
  ///
  /// This method processes the first item in the to-do list,
  /// using the conversation manager to handle the task.
  /// If the to-do list is empty, this method returns immediately.
  Future<void> processToDoList() async {
    if (toDoList.isEmpty) {
      return;
    }

    // Get the current to-do item being processed
    final currentTask = toDoList.first;
    logger.info('Processing to-do item: $currentTask');

    // Add the task to conversation history
    conversation.addUserMessage("""
      ------
      TO-DO TASK:
      $currentTask
      -------
      Complete this task. Use appropriate MCP tools as needed.
      
      Available MCP tools: ${services.mcpService.getAllTools().map((t) => t.uniqueId).join(', ')}
      
      Current date and time: ${DateTime.now().toIso8601String()}
      """);

    try {
      // Send the message and process any tool calls automatically
      logger.fine('Working on to-do task');

      await conversation.sendMessage();

      // Note: We don't automatically remove the task here
      // The agent should use an appropriate MCP tool to mark tasks as complete
      // This ensures proper tracking and notification to supervisor

      // conversation.clearConversation();
    } catch (e) {
      // Handle any errors during processing
      logger.severe('Error processing to-do task: $e');
    }
  }

  Future<void> processInboxItems() async {
    if (inbox.isEmpty) {
      return;
    }

    // Get the current inbox message being processed
    final currentMessage = inbox.first;
    logger.info(
        'Processing inbox message from ${currentMessage.sender.name}: ${currentMessage.content}');

    // Prepare the prompt for processing the inbox item
    var prompt = currentMessage.content;

    // Add the user message to conversation history after tool response
    conversation.addUserMessage("""
      ------
      MESSAGE RECEIVED FROM: ${currentMessage.sender.name}
      ${currentMessage.content}
      -------
      Process this message and create any necessary tasks.
      
      Available MCP tools: ${services.mcpService.getAllTools().map((t) => t.uniqueId).join(', ')}
      
      Current date & time: ${DateTime.now().toIso8601String()}
      """);

    conversation.addUserMessage(prompt);
    try {
      // Send the message and process any tool calls automatically
      logger.fine('Actioning inbox message');

      await conversation.sendMessage();

      // Remove the processed item from inbox
      if (inbox.isNotEmpty) {
        logger.fine('Removing processed inbox item');
        inbox.removeAt(0);
      }
      conversation.clearConversation();
    } catch (e) {
      // Handle any errors during processing
      logger.severe('Error processing inbox item: $e');
    }
  }

  String details() {
    return """
----- $name -----

Notepad
-----------
$notepad

Inbox
-----------
${inbox.join("\n")}

ToDo List
----------
${toDoList.join("\n")}

Context Files
-----------
${contextFiles.join("\n")}

MCP Status
-----------
Connected servers: ${services.mcpService.connectedServers.join(", ")}
Available tools: ${services.mcpService.getAllTools().map((t) => t.uniqueId).join(", ")}

----------------
""";
  }

  /// Dumps the conversation history to a log file in the logs directory
  /// The file will be named {agent_name}.log
  Future<void> dumpConversationHistory() async {
    final dir = Directory('logs');
    if (!await dir.exists()) {
      await dir.create();
    }

    final logFile = File('logs/${name.toLowerCase()}.log');
    final buffer = StringBuffer();

    // Add timestamp header
    buffer.writeln(
        '=== Conversation History Dump ${DateTime.now().toIso8601String()} ===\n');

    // Get conversation history from the conversation manager
    final history = conversation.getHistory();

    for (final message in history) {
      buffer.writeln(
          '${message.role.toString().split('.').last.toUpperCase()}: ${message.content}\n');

      // If this is an assistant message with tool calls, log them
      final toolCalls = message.toolCalls;
      if (message.role == MessageRole.assistant &&
          toolCalls != null &&
          toolCalls.isNotEmpty) {
        buffer.writeln('TOOL CALLS:');
        for (final toolCall in toolCalls) {
          final toolJson = const JsonEncoder.withIndent('  ').convert(toolCall);
          buffer.writeln('$toolJson\n');
        }
      }

      // If this is a tool response, indicate which tool call it's responding to
      if (message.role == MessageRole.tool && message.toolCallId != null) {
        buffer.writeln('TOOL RESPONSE for call ID: ${message.toolCallId}\n');
      }

      buffer.writeln('---\n');
    }

    buffer.writeln('=== End of Dump ===\n\n');

    // Append to file
    await logFile.writeAsString(buffer.toString(), mode: FileMode.append);
    logger.fine('Conversation history dumped to ${logFile.path}');
  }

  /// Cleanup agent resources
  ///
  /// PERF: O(1) - resource cleanup - now uses shared services MCP service
  Future<void> dispose() async {
    logger.info('Disposing Agent: $name');

    // MCP connections are shared globally - no need to close per agent
    logger.info('Agent disposed: $name (MCP connections remain shared)');
  }
}
