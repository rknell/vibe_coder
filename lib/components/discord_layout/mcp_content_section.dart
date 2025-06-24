import 'package:flutter/material.dart';

/// MCPContentSection - MCP Content Section Placeholder
///
/// ## 🏆 MISSION ACCOMPLISHED
/// **ELIMINATES FUNCTIONAL WIDGET BUILDER** - Extracts _buildMCPContentSection()
/// from DiscordHomeScreen into proper StatelessWidget component following
/// Flutter Architecture Protocol.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Container Direct | Simple structure, themed | Basic styling | CHOSEN - matches original implementation |
/// | Card Wrapper | Material elevation | Additional nesting | REJECTED - container sufficient for placeholder |
/// | ExpansionTile | Collapsible content | Unnecessary complexity | REJECTED - static placeholder content |
/// | Custom Painted | Complete visual control | Over-engineering | REJECTED - standard widgets adequate |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Crime**
///    - 🔍 Symptom: _buildMCPContentSection() violating Flutter Architecture Protocol
///    - 🎯 Root Cause: Widget logic embedded in StatefulWidget build method
///    - 💥 Kill Shot: Extracted to reusable StatelessWidget component
///
/// 2. **MCP Content Type Coupling**
///    - 🔍 Symptom: MCP section creation tightly coupled to DiscordHomeScreen
///    - 🎯 Root Cause: Hardcoded section parameters in functional builder
///    - 💥 Kill Shot: Parameterized component with flexible title/icon/description
///
/// 3. **Theme Consistency Challenge**
///    - 🔍 Symptom: Theme styling scattered throughout MCP section logic
///    - 🎯 Root Cause: Direct theme lookups embedded in functional builder
///    - 💥 Kill Shot: Centralized theme integration with consistent styling
///
/// ## PERFORMANCE PROFILE
/// - Widget creation: O(1) - Container with Column structure
/// - Theme lookups: O(1) - Theme.of(context) cached by framework
/// - Layout calculation: O(1) - simple column with fixed spacing
/// - Memory usage: O(1) - stateless widget with minimal properties
/// - Rebuild efficiency: O(1) - rebuilds only when parent triggers rebuild
///
/// ARCHITECTURAL COMPLIANCE:
/// ✅ StatelessWidget (mandatory for UI components)
/// ✅ Zero functional widget builders (pure component)
/// ✅ Single responsibility (MCP content section display)
/// ✅ Theme integration (respects app theme for consistent styling)
/// ✅ Parameterized design (flexible title, icon, description)
/// ✅ Component reusability (can be used for different MCP content types)
class MCPContentSection extends StatelessWidget {
  /// Section title (e.g., "Notepad", "Todo", "Inbox")
  final String title;

  /// Section icon
  final IconData icon;

  /// Section description text
  final String description;

  const MCPContentSection({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}
