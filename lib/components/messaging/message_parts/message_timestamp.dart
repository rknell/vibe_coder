import 'package:flutter/material.dart';

/// MessageTimestamp - Selectable Message Time Display
///
/// ## MISSION ACCOMPLISHED
/// Eliminates _buildTimestamp functional widget builder by creating reusable timestamp component.
/// Provides consistent timestamp formatting and styling across all messages.
/// DESKTOP OPTIMIZATION: Full text selection and copy functionality for timestamps.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | Text Widget | Minimal | No text selection | Rejected - lacks desktop UX |
/// | SelectableText Widget | Desktop UX, copy/paste | Slight overhead | CHOSEN - desktop optimization |
/// | Stateless Widget | Reusable, customizable | Slight overhead | CHOSEN - architectural excellence |
/// | DateTime Integration | Real timestamps | Complexity | Future enhancement for actual message times |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - simple datetime formatting with selection
/// - Space Complexity: O(1) - minimal widget tree
/// - Rebuild Frequency: Only when showTimestamp changes
/// - Desktop Optimization: Full text selection with context menu support
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Elimination**
///    - 🔍 Symptom: `_buildTimestamp()` method in MessageBubble
///    - 🎯 Root Cause: Timestamp rendering logic embedded in parent widget
///    - 💥 Kill Shot: Extracted to dedicated StatelessWidget with formatting control
///
/// 2. **Desktop Text Selection Limitation**
///    - 🔍 Symptom: No text selection/copy functionality for timestamps
///    - 🎯 Root Cause: Text widget doesn't support selection
///    - 💥 Kill Shot: Replaced with SelectableText for full desktop UX
class MessageTimestamp extends StatelessWidget {
  /// Creates a selectable message timestamp display
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor
  /// DESKTOP OPTIMIZED: Full text selection and copy functionality
  const MessageTimestamp({
    super.key,
    this.timestamp,
    this.showTimestamp = true,
  });

  /// Optional specific timestamp to display (defaults to current time)
  final DateTime? timestamp;

  /// Whether to show the timestamp
  final bool showTimestamp;

  @override
  Widget build(BuildContext context) {
    // Only render if timestamp should be shown
    if (!showTimestamp) {
      return const SizedBox.shrink();
    }

    // Use provided timestamp or current time
    final displayTime = timestamp ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      // DESKTOP OPTIMIZATION: Selectable timestamp
      child: SelectableText(
        // Simple time format (HH:MM:SS) - can be enhanced for relative time
        displayTime.toString().substring(11, 19),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
        enableInteractiveSelection: true,
        contextMenuBuilder: (context, editableTextState) {
          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: editableTextState.contextMenuButtonItems,
          );
        },
      ),
    );
  }
}
