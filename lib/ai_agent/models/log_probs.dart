import 'package:vibe_coder/ai_agent/helpers.dart';

/// Represents log probabilities in the FIM completion response.
class LogProbs {
  /// The text offset of each token in the completion.
  final List<int> textOffset;

  /// The log probability of each token in the completion.
  final List<double> tokenLogprobs;

  /// The tokens in the completion.
  final List<String> tokens;

  /// The top log probabilities for each token position.
  final List<Map<String, double>> topLogprobs;

  LogProbs({
    required this.textOffset,
    required this.tokenLogprobs,
    required this.tokens,
    required this.topLogprobs,
  });

  factory LogProbs.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawTopLogprobs = json['top_logprobs'] as List;
    final List<Map<String, double>> topLogprobsMaps = rawTopLogprobs.map((e) {
      final Map<String, dynamic> typedMap = safeCastToStringDynamicMap(e);
      return typedMap.map((k, v) => MapEntry(k, v as double));
    }).toList();

    return LogProbs(
      textOffset: List<int>.from(json['text_offset'] as List),
      tokenLogprobs: List<double>.from(json['token_logprobs'] as List),
      tokens: List<String>.from(json['tokens'] as List),
      topLogprobs: topLogprobsMaps,
    );
  }
}
