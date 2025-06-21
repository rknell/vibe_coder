import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';

/// 📊 MCP SERVER DATA MODEL LAYER
///
/// ARCHITECTURAL: Individual MCP server entity with self-management capabilities
/// Handles its own persistence, validation, and state broadcasting
/// Extends ChangeNotifier for reactive UI updates
class MCPServerModel extends ChangeNotifier {
  static final Logger _logger = Logger('MCPServerModel');
  static const _uuid = Uuid();

  // 🎯 CORE FIELDS
  final String id;
  String name;
  String displayName;
  String? description;
  MCPServerType type;
  MCPServerStatus status;

  // 🔧 CONNECTION CONFIGURATION
  String? command;
  List<String>? args;
  Map<String, String>? env;
  String? url;

  // 📊 CAPABILITY DATA
  List<MCPTool> availableTools;
  List<MCPResource> availableResources;
  List<MCPPrompt> availablePrompts;

  // 🕒 METADATA
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? lastConnectedAt;
  Map<String, dynamic> metadata;

  /// Constructor with required fields
  MCPServerModel({
    String? id,
    required this.name,
    String? displayName,
    this.description,
    required this.type,
    this.status = MCPServerStatus.disconnected,
    this.command,
    this.args,
    this.env,
    this.url,
    List<MCPTool>? availableTools,
    List<MCPResource>? availableResources,
    List<MCPPrompt>? availablePrompts,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastConnectedAt,
    Map<String, dynamic>? metadata,
  })  : id = id ?? _uuid.v4(),
        displayName = displayName ?? name,
        availableTools = availableTools ?? [],
        availableResources = availableResources ?? [],
        availablePrompts = availablePrompts ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        metadata = metadata ?? {};

