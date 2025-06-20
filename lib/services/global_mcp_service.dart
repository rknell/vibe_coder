/// GlobalMCPService - Universal MCP Connection Manager
library;

///
/// ## MISSION ACCOMPLISHED
/// Eliminates per-agent MCP initialization by providing shared MCP infrastructure.
/// All agents use the same MCP connections, reducing activation time from 5-10s to instant.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Per-Agent MCP | Agent isolation | 5-10s activation delay | ELIMINATED - performance killer |
/// | Shared MCP Pool | Resource sharing | Complexity | Rejected - overkill |
/// | Global MCP Service | Instant activation | Single point of failure | CHOSEN - optimal performance |
/// | Lazy MCP Loading | Fast startup | Runtime delays | Rejected - poor UX |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Agent Activation Delay**
///    - 🔍 Symptom: 5-10 second delays when clicking agents
///    - 🎯 Root Cause: Each agent creates new MCP connections
///    - 💥 Kill Shot: Single global MCP service shared by all agents
///
/// 2. **Resource Duplication**
///    - 🔍 Symptom: Multiple connections to same MCP servers
///    - 🎯 Root Cause: Per-agent MCPManager instances
///    - 💥 Kill Shot: Centralized connection management
///
/// 3. **UI Blocking During Activation**
///    - 🔍 Symptom: UI freezes during agent switching
///    - 🎯 Root Cause: Synchronous MCP initialization
///    - 💥 Kill Shot: Pre-initialized shared connections
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Agent activation: O(1) - instant access to pre-connected MCP
/// - MCP initialization: O(1) - done once at app startup
/// - Memory usage: O(1) - single connection per server
/// - Tool calls: O(1) - direct delegation to shared connections
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:vibe_coder/ai_agent/services/mcp_manager.dart';
import 'package:vibe_coder/ai_agent/models/mcp_models.dart';

/// GlobalMCPService - Shared MCP Infrastructure for All Agents
///
/// ARCHITECTURAL: Single instance manages all MCP connections.
/// All agents access MCP capabilities through this shared service.
class GlobalMCPService {
  static final Logger _logger = Logger('GlobalMCPService');
  static GlobalMCPService? _instance;

  // Shared MCP manager - one instance for entire app
  late final MCPManager _mcpManager;
  bool _isInitialized = false;

  // Private constructor for singleton
  GlobalMCPService._();

  /// Get singleton instance
  static GlobalMCPService get instance {
    _instance ??= GlobalMCPService._();
    return _instance!;
  }

  /// Initialize global MCP service
  ///
  /// PERF: O(n) where n = number of MCP servers - done ONCE at app startup
  /// ARCHITECTURAL: Pre-connects to all MCP servers for instant agent activation
  Future<void> initialize(String mcpConfigPath) async {
    if (_isInitialized) {
      _logger.info('🔄 GLOBAL MCP: Already initialized, skipping');
      return;
    }

    _logger.info('🚀 GLOBAL MCP: Initializing shared MCP infrastructure...');

    try {
      _mcpManager = MCPManager();
      await _mcpManager.initialize(mcpConfigPath);

      _isInitialized = true;

      final serverCount = _mcpManager.connectedServers.length;
      final toolCount = _mcpManager.getAllTools().length;

      _logger.info('✅ GLOBAL MCP: Initialization complete!');
      _logger.info('🔗 CONNECTED: $serverCount servers connected');
      _logger.info('🛠️ TOOLS: $toolCount tools available');
      _logger.info('📋 SERVERS: ${_mcpManager.connectedServers.join(', ')}');
    } catch (e, stackTrace) {
      _logger.severe('💥 GLOBAL MCP: Initialization failed: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get all available MCP tools
  ///
  /// PERF: O(1) - direct access to pre-loaded tools
  List<MCPToolWithServer> getAllTools() {
    _ensureInitialized();
    return _mcpManager.getAllTools();
  }

  /// Call MCP tool
  ///
  /// PERF: O(1) - direct delegation to connected server
  Future<MCPToolCallResult> callTool({
    required String serverName,
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    _ensureInitialized();

    _logger.info('🔧 GLOBAL MCP: Calling tool $toolName on $serverName');

    try {
      final result = await _mcpManager.callTool(
        serverName: serverName,
        toolName: toolName,
        arguments: arguments,
      );

      _logger.info('✅ GLOBAL MCP: Tool call succeeded: $toolName');
      return result;
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 GLOBAL MCP: Tool call failed: $toolName - $e', e, stackTrace);
      rethrow;
    }
  }

  /// Find server for tool
  ///
  /// PERF: O(1) - HashMap lookup
  String? findServerForTool(String toolName) {
    _ensureInitialized();
    return _mcpManager.findServerForTool(toolName);
  }

  /// Get MCP server information
  ///
  /// PERF: O(1) - direct access to server status
  Map<String, dynamic> getMCPServerInfo() {
    _ensureInitialized();

    final serverInfo = <String, dynamic>{};

    for (final serverName in _mcpManager.configuredServers) {
      serverInfo[serverName] = _mcpManager.getServerStatus(serverName);
    }

    return {
      'servers': serverInfo,
      'connectedCount': _mcpManager.connectedServers.length,
      'totalCount': _mcpManager.configuredServers.length,
      'toolCount': _mcpManager.getAllTools().length,
    };
  }

  /// Get available tools by server
  Map<String, List<MCPTool>> get availableTools {
    _ensureInitialized();
    return _mcpManager.availableTools;
  }

  /// Get available resources by server
  Map<String, List<MCPResource>> get availableResources {
    _ensureInitialized();
    return _mcpManager.availableResources;
  }

  /// Get available prompts by server
  Map<String, List<MCPPrompt>> get availablePrompts {
    _ensureInitialized();
    return _mcpManager.availablePrompts;
  }

  /// Get connected servers
  List<String> get connectedServers {
    _ensureInitialized();
    return _mcpManager.connectedServers;
  }

  /// Get configured servers
  List<String> get configuredServers {
    _ensureInitialized();
    return _mcpManager.configuredServers;
  }

  /// Refresh all MCP servers
  ///
  /// PERF: O(n) where n = number of servers - used for manual refresh
  Future<void> refreshAllServers() async {
    _ensureInitialized();

    _logger.info('🔄 GLOBAL MCP: Refreshing all servers...');

    try {
      await _mcpManager.refreshCapabilities();
      _logger.info('✅ GLOBAL MCP: All servers refreshed successfully');
    } catch (e, stackTrace) {
      _logger.severe('💥 GLOBAL MCP: Server refresh failed: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Dispose of global MCP service
  ///
  /// PERF: O(n) where n = number of connections - cleanup all resources
  Future<void> dispose() async {
    if (!_isInitialized) return;

    _logger.info('🧹 GLOBAL MCP: Disposing shared MCP infrastructure...');

    try {
      await _mcpManager.closeAll();
      _isInitialized = false;
      _logger.info('✅ GLOBAL MCP: Cleanup completed');
    } catch (e, stackTrace) {
      _logger.severe('💥 GLOBAL MCP: Cleanup failed: $e', e, stackTrace);
    }
  }

  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw GlobalMCPException(
          'GlobalMCPService not initialized. Call initialize() first.');
    }
  }
}

/// Exception for global MCP service operations
class GlobalMCPException implements Exception {
  final String message;
  GlobalMCPException(this.message);

  @override
  String toString() => 'GlobalMCPException: $message';
}
