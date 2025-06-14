import 'package:vibe_coder/ai_agent/models/fim_completion_choice.dart';
import 'package:vibe_coder/ai_agent/models/token_usage.dart';

/// Represents the FIM completion response.
class FimCompletionResponse {
  /// A unique identifier for the completion.
  final String id;

  /// The list of completion choices the model generated for the input prompt.
  final List<FimCompletionChoice> choices;

  /// The Unix timestamp (in seconds) of when the completion was created.
  final int created;

  /// The model used for completion.
  final String model;

  /// This fingerprint represents the backend configuration that the model runs with.
  final String? systemFingerprint;

  /// The object type, which is always "text_completion".
  final String object;

  /// Usage statistics for the completion request.
  final TokenUsage usage;

  FimCompletionResponse({
    required this.id,
    required this.choices,
    required this.created,
    required this.model,
    this.systemFingerprint,
    required this.object,
    required this.usage,
  });

  factory FimCompletionResponse.fromJson(Map<String, dynamic> json) {
    return FimCompletionResponse(
      id: json['id'] as String,
      choices: (json['choices'] as List)
          .map((c) => FimCompletionChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
      created: json['created'] as int,
      model: json['model'] as String,
      systemFingerprint: json['system_fingerprint'] as String?,
      object: json['object'] as String,
      usage: TokenUsage.fromJson(json['usage'] as Map<String, dynamic>),
    );
  }
}
