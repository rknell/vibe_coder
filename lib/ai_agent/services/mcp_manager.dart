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
        _logger.info('🔌 CONNECTING: Attempting to connect to $serverName...');
        await _connectToServer(serverName);
      }
    } catch (e) {
      _logger.severe('Failed to load MCP configuration: $e');
      throw MCPException('Failed to load configuration: $e');
    }
  }

  /// Initialize MCP servers from configuration
  Future<void> initialize(String configPath) async {
    _logger.info('🚀 MCP MANAGER: Starting initialization...');

    try {
      await loadConfiguration(configPath);
      _logger.info(
          '📋 CONFIG LOADED: ${_serverConfigs.length} servers configured');

      _logger.info('✅ MCP MANAGER: Initialization completed successfully');
    } catch (e, stackTrace) {
      _logger.severe('💥 MCP MANAGER FAILURE: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Connect to a specific server
  Future<void> _connectToServer(String serverName) async {
    final config = _serverConfigs[serverName];
    if (config == null) {
      _logger.warning(
          '⚠️ CONFIG MISSING: No configuration for server $serverName');
      return;
    }

    try {
      _logger.info(
          '🔧 SERVER CONFIG: $serverName - Type: ${config.type ?? (config.command != null ? 'stdio' : 'unknown')}');

      MCPClient client;

      if (config.type == 'sse' || config.url != null) {
        _logger
            .info('🌐 HTTP CLIENT: Creating HTTP/SSE client for $serverName');
        client = MCPClient(serverUrl: config.url!);
      } else if (config.command != null) {
        _logger.info('📟 STDIO CLIENT: Creating STDIO client for $serverName');
        _logger.info(
            '📟 STDIO COMMAND: ${config.command} ${config.args?.join(' ') ?? ''}');
        _logger.info(
            '📟 STDIO ENV: ${config.env?.keys.join(', ') ?? 'No custom env'}');

        client = MCPClient.stdio(
          command: config.command!,
          args: config.args,
          env: config.env,
        );
      } else {
        _logger.severe(
            '💀 INVALID CONFIG: Server $serverName has no valid transport configuration');
        return;
      }

      _logger.info(
          '🤝 INITIALIZING: Starting client initialization for $serverName...');
      await client.initialize();
      _logger
          .info('✅ CLIENT READY: $serverName client initialized successfully');

      _clients[serverName] = client;
      _logger.info('🔗 CLIENT STORED: $serverName added to active clients');

      // Load server capabilities
      _logger.info('🔍 CAPABILITIES: Loading capabilities for $serverName...');
      await _loadServerCapabilities(serverName);
      _logger.info(
          '✅ CAPABILITIES LOADED: $serverName capabilities loaded successfully');
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 CONNECTION FAILED: Server $serverName failed to connect: $e',
          e,
          stackTrace);
      // Don't rethrow - continue with other servers
    }
  }

  /// Load capabilities for a specific server
  /// Tools are required, resources and prompts are optional
  Future<void> _loadServerCapabilities(String serverName) async {
    final client = _clients[serverName];
    if (client == null) {
      _logger.warning(
          '⚠️ NO CLIENT: Cannot load capabilities for disconnected server $serverName');
      return;
    }

    try {
      // Load tools (REQUIRED) - if this fails, server is considered broken
      _logger.info('🛠️ LOADING TOOLS: Fetching tools for $serverName...');
      final tools = await client.listTools();
      _availableTools[serverName] = tools;
      _logger.info('✅ TOOLS LOADED: $serverName has ${tools.length} tools');

      for (int i = 0; i < tools.length; i++) {
        _logger.info(
            '🔧 TOOL[$i]: ${tools[i].name} - ${tools[i].description ?? 'No description'}');
      }

      // Load resources (OPTIONAL) - graceful degradation if unsupported
      _logger
          .info('📚 LOADING RESOURCES: Fetching resources for $serverName...');
      try {
        final resources = await client.listResources();
        _availableResources[serverName] = resources;
        _logger.info(
            '✅ RESOURCES LOADED: $serverName has ${resources.length} resources');
      } catch (e) {
        _logger.info(
            'ℹ️ RESOURCES OPTIONAL: $serverName does not support resources');
        _availableResources[serverName] =
            []; // Empty list for unsupported capability
      }

      // Load prompts (OPTIONAL) - graceful degradation if unsupported
      _logger.info('📝 LOADING PROMPTS: Fetching prompts for $serverName...');
      try {
        final prompts = await client.listPrompts();
        _availablePrompts[serverName] = prompts;
        _logger.info(
            '✅ PROMPTS LOADED: $serverName has ${prompts.length} prompts');
      } catch (e) {
        _logger
            .info('ℹ️ PROMPTS OPTIONAL: $serverName does not support prompts');
        _availablePrompts[serverName] =
            []; // Empty list for unsupported capability
      }

      _logger.info(
          '✅ CAPABILITIES LOADED: $serverName capabilities loaded successfully');
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 CAPABILITIES FAILED: Failed to load required capabilities for $serverName: $e',
          e,
          stackTrace);
      // Remove client only if REQUIRED capabilities (tools) fail
      _clients.remove(serverName);
      _logger.warning(
          '🗑️ CLIENT REMOVED: $serverName removed due to required capability loading failure');
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

  /// Get all configured server names (both connected and disconnected)
  List<String> get configuredServers => _serverConfigs.keys.toList();

  /// Get server configuration
  MCPServerConfig? getServerConfig(String serverName) =>
      _serverConfigs[serverName];

  /// Get server status information
  Map<String, dynamic> getServerStatus(String serverName) {
    final config = _serverConfigs[serverName];
    final isConnected = _clients.containsKey(serverName);
    final tools = _availableTools[serverName] ?? [];
    final resources = _availableResources[serverName] ?? [];
    final prompts = _availablePrompts[serverName] ?? [];

    return {
      'name': serverName,
      'status': isConnected ? 'connected' : 'disconnected',
      'type': config?.type ?? (config?.command != null ? 'stdio' : 'unknown'),
      'url': config?.url,
      'command': config?.command,
      'args': config?.args,
      'toolCount': tools.length,
      'resourceCount': resources.length,
      'promptCount': prompts.length,
      'tools': tools
          .map((tool) => {
                'name': tool.name,
                'description': tool.description ?? 'No description',
                'uniqueId': '$serverName:${tool.name}',
              })
          .toList(),
      'supported': (config?.type == 'sse' || config?.url != null) ||
          (config?.command != null),
      'reason': _getDisconnectionReason(serverName, config),
    };
  }

  /// Get the reason why a server is disconnected
  String? _getDisconnectionReason(String serverName, MCPServerConfig? config) {
    if (config == null) return 'Configuration not found';
    if (_clients.containsKey(serverName)) return null; // Connected

    if (config.type == 'sse' || config.url != null) {
      return 'HTTP/SSE server not reachable or connection failed';
    } else if (config.command != null) {
      return 'STDIO process failed to start or crashed';
    }

    return 'Invalid server configuration';
  }
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
