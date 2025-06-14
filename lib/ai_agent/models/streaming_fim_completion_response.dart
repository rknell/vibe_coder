import 'package:vibe_coder/ai_agent/models/token_usage.dart';

/// Represents a streaming FIM completion response
class StreamingFimCompletionResponse {
  /// Stream of generated text chunks
  final Stream<String> textStream;

  /// The completion ID
  final String id;

  /// The model used
  final String model;

  /// The system fingerprint
  final String systemFingerprint;

  /// The completion reason (set when stream is done)
  String? finishReason;

  /// Token usage information (set when stream is done)
  TokenUsage? usage;

  StreamingFimCompletionResponse({
    required this.textStream,
    required this.id,
    required this.model,
    required this.systemFingerprint,
  });
}
