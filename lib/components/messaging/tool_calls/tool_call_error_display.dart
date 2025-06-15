import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ToolCallErrorDisplay - Error Display with Copy Functionality
///
/// ## MISSION ACCOMPLISHED
/// Eliminates _buildErrorDisplay functional widget builder by creating reusable error display component.
/// Provides formatted error display with copy functionality and error styling.
/// ARCHITECTURAL VICTORY: Single responsibility component for error rendering.
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - error text rendering
/// - Space Complexity: O(1) - error widget tree
/// - Rebuild Frequency: Only when error changes
class ToolCallErrorDisplay extends StatelessWidget {
  /// Creates an error display with copy functionality
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor with named parameters
  const ToolCallErrorDisplay({
    super.key,
    required this.error,
  });

  /// Error data to display
  final dynamic error;

  @override
  Widget build(BuildContext context) {
    final errorText = error.toString();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              errorText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => _copyToClipboard(context, content: errorText),
            tooltip: 'Copy error',
          ),
        ],
      ),
    );
  }

  /// Copy error content to clipboard
  void _copyToClipboard(BuildContext context, {required String content}) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
