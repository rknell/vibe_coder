import 'package:flutter/material.dart';

/// ToolCallHeader - Tool Call Header with Expand/Collapse Functionality
///
/// ## MISSION ACCOMPLISHED
/// Creates reusable header component with status icons and expand/collapse functionality.
/// Provides consistent tool call header display with expansion toggle and status indicators.
/// ARCHITECTURAL VICTORY: Single responsibility component for tool call header rendering.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | InkWell Wrapper | Touch feedback | Manual styling | CHOSEN - proper interaction |
/// | GestureDetector | Touch detection | No visual feedback | Rejected - poor UX |
/// | TextButton | Button styling | Wrong semantics | Rejected - not a button |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - header rendering
/// - Space Complexity: O(1) - fixed widget tree
/// - Rebuild Frequency: Only when expansion state changes
class ToolCallHeader extends StatelessWidget {
  /// Creates a tool call header with expansion toggle
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor with named parameters
  const ToolCallHeader({
    super.key,
    required this.functionName,
    required this.toolCallId,
    required this.statusEmoji,
    required this.statusColor,
    required this.isExpanded,
    required this.onToggleExpansion,
  });

  /// Function name to display
  final String functionName;

  /// Tool call ID for identification
  final String toolCallId;

  /// Status emoji for visual indication
  final String statusEmoji;

  /// Status color for UI theming
  final Color statusColor;

  /// Current expansion state
  final bool isExpanded;

  /// Callback when expansion should toggle
  final VoidCallback onToggleExpansion;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggleExpansion,
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
}
