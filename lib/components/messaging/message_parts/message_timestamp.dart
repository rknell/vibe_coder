import 'package:flutter/material.dart';

/// MessageTimestamp - Message Time Display
///
/// ## MISSION ACCOMPLISHED
/// Eliminates _buildTimestamp functional widget builder by creating reusable timestamp component.
/// Provides consistent timestamp formatting and styling across all messages.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | Stateless Widget | Reusable, customizable | Slight overhead | CHOSEN - architectural excellence |
/// | DateTime Integration | Real timestamps | Complexity | Future enhancement for actual message times |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - simple datetime formatting
/// - Space Complexity: O(1) - minimal widget tree
/// - Rebuild Frequency: Only when showTimestamp changes
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Elimination**
///    - 🔍 Symptom: `_buildTimestamp()` method in MessageBubble
///    - 🎯 Root Cause: Timestamp rendering logic embedded in parent widget
///    - 💥 Kill Shot: Extracted to dedicated StatelessWidget with formatting control
class MessageTimestamp extends StatelessWidget {
  /// Creates a message timestamp display
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor
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
      child: Text(
        // Simple time format (HH:MM:SS) - can be enhanced for relative time
        displayTime.toString().substring(11, 19),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
      ),
    );
  }
}
