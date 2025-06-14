import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/services/debug_logger.dart';

/// MessageToolCallsEnhanced - Enhanced Tool Calls Debug Display
///
/// ## MISSION ACCOMPLISHED
/// Eliminates tool call debugging blind spots by providing comprehensive visibility.
/// Displays detailed tool call information with expandable sections and copy functionality.
/// ARCHITECTURAL VICTORY: Real-time debugging UI component with structured data display.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Basic Text Display | Simple, fast | No detail visibility | Rejected - insufficient debugging |
/// | Expandable Cards | Detailed, organized | More complex | CHOSEN - comprehensive debugging |
/// | JSON Tree View | Structured, searchable | Performance overhead | CHOSEN - maximum visibility |
/// | Copy Functionality | Shareable, testable | Extra complexity | CHOSEN - field debugging support |
/// | Color Coding | Visual clarity | Accessibility concern | CHOSEN - quick status identification |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Tool Call Information Blackout**
///    - 🔍 Symptom: Can't see tool call details in message UI
///    - 🎯 Root Cause: Basic tool call display without detail expansion
///    - 💥 Kill Shot: Expandable cards with full argument and result visibility
///
/// 2. **Debugging Data Export Challenge**
///    - 🔍 Symptom: Can't share tool call details for debugging
///    - 🎯 Root Cause: No copy/export functionality
///    - 💥 Kill Shot: Copy to clipboard functionality for all data
///
/// 3. **Tool Call Status Ambiguity**
///    - 🔍 Symptom: Can't quickly identify success/failure status
///    - 🎯 Root Cause: No visual status indicators
///    - 💥 Kill Shot: Color-coded status indicators with emoji
///
/// ## PERFORMANCE PROFILE
/// - Initial render: O(n) where n = number of tool calls
/// - JSON formatting: O(m) where m = JSON payload size (on-demand)
/// - UI expansion: O(1) - efficient state management
/// - Copy operations: O(k) where k = copied data size (acceptable for debugging)
///
/// An enhanced tool calls display component with debugging capabilities.
/// Shows comprehensive tool call information with expandable details and copy functionality.
class MessageToolCallsEnhanced extends StatefulWidget {
  /// Creates an enhanced tool calls display section
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor
  const MessageToolCallsEnhanced({
    super.key,
    required this.message,
    this.showDebugInfo = true,
    this.onToolCallTap,
  });

  /// Chat message containing tool calls data
  final ChatMessage message;

  /// Whether to show debug information
  final bool showDebugInfo;

  /// Callback when tool call is tapped
  final Function(Map<String, dynamic>)? onToolCallTap;

  @override
  State<MessageToolCallsEnhanced> createState() =>
      _MessageToolCallsEnhancedState();
}

class _MessageToolCallsEnhancedState extends State<MessageToolCallsEnhanced> {
  final Set<int> _expandedToolCalls = {};
  final DebugLogger _debugLogger = DebugLogger();

  @override
  Widget build(BuildContext context) {
    // Only render if message has tool calls
    if (widget.message.toolCalls == null || widget.message.toolCalls!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PERF: O(n) list rendering - acceptable for tool calls display
          ...widget.message.toolCalls!.asMap().entries.map((entry) {
            final index = entry.key;
            final toolCall = entry.value;
            return _buildToolCallCard(context, index, toolCall);
          }),
        ],
      ),
    );
  }

  /// Build individual tool call card with enhanced debugging
  ///
  /// PERF: O(1) card rendering - efficient widget construction
  Widget _buildToolCallCard(
      BuildContext context, int index, Map<String, dynamic> toolCall) {
    final isExpanded = _expandedToolCalls.contains(index);
    final functionName = toolCall['function']?['name'] ?? 'Unknown Function';
    final functionArgs = toolCall['function']?['parameters'] ?? {};
    final toolCallId = toolCall['id'] ?? 'unknown_id';

    // Determine status and color
    final status = _determineToolCallStatus(toolCall);
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
          _buildToolCallHeader(
            context,
            index,
            functionName,
            toolCallId,
            statusEmoji,
            statusColor,
            isExpanded,
          ),

          // Expandable content
          if (isExpanded) ...[
            const Divider(height: 1),
            _buildExpandedContent(context, toolCall, functionArgs),
          ],
        ],
      ),
    );
  }

  /// Build tool call header with expand/collapse functionality
  ///
  /// PERF: O(1) header rendering - efficient widget construction
  Widget _buildToolCallHeader(
    BuildContext context,
    int index,
    String functionName,
    String toolCallId,
    String statusEmoji,
    Color statusColor,
    bool isExpanded,
  ) {
    return InkWell(
      onTap: () => _toggleToolCallExpansion(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),

            // Tool call info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$statusEmoji Tool Call',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                      ),
                      const Spacer(),
                      Text(
                        toolCallId,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontFamily: 'monospace',
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    functionName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),

            // Expand/Collapse icon
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  /// Build expanded content with debugging details
  ///
  /// PERF: O(n) content rendering where n = argument count - acceptable for debugging
  Widget _buildExpandedContent(
    BuildContext context,
    Map<String, dynamic> toolCall,
    Map<String, dynamic> functionArgs,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Function arguments section
          if (functionArgs.isNotEmpty) ...[
            _buildSectionHeader(context, '📋 Arguments'),
            const SizedBox(height: 8),
            _buildJsonDisplay(context, functionArgs, 'arguments'),
            const SizedBox(height: 12),
          ],

          // Tool call result section (if available)
          if (toolCall.containsKey('result')) ...[
            _buildSectionHeader(context, '✅ Result'),
            const SizedBox(height: 8),
            _buildJsonDisplay(context, toolCall['result'], 'result'),
            const SizedBox(height: 12),
          ],

          // Error section (if available)
          if (toolCall.containsKey('error')) ...[
            _buildSectionHeader(context, '❌ Error'),
            const SizedBox(height: 8),
            _buildErrorDisplay(context, toolCall['error']),
            const SizedBox(height: 12),
          ],

          // Debug actions
          if (widget.showDebugInfo) _buildDebugActions(context, toolCall),
        ],
      ),
    );
  }

  /// Build section header with styling
  ///
  /// PERF: O(1) header rendering - efficient widget construction
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  /// Build JSON display with pretty formatting
  ///
  /// PERF: O(n) JSON formatting - acceptable for debugging display
  Widget _buildJsonDisplay(BuildContext context, dynamic data, String type) {
    String jsonString;
    try {
      jsonString = const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      jsonString = data.toString();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  jsonString,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () => _copyToClipboard(
                  context,
                  content: jsonString,
                  type: type,
                ),
                tooltip: 'Copy $type',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build error display with special formatting
  ///
  /// PERF: O(1) error display rendering - efficient widget construction
  Widget _buildErrorDisplay(BuildContext context, dynamic error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => _copyToClipboard(
              context,
              content: error.toString(),
              type: 'error',
            ),
            tooltip: 'Copy error',
          ),
        ],
      ),
    );
  }

  /// Build debug actions section
  ///
  /// PERF: O(1) actions rendering - efficient widget construction
  Widget _buildDebugActions(
      BuildContext context, Map<String, dynamic> toolCall) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => _copyToolCallAsJson(context, toolCall),
          icon: const Icon(Icons.code, size: 16),
          label: const Text('Copy JSON'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _logToolCallDetails(toolCall),
          icon: const Icon(Icons.bug_report, size: 16),
          label: const Text('Debug Log'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  /// Toggle tool call expansion state
  ///
  /// PERF: O(1) state toggle - efficient state management
  void _toggleToolCallExpansion(int index) {
    setState(() {
      if (_expandedToolCalls.contains(index)) {
        _expandedToolCalls.remove(index);
      } else {
        _expandedToolCalls.add(index);
      }
    });
  }

  /// Copy content to clipboard
  ///
  /// PERF: O(n) where n = content size - acceptable for debugging
  void _copyToClipboard(
    BuildContext context, {
    required String content,
    required String type,
  }) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Copy entire tool call as JSON
  ///
  /// PERF: O(n) JSON serialization - acceptable for debugging
  void _copyToolCallAsJson(
      BuildContext context, Map<String, dynamic> toolCall) {
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(toolCall);
      _copyToClipboard(
        context,
        content: jsonString,
        type: 'Tool call',
      );
    } catch (e) {
      _copyToClipboard(
        context,
        content: toolCall.toString(),
        type: 'Tool call',
      );
    }
  }

  /// Log tool call details to debug logger
  ///
  /// PERF: O(1) logging - immediate debug capture
  void _logToolCallDetails(Map<String, dynamic> toolCall) {
    _debugLogger.logSystemEvent(
      'TOOL CALL DETAILS EXPORTED',
      'Tool call details logged for analysis',
      details: toolCall,
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
