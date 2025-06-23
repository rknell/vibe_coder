import 'package:logging/logging.dart';
import 'package:vibe_coder/ai_agent/services/conversation_manager.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:vibe_coder/ai_agent/models/mcp_models.dart' as legacy;
import 'package:vibe_coder/services/services.dart';
import 'package:vibe_coder/services/mcp_service.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'dart:io';
import 'dart:convert';

class Agent {
  // Reference to AgentModel - single source of truth
  final AgentModel agentModel;

  final ConversationManager conversation;
  final List<String> taskDetails;
  final Agent? supervisor;

  final Logger logger;

  Agent({
    required this.agentModel,
    List<String>? taskDetails,
    this.supervisor,
  })  : taskDetails = taskDetails ?? [],
        logger = Logger(
            "AGENT-${agentModel.name}"), // WARRIOR PROTOCOL: Direct initialization eliminates late variable vulnerability
        conversation = ConversationManager(name: agentModel.name, agent: null) {
    // WARRIOR PROTOCOL: Direct initialization eliminates late variable vulnerability

    // Set agent reference after construction to avoid circular dependency
    conversation.agent = this;

    logger.info('Agent "${agentModel.name}" initialized');
    logger.info('System prompt: ${agentModel.systemPrompt}');

    // MCP is now handled by Services.mcpService - no per-agent initialization needed

    // Add system prompt
    final systemPromptAnnotated =
        "YOU ARE ${agentModel.name}. \nRole play in the conversation as this person.\n${agentModel.systemPrompt}";
    conversation.addSystemMessage(systemPromptAnnotated);

    logger.info(
        'Agent constructor completed - MCP initialization will be done async');
  }

  // Convenience getters that delegate to AgentModel
  String get name => agentModel.name;
  String get systemPrompt => agentModel.systemPrompt;
  List<String> get contextFiles => agentModel.contextFiles;
  String? get mcpConfigPath => agentModel.mcpConfigPath;

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

  /// Get available MCP tools filtered by agent preferences
  ///
  /// PERF: O(n) where n = number of tools - filtering based on agent preferences
  /// ARCHITECTURAL: Single source of truth - uses AgentModel preferences directly
  List<MCPToolWithServer> getAvailableTools() {
    final mcpService = services.mcpService;
    if (!mcpService.isInitialized) {
      logger.warning('⚠️ AGENT: MCP service not initialized');
      return [];
    }

    final allTools = mcpService.getAllTools();
    final filteredTools = <MCPToolWithServer>[];

    for (final tool in allTools) {
      final serverName = tool.serverName;
      final toolUniqueId =
          tool.uniqueId; // This should be in format "server:tool"

      // Check server preference (defaults to true if not set)
      final serverEnabled = agentModel.getMCPServerPreference(serverName);
      if (!serverEnabled) {
        continue; // Skip tools from disabled servers
      }

      // Check individual tool preference (defaults to true if not set)
      final toolEnabled = agentModel.getMCPToolPreference(toolUniqueId);
      if (!toolEnabled) {
        continue; // Skip disabled tools
      }

      // Tool is enabled - add to filtered list
      filteredTools.add(tool);
    }

    logger.info(
        '🛠️ AGENT TOOLS: Filtered ${filteredTools.length}/${allTools.length} tools based on preferences');

    return filteredTools;
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
    if (!agentModel.contextFiles.contains(filename)) {
      agentModel.contextFiles.add(filename);
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
    final removed = agentModel.contextFiles.remove(filename);

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
    return agentModel.contextFiles.contains(filename);
  }

  // NOTE: Inter-agent messaging is now handled by MCP servers

  // NOTE: Supervisor messaging is now handled by MCP servers

  // NOTE: Agent thinking/processing is now handled by conversation flow and MCP tools

  // NOTE: Task processing is now handled by MCP task servers

  // NOTE: Inbox processing is now handled by MCP messaging servers

  String details() {
    return """
----- ${agentModel.name} -----

Context Files
-----------
${agentModel.contextFiles.join("\n")}

MCP Status
-----------
Connected servers: ${services.mcpService.connectedServers.join(", ")}
Available tools: ${getAvailableTools().map((t) => t.uniqueId).join(", ")}

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

    final logFile = File('logs/${agentModel.name.toLowerCase()}.log');
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
    logger.info('Disposing Agent: ${agentModel.name}');

    // MCP connections are shared globally - no need to close per agent
    logger.info(
        'Agent disposed: ${agentModel.name} (MCP connections remain shared)');
  }
}
