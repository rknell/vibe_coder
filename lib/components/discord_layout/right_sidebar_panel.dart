import 'package:flutter/material.dart';
import 'package:vibe_coder/components/discord_layout/mcp_content_section.dart';

/// RightSidebarPanel - MCP Content Management Sidebar
///
/// ## 🏆 MISSION ACCOMPLISHED
/// **IMPLEMENTS COMPONENT ARCHITECTURE** - Creates reusable right sidebar panel
/// from DiscordHomeScreen into proper StatelessWidget component following
/// Flutter Architecture Protocol.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | StatelessWidget | Pure display, reusable | No internal state | CHOSEN - follows architecture protocol |
/// | StatefulWidget | Internal state management | Unnecessary complexity | REJECTED - no state needed |
/// | Container Direct | Simple structure | Not reusable | REJECTED - violates component extraction |
/// | Drawer Implementation | Native navigation | Wrong pattern | REJECTED - fixed sidebar not drawer |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Crime**
///    - 🔍 Symptom: Right sidebar panel logic embedded in parent screen widget
///    - 🎯 Root Cause: Widget logic embedded in StatefulWidget build method
///    - 💥 Kill Shot: Extracted to reusable StatelessWidget component
///
/// 2. **MCP Content Organization Challenge**
///    - 🔍 Symptom: MCP content sections scattered throughout build logic
///    - 🎯 Root Cause: Direct section creation in functional builder
///    - 💥 Kill Shot: Component composition with MCPContentSection instances
///
/// 3. **Testing Isolation Limitation**
///    - 🔍 Symptom: Cannot test MCP sidebar logic independently
///    - 🎯 Root Cause: Functional builder embedded in larger widget tree
///    - 💥 Kill Shot: Component can be tested in isolation with mock data
///
/// ## PERFORMANCE PROFILE
/// - Widget creation: O(1) - Container with Column structure
/// - Theme application: O(1) - Theme.of(context) lookups
/// - MCP section rendering: O(n) - delegated to MCPContentSection components
/// - Memory usage: O(1) - stateless widget with minimal state
/// - Rebuild efficiency: O(1) - rebuilds only when parent triggers rebuild
///
/// ARCHITECTURAL COMPLIANCE:
/// ✅ StatelessWidget (mandatory for UI components)
/// ✅ Zero functional widget builders (extracted to separate component)
/// ✅ Component composition (uses MCPContentSection)
/// ✅ Theme integration (respects app theme)
/// ✅ Single responsibility (MCP content sidebar only)
/// ✅ Parameterized design (configurable width)
class RightSidebarPanel extends StatelessWidget {
  /// Width of the right sidebar panel
  final double width;

  const RightSidebarPanel({
    super.key,
    required this.width,
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
                  Icons.note_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'MCP Content',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),

          // Panel content - MCP content sections
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MCP content sections
                  MCPContentSection(
                    title: 'Notepad',
                    icon: Icons.note_add_outlined,
                    description: 'AI notepad content will appear here',
                  ),
                  SizedBox(height: 16),
                  MCPContentSection(
                    title: 'Todo',
                    icon: Icons.checklist_outlined,
                    description: 'AI todo items will appear here',
                  ),
                  SizedBox(height: 16),
                  MCPContentSection(
                    title: 'Inbox',
                    icon: Icons.inbox_outlined,
                    description: 'AI inbox messages will appear here',
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
