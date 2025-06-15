import 'package:flutter/material.dart';
import 'package:vibe_coder/components/messaging/tool_calls/tool_call_section_header.dart';
import 'package:vibe_coder/components/messaging/tool_calls/tool_call_json_display.dart';
import 'package:vibe_coder/components/messaging/tool_calls/tool_call_error_display.dart';
import 'package:vibe_coder/components/messaging/tool_calls/tool_call_debug_actions.dart';

/// ToolCallExpandedContent - Expanded Tool Call Content Display
///
/// ## MISSION ACCOMPLISHED
/// Eliminates _buildExpandedContent functional widget builder by creating reusable expanded content component.
/// Provides structured display of tool call arguments, results, errors, and debug actions.
/// ARCHITECTURAL VICTORY: Single responsibility component for expanded tool call details.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | Stateless Widget | Lightweight | No state | CHOSEN - display only component |
/// | Column Layout | Vertical structure | Space usage | CHOSEN - clear section separation |
/// | Scrollable Content | Large data handling | Complexity | Considered for future |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(n) where n = number of sections to display
/// - Space Complexity: O(n) - section widget tree
/// - Rebuild Frequency: Only when tool call data changes
class ToolCallExpandedContent extends StatelessWidget {
  /// Creates expanded tool call content display
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor with named parameters
  const ToolCallExpandedContent({
    super.key,
    required this.toolCall,
    required this.functionArgs,
    required this.showDebugInfo,
  });

  /// Tool call data containing all information
  final Map<String, dynamic> toolCall;

  /// Function arguments parsed from tool call
  final Map<String, dynamic> functionArgs;

  /// Whether to show debug information
  final bool showDebugInfo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Function arguments section
          if (functionArgs.isNotEmpty) ...[
            const ToolCallSectionHeader(title: '📋 Arguments'),
            const SizedBox(height: 8),
            ToolCallJsonDisplay(
              data: functionArgs,
              type: 'arguments',
            ),
            const SizedBox(height: 12),
          ],

          // Tool call result section (if available)
          if (toolCall.containsKey('result')) ...[
            const ToolCallSectionHeader(title: '✅ Result'),
            const SizedBox(height: 8),
            ToolCallJsonDisplay(
              data: toolCall['result'],
              type: 'result',
            ),
            const SizedBox(height: 12),
          ],

          // Error section (if available)
          if (toolCall.containsKey('error')) ...[
            const ToolCallSectionHeader(title: '❌ Error'),
            const SizedBox(height: 8),
            ToolCallErrorDisplay(error: toolCall['error']),
            const SizedBox(height: 12),
          ],

          // Debug actions
          if (showDebugInfo) ToolCallDebugActions(toolCall: toolCall),
        ],
      ),
    );
  }
}
