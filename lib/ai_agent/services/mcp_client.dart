import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../models/mcp_models.dart';

/// Transport type for MCP client
enum MCPTransportType { http, stdio }

/// MCP Client for communicating with MCP servers
class MCPClient {
  final Logger _logger = Logger('MCPClient');

  // HTTP transport fields
  final String? serverUrl;
  final http.Client _httpClient = http.Client();

  // STDIO transport fields
  final String? command;
  final List<String>? args;
  final Map<String, String>? env;
  Process? _process;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;

  // Common fields
  final MCPTransportType transportType;
  bool _isInitialized = false;
  int _requestId = 0;
  final Map<String, Completer<JSONRPCResponse>> _pendingRequests = {};

  /// Create HTTP/SSE client
  MCPClient({required this.serverUrl})
      : transportType = MCPTransportType.http,
        command = null,
        args = null,
        env = null {
    _logger.info('Created HTTP MCP client for: $serverUrl');
  }

  /// Create STDIO client
  MCPClient.stdio({
    required this.command,
    required this.args,
    this.env,
  })  : transportType = MCPTransportType.stdio,
        serverUrl = null {
    _logger.info('Created STDIO MCP client: $command ${args?.join(' ')}');
  }

  /// Initialize the client
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      switch (transportType) {
        case MCPTransportType.http:
          await _initializeHttp();
          break;
        case MCPTransportType.stdio:
          await _initializeStdio();
          break;
      }
      _isInitialized = true;
      _logger.info('MCP client initialized successfully');
    } catch (e) {
      _logger.severe('Failed to initialize MCP client: $e');
      rethrow;
    }
  }

  /// Initialize HTTP transport
  Future<void> _initializeHttp() async {
    if (serverUrl == null) {
      throw MCPException('Server URL is required for HTTP transport');
    }

    // Test connection
    final response = await _httpClient.get(Uri.parse(serverUrl!));
    if (response.statusCode >= 400) {
      throw MCPException(
          'HTTP server returned ${response.statusCode}: ${response.body}');
    }
    _logger.info('HTTP connection established');
  }

  /// Initialize STDIO transport
  Future<void> _initializeStdio() async {
    if (command == null) {
      throw MCPException('Command is required for STDIO transport');
    }

    try {
      _logger
          .info('🚀 STDIO INIT: Starting process: $command ${args?.join(' ')}');
      _logger.info('🔧 STDIO ENV: ${env?.keys.join(', ') ?? 'No custom env'}');

      _process = await Process.start(
        command!,
        args ?? [],
        environment: env,
        mode: ProcessStartMode.normal,
      );

      _logger.info(
          '✅ STDIO PROCESS: Started successfully (PID: ${_process!.pid})');

      // Set up stdout listener for responses
      _stdoutSubscription = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.trim().isNotEmpty) {
            _logger.info('📥 STDIO STDOUT: $line');
            _handleStdioResponse(line);
          }
        },
        onError: (error) {
          _logger.severe('💥 STDIO STDOUT ERROR: $error');
        },
      );

      // Set up stderr listener for debugging
      _stderrSubscription = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.trim().isNotEmpty) {
            _logger.warning('⚠️ STDIO STDERR: $line');
          }
        },
        onError: (error) {
          _logger.severe('💥 STDIO STDERR ERROR: $error');
        },
      );

      // Send initialization request
      _logger.info('🤝 STDIO HANDSHAKE: Sending initialization...');
      await _sendStdioInitialization();

      _logger.info(
          '🎯 STDIO SUCCESS: Process initialized and handshake completed');
    } catch (e) {
      _logger.severe('💀 STDIO FAILURE: Failed to start process: $e');
      await _cleanup();
      rethrow;
    }
  }

  /// Send initialization request to STDIO server
  Future<void> _sendStdioInitialization() async {
    final initRequest = JSONRPCRequest(
      id: _getNextRequestId(),
      method: 'initialize',
      params: {
        'protocolVersion': '2024-11-05',
        'capabilities': {
          'tools': {},
          'resources': {},
          'prompts': {},
        },
        'clientInfo': {
          'name': 'VibeCoder',
          'version': '1.0.0',
        },
      },
    );

    _logger.info('📤 INIT REQUEST: ${jsonEncode(initRequest.toJson())}');

    try {
      final response = await _sendStdioRequest(initRequest);
      _logger.info('📥 INIT RESPONSE: ${jsonEncode(response.toJson())}');

      if (response.error != null) {
        throw MCPException('Initialization failed: ${response.error!.message}');
      }

      _logger.info('✅ HANDSHAKE: MCP initialization successful');
    } catch (e) {
      _logger.severe('💥 HANDSHAKE FAILED: $e');
      rethrow;
    }
  }

  /// Handle STDIO response
  void _handleStdioResponse(String line) {
    try {
      _logger.fine('🔍 PARSING: Attempting to parse JSON: $line');
      final json = jsonDecode(line) as Map<String, dynamic>;
      final response = JSONRPCResponse.fromJson(json);

      _logger.info(
          '📨 RESPONSE PARSED: ID=${response.id}, Error=${response.error?.message ?? 'None'}');

      // Find and complete the corresponding request
      final completer = _pendingRequests.remove(response.id);
      if (completer != null) {
        _logger.info('✅ REQUEST COMPLETED: ID=${response.id}');
        completer.complete(response);
      } else {
        _logger.warning(
            '⚠️ ORPHANED RESPONSE: No pending request for ID=${response.id}');
      }
    } catch (e) {
      _logger.severe(
          '💥 PARSE FAILURE: Failed to parse response: $line, error: $e');
    }
  }

  /// Send request via STDIO
  Future<JSONRPCResponse> _sendStdioRequest(JSONRPCRequest request) async {
    if (_process == null) {
      throw MCPException('STDIO process not initialized');
    }

    final completer = Completer<JSONRPCResponse>();
    _pendingRequests[request.id] = completer;

    try {
      final requestJson = jsonEncode(request.toJson());
      _logger.fine('STDIO Request: $requestJson');

      _process!.stdin.writeln(requestJson);
      await _process!.stdin.flush();

      // Wait for response with timeout
      final response = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _pendingRequests.remove(request.id);
          throw MCPException('STDIO request timeout for ${request.method}');
        },
      );

      if (response.error != null) {
        throw MCPException('STDIO request failed: ${response.error!.message}');
      }

      return response;
    } catch (e) {
      _pendingRequests.remove(request.id);
      rethrow;
    }
  }

  /// Get next request ID
  String _getNextRequestId() => (_requestId++).toString();

  /// List available tools
  Future<List<MCPTool>> listTools() async {
    if (!_isInitialized) await initialize();

    switch (transportType) {
      case MCPTransportType.http:
        return _listToolsHttp();
      case MCPTransportType.stdio:
        return _listToolsStdio();
    }
  }

  /// List tools via HTTP
  Future<List<MCPTool>> _listToolsHttp() async {
    // HTTP implementation (existing)
    throw MCPException('HTTP tools listing not yet implemented');
  }

  /// List tools via STDIO
  Future<List<MCPTool>> _listToolsStdio() async {
    _logger.info('🔧 TOOLS REQUEST: Listing available tools...');

    final request = JSONRPCRequest(
      id: _getNextRequestId(),
      method: 'tools/list',
      params: {}, // Empty params object instead of null
    );

    _logger.info('📤 TOOLS REQUEST: ${jsonEncode(request.toJson())}');

    try {
      final response = await _sendStdioRequest(request);
      _logger.info('📥 TOOLS RESPONSE: ${jsonEncode(response.toJson())}');

      if (response.result != null) {
        final toolsData = response.result!['tools'] as List<dynamic>?;
        _logger.info('🔍 TOOLS DATA: Found ${toolsData?.length ?? 0} tools');

        if (toolsData != null) {
          for (int i = 0; i < toolsData.length; i++) {
            _logger.info('🛠️ TOOL[$i]: ${jsonEncode(toolsData[i])}');
          }
        }

        final tools = toolsData
                ?.map((tool) => MCPTool.fromJson(tool as Map<String, dynamic>))
                .toList() ??
            [];

        _logger
            .info('✅ TOOLS SUCCESS: Retrieved ${tools.length} tools via STDIO');
        return tools;
      } else {
        _logger.warning('⚠️ TOOLS EMPTY: No result in response');
      }
    } catch (e) {
      _logger.severe('💥 TOOLS FAILURE: $e');
      rethrow;
    }

    return [];
  }

  /// List available resources
  Future<List<MCPResource>> listResources() async {
    if (!_isInitialized) await initialize();

    switch (transportType) {
      case MCPTransportType.http:
        return _listResourcesHttp();
      case MCPTransportType.stdio:
        return _listResourcesStdio();
    }
  }

  /// List resources via HTTP
  Future<List<MCPResource>> _listResourcesHttp() async {
    throw MCPException('HTTP resources listing not yet implemented');
  }

  /// List resources via STDIO
  Future<List<MCPResource>> _listResourcesStdio() async {
    final request = JSONRPCRequest(
      id: _getNextRequestId(),
      method: 'resources/list',
      params: {}, // Empty params object instead of null
    );

    try {
      final response = await _sendStdioRequest(request);

      if (response.result != null) {
        final resources = (response.result!['resources'] as List<dynamic>?)
                ?.map((resource) =>
                    MCPResource.fromJson(resource as Map<String, dynamic>))
                .toList() ??
            [];

        _logger.info('Retrieved ${resources.length} resources via STDIO');
        return resources;
      }
    } catch (e) {
      if (e.toString().contains('Method not found')) {
        _logger
            .info('Server does not support resources - returning empty list');
        return [];
      }
      rethrow;
    }

    return [];
  }

  /// List available prompts
  Future<List<MCPPrompt>> listPrompts() async {
    if (!_isInitialized) await initialize();

    switch (transportType) {
      case MCPTransportType.http:
        return _listPromptsHttp();
      case MCPTransportType.stdio:
        return _listPromptsStdio();
    }
  }

  /// List prompts via HTTP
  Future<List<MCPPrompt>> _listPromptsHttp() async {
    throw MCPException('HTTP prompts listing not yet implemented');
  }

  /// List prompts via STDIO
  Future<List<MCPPrompt>> _listPromptsStdio() async {
    final request = JSONRPCRequest(
      id: _getNextRequestId(),
      method: 'prompts/list',
      params: {}, // Empty params object instead of null
    );

    try {
      final response = await _sendStdioRequest(request);

      if (response.result != null) {
        final prompts = (response.result!['prompts'] as List<dynamic>?)
                ?.map((prompt) =>
                    MCPPrompt.fromJson(prompt as Map<String, dynamic>))
                .toList() ??
            [];

        _logger.info('Retrieved ${prompts.length} prompts via STDIO');
        return prompts;
      }
    } catch (e) {
      if (e.toString().contains('Method not found')) {
        _logger.info('Server does not support prompts - returning empty list');
        return [];
      }
      rethrow;
    }

    return [];
  }

  /// Call a tool
  Future<MCPToolCallResult> callTool(MCPToolCallRequest request) async {
    if (!_isInitialized) await initialize();

    switch (transportType) {
      case MCPTransportType.http:
        return _callToolHttp(request);
      case MCPTransportType.stdio:
        return _callToolStdio(request);
    }
  }

  /// Call tool via HTTP
  Future<MCPToolCallResult> _callToolHttp(MCPToolCallRequest request) async {
    throw MCPException('HTTP tool calling not yet implemented');
  }

  /// Call tool via STDIO
  Future<MCPToolCallResult> _callToolStdio(MCPToolCallRequest request) async {
    final rpcRequest = JSONRPCRequest(
      id: _getNextRequestId(),
      method: 'tools/call',
      params: {
        'name': request.name,
        'arguments': request.arguments,
      },
    );

    final response = await _sendStdioRequest(rpcRequest);

    if (response.result != null) {
      return MCPToolCallResult.fromJson(response.result!);
    }

    throw MCPException('Tool call failed: no result returned');
  }

  /// Read a resource
  Future<MCPTextContent> readResource(String uri) async {
    if (!_isInitialized) await initialize();

    switch (transportType) {
      case MCPTransportType.http:
        return _readResourceHttp(uri);
      case MCPTransportType.stdio:
        return _readResourceStdio(uri);
    }
  }

  /// Read resource via HTTP
  Future<MCPTextContent> _readResourceHttp(String uri) async {
    throw MCPException('HTTP resource reading not yet implemented');
  }

  /// Read resource via STDIO
  Future<MCPTextContent> _readResourceStdio(String uri) async {
    final request = JSONRPCRequest(
      id: _getNextRequestId(),
      method: 'resources/read',
      params: {'uri': uri},
    );

    final response = await _sendStdioRequest(request);

    if (response.result != null && response.result!['contents'] != null) {
      final contents = response.result!['contents'] as List<dynamic>;
      if (contents.isNotEmpty) {
        return MCPTextContent.fromJson(contents.first as Map<String, dynamic>);
      }
    }

    throw MCPException('Resource read failed: no content returned');
  }

  /// Get a prompt
  Future<List<MCPTextContent>> getPrompt(String name,
      {Map<String, dynamic>? arguments}) async {
    if (!_isInitialized) await initialize();

    switch (transportType) {
      case MCPTransportType.http:
        return _getPromptHttp(name, arguments: arguments);
      case MCPTransportType.stdio:
        return _getPromptStdio(name, arguments: arguments);
    }
  }

  /// Get prompt via HTTP
  Future<List<MCPTextContent>> _getPromptHttp(String name,
      {Map<String, dynamic>? arguments}) async {
    throw MCPException('HTTP prompt getting not yet implemented');
  }

  /// Get prompt via STDIO
  Future<List<MCPTextContent>> _getPromptStdio(String name,
      {Map<String, dynamic>? arguments}) async {
    final request = JSONRPCRequest(
      id: _getNextRequestId(),
      method: 'prompts/get',
      params: {
        'name': name,
        if (arguments != null) 'arguments': arguments,
      },
    );

    final response = await _sendStdioRequest(request);

    if (response.result != null && response.result!['messages'] != null) {
      final messages = response.result!['messages'] as List<dynamic>;
      return messages
          .map((msg) => MCPTextContent.fromJson(msg as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Cleanup resources
  Future<void> _cleanup() async {
    _pendingRequests.clear();

    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();

    if (_process != null) {
      _process!.kill();
      await _process!.exitCode;
      _process = null;
    }
  }

  /// Close the client
  Future<void> close() async {
    _logger.info('Closing MCP client');

    switch (transportType) {
      case MCPTransportType.http:
        _httpClient.close();
        break;
      case MCPTransportType.stdio:
        await _cleanup();
        break;
    }

    _isInitialized = false;
    _logger.info('MCP client closed');
  }
}

/// MCP Exception for error handling
class MCPException implements Exception {
  final String message;
  MCPException(this.message);

  @override
  String toString() => 'MCPException: $message';
}
