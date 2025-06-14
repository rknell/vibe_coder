import 'package:vibe_coder/ai_agent/models/deepseek_api_exception.dart';

/// Exception thrown when the server is overloaded
class ServerOverloadedException extends DeepSeekApiException {
  ServerOverloadedException({
    required super.message,
    int? statusCode,
    required super.requestId,
    super.timestamp,
    super.requestData,
  }) : super(
          statusCode: statusCode ?? 503,
          errorType: 'server_overloaded',
        );
}
