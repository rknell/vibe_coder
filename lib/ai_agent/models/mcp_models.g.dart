// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MCPServerConfig _$MCPServerConfigFromJson(Map<String, dynamic> json) =>
    MCPServerConfig(
      command: json['command'] as String,
      args: (json['args'] as List<dynamic>).map((e) => e as String).toList(),
      env: (json['env'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      type: json['type'] as String?,
      url: json['url'] as String?,
    );

Map<String, dynamic> _$MCPServerConfigToJson(MCPServerConfig instance) =>
    <String, dynamic>{
      'command': instance.command,
      'args': instance.args,
      'env': instance.env,
      'type': instance.type,
      'url': instance.url,
    };

MCPConfig _$MCPConfigFromJson(Map<String, dynamic> json) => MCPConfig(
      mcpServers: (json['mcpServers'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, MCPServerConfig.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$MCPConfigToJson(MCPConfig instance) => <String, dynamic>{
      'mcpServers': instance.mcpServers,
    };

MCPTool _$MCPToolFromJson(Map<String, dynamic> json) => MCPTool(
      name: json['name'] as String,
      description: json['description'] as String?,
      inputSchema: json['inputSchema'] as Map<String, dynamic>,
      annotations: json['annotations'] == null
          ? null
          : MCPToolAnnotations.fromJson(
              json['annotations'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MCPToolToJson(MCPTool instance) => <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'inputSchema': instance.inputSchema,
      'annotations': instance.annotations,
    };

MCPToolAnnotations _$MCPToolAnnotationsFromJson(Map<String, dynamic> json) =>
    MCPToolAnnotations(
      title: json['title'] as String?,
      readOnlyHint: json['readOnlyHint'] as bool?,
      destructiveHint: json['destructiveHint'] as bool?,
      idempotentHint: json['idempotentHint'] as bool?,
      openWorldHint: json['openWorldHint'] as bool?,
    );

Map<String, dynamic> _$MCPToolAnnotationsToJson(MCPToolAnnotations instance) =>
    <String, dynamic>{
      'title': instance.title,
      'readOnlyHint': instance.readOnlyHint,
      'destructiveHint': instance.destructiveHint,
      'idempotentHint': instance.idempotentHint,
      'openWorldHint': instance.openWorldHint,
    };

MCPToolCallRequest _$MCPToolCallRequestFromJson(Map<String, dynamic> json) =>
    MCPToolCallRequest(
      name: json['name'] as String,
      arguments: json['arguments'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$MCPToolCallRequestToJson(MCPToolCallRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'arguments': instance.arguments,
    };

MCPTextContent _$MCPTextContentFromJson(Map<String, dynamic> json) =>
    MCPTextContent(
      type: json['type'] as String,
      text: json['text'] as String,
    );

Map<String, dynamic> _$MCPTextContentToJson(MCPTextContent instance) =>
    <String, dynamic>{
      'type': instance.type,
      'text': instance.text,
    };

MCPToolCallResult _$MCPToolCallResultFromJson(Map<String, dynamic> json) =>
    MCPToolCallResult(
      content: (json['content'] as List<dynamic>)
          .map((e) => MCPTextContent.fromJson(e as Map<String, dynamic>))
          .toList(),
      isError: json['isError'] as bool?,
    );

Map<String, dynamic> _$MCPToolCallResultToJson(MCPToolCallResult instance) =>
    <String, dynamic>{
      'content': instance.content,
      'isError': instance.isError,
    };

MCPResource _$MCPResourceFromJson(Map<String, dynamic> json) => MCPResource(
      uri: json['uri'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      mimeType: json['mimeType'] as String?,
    );

Map<String, dynamic> _$MCPResourceToJson(MCPResource instance) =>
    <String, dynamic>{
      'uri': instance.uri,
      'name': instance.name,
      'description': instance.description,
      'mimeType': instance.mimeType,
    };

MCPPrompt _$MCPPromptFromJson(Map<String, dynamic> json) => MCPPrompt(
      name: json['name'] as String,
      description: json['description'] as String?,
      arguments: (json['arguments'] as List<dynamic>?)
          ?.map((e) => MCPPromptArgument.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MCPPromptToJson(MCPPrompt instance) => <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'arguments': instance.arguments,
    };

MCPPromptArgument _$MCPPromptArgumentFromJson(Map<String, dynamic> json) =>
    MCPPromptArgument(
      name: json['name'] as String,
      description: json['description'] as String?,
      required: json['required'] as bool?,
    );

Map<String, dynamic> _$MCPPromptArgumentToJson(MCPPromptArgument instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'required': instance.required,
    };

JSONRPCRequest _$JSONRPCRequestFromJson(Map<String, dynamic> json) =>
    JSONRPCRequest(
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      id: json['id'] as String,
      method: json['method'] as String,
      params: json['params'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$JSONRPCRequestToJson(JSONRPCRequest instance) =>
    <String, dynamic>{
      'jsonrpc': instance.jsonrpc,
      'id': instance.id,
      'method': instance.method,
      'params': instance.params,
    };

JSONRPCResponse _$JSONRPCResponseFromJson(Map<String, dynamic> json) =>
    JSONRPCResponse(
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      id: json['id'] as String,
      result: json['result'] as Map<String, dynamic>?,
      error: json['error'] == null
          ? null
          : JSONRPCError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JSONRPCResponseToJson(JSONRPCResponse instance) =>
    <String, dynamic>{
      'jsonrpc': instance.jsonrpc,
      'id': instance.id,
      'result': instance.result,
      'error': instance.error,
    };

JSONRPCError _$JSONRPCErrorFromJson(Map<String, dynamic> json) => JSONRPCError(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      data: json['data'],
    );

Map<String, dynamic> _$JSONRPCErrorToJson(JSONRPCError instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };
