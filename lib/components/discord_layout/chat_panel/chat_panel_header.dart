import 'package:flutter/material.dart';
import 'package:vibe_coder/models/layout_preferences_model.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/models/agent_status_model.dart';

/// ChatPanelHeader - Discord-Style Chat Panel Header Component
///
/// ## 🏆 MISSION ACCOMPLISHED
/// **DISCORD-STYLE CHAT HEADER WITH AGENT CONTEXT** - Extracted from functional widget builder
/// to proper component following warrior protocol architecture standards.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Component Extraction | Architectural compliance | Code reorganization | CHOSEN - eliminates functional builders |
/// | Agent Context Display | Rich UI information | Complexity | CHOSEN - Discord-style UX patterns |
/// | Status Indicator | Visual feedback | Color management | CHOSEN - professional status display |
/// | Toolbar Actions | Feature accessibility | Button management | CHOSEN - agent controls integration |
/// | Responsive Layout | All screen sizes | Layout complexity | CHOSEN - professional responsive design |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Elimination**
///    - 🔍 Symptom: _buildChatPanelHeader violates Flutter architecture protocol
///    - 🎯 Root Cause: Widget building logic embedded in parent component
///    - 💥 Kill Shot: Proper StatelessWidget component with comprehensive props
///
/// 2. **Agent Status Coordination**
///    - 🔍 Symptom: Status display logic scattered across component
///    - 🎯 Root Cause: No centralized status color management
///    - 💥 Kill Shot: Dedicated status color method with AgentProcessingStatus integration
///
/// 3. **Theme Integration Challenge**
///    - 🔍 Symptom: Theme switching not properly integrated with header
///    - 🎯 Root Cause: Theme logic embedded in parent component
///    - 💥 Kill Shot: Theme icon method with AppTheme enum support
///
/// ## PERFORMANCE PROFILE
/// - Widget creation: O(1) - Container with Row structure
/// - Agent status lookup: O(1) - switch statement on enum
/// - Theme icon lookup: O(1) - switch statement on enum
/// - Button press handling: O(1) - direct callback invocation
/// - Memory usage: O(1) - fixed widget tree structure
/// - Rebuild efficiency: O(1) - rebuilds only when props change
///
/// ARCHITECTURAL COMPLIANCE:
/// ✅ StatelessWidget (mandatory for UI components)
/// ✅ Zero functional widget builders (pure component extraction)
/// ✅ Object-oriented callback pattern (all actions via props)
/// ✅ Single source of truth (AgentModel passed as reference)
/// ✅ Proper component separation (header logic isolated)
/// ✅ Warrior protocol documentation (comprehensive strategy log)
class ChatPanelHeader extends StatelessWidget {
  /// Current theme for theme toggle button
  final AppTheme currentTheme;

  /// Selected agent for header display (null shows default state)
  final AgentModel? selectedAgent;

  /// Callback for theme toggle button
  final VoidCallback? onThemeToggle;

  /// Callback for left sidebar toggle
  final VoidCallback? onToggleLeftSidebar;

  /// Callback for right sidebar toggle
  final VoidCallback? onToggleRightSidebar;

  /// Callback for editing agent configuration
  final void Function(AgentModel)? onAgentEdit;

  /// Callback for clearing agent conversation
  final void Function(AgentModel)? onClearConversation;

  const ChatPanelHeader({
    super.key,
    required this.currentTheme,
    this.selectedAgent,
    this.onThemeToggle,
    this.onToggleLeftSidebar,
    this.onToggleRightSidebar,
    this.onAgentEdit,
    this.onClearConversation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Left sidebar toggle button
          IconButton(
            onPressed: onToggleLeftSidebar,
            icon: const Icon(Icons.menu),
            tooltip: 'Toggle agents sidebar',
          ),

          // Agent context section
          if (selectedAgent != null) ...[
            // Agent status indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getAgentStatusColor(context, selectedAgent!),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),

            // Agent name
            Expanded(
              child: Text(
                selectedAgent!.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Agent configuration button
            IconButton(
              onPressed: onAgentEdit != null
                  ? () => onAgentEdit!(selectedAgent!)
                  : null,
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Edit agent settings',
            ),

            // Clear conversation button
            IconButton(
              onPressed: onClearConversation != null &&
                      selectedAgent!.conversationHistory.isNotEmpty
                  ? () => onClearConversation!(selectedAgent!)
                  : null,
              icon: const Icon(Icons.clear_all_outlined),
              tooltip: 'Clear conversation',
              style: IconButton.styleFrom(
                foregroundColor: selectedAgent!.conversationHistory.isNotEmpty
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).disabledColor,
              ),
            ),
          ] else ...[
            // Default chat icon and title when no agent selected
            Icon(
              Icons.chat_outlined,
              color: Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Chat',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // Theme toggle button
          IconButton(
            onPressed: onThemeToggle,
            icon: Icon(_getThemeIcon(currentTheme)),
            tooltip: 'Toggle theme',
          ),

          // Right sidebar toggle button
          IconButton(
            onPressed: onToggleRightSidebar,
            icon: const Icon(Icons.view_sidebar),
            tooltip: 'Toggle MCP content sidebar',
          ),
        ],
      ),
    );
  }

  /// Get agent status color for visual feedback
  ///
  /// PERF: O(1) - simple status color mapping
  /// INTEGRATION: Agent status model integration for visual indicators
  Color _getAgentStatusColor(BuildContext context, AgentModel agent) {
    switch (agent.processingStatus) {
      case AgentProcessingStatus.idle:
        return Colors.green;
      case AgentProcessingStatus.processing:
        return Colors.orange;
      case AgentProcessingStatus.error:
        return Colors.red;
    }
  }

  /// Get theme icon based on current theme
  ///
  /// PERF: O(1) - simple switch statement
  IconData _getThemeIcon(AppTheme theme) {
    switch (theme) {
      case AppTheme.dark:
        return Icons.dark_mode_outlined;
      case AppTheme.light:
        return Icons.light_mode_outlined;
      case AppTheme.system:
        return Icons.brightness_auto_outlined;
    }
  }
}
