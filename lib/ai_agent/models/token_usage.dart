/// Represents token usage statistics for a completion request.
class TokenUsage {
  /// Number of tokens in the generated completion.
  final int completionTokens;

  /// Number of tokens in the prompt. It equals prompt_cache_hit_tokens + prompt_cache_miss_tokens.
  final int promptTokens;

  /// Number of tokens in the prompt that hits the context cache.
  final int promptCacheHitTokens;

  /// Number of tokens in the prompt that misses the context cache.
  final int promptCacheMissTokens;

  /// Total number of tokens used in the request (prompt + completion).
  final int totalTokens;

  /// Breakdown of tokens used in a completion.
  final Map<String, int>? completionTokensDetails;

  TokenUsage({
    required this.completionTokens,
    required this.promptTokens,
    required this.promptCacheHitTokens,
    required this.promptCacheMissTokens,
    required this.totalTokens,
    this.completionTokensDetails,
  });

  factory TokenUsage.fromJson(Map<String, dynamic> json) {
    return TokenUsage(
      completionTokens: json['completion_tokens'] as int,
      promptTokens: json['prompt_tokens'] as int,
      promptCacheHitTokens: json['prompt_cache_hit_tokens'] as int,
      promptCacheMissTokens: json['prompt_cache_miss_tokens'] as int,
      totalTokens: json['total_tokens'] as int,
      completionTokensDetails: json['completion_tokens_details'] != null
          ? Map<String, int>.from(json['completion_tokens_details'] as Map)
          : null,
    );
  }
}
