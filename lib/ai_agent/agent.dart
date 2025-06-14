import 'package:logging/logging.dart';
import 'package:vibe_coder/ai_agent/services/company_directory_service.dart';
import 'package:vibe_coder/ai_agent/services/conversation_manager.dart';
import 'package:vibe_coder/ai_agent/models/inbox_message.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:vibe_coder/ai_agent/services/mcp_manager.dart';
import 'package:vibe_coder/ai_agent/models/mcp_models.dart';
import 'package:vibe_coder/services/services.dart';
import 'dart:io';
import 'dart:convert';

class Agent {
  String systemPrompt;
  late final ConversationManager conversation;
  String name;
  String notepad;
  final List<InboxMessage> inbox;
  final List<String> toDoList;
  final List<String> taskDetails;
  final Agent? supervisor;
  final List<String> contextFiles; // List of filenames to include in context

  // MCP Integration
  late final MCPManager mcpManager;
  final String? mcpConfigPath;

  late final Logger logger;

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
        contextFiles = contextFiles ?? [] {
    companyDirectory.addAgent(this);

    conversation = ConversationManager(name: name, agent: this);

    // Initialize logger first
    logger = services.logging("AGENT-$name");
    logger.info('Agent "$name" initialized');
    logger.info('System prompt: $systemPrompt');

    // Initialize MCP Manager
    mcpManager = MCPManager();

    // Add system prompt and the inbox processing prompt
    final systemPromptAnnotated =
        "YOU ARE $name. \nRole play in the conversation as this person.\n$systemPrompt";
    conversation.addSystemMessage(systemPromptAnnotated);

    logger.info(
        'Agent constructor completed - MCP initialization will be done async');
  }

  /// Initialize MCP configuration - must be called after Agent construction
  ///
  /// PERF: O(n) where n = number of configured servers
  /// ARCHITECTURAL: Separated from constructor to allow proper async handling
  Future<void> initializeMCP() async {
    try {
      if (mcpConfigPath != null) {
        logger.info('🚀 AGENT MCP INIT: Starting with config: $mcpConfigPath');
        await mcpManager.initialize(mcpConfigPath!);
        logger.info('📋 MCP CONFIG: Configuration loaded from: $mcpConfigPath');
        logger.info(
            '🔗 CONNECTED: ${mcpManager.connectedServers.length} MCP servers connected');
        logger
            .info('⚙️ CONFIGURED: ${mcpManager.configuredServers.join(', ')}');

        // Log available tools
        final allTools = mcpManager.getAllTools();
        logger.info(
            '🛠️ TOOLS AVAILABLE: ${allTools.map((t) => t.uniqueId).join(', ')}');

        if (allTools.isEmpty) {
          logger.warning(
              '⚠️ NO TOOLS: No MCP tools are available despite server connections');
        }
      } else {
        logger.info('⚠️ NO CONFIG: No MCP configuration path provided');
      }
    } catch (e, stackTrace) {
      logger.severe(
          '💥 AGENT MCP FAILURE: Failed to initialize MCP: $e', e, stackTrace);
      rethrow; // Re-throw to allow caller to handle
    }
  }

  /// Get all available MCP tools
  List<MCPToolWithServer> getAvailableTools() {
    return mcpManager.getAllTools();
  }

  /// Call an MCP tool
  Future<MCPToolCallResult> callMCPTool({
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    final serverName = mcpManager.findServerForTool(toolName);
    if (serverName == null) {
      throw Exception('Tool not found: $toolName');
    }

    logger.info('Calling MCP tool: $toolName on server: $serverName');

    final result = await mcpManager.callTool(
      serverName: serverName,
      toolName: toolName,
      arguments: arguments,
    );

    logger.info('MCP tool call completed: $toolName');
    return result;
  }

  /// Get MCP resources
  Future<List<MCPResource>> getAvailableResources() async {
    final allResources = <MCPResource>[];

    for (final entry in mcpManager.availableResources.entries) {
      allResources.addAll(entry.value);
    }

    return allResources;
  }

  /// Get MCP prompts
  Future<List<MCPPrompt>> getAvailablePrompts() async {
    final allPrompts = <MCPPrompt>[];

    for (final entry in mcpManager.availablePrompts.entries) {
      allPrompts.addAll(entry.value);
    }

    return allPrompts;
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
      
      Available MCP tools: ${mcpManager.getAllTools().map((t) => t.uniqueId).join(', ')}
      
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
      
      Available MCP tools: ${mcpManager.getAllTools().map((t) => t.uniqueId).join(', ')}
      
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
Connected servers: ${mcpManager.connectedServers.join(", ")}
Available tools: ${mcpManager.getAllTools().map((t) => t.uniqueId).join(", ")}

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
      if (message.role == MessageRole.assistant &&
          message.toolCalls != null &&
          message.toolCalls!.isNotEmpty) {
        buffer.writeln('TOOL CALLS:');
        for (final toolCall in message.toolCalls!) {
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
  /// PERF: O(1) - resource cleanup
  Future<void> dispose() async {
    logger.info('Disposing Agent: $name');

    // Close MCP connections
    await mcpManager.closeAll();

    logger.info('Agent disposed: $name');
  }
}
