import 'package:flutter/material.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';

/// MessageReasoningContent - Selectable Reasoning Section Display
///
/// ## MISSION ACCOMPLISHED
/// Eliminates _buildReasoningContent functional widget builder by creating reusable reasoning component.
/// Provides consistent reasoning content display with proper theming for deepseek-reasoner model responses.
/// DESKTOP OPTIMIZATION: Full text selection and copy functionality for reasoning content.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | Text Widget | Minimal | No text selection | Rejected - lacks desktop UX |
/// | SelectableText Widget | Desktop UX, copy/paste | Slight overhead | CHOSEN - desktop optimization |
/// | Stateless Widget | Reusable, themed | Slight overhead | CHOSEN - architectural excellence |
/// | Inline Container | Minimal | No reusability | Rejected - violates DRY principle |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - single selectable text widget rendering
/// - Space Complexity: O(1) - minimal widget tree
/// - Rebuild Frequency: Only when reasoning content changes
/// - Desktop Optimization: Full text selection with context menu support
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Elimination**
///    - 🔍 Symptom: `_buildReasoningContent()` method in MessageBubble
///    - 🎯 Root Cause: Reasoning display logic embedded in parent widget
///    - 💥 Kill Shot: Extracted to dedicated StatelessWidget with tertiary theming
///
/// 2. **Desktop Text Selection Limitation**
///    - 🔍 Symptom: No text selection/copy functionality for reasoning content
///    - 🎯 Root Cause: Text widget doesn't support selection
///    - 💥 Kill Shot: Replaced with SelectableText for full desktop UX
class MessageReasoningContent extends StatelessWidget {
  /// Creates a selectable reasoning content display section
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor
  /// DESKTOP OPTIMIZED: Full text selection and copy functionality
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
          // DESKTOP OPTIMIZATION: Selectable label text
          SelectableText(
            'Reasoning:',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
            enableInteractiveSelection: true,
            contextMenuBuilder: (context, editableTextState) {
              return AdaptiveTextSelectionToolbar.buttonItems(
                anchors: editableTextState.contextMenuAnchors,
                buttonItems: editableTextState.contextMenuButtonItems,
              );
            },
          ),
          const SizedBox(height: 4),
          // DESKTOP OPTIMIZATION: Selectable reasoning content
          SelectableText(
            message.reasoningContent!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8),
                ),
            enableInteractiveSelection: true,
            contextMenuBuilder: (context, editableTextState) {
              return AdaptiveTextSelectionToolbar.buttonItems(
                anchors: editableTextState.contextMenuAnchors,
                buttonItems: editableTextState.contextMenuButtonItems,
              );
            },
          ),
        ],
      ),
    );
  }
}
