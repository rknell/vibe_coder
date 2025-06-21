import 'package:flutter/material.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';

/// MessageToolCalls - Selectable Tool Calls Section Display
///
/// ## MISSION ACCOMPLISHED
/// Eliminates _buildToolCalls functional widget builder by creating reusable tool calls component.
/// Provides consistent tool call information display with proper styling and formatting.
/// DESKTOP OPTIMIZATION: Full text selection and copy functionality for tool call names and details.
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
/// - Time Complexity: O(n) where n = number of tool calls (acceptable for typical usage)
/// - Space Complexity: O(n) - list rendering of tool calls
/// - Rebuild Frequency: Only when tool calls change
/// - Desktop Optimization: Full text selection with context menu support
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Elimination**
///    - 🔍 Symptom: `_buildToolCalls()` method in MessageBubble
///    - 🎯 Root Cause: Tool calls rendering logic embedded in parent widget
///    - 💥 Kill Shot: Extracted to dedicated StatelessWidget with proper theming
///
/// 2. **Desktop Text Selection Limitation**
///    - 🔍 Symptom: No text selection/copy functionality for tool call information
///    - 🎯 Root Cause: Text widget doesn't support selection
///    - 💥 Kill Shot: Replaced with SelectableText for full desktop UX
class MessageToolCalls extends StatelessWidget {
  /// Creates a selectable tool calls display section
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor
  /// DESKTOP OPTIMIZED: Full text selection and copy functionality
  const MessageToolCalls({
    super.key,
    required this.message,
  });

  /// Chat message containing tool calls data
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    // Only render if message has tool calls
    final toolCalls = message.toolCalls;
    if (toolCalls == null || toolCalls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DESKTOP OPTIMIZATION: Selectable label text
          SelectableText(
            'Tool Calls:',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
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
          // PERF: O(n) list rendering - acceptable for tool calls display
          // DESKTOP OPTIMIZATION: Each tool call is selectable
          ...toolCalls.map((toolCall) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: SelectableText(
                  '• ${toolCall['function']?['name'] ?? 'Unknown function'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                  enableInteractiveSelection: true,
                  contextMenuBuilder: (context, editableTextState) {
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: editableTextState.contextMenuAnchors,
                      buttonItems: editableTextState.contextMenuButtonItems,
                    );
                  },
                ),
              )),
        ],
      ),
    );
  }
}
