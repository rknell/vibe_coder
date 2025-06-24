import 'package:flutter/material.dart';
import 'package:vibe_coder/components/discord_layout/placeholder_agent_item.dart';

/// PlaceholderAgentList - Agent List Placeholder Component
///
/// ## 🏆 MISSION ACCOMPLISHED
/// **ELIMINATES FUNCTIONAL WIDGET BUILDER** - Extracts _buildPlaceholderAgentList()
/// from DiscordHomeScreen into proper StatelessWidget component following
/// Flutter Architecture Protocol.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | ListView.builder | Dynamic sizing, efficient | Overkill for static | REJECTED - static placeholder list |
/// | Column + SingleChildScrollView | Simple structure | No item virtualization | REJECTED - want scrolling |
/// | Expanded ListView | Fits parent, scrollable | Static content | CHOSEN - matches original behavior |
/// | Stack Absolute | Custom positioning | Complex layout | REJECTED - standard list is adequate |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Crime**
///    - 🔍 Symptom: _buildPlaceholderAgentList() violating Flutter Architecture Protocol
///    - 🎯 Root Cause: Widget logic embedded in StatefulWidget build method
///    - 💥 Kill Shot: Extracted to reusable StatelessWidget component
///
/// 2. **Component Testability Limitation**
///    - 🔍 Symptom: Cannot test agent list rendering independently
///    - 🎯 Root Cause: Functional builder embedded in larger widget tree
///    - 💥 Kill Shot: Component can be tested in isolation with mock data
///
/// 3. **Agent Item Coupling**
///    - 🔍 Symptom: Agent item creation tightly coupled to list logic
///    - 🎯 Root Cause: Direct _buildPlaceholderAgentItem() calls in builder
///    - 💥 Kill Shot: Delegates to PlaceholderAgentItem component
///
/// ## PERFORMANCE PROFILE
/// - Widget creation: O(1) - Expanded with ListView containing 3 static items
/// - Agent item rendering: O(n) - delegated to PlaceholderAgentItem components
/// - Memory usage: O(1) - stateless widget with static placeholder data
/// - Rebuild efficiency: O(1) - rebuilds only when parent triggers rebuild
/// - Scroll performance: O(1) - minimal items, no virtualization needed
///
/// ARCHITECTURAL COMPLIANCE:
/// ✅ StatelessWidget (mandatory for UI components)
/// ✅ Zero functional widget builders (uses component composition)
/// ✅ Object-oriented callback pattern (onAgentTap prop delegation)
/// ✅ Component composition (uses PlaceholderAgentItem)
/// ✅ Theme integration (delegated to child components)
/// ✅ Single responsibility (agent list placeholder only)
class PlaceholderAgentList extends StatelessWidget {
  /// Callback when an agent item is tapped
  final void Function(String agentName)? onAgentTap;

  const PlaceholderAgentList({
    super.key,
    this.onAgentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        children: [
          PlaceholderAgentItem(
            name: 'VibeCoder Assistant',
            isActive: true,
            onTap: onAgentTap,
          ),
          PlaceholderAgentItem(
            name: 'Code Reviewer',
            isActive: false,
            onTap: onAgentTap,
          ),
          PlaceholderAgentItem(
            name: 'Flutter Expert',
            isActive: false,
            onTap: onAgentTap,
          ),
        ],
      ),
    );
  }
}
