import 'package:flutter/material.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';

/// MessageHeader - Message Participant Name Display
///
/// ## MISSION ACCOMPLISHED
/// Eliminates _buildHeader functional widget builder by creating reusable header component.
/// Provides consistent message participant name styling across all message types.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | Stateless Widget | Reusable, lightweight | Slight overhead | CHOSEN - architectural excellence |
/// | Inline Text | Minimal | No reusability | Rejected - violates DRY principle |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - simple text rendering
/// - Space Complexity: O(1) - minimal widget tree
/// - Rebuild Frequency: Only when message name changes
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Elimination**
///    - 🔍 Symptom: `_buildHeader()` method in MessageBubble
///    - 🎯 Root Cause: Header logic embedded in parent widget
///    - 💥 Kill Shot: Extracted to dedicated StatelessWidget
class MessageHeader extends StatelessWidget {
  /// Creates a message header with participant name
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor
  const MessageHeader({
    super.key,
    required this.message,
  });

  /// Chat message containing participant name
  final ChatMessage message;

  /// Get role-specific color for header text
  ///
  /// PERF: O(1) - direct enum-based color mapping
  Color _getRoleColor(BuildContext context) {
    switch (message.role) {
      case MessageRole.system:
        return Theme.of(context).colorScheme.outline;
      case MessageRole.user:
        return Theme.of(context).colorScheme.primary;
      case MessageRole.assistant:
        return Theme.of(context).colorScheme.secondary;
      case MessageRole.tool:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only render if message has a name
    if (message.name == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        message.name!,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getRoleColor(context).withValues(alpha: 0.8),
            ),
      ),
    );
  }
}
