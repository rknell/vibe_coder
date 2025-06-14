import 'package:vibe_coder/ai_agent/models/deepseek_api_exception.dart';

/// Exception thrown when authentication fails
class AuthenticationException extends DeepSeekApiException {
  AuthenticationException({
    required super.message,
    int? statusCode,
    required super.requestId,
    super.timestamp,
    super.requestData,
  }) : super(
          statusCode: statusCode ?? 401,
          errorType: 'authentication_error',
        );
}
