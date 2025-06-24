import 'package:flutter/material.dart';
import 'package:vibe_coder/components/discord_layout/placeholder_agent_list.dart';

/// LeftSidebarPanel - Agent Management Sidebar
///
/// ## 🏆 MISSION ACCOMPLISHED
/// **ELIMINATES FUNCTIONAL WIDGET BUILDER** - Extracts _buildLeftSidebarPanel()
/// from DiscordHomeScreen into proper StatelessWidget component following
/// Flutter Architecture Protocol.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | StatelessWidget | Pure display, reusable | No internal state | CHOSEN - follows architecture protocol |
/// | StatefulWidget | Internal state management | Unnecessary complexity | REJECTED - no state needed |
/// | Container Direct | Simple structure | Not reusable | REJECTED - violates component extraction |
/// | Scaffold Nested | Full screen control | Overkill | REJECTED - panel component not screen |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Crime**
///    - 🔍 Symptom: _buildLeftSidebarPanel() violating Flutter Architecture Protocol
///    - 🎯 Root Cause: Widget logic embedded in StatefulWidget build method
///    - 💥 Kill Shot: Extracted to reusable StatelessWidget component
///
/// 2. **Component Reusability Limitation**
///    - 🔍 Symptom: Left sidebar logic not reusable across different screens
///    - 🎯 Root Cause: Tight coupling to DiscordHomeScreen implementation
///    - 💥 Kill Shot: Standalone component with clear prop interface
///
/// 3. **Testing Isolation Challenge**
///    - 🔍 Symptom: Cannot test sidebar logic independently
///    - 🎯 Root Cause: Functional builder embedded in larger widget tree
///    - 💥 Kill Shot: Component can be tested in isolation with MockServices
///
/// ## PERFORMANCE PROFILE
/// - Widget creation: O(1) - direct Container with Column structure
/// - Theme application: O(1) - Theme.of(context) lookups
/// - Agent list rendering: O(n) - delegated to PlaceholderAgentList component
/// - Memory usage: O(1) - stateless widget with minimal state
/// - Rebuild efficiency: O(1) - rebuilds only when parent triggers rebuild
///
/// ARCHITECTURAL COMPLIANCE:
/// ✅ StatelessWidget (mandatory for UI components)
/// ✅ Zero functional widget builders (extracted to separate component)
/// ✅ Object-oriented callback pattern (onCreateAgent prop)
/// ✅ Component composition (uses PlaceholderAgentList)
/// ✅ Theme integration (respects app theme)
/// ✅ Single responsibility (agent sidebar only)
class LeftSidebarPanel extends StatelessWidget {
  /// Width of the left sidebar panel
  final double width;

  /// Callback for create agent button
  final VoidCallback? onCreateAgent;

  const LeftSidebarPanel({
    super.key,
    required this.width,
    this.onCreateAgent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        children: [
          // Panel header
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people_outline,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Agents',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),

          // Panel content - Agent list and create button
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Agent list component
                  PlaceholderAgentList(
                    onAgentTap: (agentName) {
                      // Agent selection handling - placeholder for DR008
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Selected $agentName - Integration pending DR008'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Create agent button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onCreateAgent,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Agent'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
