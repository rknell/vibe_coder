import 'package:flutter/material.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';

/// MessageContent - Main Message Text Display
///
/// ## MISSION ACCOMPLISHED
/// Eliminates _buildContent functional widget builder by creating reusable content component.
/// Provides consistent message text rendering with proper styling integration.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | Stateless Widget | Reusable, efficient | Slight overhead | CHOSEN - architectural excellence |
/// | Raw Text Widget | Minimal | No style integration | Rejected - lacks theming |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - direct text widget rendering
/// - Space Complexity: O(1) - single text widget
/// - Rebuild Frequency: Only when message content changes
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Elimination**
///    - 🔍 Symptom: `_buildContent()` method in MessageBubble
///    - 🎯 Root Cause: Content rendering logic embedded in parent widget
///    - 💥 Kill Shot: Extracted to dedicated StatelessWidget with style integration
class MessageContent extends StatelessWidget {
  /// Creates a message content display with styling
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor
  const MessageContent({
    super.key,
    required this.message,
    required this.textStyle,
  });

  /// Chat message containing the content text
  final ChatMessage message;

  /// Text style to apply to the content
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    // Only render if message has content
    if (message.content == null || message.content!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      message.content!,
      style: textStyle,
    );
  }
}
