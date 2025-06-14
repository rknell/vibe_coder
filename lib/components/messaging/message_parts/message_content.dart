import 'package:flutter/material.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';

/// MessageContent - Selectable Message Text Display
///
/// ## MISSION ACCOMPLISHED
/// Eliminates _buildContent functional widget builder by creating reusable content component.
/// Provides consistent message text rendering with proper styling integration and TEXT SELECTION.
/// DESKTOP OPTIMIZATION: Full text selection and copy functionality for professional desktop UX.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | Text Widget | Minimal | No text selection | Rejected - lacks desktop UX |
/// | SelectableText Widget | Desktop UX, copy/paste | Slight overhead | CHOSEN - desktop optimization |
/// | Stateless Widget | Reusable, efficient | Slight overhead | CHOSEN - architectural excellence |
/// | Raw Text Widget | Minimal | No style integration | Rejected - lacks theming |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - direct selectable text widget rendering
/// - Space Complexity: O(1) - single selectable text widget
/// - Rebuild Frequency: Only when message content changes
/// - Desktop Optimization: Full text selection with context menu support
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Elimination**
///    - 🔍 Symptom: `_buildContent()` method in MessageBubble
///    - 🎯 Root Cause: Content rendering logic embedded in parent widget
///    - 💥 Kill Shot: Extracted to dedicated StatelessWidget with style integration
///
/// 2. **Desktop Text Selection Limitation**
///    - 🔍 Symptom: No text selection/copy functionality on desktop builds
///    - 🎯 Root Cause: Text widget doesn't support selection
///    - 💥 Kill Shot: Replaced with SelectableText for full desktop UX
class MessageContent extends StatelessWidget {
  /// Creates a selectable message content display with styling
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor
  /// DESKTOP OPTIMIZED: Full text selection and copy functionality
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

    // PERF: SelectableText with default context menu for desktop optimization
    // ARCHITECTURAL: General solution - works across all platforms, optimized for desktop
    return SelectableText(
      message.content!,
      style: textStyle,
      // DESKTOP OPTIMIZATION: Enable text selection for copy/paste functionality
      enableInteractiveSelection: true,
      // DESKTOP UX: Adaptive context menu with platform-specific styling
      contextMenuBuilder: (context, editableTextState) {
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: editableTextState.contextMenuButtonItems,
        );
      },
    );
  }
}
