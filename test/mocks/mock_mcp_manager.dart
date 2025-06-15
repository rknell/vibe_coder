import 'package:vibe_coder/ai_agent/services/mcp_manager.dart';
import 'package:vibe_coder/ai_agent/models/mcp_models.dart';

/// 🎭 **MOCK MCP MANAGER**
///
/// Provides instant responses for unit testing without network calls
/// Follows warrior protocol with O(1) performance and no side effects
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
  Future<void> refreshServerCapabilities(String serverName) async {
    // 🚀 INSTANT SERVER REFRESH - Mock individual server refresh
    if (!_mockServerConfigs.containsKey(serverName)) {
      throw Exception('Server not found: $serverName');
    }
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
