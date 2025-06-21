import 'package:flutter/material.dart';

/// ChatStatusIndicator - Agent Status Visualization Component
///
/// ## MISSION ACCOMPLISHED
/// Updated to use generic agent status instead of ChatService-specific states
/// following architectural refactoring to eliminate ChatService.
///
/// ## ARCHITECTURAL COMPLIANCE
/// - ✅ Component accepts generic status instead of service-specific enum
/// - ✅ Reusable across different status sources (agent, service, etc.)
/// - ✅ Stateless component following warrior protocol
///
/// PERF: O(1) rendering - direct status mapping
/// REUSE: Universal status indicator for any agent or service state

/// Generic status enumeration for UI state management
enum AgentStatus {
  uninitialized,
  initializing,
  ready,
  processing,
  error,
}

extension AgentStatusExtension on AgentStatus {
  String get displayName {
    switch (this) {
      case AgentStatus.uninitialized:
        return 'Uninitialized';
      case AgentStatus.initializing:
        return 'Initializing';
      case AgentStatus.ready:
        return 'Ready';
      case AgentStatus.processing:
        return 'Processing';
      case AgentStatus.error:
        return 'Error';
    }
  }
}

/// ChatStatusIndicator - Universal Status Visualization
///
/// ARCHITECTURAL: Generic status indicator that can display any agent or service state
class ChatStatusIndicator extends StatelessWidget {
  final AgentStatus status;
  final double size;
  final String? tooltip;

  const ChatStatusIndicator({
    super.key,
    required this.status,
    this.size = 16.0,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? status.displayName,
      child: Icon(
        _getStatusIcon(),
        size: size,
        color: _getStatusColor(),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (status) {
      case AgentStatus.uninitialized:
      case AgentStatus.initializing:
        return Icons.hourglass_empty;
      case AgentStatus.ready:
        return Icons.check_circle;
      case AgentStatus.processing:
        return Icons.autorenew;
      case AgentStatus.error:
        return Icons.error;
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case AgentStatus.uninitialized:
        return Colors.grey;
      case AgentStatus.initializing:
        return Colors.orange;
      case AgentStatus.ready:
        return Colors.green;
      case AgentStatus.processing:
        return Colors.blue;
      case AgentStatus.error:
        return Colors.red;
    }
  }
}
