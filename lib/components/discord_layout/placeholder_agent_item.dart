import 'package:flutter/material.dart';

/// PlaceholderAgentItem - Individual Agent Item Placeholder
///
/// ## 🏆 MISSION ACCOMPLISHED
/// **ELIMINATES FUNCTIONAL WIDGET BUILDER** - Extracts _buildPlaceholderAgentItem()
/// from DiscordHomeScreen into proper StatelessWidget component following
/// Flutter Architecture Protocol.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | ListTile | Standard Material Design | Limited customization | CHOSEN - matches original implementation |
/// | Custom Row/Column | Full control | More complex | REJECTED - ListTile sufficient |
/// | Card wrapper | Enhanced visual hierarchy | Additional nesting | REJECTED - sidebar context doesn't need card |
/// | InkWell custom | Complete tap control | Manual accessibility | REJECTED - ListTile handles accessibility |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Crime**
///    - 🔍 Symptom: _buildPlaceholderAgentItem() violating Flutter Architecture Protocol
///    - 🎯 Root Cause: Widget logic embedded in StatefulWidget build method
///    - 💥 Kill Shot: Extracted to reusable StatelessWidget component
///
/// 2. **Agent Selection Coupling**
///    - 🔍 Symptom: Agent selection logic tightly coupled to DiscordHomeScreen
///    - 🎯 Root Cause: Hardcoded SnackBar in functional builder
///    - 💥 Kill Shot: Callback pattern allows flexible parent handling
///
/// 3. **Visual State Management**
///    - 🔍 Symptom: Active state styling scattered throughout build logic
///    - 🎯 Root Cause: Conditional styling embedded in functional builder
///    - 💥 Kill Shot: Clean conditional styling with clear active state logic
///
/// ## PERFORMANCE PROFILE
/// - Widget creation: O(1) - ListTile with conditional styling
/// - Theme lookups: O(1) - Theme.of(context) cached by framework
/// - Conditional rendering: O(1) - boolean checks for active state
/// - Memory usage: O(1) - stateless widget with minimal properties
/// - Tap handling: O(1) - direct callback invocation
///
/// ARCHITECTURAL COMPLIANCE:
/// ✅ StatelessWidget (mandatory for UI components)
/// ✅ Zero functional widget builders (pure component)
/// ✅ Object-oriented callback pattern (onTap with agent name)
/// ✅ Single responsibility (individual agent item display)
/// ✅ Theme integration (respects app theme with conditional styling)
/// ✅ Accessibility support (ListTile provides semantics)
class PlaceholderAgentItem extends StatelessWidget {
  /// Agent display name
  final String name;

  /// Whether this agent is currently active
  final bool isActive;

  /// Callback when agent item is tapped
  final void Function(String agentName)? onTap;

  const PlaceholderAgentItem({
    super.key,
    required this.name,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.smart_toy_outlined,
          color: isActive
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          size: 20,
        ),
      ),
      title: Text(
        name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
      ),
      trailing: isActive
          ? Icon(
              Icons.circle,
              size: 8,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () => onTap?.call(name),
    );
  }
}
