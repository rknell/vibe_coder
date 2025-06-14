import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import '../models/mcp_models.dart';
import 'mcp_client.dart';

/// Manager for MCP configurations and clients
class MCPManager {
  final Logger _logger = Logger('MCPManager');
  final Map<String, MCPClient> _clients = {};
  final Map<String, MCPServerConfig> _serverConfigs = {};
  final Map<String, List<MCPTool>> _availableTools = {};
  final Map<String, List<MCPResource>> _availableResources = {};
  final Map<String, List<MCPPrompt>> _availablePrompts = {};

  /// Load MCP configuration from a JSON file
  Future<void> loadConfiguration(String configPath) async {
    try {
      final configFile = File(configPath);
      if (!await configFile.exists()) {
        _logger.warning('MCP configuration file not found: $configPath');
        return;
      }

      final configContent = await configFile.readAsString();
      final configJson = jsonDecode(configContent) as Map<String, dynamic>;
      final mcpConfig = MCPConfig.fromJson(configJson);

      _serverConfigs.clear();
      _serverConfigs.addAll(mcpConfig.mcpServers);

      _logger.info('Loaded ${_serverConfigs.length} MCP server configurations');

      // Initialize all configured servers
      for (final serverName in _serverConfigs.keys) {
        await _initializeServer(serverName);
      }
    } catch (e) {
      _logger.severe('Failed to load MCP configuration: $e');
      throw MCPException('Failed to load configuration: $e');
    }
  }

  /// Initialize a specific MCP server
  Future<void> _initializeServer(String serverName) async {
    try {
      final serverConfig = _serverConfigs[serverName];
      if (serverConfig == null) {
        throw MCPException('Server configuration not found: $serverName');
      }

      // For HTTP/SSE servers, use the URL directly
      if (serverConfig.type == 'sse' || serverConfig.url != null) {
        final client = MCPClient(serverUrl: serverConfig.url!);
        await client.initialize();
        _clients[serverName] = client;

        // Load capabilities
        await _loadServerCapabilities(serverName);

        _logger
            .info('Initialized MCP server: $serverName (${serverConfig.url})');
        return;
      }

      // For stdio servers, we would need to handle process communication
      // This is more complex and would require additional infrastructure
      _logger.warning('STDIO MCP servers not yet implemented: $serverName');
    } catch (e) {
      _logger.severe('Failed to initialize MCP server $serverName: $e');
    }
  }

  /// Load capabilities from a server
  Future<void> _loadServerCapabilities(String serverName) async {
    final client = _clients[serverName];
    if (client == null) return;

    try {
      // Load tools
      final tools = await client.listTools();
      _availableTools[serverName] = tools;
      _logger.fine('Loaded ${tools.length} tools from $serverName');

      // Load resources
      final resources = await client.listResources();
      _availableResources[serverName] = resources;
      _logger.fine('Loaded ${resources.length} resources from $serverName');

      // Load prompts
      final prompts = await client.listPrompts();
      _availablePrompts[serverName] = prompts;
      _logger.fine('Loaded ${prompts.length} prompts from $serverName');
    } catch (e) {
      _logger.warning('Failed to load capabilities from $serverName: $e');
    }
  }

  /// Get all available tools across all servers
  Map<String, List<MCPTool>> get availableTools =>
      Map.unmodifiable(_availableTools);

  /// Get all available resources across all servers
  Map<String, List<MCPResource>> get availableResources =>
      Map.unmodifiable(_availableResources);

  /// Get all available prompts across all servers
  Map<String, List<MCPPrompt>> get availablePrompts =>
      Map.unmodifiable(_availablePrompts);

  /// Get a flattened list of all tools with server context
  List<MCPToolWithServer> getAllTools() {
    final allTools = <MCPToolWithServer>[];

    for (final entry in _availableTools.entries) {
      final serverName = entry.key;
      final tools = entry.value;

      for (final tool in tools) {
        allTools.add(MCPToolWithServer(
          tool: tool,
          serverName: serverName,
        ));
      }
    }

    return allTools;
  }

  /// Call a tool on a specific server
  Future<MCPToolCallResult> callTool({
    required String serverName,
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    final client = _clients[serverName];
    if (client == null) {
      throw MCPException('Server not found or not initialized: $serverName');
    }

    final toolCall = MCPToolCallRequest(
      name: toolName,
      arguments: arguments,
    );

    try {
      final result = await client.callTool(toolCall);
      _logger.info('Called tool $toolName on $serverName successfully');
      return result;
    } catch (e) {
      _logger.severe('Failed to call tool $toolName on $serverName: $e');
      rethrow;
    }
  }

  /// Find which server provides a specific tool
  String? findServerForTool(String toolName) {
    for (final entry in _availableTools.entries) {
      final serverName = entry.key;
      final tools = entry.value;

      if (tools.any((tool) => tool.name == toolName)) {
        return serverName;
      }
    }

    return null;
  }

  /// Get a resource from a specific server
  Future<MCPTextContent> getResource({
    required String serverName,
    required String uri,
  }) async {
    final client = _clients[serverName];
    if (client == null) {
      throw MCPException('Server not found or not initialized: $serverName');
    }

    try {
      final result = await client.readResource(uri);
      _logger.info('Retrieved resource $uri from $serverName successfully');
      return result;
    } catch (e) {
      _logger.severe('Failed to get resource $uri from $serverName: $e');
      rethrow;
    }
  }

  /// Get a prompt from a specific server
  Future<List<MCPTextContent>> getPrompt({
    required String serverName,
    required String promptName,
    Map<String, dynamic>? arguments,
  }) async {
    final client = _clients[serverName];
    if (client == null) {
      throw MCPException('Server not found or not initialized: $serverName');
    }

    try {
      final result = await client.getPrompt(promptName, arguments: arguments);
      _logger
          .info('Retrieved prompt $promptName from $serverName successfully');
      return result;
    } catch (e) {
      _logger.severe('Failed to get prompt $promptName from $serverName: $e');
      rethrow;
    }
  }

  /// Refresh capabilities for all servers
  Future<void> refreshCapabilities() async {
    _logger.info('Refreshing capabilities for all servers');

    for (final serverName in _clients.keys) {
      await _loadServerCapabilities(serverName);
    }

    _logger.info('Capabilities refresh completed');
  }

  /// Close all connections
  Future<void> closeAll() async {
    _logger.info('Closing all MCP connections');

    for (final client in _clients.values) {
      await client.close();
    }

    _clients.clear();
    _availableTools.clear();
    _availableResources.clear();
    _availablePrompts.clear();

    _logger.info('All MCP connections closed');
  }

  /// Get connected server names
  List<String> get connectedServers => _clients.keys.toList();

  /// Check if a server is connected
  bool isServerConnected(String serverName) => _clients.containsKey(serverName);
}

/// Tool with server context
class MCPToolWithServer {
  final MCPTool tool;
  final String serverName;

  MCPToolWithServer({
    required this.tool,
    required this.serverName,
  });

  /// Get a unique identifier for this tool
  String get uniqueId => '$serverName:${tool.name}';
}
