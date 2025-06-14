import 'package:json_annotation/json_annotation.dart';

part 'mcp_models.g.dart';

/// MCP Server Configuration
@JsonSerializable()
class MCPServerConfig {
  final String? command;
  final List<String>? args;
  final Map<String, String>? env;
  final String? type;
  final String? url;

  MCPServerConfig({
    this.command,
    this.args,
    this.env,
    this.type,
    this.url,
  });

  factory MCPServerConfig.fromJson(Map<String, dynamic> json) =>
      _$MCPServerConfigFromJson(json);

  Map<String, dynamic> toJson() => _$MCPServerConfigToJson(this);
}

/// Root MCP Configuration
@JsonSerializable()
class MCPConfig {
  final Map<String, MCPServerConfig> mcpServers;

  MCPConfig({required this.mcpServers});

  factory MCPConfig.fromJson(Map<String, dynamic> json) =>
      _$MCPConfigFromJson(json);

  Map<String, dynamic> toJson() => _$MCPConfigToJson(this);
}

/// MCP Tool Definition
@JsonSerializable()
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

  factory MCPTool.fromJson(Map<String, dynamic> json) =>
      _$MCPToolFromJson(json);

  Map<String, dynamic> toJson() => _$MCPToolToJson(this);
}

/// MCP Tool Annotations
@JsonSerializable()
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

  factory MCPToolAnnotations.fromJson(Map<String, dynamic> json) =>
      _$MCPToolAnnotationsFromJson(json);

  Map<String, dynamic> toJson() => _$MCPToolAnnotationsToJson(this);
}

/// MCP Tool Call Request
@JsonSerializable()
class MCPToolCallRequest {
  final String name;
  final Map<String, dynamic> arguments;

  MCPToolCallRequest({
    required this.name,
    required this.arguments,
  });

  factory MCPToolCallRequest.fromJson(Map<String, dynamic> json) =>
      _$MCPToolCallRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MCPToolCallRequestToJson(this);
}

/// MCP Content types
@JsonSerializable()
class MCPTextContent {
  final String type;
  final String text;

  MCPTextContent({
    required this.type,
    required this.text,
  });

  factory MCPTextContent.fromJson(Map<String, dynamic> json) =>
      _$MCPTextContentFromJson(json);

  Map<String, dynamic> toJson() => _$MCPTextContentToJson(this);
}

/// MCP Tool Call Result
@JsonSerializable()
class MCPToolCallResult {
  final List<MCPTextContent> content;
  final bool? isError;

  MCPToolCallResult({
    required this.content,
    this.isError,
  });

  factory MCPToolCallResult.fromJson(Map<String, dynamic> json) =>
      _$MCPToolCallResultFromJson(json);

  Map<String, dynamic> toJson() => _$MCPToolCallResultToJson(this);
}

/// MCP Resource
@JsonSerializable()
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

  factory MCPResource.fromJson(Map<String, dynamic> json) =>
      _$MCPResourceFromJson(json);

  Map<String, dynamic> toJson() => _$MCPResourceToJson(this);
}

/// MCP Prompt
@JsonSerializable()
class MCPPrompt {
  final String name;
  final String? description;
  final List<MCPPromptArgument>? arguments;

  MCPPrompt({
    required this.name,
    this.description,
    this.arguments,
  });

  factory MCPPrompt.fromJson(Map<String, dynamic> json) =>
      _$MCPPromptFromJson(json);

  Map<String, dynamic> toJson() => _$MCPPromptToJson(this);
}

/// MCP Prompt Argument
@JsonSerializable()
class MCPPromptArgument {
  final String name;
  final String? description;
  final bool? required;

  MCPPromptArgument({
    required this.name,
    this.description,
    this.required,
  });

  factory MCPPromptArgument.fromJson(Map<String, dynamic> json) =>
      _$MCPPromptArgumentFromJson(json);

  Map<String, dynamic> toJson() => _$MCPPromptArgumentToJson(this);
}

/// JSON-RPC 2.0 Request
@JsonSerializable()
class JSONRPCRequest {
  final String jsonrpc;
  final String id;
  final String method;
  final Map<String, dynamic>? params;

  JSONRPCRequest({
    this.jsonrpc = '2.0',
    required this.id,
    required this.method,
    this.params,
  });

  factory JSONRPCRequest.fromJson(Map<String, dynamic> json) =>
      _$JSONRPCRequestFromJson(json);

  Map<String, dynamic> toJson() => _$JSONRPCRequestToJson(this);
}

/// JSON-RPC 2.0 Response
@JsonSerializable()
class JSONRPCResponse {
  final String jsonrpc;
  final String id;
  final Map<String, dynamic>? result;
  final JSONRPCError? error;

  JSONRPCResponse({
    this.jsonrpc = '2.0',
    required this.id,
    this.result,
    this.error,
  });

  factory JSONRPCResponse.fromJson(Map<String, dynamic> json) =>
      _$JSONRPCResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JSONRPCResponseToJson(this);
}

/// JSON-RPC 2.0 Error
@JsonSerializable()
class JSONRPCError {
  final int code;
  final String message;
  final dynamic data;

  JSONRPCError({
    required this.code,
    required this.message,
    this.data,
  });

  factory JSONRPCError.fromJson(Map<String, dynamic> json) =>
      _$JSONRPCErrorFromJson(json);

  Map<String, dynamic> toJson() => _$JSONRPCErrorToJson(this);
}
