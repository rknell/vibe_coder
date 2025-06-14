import 'package:vibe_coder/ai_agent/models/deepseek_api_exception.dart';

/// Exception thrown when there are invalid parameters
class InvalidParametersException extends DeepSeekApiException {
  InvalidParametersException({
    required super.message,
    int? statusCode,
    required super.requestId,
    super.timestamp,
    super.requestData,
  }) : super(
          statusCode: statusCode ?? 422,
          errorType: 'invalid_parameters',
        );
}
