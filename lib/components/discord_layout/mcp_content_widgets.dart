import 'package:flutter/material.dart';
import '../../models/agent_model.dart';

/// Build notepad content display
class MCPNotepadContentWidget extends StatelessWidget {
  /// The notepad content to display
  final String content;

  /// Creates an MCP notepad content widget
  ///
  /// ## 🏆 COMPONENT CONQUEST REPORT
  ///
  /// ### 🎯 MISSION ACCOMPLISHED
  /// Extracted functional widget builder `_buildNotepadContent` from MCPNotepadSection
  /// into proper StatelessWidget component following Flutter architecture protocols.
  ///
  /// ### ⚔️ STRATEGIC DECISIONS
  /// | Option | Power-Ups | Weaknesses | Victory Reason |
  /// |--------|-----------|------------|----------------|
  /// | StatelessWidget | Zero state, pure display, reusable | None | Perfect for content display |
  /// | Extract as component | Clean architecture, testable | Slight complexity | Architecture compliance |
  /// | Keep as builder | Simple code | Violates protocols | BANNED by flutter_architecture.mdc |
  ///
  /// ### 💀 BOSS FIGHTS DEFEATED
  /// 1. **Functional Widget Builder Violation**
  ///    - 🔍 Symptom: _buildNotepadContent method creating UI imperatively
  ///    - 🎯 Root Cause: Architecture protocol violation - functional builders banned
  ///    - 💥 Kill Shot: Extracted to StatelessWidget with content preview functionality
  ///
  /// ### 🚀 PERFORMANCE PROFILE
  /// - Widget creation: O(1) - Direct widget instantiation
  /// - Content preview: O(n) where n is preview length (max 200 chars)
  /// - Memory usage: Minimal - Single content display container
  /// - Rebuild efficiency: Optimal - Pure StatelessWidget with immutable props
  ///
  /// ### 🎮 USAGE PATTERNS
  /// ```dart
  /// MCPNotepadContentWidget(content: notepadText)
  /// ```
  ///
  /// ### 🛡️ ARCHITECTURAL COMPLIANCE
  /// - ✅ StatelessWidget component extraction
  /// - ✅ Object-oriented parameter passing (whole string)
  /// - ✅ Immutable widget design
  /// - ✅ Zero functional widget builders
  /// - ✅ Component separation following warrior protocols
  const MCPNotepadContentWidget({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final preview = _getContentPreview(content);
    final hasMore = content.length > preview.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.4,
                ),
          ),
          if (hasMore) ...[
            const SizedBox(height: 8),
            Text(
              '... (${content.length - preview.length} more characters)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get content preview for display (first 200 characters)
  String _getContentPreview(String content, {int maxLength = 200}) {
    if (content.length <= maxLength) return content;

    // Find a good break point near the limit
    final cutoff = content.substring(0, maxLength);
    final lastSpace = cutoff.lastIndexOf(' ');
    final lastNewline = cutoff.lastIndexOf('\n');

    final breakPoint = [lastSpace, lastNewline]
        .where((i) => i > 0)
        .fold(0, (a, b) => a > b ? a : b);

    return breakPoint > 0 ? content.substring(0, breakPoint) : cutoff;
  }
}

/// Build empty state for notepad section
class MCPNotepadEmptyStateWidget extends StatelessWidget {
  /// The selected agent for contextual messaging
  final AgentModel? selectedAgent;

  /// Creates an MCP notepad empty state widget
  ///
  /// ## 🏆 COMPONENT CONQUEST REPORT
  ///
  /// ### 🎯 MISSION ACCOMPLISHED
  /// Extracted functional widget builder `_buildEmptyState` from MCPNotepadSection
  /// into proper StatelessWidget component following Flutter architecture protocols.
  ///
  /// ### ⚔️ STRATEGIC DECISIONS
  /// | Option | Power-Ups | Weaknesses | Victory Reason |
  /// |--------|-----------|------------|----------------|
  /// | StatelessWidget | Zero state, pure display, reusable | None | Perfect for empty state |
  /// | Extract as component | Clean architecture, testable | Slight complexity | Architecture compliance |
  /// | Keep as builder | Simple code | Violates protocols | BANNED by flutter_architecture.mdc |
  ///
  /// ### 💀 BOSS FIGHTS DEFEATED
  /// 1. **Functional Widget Builder Violation**
  ///    - 🔍 Symptom: _buildEmptyState method creating UI imperatively
  ///    - 🎯 Root Cause: Architecture protocol violation - functional builders banned
  ///    - 💥 Kill Shot: Extracted to StatelessWidget with contextual agent support
  ///
  /// ### 🚀 PERFORMANCE PROFILE
  /// - Widget creation: O(1) - Direct widget instantiation
  /// - Memory usage: Minimal - Static empty state display
  /// - Rebuild efficiency: Optimal - Pure StatelessWidget with immutable props
  ///
  /// ### 🎮 USAGE PATTERNS
  /// ```dart
  /// MCPNotepadEmptyStateWidget(selectedAgent: agent)
  /// ```
  ///
  /// ### 🛡️ ARCHITECTURAL COMPLIANCE
  /// - ✅ StatelessWidget component extraction
  /// - ✅ Object-oriented parameter passing (whole AgentModel)
  /// - ✅ Immutable widget design
  /// - ✅ Zero functional widget builders
  /// - ✅ Component separation following warrior protocols
  const MCPNotepadEmptyStateWidget({
    super.key,
    this.selectedAgent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.note_outlined,
            size: 48,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            selectedAgent == null
                ? 'Select an agent to view notepad'
                : 'No notepad content',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
