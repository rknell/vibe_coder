import 'package:vibe_coder/ai_agent/models/deepseek_api_exception.dart';

/// Exception thrown when rate limit is exceeded
class RateLimitException extends DeepSeekApiException {
  final Duration? retryAfter;

  RateLimitException({
    required super.message,
    int? statusCode,
    required super.requestId,
    super.timestamp,
    super.requestData,
    this.retryAfter,
  }) : super(
          statusCode: statusCode ?? 429,
          errorType: 'rate_limit_exceeded',
        );

  @override
  String toString() {
    final base = super.toString();
    if (retryAfter != null) {
      return '$base\nRetry after: ${retryAfter!.inSeconds} seconds';
    }
    return base;
  }
}
