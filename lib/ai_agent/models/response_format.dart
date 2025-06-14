import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';

/// Represents the response format configuration.
///
/// Setting to { "type": "json_object" } enables JSON Output, which guarantees the message the model generates is valid JSON.
///
/// Important: When using JSON Output, you must also instruct the model to produce JSON yourself via a system or user message.
/// Without this, the model may generate an unending stream of whitespace until the generation reaches the token limit,
/// resulting in a long-running and seemingly "stuck" request. Also note that the message content may be partially cut off
/// if finish_reason="length", which indicates the generation exceeded max_tokens or the conversation exceeded the max context length.
class ResponseFormat {
  /// The type of response format.
  final ResponseFormatType type;

  ResponseFormat({required this.type});

  Map<String, String> toJson() => {
        'type': type == ResponseFormatType.jsonObject
            ? 'json_object'
            : type.toString().split('.').last,
      };

  factory ResponseFormat.fromJson(Map<String, dynamic> json) {
    return ResponseFormat(
      type: ResponseFormatType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'] as String,
      ),
    );
  }
}
