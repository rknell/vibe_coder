import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:vibe_coder/ai_agent/models/authentication_exception.dart';
import 'package:vibe_coder/ai_agent/models/chat_completion_choice.dart';
import 'package:vibe_coder/ai_agent/models/chat_completion_request.dart';
import 'package:vibe_coder/ai_agent/models/chat_completion_response.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/deepseek_api_exception.dart';
import 'package:vibe_coder/ai_agent/models/fim_completion_request.dart';
import 'package:vibe_coder/ai_agent/models/invalid_parameters_exception.dart';
import 'package:vibe_coder/ai_agent/models/model.dart';
import 'package:vibe_coder/ai_agent/models/rate_limit_exception.dart';
import 'package:vibe_coder/ai_agent/models/server_overloaded_exception.dart';
import 'package:vibe_coder/ai_agent/models/streaming_fim_completion_response.dart';
import 'package:vibe_coder/ai_agent/models/token_usage.dart';
import 'package:vibe_coder/ai_agent/models/user_balance_response.dart';

import 'package:vibe_coder/services/debug_logger.dart';

/// A client for interacting with the DeepSeek API.
/// This is a stateless client that handles communication with the DeepSeek API.
class DeepSeekApiClient {
  /// The base URL for the DeepSeek API
  static const String _baseUrl = 'https://api.deepseek.com/v1';

  /// The beta base URL for the DeepSeek API
  static const String _betaBaseUrl = 'https://api.deepseek.com/beta';

  /// The HTTP client used for making requests
  final http.Client _client;

  /// The API key for authentication
  final String _apiKey;

  /// The logger instance
  final Logger _logger;

  /// Request timeout duration
  final Duration _timeout;

  /// Whether the client has been disposed
  bool _isDisposed = false;

  /// 🛡️ DEBUG INTELLIGENCE: Comprehensive API communication logging
  final DebugLogger _debugLogger = DebugLogger();

