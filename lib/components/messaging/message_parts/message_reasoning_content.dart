import 'package:flutter/material.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';

/// MessageReasoningContent - Reasoning Section Display
///
/// ## MISSION ACCOMPLISHED
/// Eliminates _buildReasoningContent functional widget builder by creating reusable reasoning component.
/// Provides consistent reasoning content display with proper theming for deepseek-reasoner model responses.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | Stateless Widget | Reusable, themed | Slight overhead | CHOSEN - architectural excellence |
/// | Inline Container | Minimal | No reusability | Rejected - violates DRY principle |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - single text widget rendering
/// - Space Complexity: O(1) - minimal widget tree
/// - Rebuild Frequency: Only when reasoning content changes
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Elimination**
///    - 🔍 Symptom: `_buildReasoningContent()` method in MessageBubble
///    - 🎯 Root Cause: Reasoning display logic embedded in parent widget
///    - 💥 Kill Shot: Extracted to dedicated StatelessWidget with tertiary theming
class MessageReasoningContent extends StatelessWidget {
  /// Creates a reasoning content display section
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor
  const MessageReasoningContent({
    super.key,
    required this.message,
  });

  /// Chat message containing reasoning content
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    // Only render if message has reasoning content
    if (message.reasoningContent == null || message.reasoningContent!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reasoning:',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            message.reasoningContent!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }
}
