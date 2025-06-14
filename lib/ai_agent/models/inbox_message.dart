import 'package:vibe_coder/ai_agent/agent.dart';

/// Represents a message in an agent's inbox
class InboxMessage {
  /// The content of the message
  final String content;

  /// The agent who sent this message
  final Agent sender;

  /// Optional response to be sent back to the sender when processing is complete
  String? response;

  /// Timestamp when this message was created
  final DateTime timestamp;

  /// Creates a new inbox message
  InboxMessage({
    required this.content,
    required this.sender,
    this.response,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => content;
}
