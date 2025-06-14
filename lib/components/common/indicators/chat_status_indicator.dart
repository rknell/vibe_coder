import 'package:flutter/material.dart';
import 'package:vibe_coder/services/chat_service.dart';

/// ChatStatusIndicator - Service State Visualization
///
/// ## MISSION ACCOMPLISHED
/// Eliminates functional widget builder pattern by creating reusable status indicator.
/// Provides consistent visual feedback for ChatService state across the application.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | Stateless Widget | Reusable, testable | Slight overhead | CHOSEN - architectural excellence |
/// | Custom Painter | High performance | Complex | Overkill for simple indicator |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - constant widget tree construction
/// - Space Complexity: O(1) - minimal memory footprint
/// - Rebuild Frequency: Only on state changes via prop updates
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Elimination**
///    - 🔍 Symptom: `_buildStatusIndicator()` method in StatefulWidget
///    - 🎯 Root Cause: Violation of component architecture rules
///    - 💥 Kill Shot: Extracted to reusable StatelessWidget
///
/// 2. **Reusability Achievement**
///    - 🔍 Symptom: Status indicator locked to single screen
///    - 🎯 Root Cause: Embedded in parent widget logic
///    - 💥 Kill Shot: Standalone component with prop injection
class ChatStatusIndicator extends StatelessWidget {
  /// Creates a chat status indicator with required service state
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor
  const ChatStatusIndicator({
    super.key,
    required this.serviceState,
  });

  /// Current state of the chat service
  final ChatServiceState serviceState;

  /// Get status widget based on service state
  ///
  /// PERF: O(1) - simple switch statement with constant operations
  Widget _getStatusWidget() {
    switch (serviceState) {
      case ChatServiceState.uninitialized:
      case ChatServiceState.initializing:
        return const CircularProgressIndicator(strokeWidth: 2);
      case ChatServiceState.ready:
        return const Icon(Icons.check_circle, size: 16);
      case ChatServiceState.processing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case ChatServiceState.error:
        return const Icon(Icons.error, size: 16);
    }
  }

  /// Get status color based on service state
  ///
  /// PERF: O(1) - direct color mapping
  Color _getStatusColor() {
    switch (serviceState) {
      case ChatServiceState.uninitialized:
        return Colors.grey;
      case ChatServiceState.initializing:
        return Colors.blue;
      case ChatServiceState.ready:
        return Colors.green;
      case ChatServiceState.processing:
        return Colors.orange;
      case ChatServiceState.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusWidget = _getStatusWidget();

    // PERF: Optimized widget tree with const decorations where possible
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          statusWidget,
          const SizedBox(width: 6),
          Text(
            serviceState.name.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
