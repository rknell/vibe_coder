import 'dart:convert';

/// Base class for all DeepSeek API exceptions
class DeepSeekApiException implements Exception {
  /// The error message
  final String message;

  /// The request ID associated with the error
  final String requestId;

  /// The HTTP status code
  final int statusCode;

  /// Type of error returned by the API
  final String errorType;

  /// The request data that caused the error
  final Map<String, dynamic>? requestData;

  /// The timestamp of when the error occurred
  final DateTime timestamp;

  DeepSeekApiException({
    required this.message,
    required this.requestId,
    required this.statusCode,
    required this.errorType,
    this.requestData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    String requestDataStr = "null";
    if (requestData != null) {
      try {
        requestDataStr = jsonEncode(requestData);
      } catch (e) {
        requestDataStr = "Error encoding request data: $e";
      }
    }

    return 'DeepSeekApiException: $message [Request ID: $requestId] [Timestamp: $timestamp] [Type: $errorType]'
        '\n   Request Data: $requestDataStr';
  }
}