  /// 💾 SELF-MANAGEMENT: Save to JSON file
  ///
  /// PERF: O(1) - single file write operation
  /// ARCHITECTURAL: Model handles its own persistence in /data directory
  Future<void> save() async {
    try {
      _logger.info('💾 SAVING: MCP server $name to persistence');

      updatedAt = DateTime.now();

      final dataDir = Directory('data/mcp_servers');
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
        _logger.info('📁 CREATED: MCP servers data directory');
      }

      final file = File('data/mcp_servers/$id.json');
      await file.writeAsString(jsonEncode(toJson()));

      _logger.info('✅ SAVED: MCP server $name successfully');
      notifyListeners(); // MANDATORY after state change
    } catch (e, stackTrace) {
      _logger.severe('💥 SAVE FAILED: MCP server $name - $e', e, stackTrace);
      rethrow; // Bubble stack trace to surface
    }
  }

  /// 🗑️ SELF-MANAGEMENT: Delete from storage
  ///
  /// PERF: O(1) - single file delete operation
  /// ARCHITECTURAL: Model handles its own deletion
  Future<void> delete() async {
    try {
      _logger.info('🗑️ DELETING: MCP server $name from persistence');

      final file = File('data/mcp_servers/$id.json');
      if (await file.exists()) {
        await file.delete();
        _logger.info('✅ DELETED: MCP server $name successfully');
      }

      notifyListeners(); // MANDATORY after state change
    } catch (e, stackTrace) {
      _logger.severe('💥 DELETE FAILED: MCP server $name - $e', e, stackTrace);
      rethrow; // Bubble stack trace to surface
    }
  }

  /// ✅ VALIDATION: Data model level validation
  ///
  /// PERF: O(1) - simple field validation
  /// ARCHITECTURAL: Validation handled at individual record level
  bool validate() {
    final errors = <String>[];

    if (name.trim().isEmpty) {
      errors.add('Server name cannot be empty');
    }

    if (displayName.trim().isEmpty) {
      errors.add('Display name cannot be empty');
    }

    switch (type) {
      case MCPServerType.stdio:
        final commandValue = command;
        if (commandValue == null || commandValue.trim().isEmpty) {
          errors.add('STDIO servers require command');
        }
        break;
      case MCPServerType.sse:
        final urlValue = url;
        if (urlValue == null || urlValue.trim().isEmpty) {
          errors.add('SSE servers require URL');
        }
        try {
          if (urlValue != null) Uri.parse(urlValue);
        } catch (e) {
          errors.add('Invalid URL format: $url');
        }
        break;
    }

    if (errors.isNotEmpty) {
      _logger.warning('⚠️ VALIDATION FAILED: ${errors.join(', ')}');
      throw MCPServerValidationException(errors);
    }

    return true;
  }

  /// 🔄 STATUS MANAGEMENT: Update connection status
  ///
  /// PERF: O(1) - simple status update
  /// ARCHITECTURAL: Self-managed status with state broadcasting
  void updateStatus(MCPServerStatus newStatus) {
    if (status != newStatus) {
      status = newStatus;
      updatedAt = DateTime.now();

      if (newStatus == MCPServerStatus.connected) {
        lastConnectedAt = DateTime.now();
      }

      _logger.info('🔄 STATUS UPDATE: $name → ${newStatus.name}');
      notifyListeners(); // MANDATORY after state change
    }
  }

  /// 🛠️ CAPABILITY MANAGEMENT: Update available tools
  ///
  /// PERF: O(n) where n = number of tools
  /// ARCHITECTURAL: Self-managed capability updates
  void updateTools(List<MCPTool> tools) {
    availableTools = tools;
    updatedAt = DateTime.now();

    _logger.info('🛠️ TOOLS UPDATED: $name now has ${tools.length} tools');
    notifyListeners(); // MANDATORY after state change
  }

  /// 📚 CAPABILITY MANAGEMENT: Update available resources
  void updateResources(List<MCPResource> resources) {
    availableResources = resources;
    updatedAt = DateTime.now();

    _logger.info(
        '📚 RESOURCES UPDATED: $name now has ${resources.length} resources');
    notifyListeners(); // MANDATORY after state change
  }

  /// 💬 CAPABILITY MANAGEMENT: Update available prompts
  void updatePrompts(List<MCPPrompt> prompts) {
    availablePrompts = prompts;
    updatedAt = DateTime.now();

    _logger.info('💬 PROMPTS UPDATED: $name now has ${prompts.length} prompts');
    notifyListeners(); // MANDATORY after state change
  }

  /// 📊 RELATIONSHIP ACCESS: Get configuration for client connection
  ///
  /// PERF: O(1) - direct field access
  /// ARCHITECTURAL: Related data access via getter
  Map<String, dynamic> get connectionConfig {
    switch (type) {
      case MCPServerType.stdio:
        return {
          'type': 'stdio',
          'command': command,
          'args': args ?? [],
          'env': env ?? {},
        };
      case MCPServerType.sse:
        return {
          'type': 'sse',
          'url': url,
        };
    }
  }

  /// 📈 METRICS: Get capability counts
  Map<String, int> get capabilityCounts => {
        'tools': availableTools.length,
        'resources': availableResources.length,
        'prompts': availablePrompts.length,
      };

  /// 🎯 SERIALIZATION: Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'displayName': displayName,
        'description': description,
        'type': type.name,
        'status': status.name,
        'command': command,
        'args': args,
        'env': env,
        'url': url,
        'availableTools': availableTools.map((t) => t.toJson()).toList(),
        'availableResources':
            availableResources.map((r) => r.toJson()).toList(),
        'availablePrompts': availablePrompts.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'lastConnectedAt': lastConnectedAt?.toIso8601String(),
        'metadata': metadata,
      };

  /// 🎯 DESERIALIZATION: Create from JSON
  factory MCPServerModel.fromJson(Map<String, dynamic> json) {
    return MCPServerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String?,
      description: json['description'] as String?,
      type: MCPServerType.values.byName(json['type'] as String),
      status: MCPServerStatus.values.byName(json['status'] as String),
      command: json['command'] as String?,
      args: (json['args'] as List<dynamic>?)?.cast<String>(),
      env: (json['env'] as Map<String, dynamic>?)?.cast<String, String>(),
      url: json['url'] as String?,
      availableTools: (json['availableTools'] as List<dynamic>? ?? [])
          .map((t) => MCPTool.fromJson(t as Map<String, dynamic>))
          .toList(),
      availableResources: (json['availableResources'] as List<dynamic>? ?? [])
          .map((r) => MCPResource.fromJson(r as Map<String, dynamic>))
          .toList(),
      availablePrompts: (json['availablePrompts'] as List<dynamic>? ?? [])
          .map((p) => MCPPrompt.fromJson(p as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastConnectedAt: json['lastConnectedAt'] != null
          ? DateTime.parse(json['lastConnectedAt'] as String)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  /// 🏭 FACTORY: Create STDIO server
  factory MCPServerModel.stdio({
    required String name,
    required String command,
    List<String>? args,
    Map<String, String>? env,
    String? description,
  }) {
    return MCPServerModel(
      name: name,
      type: MCPServerType.stdio,
      command: command,
      args: args,
      env: env,
      description: description,
    );
  }

  /// 🏭 FACTORY: Create SSE server
  factory MCPServerModel.sse({
    required String name,
    required String url,
    String? description,
  }) {
    return MCPServerModel(
      name: name,
      type: MCPServerType.sse,
      url: url,
      description: description,
    );
  }
}

/// 🔧 MCP SERVER ENUMERATIONS
enum MCPServerType { stdio, sse }

enum MCPServerStatus { disconnected, connecting, connected, error, unsupported }

/// ⚠️ MCP SERVER VALIDATION EXCEPTION
class MCPServerValidationException implements Exception {
  final List<String> errors;

  MCPServerValidationException(this.errors);

  @override
  String toString() => 'MCPServerValidationException: ${errors.join(', ')}';
}

/// 🛠️ MCP TOOL MODEL
class MCPTool {
  final String name;
  final String? description;
  final Map<String, dynamic> inputSchema;
  final MCPToolAnnotations? annotations;

  MCPTool({
    required this.name,
    this.description,
    required this.inputSchema,
    this.annotations,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'inputSchema': inputSchema,
        'annotations': annotations?.toJson(),
      };

  factory MCPTool.fromJson(Map<String, dynamic> json) => MCPTool(
        name: json['name'] as String,
        description: json['description'] as String?,
        inputSchema: json['inputSchema'] as Map<String, dynamic>,
        annotations: json['annotations'] != null
            ? MCPToolAnnotations.fromJson(
                json['annotations'] as Map<String, dynamic>)
            : null,
      );
}

/// 🏷️ MCP TOOL ANNOTATIONS
class MCPToolAnnotations {
  final String? title;
  final bool? readOnlyHint;
  final bool? destructiveHint;
  final bool? idempotentHint;
  final bool? openWorldHint;

  MCPToolAnnotations({
    this.title,
    this.readOnlyHint,
    this.destructiveHint,
    this.idempotentHint,
    this.openWorldHint,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'readOnlyHint': readOnlyHint,
        'destructiveHint': destructiveHint,
        'idempotentHint': idempotentHint,
        'openWorldHint': openWorldHint,
      };

  factory MCPToolAnnotations.fromJson(Map<String, dynamic> json) =>
      MCPToolAnnotations(
        title: json['title'] as String?,
        readOnlyHint: json['readOnlyHint'] as bool?,
        destructiveHint: json['destructiveHint'] as bool?,
        idempotentHint: json['idempotentHint'] as bool?,
        openWorldHint: json['openWorldHint'] as bool?,
      );
}

/// 📚 MCP RESOURCE MODEL
class MCPResource {
  final String uri;
  final String name;
  final String? description;
  final String? mimeType;

  MCPResource({
    required this.uri,
    required this.name,
    this.description,
    this.mimeType,
  });

  Map<String, dynamic> toJson() => {
        'uri': uri,
        'name': name,
        'description': description,
        'mimeType': mimeType,
      };

  factory MCPResource.fromJson(Map<String, dynamic> json) => MCPResource(
        uri: json['uri'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        mimeType: json['mimeType'] as String?,
      );
}

/// 💬 MCP PROMPT MODEL
class MCPPrompt {
  final String name;
  final String? description;
  final List<MCPPromptArgument>? arguments;

  MCPPrompt({
    required this.name,
    this.description,
    this.arguments,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'arguments': arguments?.map((a) => a.toJson()).toList(),
      };

  factory MCPPrompt.fromJson(Map<String, dynamic> json) => MCPPrompt(
        name: json['name'] as String,
        description: json['description'] as String?,
        arguments: (json['arguments'] as List<dynamic>?)
            ?.map((a) => MCPPromptArgument.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
}

/// 🔧 MCP PROMPT ARGUMENT
class MCPPromptArgument {
  final String name;
  final String? description;
  final bool? required;

  MCPPromptArgument({
    required this.name,
    this.description,
    this.required,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'required': required,
      };

  factory MCPPromptArgument.fromJson(Map<String, dynamic> json) =>
      MCPPromptArgument(
        name: json['name'] as String,
        description: json['description'] as String?,
        required: json['required'] as bool?,
      );
}
