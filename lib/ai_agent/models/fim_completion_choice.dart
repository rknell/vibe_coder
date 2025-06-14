import 'package:vibe_coder/ai_agent/models/log_probs.dart';

/// Represents a choice in the FIM completion response.
class FimCompletionChoice {
  /// The generated text.
  final String text;

  /// The index of the choice in the list of choices.
  final int index;

  /// The reason the model stopped generating tokens.
  /// Possible values:
  /// - stop: The model hit a natural stop point or a provided stop sequence
  /// - length: The maximum number of tokens specified in the request was reached
  /// - content_filter: Content was omitted due to a flag from our content filters
  /// - insufficient_system_resource: The request is interrupted due to insufficient resource of the inference system
  final String finishReason;

  /// Log probability information for the choice.
  final LogProbs? logprobs;

  FimCompletionChoice({
    required this.text,
    required this.index,
    required this.finishReason,
    this.logprobs,
  });

  factory FimCompletionChoice.fromJson(Map<String, dynamic> json) {
    return FimCompletionChoice(
      text: json['text'] as String,
      index: json['index'] as int,
      finishReason: json['finish_reason'] as String,
      logprobs: json['logprobs'] != null
          ? LogProbs.fromJson(json['logprobs'] as Map<String, dynamic>)
          : null,
    );
  }
}
