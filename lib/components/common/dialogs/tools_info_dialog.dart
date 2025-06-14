import 'package:flutter/material.dart';

/// ToolsInfoDialog - Available AI Tools Display
///
/// ## MISSION ACCOMPLISHED
/// Eliminates functional dialog builder pattern by creating reusable tools info dialog.
/// Provides consistent information display for available MCP tools across the application.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Inline showDialog | Simple | Not reusable | Rejected - violates architecture |
/// | Static method | Reusable | No state management | Considered but limited |
/// | Stateless Widget | Reusable, testable | Clean separation | CHOSEN - architectural excellence |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(n) where n = number of tools (acceptable for info display)
/// - Space Complexity: O(n) - tool list storage
/// - Rebuild Frequency: Only when tools list changes
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Functional Dialog Elimination**
///    - 🔍 Symptom: `_showToolsInfo()` method embedded in StatefulWidget
///    - 🎯 Root Cause: Dialog logic mixed with screen logic
///    - 💥 Kill Shot: Extracted to reusable dialog component
///
/// 2. **Separation of Concerns**
///    - 🔍 Symptom: UI logic coupled with business logic
///    - 🎯 Root Cause: Dialog construction in parent widget
///    - 💥 Kill Shot: Pure UI component with prop injection
class ToolsInfoDialog extends StatelessWidget {
  /// Creates a tools info dialog with the provided tools list
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor
  const ToolsInfoDialog({
    super.key,
    required this.tools,
  });

  /// List of available tool names
  final List<String> tools;

  /// Show the tools info dialog
  ///
  /// PERF: O(1) - dialog display with O(n) content rendering
  static Future<void> show(BuildContext context, List<String> tools) {
    return showDialog<void>(
      context: context,
      builder: (context) => ToolsInfoDialog(tools: tools),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Available AI Tools'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The AI assistant has access to ${tools.length} tools:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (tools.isEmpty)
              const Text('No tools currently available')
            else
              // PERF: O(n) list rendering - acceptable for tool info display
              ...tools.map((tool) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.build, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(child: Text(tool)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
