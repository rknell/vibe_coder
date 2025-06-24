import 'package:flutter/material.dart';
import 'package:vibe_coder/components/discord_layout/mcp_content_section.dart';
import 'package:vibe_coder/models/agent_model.dart';

/// RightSidebarPanel - Enhanced Dynamic MCP Content Sidebar
///
/// ## 🏆 MISSION ACCOMPLISHED
/// **TRANSFORMS STATIC PLACEHOLDERS INTO DYNAMIC MCP CONTENT DISPLAY** - Eliminates
/// static placeholder sections and implements real-time Discord-style MCP content
/// with reactive updates and agent-specific data display.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | ListenableBuilder | Reactive updates | Minor overhead | CHOSEN - real-time agent content sync |
/// | StatefulWidget | Direct state management | Complexity | REJECTED - violates architecture protocol |
/// | StreamBuilder | Async updates | Overkill | REJECTED - ChangeNotifier sufficient |
/// | Manual setState | Direct control | Breaks reactivity | REJECTED - not reactive pattern |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Static Placeholder Elimination**
///    - 🔍 Symptom: Hard-coded placeholder content with no real data
///    - 🎯 Root Cause: MCPContentSection displaying static descriptions
///    - 💥 Kill Shot: Dynamic content sections with agent-specific MCP data
///
/// 2. **Agent Content Isolation Missing**
///    - 🔍 Symptom: No connection between selected agent and displayed content
///    - 🎯 Root Cause: Static components with no agent parameter
///    - 💥 Kill Shot: Agent-aware components with selectedAgent parameter
///
/// 3. **Real-Time Update Absence**
///    - 🔍 Symptom: Content not updating when agent data changes
///    - 🎯 Root Cause: No reactive patterns for agent data updates
///    - 💥 Kill Shot: ListenableBuilder for automatic UI updates
///
/// 4. **Discord UX Pattern Missing**
///    - 🔍 Symptom: Basic container layout without interactivity
///    - 🎯 Root Cause: Static component design philosophy
///    - 💥 Kill Shot: Collapsible ExpansionTile sections with content badges
///
/// ## PERFORMANCE PROFILE
/// - Agent switching: O(1) - parameter passing with automatic rebuild
/// - Content rendering: O(n) where n = total MCP content items across sections
/// - Reactive updates: O(1) - ListenableBuilder selective rebuild optimization
/// - Memory usage: O(n) - proportional to agent MCP content size
/// - Empty state handling: O(1) - conditional rendering patterns
/// - Expansion state: O(1) - native Flutter ExpansionTile performance
///
/// ARCHITECTURAL COMPLIANCE:
/// ✅ StatelessWidget (mandatory for UI components)
/// ✅ Zero functional widget builders (pure component extraction)
/// ✅ ListenableBuilder positioning (strategic reactive updates)
/// ✅ Agent-oriented design (selectedAgent parameter integration)
/// ✅ Discord-style UX (collapsible sections with interactive elements)
/// ✅ Single source of truth (agent MCP data as authoritative source)

/// MCPContentEmptyStateWidget - Agent Selection Empty State Component
///
/// ## 🏆 MISSION ACCOMPLISHED
/// **PROFESSIONAL EMPTY STATE WITH USER GUIDANCE** - Extracted from functional widget builder
/// to proper component following warrior protocol architecture standards.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Component Extraction | Architectural compliance | Code reorganization | CHOSEN - eliminates functional builders |
/// | Professional Guidance | User experience | UI complexity | CHOSEN - Discord-style empty states |
/// | Icon-Based Design | Visual clarity | Accessibility | CHOSEN - industry standard patterns |
/// | Responsive Typography | All screen sizes | Font management | CHOSEN - professional polish |
/// | Centered Layout | Balance and focus | Layout complexity | CHOSEN - user attention direction |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Elimination**
///    - 🔍 Symptom: _buildEmptyState violates Flutter architecture protocol
///    - 🎯 Root Cause: Widget building logic embedded in parent component
///    - 💥 Kill Shot: Proper StatelessWidget component with professional UX
///
/// 2. **Empty State User Experience**
///    - 🔍 Symptom: Users confused when no agent selected
///    - 🎯 Root Cause: No clear guidance for next user action
///    - 💥 Kill Shot: Professional empty state with clear instructions
///
/// 3. **Theme Integration Challenge**
///    - 🔍 Symptom: Empty state not properly integrated with theme system
///    - 🎯 Root Cause: Hardcoded colors and opacity values
///    - 💥 Kill Shot: Dynamic theme color application with proper opacity
///
/// ## PERFORMANCE PROFILE
/// - Widget creation: O(1) - Center with Column structure
/// - Theme application: O(1) - Theme.of(context) lookups
/// - Icon rendering: O(1) - single icon widget
/// - Text rendering: O(1) - fixed text widgets
/// - Memory usage: O(1) - static widget tree structure
/// - Rebuild efficiency: O(1) - rebuilds only when theme changes
///
/// ARCHITECTURAL COMPLIANCE:
/// ✅ StatelessWidget (mandatory for UI components)
/// ✅ Zero functional widget builders (pure component extraction)
/// ✅ Zero props (self-contained empty state)
/// ✅ Theme integration (dynamic color application)
/// ✅ Proper component separation (empty state logic isolated)
/// ✅ Professional UX patterns (industry standard empty state)
class MCPContentEmptyStateWidget extends StatelessWidget {
  const MCPContentEmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Select an Agent',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose an agent from the sidebar to view\ntheir MCP content and workspace',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class RightSidebarPanel extends StatelessWidget {
  /// Width of the right sidebar panel
  final double width;

  /// Selected agent for MCP content display (null shows empty state)
  final AgentModel? selectedAgent;

  const RightSidebarPanel({
    super.key,
    required this.width,
    this.selectedAgent,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'MCP Content',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      if (selectedAgent != null)
                        Text(
                          selectedAgent!.name,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Panel content - Dynamic MCP content sections with reactive updates
          Expanded(
            child: selectedAgent != null
                ? ListenableBuilder(
                    listenable: selectedAgent!,
                    builder: (context, child) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Notepad section
                            MCPNotepadSection(
                              selectedAgent: selectedAgent,
                              initiallyExpanded: true,
                            ),
                            const SizedBox(height: 12),

                            // Todo section
                            MCPTodoSection(
                              selectedAgent: selectedAgent,
                              initiallyExpanded: false,
                            ),
                            const SizedBox(height: 12),

                            // Inbox section
                            MCPInboxSection(
                              selectedAgent: selectedAgent,
                              initiallyExpanded: false,
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : const MCPContentEmptyStateWidget(),
          ),
        ],
      ),
    );
  }
}
