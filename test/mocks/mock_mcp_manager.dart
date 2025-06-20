import 'package:vibe_coder/ai_agent/services/mcp_manager.dart';
import 'package:vibe_coder/ai_agent/models/mcp_models.dart';

/// �� **MOCK MCP MANAGER WITH PROCESS TRACKING**
///
/// Provides instant responses for unit testing without network calls
/// Follows warrior protocol with O(1) performance and no side effects
/// Enhanced with process management simulation for shared process testing
class MockMCPManager implements MCPManager {
  final Map<String, MCPServerConfig> _mockServerConfigs = {
    'mock-filesystem': MCPServerConfig(
      command: 'mock-command',
      args: ['mock-args'],
      type: 'stdio',
    ),
    'mock-memory': MCPServerConfig(
      command: 'mock-command',
      args: ['mock-args'],
      type: 'stdio',
    ),
  };

  final List<MCPToolWithServer> _mockTools = [
    MCPToolWithServer(
      serverName: 'mock-filesystem',
      tool: MCPTool(
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
    ),
    MCPToolWithServer(
      serverName: 'mock-memory',
      tool: MCPTool(
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
    ),
  ];

  // 🎯 PROCESS MANAGEMENT SIMULATION: Track process creation for testing
  final Map<String, int> _processCreationCount = {};
  final Map<String, Set<String>> _processReferences = {};

  @override
  List<String> get configuredServers => _mockServerConfigs.keys.toList();

  @override
  List<String> get connectedServers => _mockServerConfigs.keys.toList();

  @override
  List<MCPToolWithServer> getAllTools() => _mockTools;

  @override
  Map<String, List<MCPTool>> get availableTools => {
        'mock-filesystem': [_mockTools[0].tool],
        'mock-memory': [_mockTools[1].tool],
      };

  @override
  Map<String, List<MCPResource>> get availableResources => {};

  @override
  Map<String, List<MCPPrompt>> get availablePrompts => {};

  @override
  Future<void> initialize(String configPath) async {
    // 🚀 INSTANT INITIALIZATION - No I/O operations
    await Future.delayed(Duration.zero);
  }

  @override
  Future<void> refreshCapabilities() async {
    // 🚀 INSTANT REFRESH - No network calls
    await Future.delayed(Duration.zero);
  }

  @override
  Future<MCPToolCallResult> callTool({
    required String serverName,
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    // 🚀 INSTANT TOOL CALL - Mock response
    return MCPToolCallResult(
      content: [
        MCPTextContent(
          type: 'text',
          text: 'Mock tool response for $toolName',
        ),
      ],
      isError: false,
    );
  }

  @override
  Future<void> closeAll() async {
    // 🚀 INSTANT CLEANUP - No resources to clean
    await Future.delayed(Duration.zero);
  }

  @override
  Future<void> loadConfiguration(String configPath) async {
    // 🚀 INSTANT CONFIG LOAD - No file I/O
    await Future.delayed(Duration.zero);
  }

  @override
  bool isServerConnected(String serverName) =>
      _mockServerConfigs.containsKey(serverName);

  @override
  MCPServerConfig? getServerConfig(String serverName) =>
      _mockServerConfigs[serverName];

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
  Future<MCPTextContent> getResource({
    required String serverName,
    required String uri,
  }) async {
    return MCPTextContent(
      type: 'text',
      text: 'Mock resource content for $uri',
    );
  }

  @override
  Future<List<MCPTextContent>> getPrompt({
    required String serverName,
    required String promptName,
    Map<String, dynamic>? arguments,
  }) async {
    return [
      MCPTextContent(
        type: 'text',
        text: 'Mock prompt content for $promptName',
      ),
    ];
  }

  @override
  Map<String, dynamic> getServerStatus(String serverName) {
    final config = _mockServerConfigs[serverName];
    final tools = _mockTools.where((t) => t.serverName == serverName);

    return {
      'name': serverName,
      'status': 'connected',
      'type': config?.type ?? 'stdio',
      'toolCount': tools.length,
      'resourceCount': 0,
      'promptCount': 0,
      'tools': tools
          .map((t) => {
                'name': t.tool.name,
                'description': t.tool.description ?? 'Mock tool',
                'uniqueId': t.uniqueId,
              })
          .toList(),
      'supported': true,
      'reason': null,
    };
  }

  // 🎯 PROCESS MANAGEMENT TESTING: Additional methods for testing shared process behavior

  /// Simulate process creation for testing
  void simulateProcessCreation(String serverName, String clientId) {
    _processCreationCount[serverName] =
        (_processCreationCount[serverName] ?? 0) + 1;
    _processReferences[serverName] ??= <String>{};
    _processReferences[serverName]!.add(clientId);
  }

  /// Simulate process release for testing
  void simulateProcessRelease(String serverName, String clientId) {
    _processReferences[serverName]?.remove(clientId);
    if (_processReferences[serverName]?.isEmpty ?? true) {
      _processReferences.remove(serverName);
    }
  }

  /// Get process creation count for testing
  int getProcessCreationCount(String serverName) {
    return _processCreationCount[serverName] ?? 0;
  }

  /// Get active reference count for testing
  int getActiveReferenceCount(String serverName) {
    return _processReferences[serverName]?.length ?? 0;
  }

  /// Get all process statistics for testing
  Map<String, dynamic> getProcessStats() {
    return {
      'totalProcessesCreated': _processCreationCount.values
          .fold<int>(0, (sum, count) => sum + count),
      'activeProcesses': _processReferences.length,
      'processDetails': _processReferences.entries
          .map((entry) => {
                'serverName': entry.key,
                'activeReferences': entry.value.length,
                'creationCount': _processCreationCount[entry.key] ?? 0,
                'referencingClients': entry.value.toList(),
              })
          .toList(),
    };
  }

  /// Reset process tracking for testing
  void resetProcessTracking() {
    _processCreationCount.clear();
    _processReferences.clear();
  }

  // Additional mock methods for testing specific scenarios
  void addMockTool(MCPToolWithServer tool) {
    _mockTools.add(tool);
  }

  void clearMockTools() {
    _mockTools.clear();
  }

  void addMockServer(String name, MCPServerConfig config) {
    _mockServerConfigs[name] = config;
  }
}
