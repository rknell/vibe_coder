import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibe_coder/services/debug_logger.dart';

/// ToolCallDebugActions - Debug Action Buttons for Tool Calls
///
/// ## MISSION ACCOMPLISHED
/// Creates reusable debug actions component with copy and retry functionality.
/// Provides copy and debug logging functionality for tool call data.
/// ARCHITECTURAL VICTORY: Single responsibility component for debug actions.
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - button rendering
/// - Space Complexity: O(1) - button widget tree
/// - Rebuild Frequency: Only when tool call data changes
class ToolCallDebugActions extends StatelessWidget {
  /// Creates debug action buttons for tool calls
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor with named parameters
  const ToolCallDebugActions({
    super.key,
    required this.toolCall,
  });

  /// Tool call data for debug operations
  final Map<String, dynamic> toolCall;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => _copyToolCallAsJson(context, toolCall: toolCall),
          icon: const Icon(Icons.code, size: 16),
          label: const Text('Copy JSON'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _logToolCallDetails(toolCall: toolCall),
          icon: const Icon(Icons.bug_report, size: 16),
          label: const Text('Debug Log'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  /// Copy entire tool call as JSON
  ///
  /// PERF: O(n) JSON serialization - acceptable for debugging
  void _copyToolCallAsJson(
    BuildContext context, {
    required Map<String, dynamic> toolCall,
  }) {
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
  void _logToolCallDetails({required Map<String, dynamic> toolCall}) {
    DebugLogger().logSystemEvent(
      'TOOL CALL DETAILS EXPORTED',
      'Tool call details logged for analysis',
      details: toolCall,
    );
  }

  /// Copy content to clipboard with user feedback
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
