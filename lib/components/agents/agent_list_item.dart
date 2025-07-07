import 'package:flutter/material.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/models/agent_status_model.dart';
import 'package:vibe_coder/components/agents/agent_status_indicator.dart';

/// AgentAvatar - Discord-style Agent Avatar with Initials
///
/// COMPONENT ARCHITECTURE: Extracted from functional widget builder
/// Provides reusable avatar display with initials fallback
class AgentAvatar extends StatelessWidget {
  final String agentName;
  final bool isSelected;

  const AgentAvatar({
    super.key,
    required this.agentName,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Text(
          _generateAvatarInitials(agentName),
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Generate avatar initials from agent name
  ///
  /// PERFORMANCE: O(n) where n = agent name length
  /// LOGIC: Extract first letter of each word, max 2 characters
  String _generateAvatarInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }

    // Take first letter of first two words
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }
}

/// AgentListItem - Discord-style Individual Agent List Item
///
/// ## 🏆 MISSION ACCOMPLISHED
/// **IMPLEMENTS COMPONENT ARCHITECTURE** - Creates reusable agent list item
/// with Discord-style selection highlighting, status indicators, and avatar initials.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | ListTile | Built-in structure | Limited customization | REJECTED - need Discord styling |
/// | Container + Row | Full control | More verbose | CHOSEN - Discord-style layout needed |
/// | Card widget | Material elevation | Card semantics | REJECTED - list item not card |
/// | InkWell + padding | Ripple effects | Manual layout | CONSIDERED - good for interactions |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Agent Selection Visual Feedback**
///    - 🔍 Symptom: Need to show active agent with different styling
///    - 🎯 Root Cause: Discord-style selection highlighting required
///    - 💥 Kill Shot: Conditional background color and font weight styling
///
/// 2. **Avatar Initials Generation**
///    - 🔍 Symptom: Need agent avatar fallback for missing images
///    - 🎯 Root Cause: Agent name needs to generate display initials
///    - 💥 Kill Shot: AgentAvatar component with name parsing logic
///
/// 3. **Status Integration Challenge**
///    - 🔍 Symptom: Agent status needs visual representation in list item
///    - 🎯 Root Cause: AgentModel status fields need UI integration
///    - 💥 Kill Shot: AgentStatusIndicator component integration
///
/// ## PERFORMANCE PROFILE
/// - Widget creation: O(1) - simple Container with Row layout
/// - Avatar initials generation: O(n) where n = agent name length
/// - Status indicator rendering: O(1) - delegated to status component
/// - Memory usage: O(1) - stateless widget with AgentModel reference
/// - Rebuild efficiency: O(1) - rebuilds only when agent data changes
///
/// ARCHITECTURAL COMPLIANCE:
/// ✅ StatelessWidget (mandatory for UI components)
/// ✅ Zero functional widget builders (pure widget composition)
/// ✅ Object-oriented interface (receives whole AgentModel object)
/// ✅ Single source of truth (AgentModel reference, no data extraction)
/// ✅ Component composition (uses AgentStatusIndicator + AgentAvatar)
/// ✅ Theme integration (Discord-style theming)
class AgentListItem extends StatelessWidget {
  /// The agent to display (single source of truth)
  final AgentModel agent;

  /// Whether this agent is currently selected/active
  final bool isSelected;

  /// Callback when agent is tapped (object-oriented pattern)
  final void Function(AgentModel?)? onTap;

  const AgentListItem({
    super.key,
    required this.agent,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap?.call(agent), // Pass whole object
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3)
                : null,
          ),
          child: Row(
            children: [
              // Agent Avatar with Initials
              AgentAvatar(
                agentName: agent.name,
                isSelected: isSelected,
              ),

              const SizedBox(width: 12),

              // Agent Name and Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Agent Name
                        Expanded(
                          child: Text(
                            agent.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Status Indicator
                        AgentStatusIndicator(
                          status: agent.processingStatus,
                          size: 8,
                          showBorder: true,
                        ),
                      ],
                    ),

                    // Subtle status text (optional)
                    if (agent.processingStatus != AgentProcessingStatus.idle)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _getStatusText(agent.processingStatus),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get human-readable status text
  ///
  /// PERFORMANCE: O(1) - direct enum mapping
  String _getStatusText(AgentProcessingStatus status) {
    switch (status) {
      case AgentProcessingStatus.idle:
        return 'Ready';
      case AgentProcessingStatus.processing:
        return 'Processing...';
      case AgentProcessingStatus.error:
        return 'Error';
    }
  }
}
