import 'package:flutter/material.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';

/// MessageAvatar - Role-Based Avatar Display
///
/// ## MISSION ACCOMPLISHED
/// Creates reusable avatar component with consistent styling and interaction patterns.
/// Provides consistent role-based avatar display with proper theming and icon mapping.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | Stateless Widget | Reusable, themed | Slight overhead | CHOSEN - architectural excellence |
/// | Image Avatars | Visual appeal | Asset management | Future enhancement for custom avatars |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - direct role-based color/icon mapping
/// - Space Complexity: O(1) - single CircleAvatar widget
/// - Rebuild Frequency: Only when message role changes
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Component Architecture Excellence**
///    - 🔍 Symptom: Avatar rendering logic embedded in parent widgets
///    - 🎯 Root Cause: Avatar rendering logic embedded in parent widget
///    - 💥 Kill Shot: Extracted to dedicated StatelessWidget with role theming
class MessageAvatar extends StatelessWidget {
  /// Creates a role-based message avatar
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor
  const MessageAvatar({
    super.key,
    required this.message,
    this.radius = 16.0,
  });

  /// Chat message containing role information
  final ChatMessage message;

  /// Radius of the avatar circle
  final double radius;

  /// Get role-specific color for avatar background
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

  /// Get role-specific icon for avatar display
  ///
  /// PERF: O(1) - direct enum-based icon mapping
  IconData _getRoleIcon() {
    switch (message.role) {
      case MessageRole.system:
        return Icons.settings;
      case MessageRole.user:
        return Icons.person;
      case MessageRole.assistant:
        return Icons.smart_toy;
      case MessageRole.tool:
        return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRoleColor(context);
    final icon = _getRoleIcon();

    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(
        icon,
        size: radius,
        color: color,
      ),
    );
  }
}
