import 'package:flutter/material.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/components/messaging/tool_calls/tool_call_card.dart';

/// MessageToolCallsEnhanced - Enhanced Tool Calls Display (Architecture Compliant)
///
/// ## MISSION ACCOMPLISHED
/// ARCHITECTURAL VICTORY: Eliminated ALL functional widget builders from tool calls display
/// Replaced 7 _buildSomething() methods with proper component architecture
/// Fixed Map<dynamic, dynamic> type casting issues with proper type safety
/// PERFORMANCE: O(n) where n = number of tool calls - efficient list rendering
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builders | Simple | Architecture violation | ELIMINATED - zero tolerance |
/// | Component Extraction | Reusable | More files | CHOSEN - architecture compliance |
/// | StatefulWidget | State management | Overhead | CHOSEN - expansion state needed |
/// | Type-safe parsing | Error prevention | Complexity | CHOSEN - stability first |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Map Type Casting Error**
///    - 🔍 Symptom: _Map<dynamic, dynamic> is not a subtype of Map<String, dynamic>
///    - 🎯 Root Cause: Direct casting without type safety
///    - 💥 Kill Shot: Safe type conversion in ToolCallCard component
///
/// 2. **Functional Widget Builder Violations**
///    - 🔍 Symptom: Multiple _buildSomething() methods in StatefulWidget
///    - 🎯 Root Cause: Architectural protocol violations
///    - 💥 Kill Shot: Extracted 7 functional builders into proper components
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(n) where n = number of tool calls
/// - Space Complexity: O(n) - expansion state storage
/// - Rebuild Frequency: Only when tool calls change or expansion toggles
class MessageToolCallsEnhanced extends StatefulWidget {
  /// Creates enhanced tool calls display following architecture protocols
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor with named parameters
  const MessageToolCallsEnhanced({
    super.key,
    required this.message,
    this.showDebugInfo = false,
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
  /// Track expansion state for each tool call by index
  ///
  /// PERF: O(1) expansion state lookup - efficient state management
  final Map<int, bool> _expandedStates = {};

  @override
  Widget build(BuildContext context) {
    // Show nothing if no tool calls
    final toolCalls = widget.message.toolCalls;
    if (toolCalls == null || toolCalls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.build,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Tool Calls (${toolCalls.length})',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Tool calls list using extracted components
          // ARCHITECTURAL VICTORY: Zero functional builders - all proper components
          Column(
            children: toolCalls
                .asMap()
                .entries
                .map((entry) => ToolCallCard(
                      index: entry.key,
                      toolCall: entry.value,
                      isExpanded: _expandedStates[entry.key] ?? false,
                      onToggleExpansion: () => _toggleExpansion(entry.key),
                      showDebugInfo: widget.showDebugInfo,
                      onToolCallTap: widget.onToolCallTap,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  /// Toggle expansion state for specific tool call
  ///
  /// PERF: O(1) state toggle - efficient expansion management
  void _toggleExpansion(int index) {
    setState(() {
      _expandedStates[index] = !(_expandedStates[index] ?? false);
    });
  }
}
