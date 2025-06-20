import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../models/mcp_models.dart';
import 'package:vibe_coder/services/debug_logger.dart';
import 'package:vibe_coder/services/mcp_process_manager.dart';

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
  SharedMCPProcess? _sharedProcess;
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

  /// Initialize STDIO transport using shared process manager
  ///
  /// PERF: O(1) - reuses existing processes, O(n) for new process creation
  /// ARCHITECTURAL: Uses MCPProcessManager to prevent multiple server instances
  Future<void> _initializeStdio() async {
    if (command == null) {
      throw MCPException('Command is required for STDIO transport');
    }

    try {
      _logger.info(
          '🔍 STDIO INIT: Requesting shared process for: $command ${args?.join(' ')}');
      _logger.info('🔧 STDIO ENV: ${env?.keys.join(', ') ?? 'No custom env'}');

      // Use process manager to get or create shared process
      final processManager = MCPProcessManager.instance;
      final serverName =
          '${command}_${args?.join('_') ?? ''}'; // Create unique server name

      _sharedProcess = await processManager.getOrCreateProcess(
        serverName: serverName,
        command: command!,
        args: args,
        env: env,
      );

      // Get reference to the underlying process
      _process = _sharedProcess!.process;

      _logger
          .info('✅ STDIO SHARED: Using shared process (PID: ${_process!.pid})');
      _logger.info('🔗 PROCESS KEY: ${_sharedProcess!.processKey}');
      _logger.info('🏢 SERVER NAME: ${_sharedProcess!.serverName}');

      // Set up stdout listener for responses
      _stdoutSubscription = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.trim().isNotEmpty) {
            _logger
                .info('📥 STDIO STDOUT [${_sharedProcess!.serverName}]: $line');
            _handleStdioResponse(line);
          }
        },
        onError: (error) {
          _logger.severe(
              '💥 STDIO STDOUT ERROR [${_sharedProcess!.serverName}]: $error');
        },
      );

      // Set up stderr listener for debugging
      _stderrSubscription = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.trim().isNotEmpty) {
            _logger.warning(
                '⚠️ STDIO STDERR [${_sharedProcess!.serverName}]: $line');
          }
        },
        onError: (error) {
          _logger.severe(
              '💥 STDIO STDERR ERROR [${_sharedProcess!.serverName}]: $error');
        },
      );

      // Send initialization request
      _logger.info(
          '🤝 STDIO HANDSHAKE: Sending initialization to shared process...');
      await _sendStdioInitialization();

      _logger.info(
          '🎯 STDIO SUCCESS: Shared process initialized and handshake completed');
    } catch (e) {
      _logger
          .severe('💀 STDIO FAILURE: Failed to initialize shared process: $e');
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
    final stopwatch = Stopwatch()..start();

    // 🛡️ DEBUG LOGGING: Log low-level MCP tool call
    DebugLogger().logSystemEvent(
      'MCP STDIO TOOL CALL',
      'Calling tool ${request.name} via STDIO protocol',
      details: {
        'toolName': request.name,
        'arguments': request.arguments,
        'transportType': 'STDIO',
        'serverInfo': 'MCP Client STDIO',
      },
    );

    final rpcRequest = JSONRPCRequest(
      id: _getNextRequestId(),
      method: 'tools/call',
      params: {
        'name': request.name,
        'arguments': request.arguments,
      },
    );

    try {
      final response = await _sendStdioRequest(rpcRequest);
      stopwatch.stop();

      if (response.result != null) {
        final result = MCPToolCallResult.fromJson(response.result!);

        // 🛡️ DEBUG LOGGING: Log successful low-level MCP response
        DebugLogger().logSystemEvent(
          'MCP STDIO TOOL SUCCESS',
          'Tool ${request.name} executed successfully via STDIO',
          details: {
            'toolName': request.name,
            'executionTimeMs': stopwatch.elapsedMilliseconds,
            'resultType':
                result.content.isNotEmpty ? result.content.first.type : 'empty',
            'resultLength': result.content.isNotEmpty
                ? result.content.first.text.length
                : 0,
            'transportType': 'STDIO',
          },
        );

        return result;
      }

      // Handle case where no result is returned
      stopwatch.stop();

      // 🛡️ DEBUG LOGGING: Log MCP no-result error
      DebugLogger().logSystemEvent(
        'MCP STDIO TOOL ERROR',
        'Tool call failed: no result returned',
        details: {
          'toolName': request.name,
          'executionTimeMs': stopwatch.elapsedMilliseconds,
          'error': 'No result returned from MCP server',
          'transportType': 'STDIO',
        },
      );

      throw MCPException('Tool call failed: no result returned');
    } catch (e) {
      stopwatch.stop();

      // 🛡️ DEBUG LOGGING: Log MCP exception
      DebugLogger().logSystemEvent(
        'MCP STDIO TOOL EXCEPTION',
        'Tool call threw exception: ${e.toString()}',
        details: {
          'toolName': request.name,
          'executionTimeMs': stopwatch.elapsedMilliseconds,
          'error': e.toString(),
          'transportType': 'STDIO',
          'arguments': request.arguments,
        },
      );

      rethrow;
    }
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

  /// Cleanup resources with shared process management
  ///
  /// PERF: O(1) - cancels subscriptions and releases process reference
  /// ARCHITECTURAL: Disposes shared process handle, process terminates when no more references
  Future<void> _cleanup() async {
    _pendingRequests.clear();

    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();

    // Release shared process reference instead of directly killing
    if (_sharedProcess != null) {
      _logger.info('🔗 CLEANUP: Releasing shared process reference');
      _sharedProcess!.dispose();
      _sharedProcess = null;
    }

    // Clear process reference (don't kill directly - managed by process manager)
    _process = null;
  }

  /// Close the client with shared process management
  ///
  /// PERF: O(1) - releases resources and shared process references
  /// ARCHITECTURAL: Graceful shutdown with process sharing support
  Future<void> close() async {
    _logger.info('🚪 CLOSING: MCP client shutdown initiated');

    switch (transportType) {
      case MCPTransportType.http:
        _httpClient.close();
        _logger.info('🌐 HTTP CLIENT: Closed HTTP client');
        break;
      case MCPTransportType.stdio:
        await _cleanup();
        _logger.info('📟 STDIO CLIENT: Released shared process resources');
        break;
    }

    _isInitialized = false;
    _logger.info('✅ CLIENT CLOSED: MCP client shutdown complete');
  }
}

/// MCP Exception for error handling
class MCPException implements Exception {
  final String message;
  MCPException(this.message);

  @override
  String toString() => 'MCPException: $message';
}
