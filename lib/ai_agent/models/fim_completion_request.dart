import 'package:vibe_coder/ai_agent/models/stream_options.dart';

/// Represents the FIM (Fill-In-the-Middle) completion request parameters.
///
/// The FIM Completion API allows you to generate text completions with a prompt and optional suffix.
/// User must set base_url="https://api.deepseek.com/beta" to use this feature.
class FimCompletionRequest {
  /// ID of the model to use.
  /// Possible values: deepseek-chat
  final String model;

  /// The prompt to generate completions for.
  /// Default value: "Once upon a time, "
  final String prompt;

  /// Echo back the prompt in addition to the completion
  final bool? echo;

  /// Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far,
  /// decreasing the model's likelihood to repeat the same line verbatim.
  /// Default value: 0
  final double? frequencyPenalty;

  /// Include the log probabilities on the logprobs most likely output tokens, as well the chosen tokens.
  /// For example, if logprobs is 20, the API will return a list of the 20 most likely tokens.
  /// The API will always return the logprob of the sampled token, so there may be up to logprobs+1 elements in the response.
  /// The maximum value for logprobs is 20.
  final int? logprobs;

  /// The maximum number of tokens that can be generated in the completion.
  final int? maxTokens;

  /// Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far,
  /// increasing the model's likelihood to talk about new topics.
  /// Default value: 0
  final double? presencePenalty;

  /// Up to 16 sequences where the API will stop generating further tokens.
  /// The returned text will not contain the stop sequence.
  final List<String>? stop;

  /// Whether to stream back partial progress. If set, tokens will be sent as data-only server-sent events (SSE)
  /// as they become available, with the stream terminated by a data: [DONE] message.
  final bool stream;

  /// Options for streaming response. Only set this when you set stream: true.
  final StreamOptions? streamOptions;

  /// The suffix that comes after a completion of inserted text.
  final String? suffix;

  /// What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random,
  /// while lower values like 0.2 will make it more focused and deterministic.
  /// Default value: 1
  /// We generally recommend altering this or top_p but not both.
  final double? temperature;

  /// An alternative to sampling with temperature, called nucleus sampling, where the model considers the results
  /// of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered.
  /// Default value: 1
  /// We generally recommend altering this or temperature but not both.
  final double? topP;

  FimCompletionRequest({
    required this.model,
    required this.prompt,
    this.echo,
    this.frequencyPenalty,
    this.logprobs,
    this.maxTokens,
    this.presencePenalty,
    this.stop,
    this.stream = false,
    this.streamOptions,
    this.suffix,
    this.temperature,
    this.topP,
  }) {
    // Validate model
    if (model != 'deepseek-chat') {
      throw ArgumentError('Model must be "deepseek-chat"');
    }

    // Validate frequency_penalty
    if (frequencyPenalty != null &&
        (frequencyPenalty! < -2 || frequencyPenalty! > 2)) {
      throw ArgumentError('frequency_penalty must be between -2 and 2');
    }

    // Validate logprobs
    if (logprobs != null && (logprobs! < 0 || logprobs! > 20)) {
      throw ArgumentError('logprobs must be between 0 and 20');
    }

    // Validate presence_penalty
    if (presencePenalty != null &&
        (presencePenalty! < -2 || presencePenalty! > 2)) {
      throw ArgumentError('presence_penalty must be between -2 and 2');
    }

    // Validate stop
    if (stop != null && stop!.length > 16) {
      throw ArgumentError('stop must contain at most 16 sequences');
    }

    // Validate temperature
    if (temperature != null && (temperature! < 0 || temperature! > 2)) {
      throw ArgumentError('temperature must be between 0 and 2');
    }

    // Validate top_p
    if (topP != null && (topP! < 0 || topP! > 1)) {
      throw ArgumentError('top_p must be between 0 and 1');
    }

    // Validate stream_options
    if (streamOptions != null && !stream) {
      throw ArgumentError('stream_options can only be set when stream is true');
    }
  }

  Map<String, dynamic> toJson() => {
        'model': model,
        'prompt': prompt,
        if (echo != null) 'echo': echo,
        if (frequencyPenalty != null) 'frequency_penalty': frequencyPenalty,
        if (logprobs != null) 'logprobs': logprobs,
        if (maxTokens != null) 'max_tokens': maxTokens,
        if (presencePenalty != null) 'presence_penalty': presencePenalty,
        if (stop != null) 'stop': stop,
        'stream': stream,
        if (streamOptions != null) 'stream_options': streamOptions!.toJson(),
        if (suffix != null) 'suffix': suffix,
        if (temperature != null) 'temperature': temperature,
        if (topP != null) 'top_p': topP,
      };
}
