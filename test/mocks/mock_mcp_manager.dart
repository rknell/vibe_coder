import 'package:vibe_coder/services/mcp_service.dart';
import 'package:vibe_coder/models/mcp_server_model.dart';
import 'package:vibe_coder/ai_agent/models/mcp_models.dart' as legacy;

/// 🧪 **MOCK MCP SERVICE FOR TESTING**
///
/// ✅ **UPDATED FOR MCPService ARCHITECTURE**
///
/// Provides instant responses for unit testing without network calls
/// Extends MCPService to override key methods with mock implementations
/// Follows warrior protocol with O(1) performance and no side effects
class MockMCPService extends MCPService {
  final List<MCPServerModel> _mockServers = [];
  final List<MCPToolWithServer> _mockTools = [];
  bool _isInitialized = false;

  MockMCPService() {
    // Create mock servers
    _mockServers.addAll([
      MCPServerModel.stdio(
        name: 'mock-filesystem',
        command: 'mock-command',
        args: ['mock-args'],
        description: 'Mock filesystem server',
      ),
      MCPServerModel.stdio(
        name: 'mock-memory',
        command: 'mock-command',
        args: ['mock-args'],
        description: 'Mock memory server',
      ),
    ]);

    // Update server status to connected
    for (final server in _mockServers) {
      server.updateStatus(MCPServerStatus.connected);

      // Add mock tools
      if (server.name == 'mock-filesystem') {
        server.updateTools([
          MCPTool(
            name: 'read_file',
            description: 'Mock file reading tool',
            inputSchema: {
              'type': 'object',
              'properties': {
                'path': {'type': 'string', 'description': 'File path'}
              },
              'required': ['path']
            },
          ),
        ]);
      } else if (server.name == 'mock-memory') {
        server.updateTools([
          MCPTool(
            name: 'store_memory',
            description: 'Mock memory storage tool',
            inputSchema: {
              'type': 'object',
              'properties': {
                'key': {'type': 'string'},
                'value': {'type': 'string'}
              },
              'required': ['key', 'value']
            },
          ),
        ]);
      }
    }

    // Create mock tools with server context
    for (final server in _mockServers) {
      for (final tool in server.availableTools) {
        _mockTools.add(MCPToolWithServer(
          tool: legacy.MCPTool(
            name: tool.name,
            description: tool.description,
            inputSchema: tool.inputSchema,
          ),
          serverName: server.name,
        ));
      }
    }

    // Set mock data
    data = _mockServers;
  }

  @override
  Future<void> initialize() async {
    // 🚀 INSTANT INITIALIZATION - No I/O operations
    await Future.delayed(Duration.zero);
    _isInitialized = true;
    notifyListeners();
  }

  @override
  Future<void> loadAll() async {
    // 🚀 INSTANT LOAD - Use pre-created mock data
    await Future.delayed(Duration.zero);
    data = _mockServers;
    notifyListeners();
  }

  @override
  List<MCPToolWithServer> getAllTools() => _mockTools;

  @override
  List<MCPServerModel> get connectedServers =>
      _mockServers.where((s) => s.status == MCPServerStatus.connected).toList();

  @override
  String? findServerForTool(String toolName) {
    for (final tool in _mockTools) {
      if (tool.tool.name == toolName) {
        return tool.serverName;
      }
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> callTool({
    required String serverId,
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    // 🚀 INSTANT TOOL CALL - Mock response
    await Future.delayed(Duration.zero);

    return {
      'content': [
        {
          'type': 'text',
          'text': 'Mock tool response for $toolName',
        }
      ],
      'isError': false,
    };
  }

  @override
  Future<void> refreshAll() async {
    // 🚀 INSTANT REFRESH - No network calls
    await Future.delayed(Duration.zero);
  }

  @override
  Future<void> refreshServer(String serverId) async {
    // 🚀 INSTANT REFRESH - No network calls
    await Future.delayed(Duration.zero);
  }

  @override
  Future<void> connectServer(String serverId) async {
    // 🚀 INSTANT CONNECT - Update mock status
    await Future.delayed(Duration.zero);
    final server = getById(serverId);
    if (server != null) {
      server.updateStatus(MCPServerStatus.connected);
    }
  }

  @override
  Future<void> disconnectServer(String serverId) async {
    // 🚀 INSTANT DISCONNECT - Update mock status
    await Future.delayed(Duration.zero);
    final server = getById(serverId);
    if (server != null) {
      server.updateStatus(MCPServerStatus.disconnected);
    }
  }

  @override
  Map<String, dynamic> getMCPServerInfo() {
    return {
      'servers': _mockServers
          .map((server) => {
                'name': server.name,
                'status': server.status.name,
                'type': server.type.name,
                'toolCount': server.availableTools.length,
                'resourceCount': server.availableResources.length,
                'promptCount': server.availablePrompts.length,
                'tools': server.availableTools
                    .map((tool) => {
                          'name': tool.name,
                          'description': tool.description ?? 'Mock tool',
                        })
                    .toList(),
                'supported': true,
                'reason': null,
              })
          .toList(),
      'totalTools': _mockTools.length,
      'connectedServers': connectedServers.length,
      'configuredServers': _mockServers.length,
    };
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  void dispose() {
    // 🚀 INSTANT CLEANUP - No resources to clean
    super.dispose();
  }
}
