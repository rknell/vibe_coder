/// 📊 MCP SERVER INFO MODEL
///
/// ARCHITECTURAL: Strongly-typed data model for MCP server information
/// Replaces Map<String, dynamic> returns with type-safe structures
/// Provides comprehensive server status and capability information
library;

/// Individual tool information within a server
class MCPToolInfo {
  final String name;
  final String description;
  final String uniqueId;

  const MCPToolInfo({
    required this.name,
    required this.description,
    required this.uniqueId,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'uniqueId': uniqueId,
      };

  factory MCPToolInfo.fromJson(Map<String, dynamic> json) => MCPToolInfo(
        name: json['name'] as String,
        description: json['description'] as String,
        uniqueId: json['uniqueId'] as String,
      );
}

/// Individual server information within the MCP ecosystem
class MCPServerInfo {
  final String name;
  final String displayName;
  final String? description;
  final String status;
  final String type;
  final String? url;
  final String? command;
  final List<String>? args;
  final int toolCount;
  final int resourceCount;
  final int promptCount;
  final List<MCPToolInfo> tools;
  final bool supported;
  final String? reason;
  final String? lastConnectedAt;

  const MCPServerInfo({
    required this.name,
    required this.displayName,
    this.description,
    required this.status,
    required this.type,
    this.url,
    this.command,
    this.args,
    required this.toolCount,
    required this.resourceCount,
    required this.promptCount,
    required this.tools,
    required this.supported,
    this.reason,
    this.lastConnectedAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'displayName': displayName,
        'description': description,
        'status': status,
        'type': type,
        'url': url,
        'command': command,
        'args': args,
        'toolCount': toolCount,
        'resourceCount': resourceCount,
        'promptCount': promptCount,
        'tools': tools.map((t) => t.toJson()).toList(),
        'supported': supported,
        'reason': reason,
        'lastConnectedAt': lastConnectedAt,
      };

  factory MCPServerInfo.fromJson(Map<String, dynamic> json) => MCPServerInfo(
        name: json['name'] as String,
        displayName: json['displayName'] as String,
        description: json['description'] as String?,
        status: json['status'] as String,
        type: json['type'] as String,
        url: json['url'] as String?,
        command: json['command'] as String?,
        args: (json['args'] as List<dynamic>?)?.cast<String>(),
        toolCount: json['toolCount'] as int,
        resourceCount: json['resourceCount'] as int,
        promptCount: json['promptCount'] as int,
        tools: (json['tools'] as List<dynamic>)
            .map((t) => MCPToolInfo.fromJson(t as Map<String, dynamic>))
            .toList(),
        supported: json['supported'] as bool,
        reason: json['reason'] as String?,
        lastConnectedAt: json['lastConnectedAt'] as String?,
      );
}

/// Complete MCP server information response
///
/// ARCHITECTURAL: Top-level container for all MCP server information
/// Provides summary statistics and individual server details
class MCPServerInfoResponse {
  final Map<String, MCPServerInfo> servers;
  final int connectedCount;
  final int totalCount;
  final int toolCount;

  const MCPServerInfoResponse({
    required this.servers,
    required this.connectedCount,
    required this.totalCount,
    required this.toolCount,
  });

  /// Convert to JSON (for serialization)
  Map<String, dynamic> toJson() => {
        'servers': servers.map((key, server) => MapEntry(key, server.toJson())),
        'connectedCount': connectedCount,
        'totalCount': totalCount,
        'toolCount': toolCount,
      };

  /// Create from JSON (for deserialization)
  factory MCPServerInfoResponse.fromJson(Map<String, dynamic> json) {
    final serversJson = json['servers'] as Map<String, dynamic>;
    final servers = serversJson.map(
      (key, value) => MapEntry(
        key,
        MCPServerInfo.fromJson(value as Map<String, dynamic>),
      ),
    );

    return MCPServerInfoResponse(
      servers: servers,
      connectedCount: json['connectedCount'] as int,
      totalCount: json['totalCount'] as int,
      toolCount: json['toolCount'] as int,
    );
  }

  /// Convenience getters for common queries
  List<MCPServerInfo> get connectedServers =>
      servers.values.where((s) => s.status == 'connected').toList();

  List<MCPServerInfo> get disconnectedServers =>
      servers.values.where((s) => s.status != 'connected').toList();

  List<MCPServerInfo> get supportedServers =>
      servers.values.where((s) => s.supported).toList();

  List<MCPServerInfo> get unsupportedServers =>
      servers.values.where((s) => !s.supported).toList();

  /// Get server by name
  MCPServerInfo? getServerByName(String name) => servers[name];

  /// Get all tools across all servers
  List<MCPToolInfo> get allTools =>
      servers.values.expand((server) => server.tools).toList();

  /// Convert to legacy Map format for backward compatibility
  ///
  /// DEPRECATED: Use strongly-typed accessors instead
  /// ARCHITECTURAL: Temporary bridge during migration period
  Map<String, dynamic> toLegacyMap() {
    return {
      'servers': servers.values.map((server) => server.toJson()).toList(),
      'connectedCount': connectedCount,
      'totalCount': totalCount,
      'toolCount': toolCount,
      'connectedServers': connectedCount, // Legacy alias
      'configuredServers': totalCount, // Legacy alias
      'totalTools': toolCount, // Legacy alias
    };
  }
}
