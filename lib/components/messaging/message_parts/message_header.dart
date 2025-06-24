import 'package:flutter/material.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';

/// MessageHeader - Selectable Message Participant Name Display
///
/// ## MISSION ACCOMPLISHED
/// Creates reusable header component with role display and action integration.
/// Provides consistent message participant name styling across all message types.
/// DESKTOP OPTIMIZATION: Full text selection and copy functionality for participant names.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | Text Widget | Minimal | No text selection | Rejected - lacks desktop UX |
/// | SelectableText Widget | Desktop UX, copy/paste | Slight overhead | CHOSEN - desktop optimization |
/// | Stateless Widget | Reusable, lightweight | Slight overhead | CHOSEN - architectural excellence |
/// | Inline Text | Minimal | No reusability | Rejected - violates DRY principle |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - simple selectable text rendering
/// - Space Complexity: O(1) - minimal widget tree
/// - Rebuild Frequency: Only when message name changes
/// - Desktop Optimization: Full text selection with context menu support
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Component Architecture Excellence**
///    - 🔍 Symptom: Header rendering logic embedded in parent widgets
///    - 🎯 Root Cause: Header logic embedded in parent widget
///    - 💥 Kill Shot: Extracted to dedicated StatelessWidget
///
/// 2. **Desktop Text Selection Limitation**
///    - 🔍 Symptom: No text selection/copy functionality for participant names
///    - 🎯 Root Cause: Text widget doesn't support selection
///    - 💥 Kill Shot: Replaced with SelectableText for full desktop UX
class MessageHeader extends StatelessWidget {
  /// Creates a selectable message header with participant name
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor
  /// DESKTOP OPTIMIZED: Full text selection and copy functionality
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
      // DESKTOP OPTIMIZATION: Selectable participant name
      child: SelectableText(
        message.name!,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getRoleColor(context).withValues(alpha: 0.8),
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
