import 'dart:convert';
// dart:io removed - not needed for HTTP client
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../models/mcp_models.dart';

/// MCP Client that communicates with MCP servers using JSON-RPC 2.0
class MCPClient {
  final Logger _logger = Logger('MCPClient');
  final String _serverUrl;
  final Map<String, String> _headers;
  int _requestId = 0;

  MCPClient({
    required String serverUrl,
    Map<String, String>? headers,
  })  : _serverUrl = serverUrl,
        _headers = headers ?? {};

  /// Generate a unique request ID
  String _generateRequestId() {
    return 'req_${++_requestId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Send a JSON-RPC request to the MCP server
  Future<JSONRPCResponse> _sendRequest(JSONRPCRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {
          'Content-Type': 'application/json',
          ..._headers,
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode != 200) {
        throw MCPException(
          'HTTP error: ${response.statusCode} - ${response.body}',
        );
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      return JSONRPCResponse.fromJson(jsonResponse);
    } catch (e) {
      _logger.severe('Error sending MCP request: $e');
      throw MCPException('Failed to send request: $e');
    }
  }

  /// Initialize connection with the MCP server
  Future<void> initialize() async {
    final request = JSONRPCRequest(
      id: _generateRequestId(),
      method: 'initialize',
      params: {
        'protocolVersion': '2025-03-26',
        'capabilities': {
          'tools': {},
          'resources': {},
          'prompts': {},
        },
        'clientInfo': {
          'name': 'vibe_coder',
          'version': '1.0.0',
        },
      },
    );

    final response = await _sendRequest(request);

    if (response.error != null) {
      throw MCPException(
        'Failed to initialize: ${response.error!.message}',
      );
    }

    _logger.info('MCP client initialized successfully');
  }

  /// List available tools from the MCP server
  Future<List<MCPTool>> listTools() async {
    final request = JSONRPCRequest(
      id: _generateRequestId(),
      method: 'tools/list',
    );

    final response = await _sendRequest(request);

    if (response.error != null) {
      throw MCPException(
        'Failed to list tools: ${response.error!.message}',
      );
    }

    final result = response.result!;
    final toolsData = result['tools'] as List<dynamic>;

    return toolsData
        .map((tool) => MCPTool.fromJson(tool as Map<String, dynamic>))
        .toList();
  }

  /// Call a tool on the MCP server
  Future<MCPToolCallResult> callTool(MCPToolCallRequest toolCall) async {
    final request = JSONRPCRequest(
      id: _generateRequestId(),
      method: 'tools/call',
      params: {
        'name': toolCall.name,
        'arguments': toolCall.arguments,
      },
    );

    final response = await _sendRequest(request);

    if (response.error != null) {
      throw MCPException(
        'Failed to call tool: ${response.error!.message}',
      );
    }

    return MCPToolCallResult.fromJson(response.result!);
  }

  /// List available resources from the MCP server
  Future<List<MCPResource>> listResources() async {
    final request = JSONRPCRequest(
      id: _generateRequestId(),
      method: 'resources/list',
    );

    final response = await _sendRequest(request);

    if (response.error != null) {
      throw MCPException(
        'Failed to list resources: ${response.error!.message}',
      );
    }

    final result = response.result!;
    final resourcesData = result['resources'] as List<dynamic>;

    return resourcesData
        .map((resource) =>
            MCPResource.fromJson(resource as Map<String, dynamic>))
        .toList();
  }

  /// Read a resource from the MCP server
  Future<MCPTextContent> readResource(String uri) async {
    final request = JSONRPCRequest(
      id: _generateRequestId(),
      method: 'resources/read',
      params: {
        'uri': uri,
      },
    );

    final response = await _sendRequest(request);

    if (response.error != null) {
      throw MCPException(
        'Failed to read resource: ${response.error!.message}',
      );
    }

    final result = response.result!;
    final contentsData = result['contents'] as List<dynamic>;

    if (contentsData.isEmpty) {
      throw MCPException('Resource returned no content');
    }

    return MCPTextContent.fromJson(contentsData.first as Map<String, dynamic>);
  }

  /// List available prompts from the MCP server
  Future<List<MCPPrompt>> listPrompts() async {
    final request = JSONRPCRequest(
      id: _generateRequestId(),
      method: 'prompts/list',
    );

    final response = await _sendRequest(request);

    if (response.error != null) {
      throw MCPException(
        'Failed to list prompts: ${response.error!.message}',
      );
    }

    final result = response.result!;
    final promptsData = result['prompts'] as List<dynamic>;

    return promptsData
        .map((prompt) => MCPPrompt.fromJson(prompt as Map<String, dynamic>))
        .toList();
  }

  /// Get a prompt from the MCP server
  Future<List<MCPTextContent>> getPrompt(
    String name, {
    Map<String, dynamic>? arguments,
  }) async {
    final request = JSONRPCRequest(
      id: _generateRequestId(),
      method: 'prompts/get',
      params: {
        'name': name,
        if (arguments != null) 'arguments': arguments,
      },
    );

    final response = await _sendRequest(request);

    if (response.error != null) {
      throw MCPException(
        'Failed to get prompt: ${response.error!.message}',
      );
    }

    final result = response.result!;
    final messagesData = result['messages'] as List<dynamic>;

    return messagesData
        .map((message) =>
            MCPTextContent.fromJson(message as Map<String, dynamic>))
        .toList();
  }

  /// Close the connection to the MCP server
  Future<void> close() async {
    _logger.info('MCP client connection closed');
  }
}

/// Exception thrown when MCP operations fail
class MCPException implements Exception {
  final String message;

  MCPException(this.message);

  @override
  String toString() => 'MCPException: $message';
}
