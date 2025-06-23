import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:vibe_coder/models/mcp_server_model.dart';
import 'package:vibe_coder/models/mcp_server_info.dart';
import 'package:vibe_coder/models/service_statistics.dart';
import 'package:vibe_coder/ai_agent/services/mcp_client.dart';
import 'package:vibe_coder/ai_agent/models/mcp_models.dart' as legacy;
import 'package:vibe_coder/services/mcp_cache_service.dart';

/// Tool with server context for flattened access
class MCPToolWithServer {
  final legacy.MCPTool tool;
  final String serverName;

  MCPToolWithServer({
    required this.tool,
    required this.serverName,
  });

  /// Get a unique identifier for this tool
  String get uniqueId => '$serverName:${tool.name}';
}

/// 🔧 MCP SERVICE LAYER
///
/// ARCHITECTURAL: Multi-record management and business logic for MCP servers
/// Manages collection of MCPServerModel instances with filtering and operations
/// Extends ChangeNotifier for reactive UI updates
class MCPService extends ChangeNotifier {
  static final Logger _logger = Logger('MCPService');

  // 📊 COLLECTION MANAGEMENT: Core data field
  List<MCPServerModel> data = [];

  // 🌐 API LAYER: MCP client connections
  final Map<String, MCPClient> _clients = {};

  // ⚡ PERFORMANCE ENHANCEMENT: MCP Cache Service Integration
  MCPCacheService?
      _cacheService; // WARRIOR PROTOCOL: Nullable instead of late to eliminate vulnerability
  bool _isCacheInitialized = false;

  // 🔄 SERVICE STATE
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _lastError;

  /// 🚀 INITIALIZATION: Load all MCP servers from persistence
  ///
  /// PERF: O(n) where n = number of server files
  /// ARCHITECTURAL: Service handles collection loading, models handle individual persistence
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('🚀 MCP SERVICE: Initializing service');
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      // 🎯 CACHE INITIALIZATION: Set up intelligent caching
      if (!_isCacheInitialized) {
        _cacheService = MCPCacheService();
        final cacheService = _cacheService;
        if (cacheService != null) {
          await cacheService.initialize();
        }
        _isCacheInitialized = true;
        _logger.info('💾 CACHE READY: MCP cache service initialized');
      }

      await loadAll();
      await _loadFromMCPConfig();

      _isInitialized = true;
      _isLoading = false;

      _logger.info('✅ MCP SERVICE: Initialized with ${data.length} servers');
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 MCP SERVICE: Initialization failed - $e', e, stackTrace);
      _lastError = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow; // Bubble stack trace to surface
    }
  }

  /// 📋 COLLECTION LOADING: Load all servers from data directory
  ///
  /// PERF: O(n) where n = number of server files
  /// ARCHITECTURAL: Service manages loading, models handle their own deserialization
  Future<void> loadAll() async {
    try {
      _logger.info('📋 LOADING: All MCP servers from persistence');

      final dataDir = Directory('data/mcp_servers');
      if (!await dataDir.exists()) {
        _logger.info('📁 NO DATA: MCP servers directory does not exist');
        data = [];
        notifyListeners();
        return;
      }

      final files = await dataDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .toList();

      final loadedServers = <MCPServerModel>[];

      for (final file in files) {
        try {
          final content = await (file as File).readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;

          // 🎯 ADAPTIVE LOADING: Handle both full MCPServerModel format and simple config format
          MCPServerModel server;

          if (_isFullServerModel(json)) {
            // Full MCPServerModel JSON structure
            server = MCPServerModel.fromJson(json);
            _logger.fine('✅ LOADED: Full model ${server.name}');
          } else {
            // Simple configuration file format
            server = _createServerFromConfigFile(file.path, json);
            _logger.fine('✅ LOADED: Config file ${server.name}');
          }

          loadedServers.add(server);
        } catch (e, stackTrace) {
          _logger.warning('⚠️ LOAD FAILED: ${file.path} - $e', e, stackTrace);
          // Continue loading other servers, don't fail entire operation
        }
      }

      data = loadedServers;
      _logger.info('📋 LOADED: ${data.length} MCP servers from persistence');
      notifyListeners(); // MANDATORY after data changes
    } catch (e, stackTrace) {
      _logger.severe('💥 LOAD ALL FAILED: $e', e, stackTrace);
      rethrow; // Bubble stack trace to surface
    }
  }

  /// 🔍 DETECTION: Check if JSON is full MCPServerModel format
  ///
  /// PERF: O(1) - simple field presence check
  /// ARCHITECTURAL: Distinguishes between config files and full model files
  bool _isFullServerModel(Map<String, dynamic> json) {
    // Full models have 'id', 'name', 'status' fields
    // Simple configs only have 'command'/'url', 'type', etc.
    return json.containsKey('id') &&
        json.containsKey('name') &&
        json.containsKey('status');
  }

  /// 🏭 CONFIG FILE FACTORY: Create server model from simple config file
  ///
  /// PERF: O(1) - single object creation
  /// ARCHITECTURAL: Converts simple config files to full MCPServerModel objects
  MCPServerModel _createServerFromConfigFile(
      String filePath, Map<String, dynamic> config) {
    // Extract server name from filename (remove .json extension)
    final fileName = filePath.split('/').last;
    final serverName =
        fileName.substring(0, fileName.length - 5); // Remove '.json'

    final type = config['type'] as String?;

    if (type == 'sse') {
      return MCPServerModel.sse(
        name: serverName,
        url: config['url'] as String,
        description: 'Loaded from $filePath configuration',
      );
    } else {
      // Default to STDIO if no type specified or type is 'stdio'
      return MCPServerModel.stdio(
        name: serverName,
        command: config['command'] as String,
        args: (config['args'] as List<dynamic>?)?.cast<String>(),
        env: (config['env'] as Map<String, dynamic>?)?.cast<String, String>(),
        description: 'Loaded from $filePath configuration',
      );
    }
  }

  /// 🔧 LEGACY INTEGRATION: Load servers from mcp.json configuration
  ///
  /// PERF: O(n) where n = number of configured servers
  /// ARCHITECTURAL: Bridge to existing mcp.json format during transition
  /// 🚫 NO WRITING: Removed server.save() calls to prevent unauthorized writes
  Future<void> _loadFromMCPConfig() async {
    try {
      final configFile = File('mcp.json');
      if (!await configFile.exists()) {
        _logger
            .info('📋 NO CONFIG: mcp.json not found, skipping legacy import');
        return;
      }

      final configContent = await configFile.readAsString();
      final configJson = jsonDecode(configContent) as Map<String, dynamic>;
      final mcpServers =
          configJson['mcpServers'] as Map<String, dynamic>? ?? {};

      var importCount = 0;

      for (final entry in mcpServers.entries) {
        final serverName = entry.key;
        final config = entry.value as Map<String, dynamic>;

        // Check if server already exists
        if (getByName(serverName) != null) {
          _logger.fine('⏭️ SKIP: Server $serverName already exists');
          continue;
        }

        try {
          final server = _createServerFromConfig(serverName, config);
          data.add(server);
          // 🚫 REMOVED: await server.save(); - NO WRITING during load phase
          importCount++;

          _logger.info('📥 IMPORTED: $serverName from mcp.json (NO WRITE)');
        } catch (e, stackTrace) {
          _logger.warning('⚠️ IMPORT FAILED: $serverName - $e', e, stackTrace);
          // Continue importing other servers
        }
      }

      if (importCount > 0) {
        _logger.info(
            '📥 LEGACY IMPORT: $importCount servers imported from mcp.json (NO PERSISTENCE)');
        notifyListeners();
      }
    } catch (e, stackTrace) {
      _logger.warning('⚠️ MCP CONFIG LOAD FAILED: $e', e, stackTrace);
      // Don't fail initialization for config import issues
    }
  }

  /// 🏭 FACTORY: Create server model from legacy config
  MCPServerModel _createServerFromConfig(
      String name, Map<String, dynamic> config) {
    final type = config['type'] as String?;

    if (type == 'stdio') {
      return MCPServerModel.stdio(
        name: name,
        command: config['command'] as String,
        args: (config['args'] as List<dynamic>?)?.cast<String>(),
        env: (config['env'] as Map<String, dynamic>?)?.cast<String, String>(),
        description: 'Imported from mcp.json configuration',
      );
    } else {
      return MCPServerModel.sse(
        name: name,
        url: config['url'] as String,
        description: 'Imported from mcp.json configuration',
      );
    }
  }

  /// 🔍 FILTERING: Get server by ID
  ///
  /// PERF: O(n) - linear search through collection
  /// ARCHITECTURAL: Convenient filtering function for UI components
  MCPServerModel? getById(String id) {
    try {
      return data.firstWhere((server) => server.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 🔍 FILTERING: Get server by name
  ///
  /// PERF: O(n) - linear search through collection
  /// ARCHITECTURAL: Convenient filtering function for UI components
  MCPServerModel? getByName(String name) {
    try {
      return data.firstWhere((server) => server.name == name);
    } catch (e) {
      return null;
    }
  }

  /// 🔍 FILTERING: Get servers by status
  ///
  /// PERF: O(n) - filters entire collection
  /// ARCHITECTURAL: Status-based filtering for UI displays
  List<MCPServerModel> getByStatus(MCPServerStatus status) {
    return data.where((server) => server.status == status).toList();
  }

  /// 🔍 FILTERING: Get servers by type
  ///
  /// PERF: O(n) - filters entire collection
  /// ARCHITECTURAL: Type-based filtering for configuration views
  List<MCPServerModel> getByType(MCPServerType type) {
    return data.where((server) => server.type == type).toList();
  }

  /// 🛠️ ENHANCED: Get all available tools with server context
  ///
  /// PERF: O(n) where n = total tools across all servers
  /// ARCHITECTURAL: Flattened tool access for AI function calling
  List<MCPToolWithServer> getAllTools() {
    final allTools = <MCPToolWithServer>[];

    for (final server
        in data.where((s) => s.status == MCPServerStatus.connected)) {
      for (final tool in server.availableTools) {
        allTools.add(MCPToolWithServer(
          tool: legacy.MCPTool(
            name: tool.name,
            description: tool.description,
            inputSchema: tool.inputSchema,
            annotations: (() {
              final annotations = tool.annotations;
              if (annotations != null) {
                return legacy.MCPToolAnnotations(
                  title: annotations.title,
                  readOnlyHint: annotations.readOnlyHint,
                  destructiveHint: annotations.destructiveHint,
                  idempotentHint: annotations.idempotentHint,
                  openWorldHint: annotations.openWorldHint,
                );
              }
              return null;
            })(),
          ),
          serverName: server.name,
        ));
      }
    }

    return allTools;
  }

  /// 🔍 ENHANCED: Find which server provides a specific tool
  ///
  /// PERF: O(n*m) where n = servers, m = tools per server
  /// ARCHITECTURAL: Tool resolution for function calling
  String? findServerForTool(String toolName) {
    for (final server
        in data.where((s) => s.status == MCPServerStatus.connected)) {
      if (server.availableTools.any((tool) => tool.name == toolName)) {
        return server.name;
      }
    }
    return null;
  }

  /// 📊 ENHANCED: Get comprehensive MCP server information for UI
  ///
  /// PERF: O(n) where n = number of servers
  /// ARCHITECTURAL: UI integration with strongly-typed server status displays
  MCPServerInfoResponse getMCPServerInfo() {
    final serverInfo = <String, MCPServerInfo>{};

    for (final server in data) {
      final tools = server.availableTools
          .map((tool) => MCPToolInfo(
                name: tool.name,
                description: tool.description ?? 'No description',
                uniqueId: '${server.name}:${tool.name}',
              ))
          .toList();

      serverInfo[server.name] = MCPServerInfo(
        name: server.name,
        displayName: server.displayName,
        description: server.description,
        status: server.status.name,
        type: server.type.name,
        url: server.url,
        command: server.command,
        args: server.args,
        toolCount: server.availableTools.length,
        resourceCount: server.availableResources.length,
        promptCount: server.availablePrompts.length,
        tools: tools,
        supported: _isServerSupported(server),
        reason: _getDisconnectionReason(server),
        lastConnectedAt: server.lastConnectedAt?.toIso8601String(),
      );
    }

    final connectedServers = getByStatus(MCPServerStatus.connected);

    return MCPServerInfoResponse(
      servers: serverInfo,
      connectedCount: connectedServers.length,
      totalCount: data.length,
      toolCount: getAllTools().length,
    );
  }

  /// 📊 DEPRECATED: Get MCP server info as Map (legacy compatibility)
  ///
  /// DEPRECATED: Use getMCPServerInfo() which returns strongly-typed data
  /// ARCHITECTURAL: Temporary bridge during migration period
  Map<String, dynamic> getMCPServerInfoLegacy() {
    return getMCPServerInfo().toJson();
  }

  /// 🔍 PRIVATE: Check if server configuration is supported
  bool _isServerSupported(MCPServerModel server) {
    switch (server.type) {
      case MCPServerType.sse:
        final url = server.url;
        return url != null && url.isNotEmpty;
      case MCPServerType.stdio:
        final command = server.command;
        return command != null && command.isNotEmpty;
    }
  }

  /// 🔍 PRIVATE: Get the reason why a server is disconnected
  String? _getDisconnectionReason(MCPServerModel server) {
    if (server.status == MCPServerStatus.connected) return null;

    if (!_isServerSupported(server)) {
      return 'Invalid server configuration';
    }

    switch (server.type) {
      case MCPServerType.sse:
        return 'HTTP/SSE server not reachable or connection failed';
      case MCPServerType.stdio:
        return 'STDIO process failed to start or crashed';
    }
  }

  /// ➕ BUSINESS OPERATIONS: Create new MCP server
  ///
  /// PERF: O(1) - adds to collection and saves
  /// ARCHITECTURAL: Service orchestrates, model handles persistence
  Future<MCPServerModel> createServer(MCPServerModel server) async {
    try {
      _logger.info('➕ CREATING: MCP server ${server.name}');

      // Validation handled at model level
      server.validate();

      // Model handles its own persistence
      await server.save();

      // Add to collection
      data.add(server);

      _logger.info('✅ CREATED: MCP server ${server.name}');
      notifyListeners(); // MANDATORY after collection change

      return server;
    } catch (e, stackTrace) {
      _logger.severe('💥 CREATE FAILED: ${server.name} - $e', e, stackTrace);
      rethrow; // Bubble stack trace to surface
    }
  }

  /// ✏️ BUSINESS OPERATIONS: Update existing MCP server
  ///
  /// PERF: O(1) - direct model update
  /// ARCHITECTURAL: Service coordinates, model handles persistence
  Future<void> updateServer(MCPServerModel server) async {
    try {
      _logger.info('✏️ UPDATING: MCP server ${server.name}');

      // Validation handled at model level
      server.validate();

      // Model handles its own persistence
      await server.save();

      _logger.info('✅ UPDATED: MCP server ${server.name}');
      notifyListeners(); // MANDATORY after change
    } catch (e, stackTrace) {
      _logger.severe('💥 UPDATE FAILED: ${server.name} - $e', e, stackTrace);
      rethrow; // Bubble stack trace to surface
    }
  }

  /// 🗑️ BUSINESS OPERATIONS: Delete MCP server
  ///
  /// PERF: O(n) - removes from collection
  /// ARCHITECTURAL: Service orchestrates, model handles persistence
  Future<void> deleteServer(String serverId) async {
    try {
      final server = getById(serverId);
      if (server == null) {
        throw MCPServiceException('Server not found: $serverId');
      }

      _logger.info('🗑️ DELETING: MCP server ${server.name}');

      // Disconnect if connected
      if (server.status == MCPServerStatus.connected) {
        await disconnectServer(serverId);
      }

      // Model handles its own deletion
      await server.delete();

      // Remove from collection
      data.removeWhere((s) => s.id == serverId);

      _logger.info('✅ DELETED: MCP server ${server.name}');
      notifyListeners(); // MANDATORY after collection change
    } catch (e, stackTrace) {
      _logger.severe('💥 DELETE FAILED: $serverId - $e', e, stackTrace);
      rethrow; // Bubble stack trace to surface
    }
  }

  /// 🔌 ENHANCED: Connect to MCP server with caching
  ///
  /// PERF: O(1) - establishes single connection with cache optimization
  /// ARCHITECTURAL: Service handles connection logic with cache integration
  Future<void> connectServer(String serverId) async {
    try {
      final server = getById(serverId);
      if (server == null) {
        throw MCPServiceException('Server not found: $serverId');
      }

      if (server.status == MCPServerStatus.connected) {
        _logger.info('⏭️ ALREADY CONNECTED: ${server.name}');
        return;
      }

      _logger.info('🔌 CONNECTING: MCP server ${server.name}');
      server.updateStatus(MCPServerStatus.connecting);

      // Create and initialize client
      final client = _createClient(server);
      await client.initialize();

      // Load server capabilities with cache optimization
      await _loadServerCapabilitiesWithCache(server, client);

      // Store client connection
      _clients[serverId] = client;
      server.updateStatus(MCPServerStatus.connected);

      _logger.info('✅ CONNECTED: MCP server ${server.name}');
    } catch (e, stackTrace) {
      final server = getById(serverId);
      server?.updateStatus(MCPServerStatus.error);
      _logger.severe('💥 CONNECTION FAILED: $serverId - $e', e, stackTrace);
      rethrow; // Bubble stack trace to surface
    }
  }

  /// 📊 ENHANCED: Load server capabilities with intelligent caching
  ///
  /// PERF: Cache hit O(1), cache miss O(n) where n = capability count
  /// ARCHITECTURAL: Integrates with cache service for performance optimization
  Future<void> _loadServerCapabilitiesWithCache(
      MCPServerModel server, MCPClient client) async {
    try {
      // 🎯 CACHE CHECK FIRST: Try to load from cache for instant startup
      if (_isCacheInitialized) {
        final cachedCapabilities =
            _cacheService?.getCachedCapabilities(server.name);
        if (cachedCapabilities != null) {
          _logger.info(
              '⚡ CACHE HIT: Using cached capabilities for ${server.name}');

          // Load from cache - INSTANT startup!
          final tools = cachedCapabilities.tools.map(_convertTool).toList();
          final resources =
              cachedCapabilities.resources.map(_convertResource).toList();
          final prompts =
              cachedCapabilities.prompts.map(_convertPrompt).toList();

          server.updateTools(tools);
          server.updateResources(resources);
          server.updatePrompts(prompts);

          _logger
              .info('✅ CACHED CAPABILITIES: ${server.name} loaded from cache');

          // Start background refresh but don't wait for it
          _backgroundRefreshCapabilities(server, client);
          return;
        }
      }

      // 🐌 CACHE MISS: Load fresh capabilities (slower path)
      _logger.info(
          '💭 CACHE MISS: Loading fresh capabilities for ${server.name}...');
      await _loadServerCapabilitiesFromClient(server, client);
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 CAPABILITY LOAD FAILED: ${server.name} - $e', e, stackTrace);
      rethrow;
    }
  }

  /// 🔄 ENHANCED: Background refresh of capabilities without blocking startup
  ///
  /// PERF: O(n) where n = capabilities - non-blocking background operation
  Future<void> _backgroundRefreshCapabilities(
      MCPServerModel server, MCPClient client) async {
    _logger.info(
        '🔄 BACKGROUND REFRESH: Updating capabilities for ${server.name}...');

    try {
      // Load fresh capabilities in background
      await _loadServerCapabilitiesFromClient(server, client);
      _logger.info(
          '🔄 BACKGROUND COMPLETE: ${server.name} capabilities refreshed');
    } catch (e) {
      _logger.warning('⚠️ BACKGROUND REFRESH FAILED: ${server.name} - $e');
      // Don't throw - background refresh failures are non-critical
    }
  }

  /// 📊 ENHANCED: Load server capabilities with cache storage
  Future<void> _loadServerCapabilitiesFromClient(
      MCPServerModel server, MCPClient client) async {
    try {
      // Load tools (REQUIRED) - if this fails, server is considered broken
      _logger.info('🛠️ LOADING TOOLS: Fetching tools for ${server.name}...');
      final legacyTools = await client.listTools();
      final tools = legacyTools.map(_convertTool).toList();
      server.updateTools(tools);

      _logger.info('✅ TOOLS LOADED: ${server.name} has ${tools.length} tools');

      // Load resources (OPTIONAL) - graceful degradation if unsupported
      _logger.info(
          '📚 LOADING RESOURCES: Fetching resources for ${server.name}...');
      List<MCPResource> resources = [];
      try {
        final legacyResources = await client.listResources();
        resources = legacyResources.map(_convertResource).toList();
        server.updateResources(resources);
        _logger.info(
            '✅ RESOURCES LOADED: ${server.name} has ${resources.length} resources');
      } catch (e) {
        _logger.info('ℹ️ RESOURCES UNAVAILABLE: ${server.name} - $e');
        server.updateResources(resources); // Empty list
      }

      // Load prompts (OPTIONAL) - graceful degradation if unsupported
      _logger
          .info('📝 LOADING PROMPTS: Fetching prompts for ${server.name}...');
      List<MCPPrompt> prompts = [];
      try {
        final legacyPrompts = await client.listPrompts();
        prompts = legacyPrompts.map(_convertPrompt).toList();
        server.updatePrompts(prompts);
        _logger.info(
            '✅ PROMPTS LOADED: ${server.name} has ${prompts.length} prompts');
      } catch (e) {
        _logger.info('ℹ️ PROMPTS UNAVAILABLE: ${server.name} - $e');
        server.updatePrompts(prompts); // Empty list
      }

      // 💾 CACHE STORE: Save capabilities for next startup
      if (_isCacheInitialized) {
        await _cacheService?.cacheCapabilities(
          serverName: server.name,
          tools: legacyTools,
          resources: resources
              .map((r) => legacy.MCPResource(
                    uri: r.uri,
                    name: r.name,
                    description: r.description,
                    mimeType: r.mimeType,
                  ))
              .toList(),
          prompts: prompts
              .map((p) => legacy.MCPPrompt(
                    name: p.name,
                    description: p.description,
                    arguments: p.arguments
                        ?.map((arg) => legacy.MCPPromptArgument(
                              name: arg.name,
                              description: arg.description,
                              required: arg.required,
                            ))
                        .toList(),
                  ))
              .toList(),
          metadata: {
            'version': '1.0.0',
            'loadedAt': DateTime.now().toIso8601String()
          },
        );
        _logger.info('💾 CACHED: Stored capabilities for ${server.name}');
      }

      _logger.info(
          '✅ CAPABILITIES LOADED: ${server.name} capabilities loaded successfully');
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 CAPABILITY LOAD FAILED: ${server.name} - $e', e, stackTrace);
      rethrow;
    }
  }

  /// 🔌 CONNECTION MANAGEMENT: Disconnect from MCP server
  ///
  /// PERF: O(1) - closes single connection
  /// ARCHITECTURAL: Service handles disconnection, model tracks status
  Future<void> disconnectServer(String serverId) async {
    try {
      final server = getById(serverId);
      final client = _clients[serverId];

      if (client != null) {
        _logger
            .info('🔌 DISCONNECTING: MCP server ${server?.name ?? serverId}');
        await client.close();
        _clients.remove(serverId);
      }

      server?.updateStatus(MCPServerStatus.disconnected);
      _logger.info('✅ DISCONNECTED: MCP server ${server?.name ?? serverId}');
    } catch (e, stackTrace) {
      _logger.severe('💥 DISCONNECT FAILED: $serverId - $e', e, stackTrace);
      rethrow; // Bubble stack trace to surface
    }
  }

  /// 🛠️ TOOL OPERATIONS: Call MCP tool
  ///
  /// PERF: O(1) - direct client delegation
  /// ARCHITECTURAL: Service coordinates tool calls across connected servers
  Future<Map<String, dynamic>> callTool({
    required String serverId,
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    try {
      final server = getById(serverId);
      final client = _clients[serverId];

      if (server == null) {
        throw MCPServiceException('Server not found: $serverId');
      }

      if (client == null || server.status != MCPServerStatus.connected) {
        throw MCPServiceException('Server not connected: ${server.name}');
      }

      _logger.info('🛠️ CALLING TOOL: $toolName on ${server.name}');

      final request =
          legacy.MCPToolCallRequest(name: toolName, arguments: arguments);
      final result = await client.callTool(request);

      _logger.info('✅ TOOL SUCCESS: $toolName on ${server.name}');
      return {
        'content': result.content
            .map((c) => {
                  'type': c.type,
                  'text': c.text,
                })
            .toList(),
        'isError': result.isError ?? false,
      };
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 TOOL FAILED: $toolName on $serverId - $e', e, stackTrace);
      rethrow; // Bubble stack trace to surface
    }
  }

  /// 🔄 REFRESH OPERATIONS: Refresh server capabilities
  ///
  /// PERF: O(1) per server - refreshes capabilities for connected servers
  /// ARCHITECTURAL: Service orchestrates refresh, model tracks updated data
  Future<void> refreshServer(String serverId) async {
    try {
      final server = getById(serverId);
      final client = _clients[serverId];

      if (server == null) {
        throw MCPServiceException('Server not found: $serverId');
      }

      if (client == null) {
        _logger.info('⏭️ SKIP REFRESH: ${server.name} not connected');
        return;
      }

      _logger.info('🔄 REFRESHING: MCP server ${server.name}');
      await _loadServerCapabilitiesFromClient(server, client);
      _logger.info('✅ REFRESHED: MCP server ${server.name}');
    } catch (e, stackTrace) {
      _logger.severe('💥 REFRESH FAILED: $serverId - $e', e, stackTrace);
      rethrow; // Bubble stack trace to surface
    }
  }

  /// 🔄 REFRESH OPERATIONS: Refresh all connected servers
  ///
  /// PERF: O(n) where n = number of connected servers
  /// ARCHITECTURAL: Batch refresh operation for UI convenience
  Future<void> refreshAll() async {
    try {
      _logger.info('🔄 REFRESHING: All connected MCP servers');

      final connectedServers = getByStatus(MCPServerStatus.connected);

      for (final server in connectedServers) {
        try {
          await refreshServer(server.id);
        } catch (e, stackTrace) {
          _logger.warning(
              '⚠️ REFRESH FAILED: ${server.name} - $e', e, stackTrace);
          // Continue refreshing other servers
        }
      }

      _logger.info('✅ REFRESH COMPLETE: ${connectedServers.length} servers');
    } catch (e, stackTrace) {
      _logger.severe('💥 REFRESH ALL FAILED: $e', e, stackTrace);
      rethrow; // Bubble stack trace to surface
    }
  }

  /// 🏭 PRIVATE: Create MCP client for server
  MCPClient _createClient(MCPServerModel server) {
    switch (server.type) {
      case MCPServerType.stdio:
        return MCPClient.stdio(
          command: server.command!,
          args: server.args,
          env: server.env,
        );
      case MCPServerType.sse:
        return MCPClient(serverUrl: server.url!);
    }
  }

  /// 🔄 PRIVATE: Convert legacy MCP tool to new model
  MCPTool _convertTool(legacy.MCPTool legacyTool) {
    return MCPTool(
      name: legacyTool.name,
      description: legacyTool.description,
      inputSchema: legacyTool.inputSchema,
      annotations: legacyTool.annotations != null
          ? MCPToolAnnotations(
              title: (() {
                final annotations = legacyTool.annotations;
                return annotations?.title;
              })(),
              readOnlyHint: (() {
                final annotations = legacyTool.annotations;
                return annotations?.readOnlyHint;
              })(),
              destructiveHint: (() {
                final annotations = legacyTool.annotations;
                return annotations?.destructiveHint;
              })(),
              idempotentHint: (() {
                final annotations = legacyTool.annotations;
                return annotations?.idempotentHint;
              })(),
              openWorldHint: (() {
                final annotations = legacyTool.annotations;
                return annotations?.openWorldHint;
              })(),
            )
          : null,
    );
  }

  /// 🔄 PRIVATE: Convert legacy MCP resource to new model
  MCPResource _convertResource(legacy.MCPResource legacyResource) {
    return MCPResource(
      uri: legacyResource.uri,
      name: legacyResource.name,
      description: legacyResource.description,
      mimeType: legacyResource.mimeType,
    );
  }

  /// 🔄 PRIVATE: Convert legacy MCP prompt to new model
  MCPPrompt _convertPrompt(legacy.MCPPrompt legacyPrompt) {
    return MCPPrompt(
      name: legacyPrompt.name,
      description: legacyPrompt.description,
      arguments: legacyPrompt.arguments
          ?.map((arg) => MCPPromptArgument(
                name: arg.name,
                description: arg.description,
                required: arg.required,
              ))
          .toList(),
    );
  }

  /// 📈 METRICS: Get service statistics
  ///
  /// ARCHITECTURAL: Returns strongly-typed MCP service statistics
  MCPServiceStatistics get statistics => MCPServiceStatistics(
        totalServers: data.length,
        connectedServers: getByStatus(MCPServerStatus.connected).length,
        disconnectedServers: getByStatus(MCPServerStatus.disconnected).length,
        errorServers: getByStatus(MCPServerStatus.error).length,
        stdioServers: getByType(MCPServerType.stdio).length,
        sseServers: getByType(MCPServerType.sse).length,
        totalTools: data.fold<int>(
            0, (sum, server) => sum + server.availableTools.length),
        totalResources: data.fold<int>(
            0, (sum, server) => sum + server.availableResources.length),
        totalPrompts: data.fold<int>(
            0, (sum, server) => sum + server.availablePrompts.length),
      );

  /// 📊 DEPRECATED: Get statistics as Map (legacy compatibility)
  ///
  /// DEPRECATED: Use statistics property which returns strongly-typed data
  /// ARCHITECTURAL: Temporary bridge during migration period
  Map<String, dynamic> get statisticsLegacy => statistics.toJson();

  /// 🧹 ENHANCED: Dispose service and close connections with cache cleanup
  ///
  /// PERF: O(n) where n = number of active connections
  /// ARCHITECTURAL: Clean resource management with cache disposal
  @override
  void dispose() {
    _logger.info('🧹 DISPOSING: MCP service');

    // Close all client connections
    for (final client in _clients.values) {
      client.close().catchError((e) {
        _logger.warning('⚠️ CLIENT CLOSE FAILED: $e');
      });
    }

    _clients.clear();

    // 🧹 CACHE CLEANUP: Dispose cache service
    if (_isCacheInitialized) {
      _cacheService?.dispose().catchError((e) {
        _logger.warning('⚠️ CACHE DISPOSE FAILED: $e');
      });
      _isCacheInitialized = false;
    }

    super.dispose();
  }

  // 🎯 GETTERS: Service state access
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  List<MCPServerModel> get connectedServers =>
      getByStatus(MCPServerStatus.connected);
  List<MCPServerModel> get disconnectedServers =>
      getByStatus(MCPServerStatus.disconnected);
}

/// ⚠️ MCP SERVICE EXCEPTION
class MCPServiceException implements Exception {
  final String message;

  MCPServiceException(this.message);

  @override
  String toString() => 'MCPServiceException: $message';
}
