import 'package:flutter/material.dart';

/// ToolCallSectionHeader - Section Header for Tool Call Content
///
/// ## MISSION ACCOMPLISHED
/// Creates reusable section header component with consistent typography and spacing.
/// Provides consistent section header styling for tool call content sections.
/// ARCHITECTURAL VICTORY: Single responsibility component for section header rendering.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | Stateless Widget | Lightweight | No state | CHOSEN - display only component |
/// | Text Widget | Direct rendering | No reusability | Rejected - needs consistency |
/// | Themed Text | Consistent styling | Slight overhead | CHOSEN - visual consistency |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - text rendering
/// - Space Complexity: O(1) - single text widget
/// - Rebuild Frequency: Only when title changes
class ToolCallSectionHeader extends StatelessWidget {
  /// Creates a section header with consistent styling
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor with named parameters
  const ToolCallSectionHeader({
    super.key,
    required this.title,
  });

  /// Section title to display
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}
