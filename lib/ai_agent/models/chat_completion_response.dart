import 'package:vibe_coder/ai_agent/models/chat_completion_choice.dart';
import 'package:vibe_coder/ai_agent/models/token_usage.dart';

/// Represents the chat completion response.
class ChatCompletionResponse {
  /// A unique identifier for the chat completion.
  final String id;

  /// A list of chat completion choices.
  final List<ChatCompletionChoice> choices;

  /// The Unix timestamp (in seconds) of when the chat completion was created.
  final int created;

  /// The model used for the chat completion.
  final String model;

  /// This fingerprint represents the backend configuration that the model runs with.
  final String? systemFingerprint;

  /// The object type, which is always chat.completion.
  final String object;

  /// Usage statistics for the completion request.
  final TokenUsage? usage;

  ChatCompletionResponse({
    required this.id,
    required this.choices,
    required this.created,
    required this.model,
    this.systemFingerprint,
    required this.object,
    this.usage,
  });

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) {
    return ChatCompletionResponse(
      id: json['id'] as String,
      object: json['object'] as String,
      created: json['created'] as int,
      model: json['model'] as String,
      choices: (json['choices'] as List)
          .map((choice) =>
              ChatCompletionChoice.fromJson(choice as Map<String, dynamic>))
          .toList(),
      usage: json['usage'] != null
          ? TokenUsage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
      systemFingerprint: json['system_fingerprint'] as String?,
    );
  }
}
