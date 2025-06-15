import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ToolCallJsonDisplay - JSON Data Display with Copy Functionality
///
/// ## MISSION ACCOMPLISHED
/// Eliminates _buildJsonDisplay functional widget builder by creating reusable JSON display component.
/// Provides formatted JSON display with copy functionality and proper type safety.
/// ARCHITECTURAL VICTORY: Single responsibility component for JSON data rendering.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | Container + Text | Formatted display | Manual styling | CHOSEN - visual consistency |
/// | Raw JSON String | Direct output | Poor readability | Rejected - user experience |
/// | Type-Safe Parsing | Error prevention | Complexity | CHOSEN - stability |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(n) where n = JSON data size for formatting
/// - Space Complexity: O(n) - formatted string storage
/// - Rebuild Frequency: Only when data changes
class ToolCallJsonDisplay extends StatelessWidget {
  /// Creates a JSON display with copy functionality
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor with named parameters
  const ToolCallJsonDisplay({
    super.key,
    required this.data,
    required this.type,
  });

  /// Data to display as JSON
  final dynamic data;

  /// Type description for copy feedback
  final String type;

  @override
  Widget build(BuildContext context) {
    final jsonString = _formatJsonSafely(data);

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }

  /// Format data as JSON with proper type safety
  ///
  /// PERF: O(n) JSON formatting - acceptable for debugging display
  /// TYPE SAFETY: Handles various data types safely
  String _formatJsonSafely(dynamic data) {
    try {
      // Handle different data types safely
      if (data == null) {
        return 'null';
      } else if (data is String) {
        // If it's already a string, try to parse it as JSON first
        try {
          final parsed = jsonDecode(data);
          return const JsonEncoder.withIndent('  ').convert(parsed);
        } catch (e) {
          // If not valid JSON, return as string
          return data;
        }
      } else if (data is Map) {
        // Convert Map<dynamic, dynamic> to Map<String, dynamic> safely
        final Map<String, dynamic> safeMap = {};
        data.forEach((key, value) {
          safeMap[key.toString()] = value;
        });
        return const JsonEncoder.withIndent('  ').convert(safeMap);
      } else if (data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      } else {
        // For other types, convert to string representation
        return const JsonEncoder.withIndent('  ').convert(data.toString());
      }
    } catch (e) {
      // Fallback to string representation
      return data.toString();
    }
  }

  /// Copy content to clipboard with user feedback
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
}