  /// Creates a new instance of [DeepSeekApiClient].
  ///
  /// SECURITY: API key loaded from .env file via flutter_dotenv for proper secret management
  /// ARCHITECTURAL: Dotenv first, then system environment, then override for testing
  DeepSeekApiClient({
    String? apiKey,
    http.Client? client,
    Duration? timeout,
    String loggerName = 'DeepSeekApiClient',
    Logger? logger,
  })  : _apiKey = apiKey ?? _loadApiKey(),
        _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 30),
        _logger = logger ?? Logger(loggerName) {
    // Validate API key is provided
    if (_apiKey.isEmpty) {
      _logger.severe(
          'DeepSeek API key not provided. Add DEEPSEEK_API_KEY to your .env file.');
      throw Exception(
          'DeepSeek API key is required. Add DEEPSEEK_API_KEY to your .env file.');
    }

    _logger.info('DeepSeek API client initialized');
  }

  /// Load API key from dotenv, fallback to system environment
  ///
  /// SECURITY: Multi-layered key loading with secure fallback
  /// PERF: O(1) - direct key access from loaded environment
  static String _loadApiKey() {
    try {
      // Try dotenv first (from .env file)
      final dotenvKey = dotenv.env['DEEPSEEK_API_KEY'];
      if (dotenvKey != null && dotenvKey.isNotEmpty) {
        return dotenvKey;
      }
    } catch (e) {
      // dotenv not initialized or key not found, continue to fallback
    }

    // Fallback to system environment variable
    return const String.fromEnvironment('DEEPSEEK_API_KEY', defaultValue: '');
  }

  /// Makes an HTTP request with proper error handling and logging
  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, String>? additionalHeaders,
    String? body,
    bool useBeta = false,
  }) async {
    if (_isDisposed) {
      throw StateError('Client has been disposed');
    }

    final baseUrl = useBeta ? _betaBaseUrl : _baseUrl;
    final url = Uri.parse('$baseUrl$endpoint');

    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    _logger
        .fine('Making $method request to ${url.path} [Request ID: $requestId]');
    if (body != null) {
      _logger.fine('Request body: $body');
    }

    // Default headers for all requests
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Merge any additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    try {
      final request = http.Request(method, url)
        ..headers.addAll(headers)
        ..body = body ?? '';

      final response = await _client.send(request).timeout(_timeout);
      final responseBodyBytes = await response.stream.toBytes();
      String responseBody;
      try {
        // Explicitly decode using UTF-8, allowing malformed sequences
        responseBody = utf8.decode(responseBodyBytes, allowMalformed: true);
      } catch (e) {
        _logger.severe(
            'Failed to decode response body as UTF-8 [Request ID: $requestId]. Error: $e');
        // Attempt to decode as Latin-1 as a fallback or handle error differently
        try {
          responseBody = latin1.decode(responseBodyBytes);
          _logger.warning(
              'Decoded response body as Latin-1 after UTF-8 failure [Request ID: $requestId]');
        } catch (fallbackError) {
          _logger.severe(
              'Failed to decode response body with UTF-8 or Latin-1 [Request ID: $requestId]. Error: $fallbackError');
          throw DeepSeekApiException(
            message:
                'Failed to decode API response body. Original UTF-8 Error: $e, Fallback Error: $fallbackError',
            requestId: requestId,
            statusCode:
                response.statusCode, // Use original status code if available
            errorType: 'decoding_error',
            requestData: null,
          );
        }
      }

      // Check for API errors based on status code
      if (response.statusCode >= 400) {
        Map<String, dynamic> errorData;
        String errorMessage;

        try {
          errorData = jsonDecode(responseBody) as Map<String, dynamic>;
          errorMessage = errorData['error']?['message'] as String? ??
              'Unknown error occurred';
        } catch (e) {
          // If JSON parsing fails, use a generic error message
          errorData = {'error': 'Failed to parse error response'};
          errorMessage = 'Error code ${response.statusCode}: ${e.toString()}';
        }

        DeepSeekApiException exception;
        switch (response.statusCode) {
          case 401:
            exception = AuthenticationException(
              message: errorMessage,
              statusCode: response.statusCode,
              requestId: requestId,
              requestData: null, // Don't include sensitive data
            );
            break;
          case 429:
            final retryAfter = response.headers['retry-after'];
            exception = RateLimitException(
              message: errorMessage,
              statusCode: response.statusCode,
              requestId: requestId,
              requestData: null,
              retryAfter: retryAfter != null
                  ? Duration(seconds: int.parse(retryAfter))
                  : null,
            );
            break;
          case 503:
            exception = ServerOverloadedException(
              message: errorMessage,
              statusCode: response.statusCode,
              requestId: requestId,
              requestData: null,
            );
            break;
          case 422:
            exception = InvalidParametersException(
              message: errorMessage,
              statusCode: response.statusCode,
              requestId: requestId,
              requestData: null,
            );
            break;
          default:
            exception = DeepSeekApiException(
              message: errorMessage,
              statusCode: response.statusCode,
              requestId: requestId,
              errorType: 'unknown_error',
              requestData: null,
            );
        }
        throw exception;
      }

      // Return a new Response object using the decoded body
      return http.Response(responseBody, response.statusCode,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
          request: response.request);
    } catch (e) {
      if (e is DeepSeekApiException) rethrow;
      _logger.severe(
        'Error making request to ${url.path} [Request ID: $requestId]',
        e,
      );

      throw DeepSeekApiException(
        message: 'Request failed: ${e.toString()}',
        requestId: requestId,
        statusCode: 500,
        errorType: 'unknown_error',
        requestData:
            null, // Don't include request data to avoid further parsing issues
      );
    }
  }

  /// Makes a POST request with proper error handling and logging
  Future<http.Response> _postRequest(
    String endpoint, {
    required String body,
    Map<String, String>? additionalHeaders,
    bool useBeta = false,
  }) async {
    return _makeRequest(
      'POST',
      endpoint,
      additionalHeaders: additionalHeaders,
      body: body,
      useBeta: useBeta,
    );
  }

  /// Makes a GET request with proper error handling and logging
  Future<http.Response> _getRequest(
    String endpoint, {
    Map<String, String>? additionalHeaders,
    bool useBeta = false,
  }) async {
    return _makeRequest(
      'GET',
      endpoint,
      additionalHeaders: additionalHeaders,
      useBeta: useBeta,
    );
  }

  /// Sends a chat completion request to the DeepSeek API.
  ///
  /// [request] contains all parameters for the chat completion request.
  /// [useBeta] If true, uses the beta endpoint for features like chat prefix completion.
  /// Returns a [Future] that completes with the API response.
  Future<ChatCompletionResponse> createChatCompletion(
      ChatCompletionRequest request,
      {bool useBeta = false}) async {
    final body = jsonEncode(request.toJson());
    final stopwatch = Stopwatch()..start();
    final requestId = _generateRequestId();
    const endpoint = '/chat/completions';
    final url = useBeta ? '$_betaBaseUrl$endpoint' : '$_baseUrl$endpoint';

    // 🛡️ DEBUG LOGGING: Log API request
    _debugLogger.logApiRequest(
      method: 'POST',
      url: url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        if (useBeta) 'beta': 'true',
      },
      body: jsonDecode(body), // Convert back to Map for structured logging
      requestId: requestId,
    );

    try {
      final response = await _postRequest(
        endpoint,
        body: body,
        useBeta: useBeta,
      );
      stopwatch.stop();

      // 🛡️ DEBUG LOGGING: Log successful API response
      _debugLogger.logApiResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        headers: response.headers,
        responseBody: response.body.length > 1000
            ? '${response.body.substring(0, 1000)}...[truncated]'
            : response.body,
        requestId: requestId,
        duration: stopwatch.elapsed,
      );

      try {
        // Use a manual approach to extract key elements to avoid full JSON parsing issues
        // Especially with the reasoning_content field that contains many escaped characters
        final Map<String, dynamic> rawData =
            jsonDecode(response.body) as Map<String, dynamic>;

        // Extract basic info
        final id = rawData['id'] as String;
        final created = rawData['created'] as int;
        final model = rawData['model'] as String;
        final object = rawData['object'] as String;
        final systemFingerprint = rawData['system_fingerprint'] as String?;

        // Extract usage if available
        TokenUsage? usage;
        if (rawData.containsKey('usage') && rawData['usage'] != null) {
          final usageData = rawData['usage'] as Map<String, dynamic>;
          usage = TokenUsage(
            completionTokens: usageData['completion_tokens'] as int,
            promptTokens: usageData['prompt_tokens'] as int,
            promptCacheHitTokens: usageData['prompt_cache_hit_tokens'] as int,
            promptCacheMissTokens: usageData['prompt_cache_miss_tokens'] as int,
            totalTokens: usageData['total_tokens'] as int,
          );
        }

        // Create choices
        final List<ChatCompletionChoice> choices = [];
        if (rawData.containsKey('choices') && rawData['choices'] is List) {
          final choicesList = rawData['choices'] as List;

          for (final choiceData in choicesList) {
            if (choiceData is Map<String, dynamic>) {
              final index = choiceData['index'] as int;
              final finishReasonStr = choiceData['finish_reason'] as String?;

              FinishReason? finishReason;
              if (finishReasonStr != null) {
                switch (finishReasonStr) {
                  case 'stop':
                    finishReason = FinishReason.stop;
                    break;
                  case 'length':
                    finishReason = FinishReason.length;
                    break;
                  case 'content_filter':
                    finishReason = FinishReason.contentFilter;
                    break;
                  case 'tool_calls':
                    finishReason = FinishReason.toolCalls;
                    break;
                  case 'insufficient_system_resource':
                    finishReason = FinishReason.insufficientSystemResource;
                    break;
                  default:
                    finishReason = FinishReason.stop;
                }
              }

              // Extract message data
              if (choiceData.containsKey('message') &&
                  choiceData['message'] is Map<String, dynamic>) {
                final messageData =
                    choiceData['message'] as Map<String, dynamic>;
                final roleStr = messageData['role'] as String;
                final content = messageData['content'] as String?;
                final name = messageData['name'] as String?;
                final toolCallId = messageData['tool_call_id'] as String?;
                final prefix = messageData['prefix'] as bool?;
                final reasoningContent =
                    messageData['reasoning_content'] as String?;

                // Process tool calls if present
                List<Map<String, dynamic>>? toolCalls;
                if (messageData.containsKey('tool_calls') &&
                    messageData['tool_calls'] is List) {
                  final List<dynamic> rawToolCalls =
                      messageData['tool_calls'] as List;
                  toolCalls = rawToolCalls
                      .map((tc) => _safeCastToStringDynamicMap(tc))
                      .toList();
                }

                // Create message with role enum
                final role = _roleFromString(roleStr);
                final message = ChatMessage(
                  role: role,
                  content: content,
                  name: name,
                  toolCallId: toolCallId,
                  prefix: prefix,
                  reasoningContent: reasoningContent,
                  toolCalls: toolCalls,
                );

                // Add choice to list
                choices.add(ChatCompletionChoice(
                  index: index,
                  message: message,
                  finishReason: finishReason,
                ));
              }
            }
          }
        }

        // Construct and return the complete response
        return ChatCompletionResponse(
          id: id,
          created: created,
          model: model,
          object: object,
          systemFingerprint: systemFingerprint,
          choices: choices,
          usage: usage,
        );
      } catch (e) {
        // Handle JSON parsing errors specifically
        _logger.severe('Error processing API response: $e');

        // 🛡️ DEBUG LOGGING: Log processing error
        _debugLogger.logApiResponse(
          method: 'POST',
          url: url,
          statusCode: response.statusCode,
          headers: response.headers,
          responseBody: response.body,
          requestId: requestId,
          duration: stopwatch.elapsed,
          error: 'Failed to process API response: $e',
        );

        throw DeepSeekApiException(
          message: 'Failed to process API response: $e',
          requestId: requestId,
          statusCode: 500,
          errorType: 'processing_error',
          requestData: null, // Don't include request data
        );
      }
    } catch (e) {
      stopwatch.stop();

      if (e is DeepSeekApiException) {
        // 🛡️ DEBUG LOGGING: Log API exception
        _debugLogger.logApiResponse(
          method: 'POST',
          url: url,
          statusCode: e.statusCode,
          requestId: requestId,
          duration: stopwatch.elapsed,
          error: e.message,
        );
        rethrow;
      } else {
        // Handle other errors
        _logger.severe('Error during chat completion: $e');

        // 🛡️ DEBUG LOGGING: Log general error
        _debugLogger.logApiResponse(
          method: 'POST',
          url: url,
          statusCode: 500,
          requestId: requestId,
          duration: stopwatch.elapsed,
          error: 'Error during chat completion: $e',
        );

        throw DeepSeekApiException(
          message: 'Error during chat completion: $e',
          requestId: requestId,
          statusCode: 500,
          errorType: 'unknown_error',
          requestData: null, // Don't include request data
        );
      }
    }
  }

  /// Sends a FIM (Fill-In-the-Middle) completion request to the DeepSeek API.
  ///
  /// [request] contains all parameters for the FIM completion request.
  /// Returns a [Future] that completes with a [StreamingFimCompletionResponse].
  Future<StreamingFimCompletionResponse> createFimCompletion(
      FimCompletionRequest request) async {
    final body = jsonEncode(request.toJson());

    final response = await _postRequest(
      '/completions',
      body: body,
      useBeta: true,
    );

    // Create a controller for the text stream
    final controller = StreamController<String>();

    // Process the response body as a stream of SSE events
    final events = response.body.split('\n');
    String? id;
    String? model;
    String? systemFingerprint;
    String? finishReason;
    TokenUsage? usage;

    for (final event in events) {
      if (event.startsWith('data: ')) {
        final data = event.substring(6); // Remove 'data: ' prefix

        if (data == '[DONE]') {
          controller.close();
          break;
        }

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;

          // Store metadata from first event
          id ??= json['id'] as String;
          model ??= json['model'] as String;
          systemFingerprint ??= json['system_fingerprint'] as String;

          final choices = json['choices'] as List;
          for (final choice in choices) {
            final text = choice['text'] as String?;
            if (text != null && text.isNotEmpty) {
              controller.add(text);
            }

            // Store completion info from final event
            if (choice['finish_reason'] != null) {
              finishReason = choice['finish_reason'] as String;
              final usageJson = json['usage'] as Map<String, dynamic>?;
              if (usageJson != null) {
                usage = TokenUsage.fromJson(usageJson);
              }
            }
          }
        } catch (e) {
          _logger.warning('Error parsing SSE event: $e');
        }
      }
    }

    final streamingResponse = StreamingFimCompletionResponse(
      textStream: controller.stream,
      id: id!,
      model: model!,
      systemFingerprint: systemFingerprint!,
    );

    // Set the completion info
    streamingResponse.finishReason = finishReason;
    streamingResponse.usage = usage;

    return streamingResponse;
  }

  /// Lists all available models from the DeepSeek API.
  ///
  /// Returns a [Future] that completes with a list of available models.
  Future<ModelsResponse> listModels() async {
    final response = await _getRequest('/models');

    return ModelsResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Gets the current user balance information from the DeepSeek API.
  ///
  /// Returns a [Future] that completes with the user's balance information.
  Future<UserBalanceResponse> getUserBalance() async {
    final response = await _getRequest('/user/balance');

    return UserBalanceResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Closes the HTTP client and cleans up resources.
  Future<void> dispose() async {
    if (_isDisposed) return;

    _logger.info('Disposing DeepSeekApiClient');
    _isDisposed = true;

    try {
      _client.close();
      _logger.info('DeepSeekApiClient disposed successfully');
    } catch (e) {
      _logger.severe('Error disposing DeepSeekApiClient', e);
      rethrow;
    }
  }

  /// Generate unique request ID for tracking
  ///
  /// PERF: O(1) - timestamp-based ID generation
  String _generateRequestId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}_${_getRandomString(6)}';
  }

  /// Generate random string for request ID
  ///
  /// PERF: O(n) where n = length - acceptable for ID generation
  String _getRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(Iterable.generate(
        length,
        (index) => chars
            .codeUnitAt((DateTime.now().microsecond + index) % chars.length)));
  }
}

