import 'package:flutter/material.dart';
import 'package:vibe_coder/components/messaging/tool_calls/tool_call_header.dart';
import 'package:vibe_coder/components/messaging/tool_calls/tool_call_expanded_content.dart';

/// ToolCallCard - Individual Tool Call Display Card
///
/// ## MISSION ACCOMPLISHED
/// Eliminates _buildToolCallCard functional widget builder by creating reusable tool call card component.
/// Provides consistent tool call card display with expansion state management and status visualization.
/// ARCHITECTURAL VICTORY: Single responsibility component for tool call card rendering.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | StatefulWidget | State management | Heavier | CHOSEN - expansion state needed |
/// | Stateless Widget | Lightweight | No state | Rejected - expansion toggle needed |
/// | Container + InkWell | Touch feedback | Manual styling | CHOSEN - proper interaction |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - single card rendering
/// - Space Complexity: O(1) - widget tree depth
/// - Rebuild Frequency: Only when expansion state changes
class ToolCallCard extends StatefulWidget {
  /// Creates a tool call card with expansion functionality
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor with named parameters
  const ToolCallCard({
    super.key,
    required this.index,
    required this.toolCall,
    required this.onToggleExpansion,
    required this.isExpanded,
    required this.showDebugInfo,
    this.onToolCallTap,
  });

  /// Index of this tool call in the list
  final int index;

  /// Tool call data containing function details
  final Map<String, dynamic> toolCall;

  /// Callback when expansion state should toggle
  final VoidCallback onToggleExpansion;

  /// Current expansion state
  final bool isExpanded;

  /// Whether to show debug information
  final bool showDebugInfo;

  /// Callback when tool call is tapped
  final Function(Map<String, dynamic>)? onToolCallTap;

  @override
  State<ToolCallCard> createState() => _ToolCallCardState();
}

class _ToolCallCardState extends State<ToolCallCard> {
  @override
  Widget build(BuildContext context) {
    // Extract tool call data with type safety
    final functionData = widget.toolCall['function'];
    final functionMap = functionData is Map<String, dynamic>
        ? functionData
        : <String, dynamic>{};

    final functionName = functionMap['name'] as String? ?? 'Unknown Function';
    final functionArgs = functionMap['parameters'] ?? functionMap['arguments'];

    // Parse arguments safely
    Map<String, dynamic> parsedArgs;
    if (functionArgs is String) {
      // If arguments is a JSON string, we'd need to parse it, but for display we'll use the raw parameters
      parsedArgs = <String, dynamic>{'raw': functionArgs};
    } else if (functionArgs is Map<String, dynamic>) {
      parsedArgs = functionArgs;
    } else if (functionArgs is Map) {
      // Handle Map<dynamic, dynamic> case safely
      parsedArgs = <String, dynamic>{};
      functionArgs.forEach((key, value) {
        parsedArgs[key.toString()] = value;
      });
    } else {
      parsedArgs = <String, dynamic>{};
    }

    final toolCallId = widget.toolCall['id'] as String? ?? 'unknown_id';

    // Determine status and color
    final status = _determineToolCallStatus(widget.toolCall);
    final statusColor = _getStatusColor(context, status);
    final statusEmoji = _getStatusEmoji(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tool call header
          ToolCallHeader(
            functionName: functionName,
            toolCallId: toolCallId,
            statusEmoji: statusEmoji,
            statusColor: statusColor,
            isExpanded: widget.isExpanded,
            onToggleExpansion: widget.onToggleExpansion,
          ),

          // Expandable content
          if (widget.isExpanded) ...[
            const Divider(height: 1),
            ToolCallExpandedContent(
              toolCall: widget.toolCall,
              functionArgs: parsedArgs,
              showDebugInfo: widget.showDebugInfo,
            ),
          ],
        ],
      ),
    );
  }

  /// Determine tool call status based on available data
  ///
  /// PERF: O(1) status determination - efficient classification
  ToolCallStatus _determineToolCallStatus(Map<String, dynamic> toolCall) {
    if (toolCall.containsKey('error')) {
      return ToolCallStatus.error;
    } else if (toolCall.containsKey('result')) {
      return ToolCallStatus.success;
    } else {
      return ToolCallStatus.pending;
    }
  }

  /// Get status color for UI indication
  ///
  /// PERF: O(1) color determination - efficient styling
  Color _getStatusColor(BuildContext context, ToolCallStatus status) {
    switch (status) {
      case ToolCallStatus.success:
        return Theme.of(context).colorScheme.primary;
      case ToolCallStatus.error:
        return Theme.of(context).colorScheme.error;
      case ToolCallStatus.pending:
        return Theme.of(context).colorScheme.outline;
    }
  }

  /// Get status emoji for visual indication
  ///
  /// PERF: O(1) emoji determination - efficient visual indication
  String _getStatusEmoji(ToolCallStatus status) {
    switch (status) {
      case ToolCallStatus.success:
        return '✅';
      case ToolCallStatus.error:
        return '❌';
      case ToolCallStatus.pending:
        return '⏳';
    }
  }
}

/// Tool Call Status enumeration
///
/// ARCHITECTURAL: Status classification for UI indication
enum ToolCallStatus {
  pending,
  success,
  error,
}