/// Helper method to convert a role string to a [MessageRole] enum value.
MessageRole _roleFromString(String role) {
  return MessageRole.values.firstWhere(
    (r) => r.toString().split('.').last == role,
    orElse: () => throw StateError('Unknown role: $role'),
  );
}

/// Safely converts a dynamic object to a `Map<String, dynamic>`
/// This is used throughout the codebase to handle API responses
Map<String, dynamic> _safeCastToStringDynamicMap(dynamic obj) {
  if (obj is Map<String, dynamic>) {
    return obj;
  } else if (obj is Map) {
    return obj.map((key, value) => MapEntry(key.toString(), value));
  }
  throw ArgumentError('Cannot convert $obj to Map<String, dynamic>');
}

/// Represents a tool call in the chat completion response.
class ToolCall {
  /// The ID of the tool call.
  final String id;

  /// The type of the tool call (e.g., 'function').
  final String type;

  /// The function information if the tool call is a function.
  final Map<String, dynamic> function;

  ToolCall({required this.id, required this.type, required this.function});

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      id: json['id'] as String,
      type: json['type'] as String,
      function: _safeCastToStringDynamicMap(json['function']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'function': function,
      };
}

/// Extension to safely convert a Map to a `Map<String, dynamic>`
extension MapCastingExtension on Map<dynamic, dynamic> {
  /// Convert this map to a `Map<String, dynamic>` safely
  Map<String, dynamic> toStringDynamicMap() {
    return map((key, value) => MapEntry(key.toString(), value));
  }
}
