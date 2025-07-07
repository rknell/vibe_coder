import 'package:flutter/material.dart';
import 'package:vibe_coder/models/layout_preferences_model.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/components/discord_layout/chat_panel/chat_panel_header.dart';
import 'package:vibe_coder/components/discord_layout/chat_panel/chat_interface_container.dart';
import 'package:vibe_coder/components/discord_layout/chat_panel/chat_empty_state.dart';

/// CenterChatPanel - Enhanced Discord-Style Chat Interface
///
/// ## 🏆 MISSION ACCOMPLISHED
/// **DISCORD-STYLE CHAT PANEL WITH COMPONENT ARCHITECTURE** - Transforms placeholder content
/// into fully functional chat interface with proper component extraction and Discord UX patterns.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Component Extraction | Architectural compliance | Code reorganization | CHOSEN - eliminates functional builders |
/// | MessagingUI Integration | Full chat functionality | Component coupling | CHOSEN - preserves all features |
/// | Agent Header Display | Discord-style UX | More complexity | CHOSEN - follows Discord patterns |
/// | Conversation Switching | Smooth UX | State management | CHOSEN - essential for multi-agent workflow |
/// | Empty State Handling | User guidance | Additional logic | CHOSEN - professional UX standards |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Architectural Violation**
///    - 🔍 Symptom: Three functional builders (_buildChatPanelHeader, _buildChatInterface, _buildEmptyState) violating Flutter architecture protocol
///    - 🎯 Root Cause: Widget building logic embedded in main component
///    - 💥 Kill Shot: Complete component extraction to ChatPanelHeader, ChatInterfaceContainer, ChatEmptyState
///
/// 2. **Agent Selection Coordination**
///    - 🔍 Symptom: Chat panel not responding to agent selection changes
///    - 🎯 Root Cause: No agent context or conversation switching logic
///    - 💥 Kill Shot: Agent prop with reactive conversation display and state management
///
/// 3. **Discord-Style Integration Challenge**
///    - 🔍 Symptom: Generic header without agent context and MCP integration
///    - 🎯 Root Cause: Header showing static "Chat" text instead of agent information
///    - 💥 Kill Shot: Dynamic header with agent name, configuration access, and status indicators
///
/// ## PERFORMANCE PROFILE
/// - Widget creation: O(1) - Container with Column structure
/// - Theme application: O(1) - Theme.of(context) lookups
/// - Agent switching: O(1) - direct agent reference update
/// - Conversation loading: O(n) where n = message count (delegated to ChatInterfaceContainer)
/// - Memory usage: O(n) - current conversation messages in memory
/// - Rebuild efficiency: O(1) - rebuilds only when agent or messages change
///
/// ARCHITECTURAL COMPLIANCE:
/// ✅ StatelessWidget (mandatory for UI components)
/// ✅ Zero functional widget builders (complete elimination achieved)
/// ✅ Object-oriented callback pattern (onSendMessage, onClearConversation, onAgentEdit props)
/// ✅ Single source of truth (AgentModel passed as reference)
/// ✅ Component extraction (ChatPanelHeader, ChatInterfaceContainer, ChatEmptyState)
/// ✅ Discord-style UI patterns (header with agent info and controls)
class CenterChatPanel extends StatelessWidget {
  /// Current theme for theme toggle button
  final AppTheme currentTheme;

  /// Selected agent for chat display (null shows empty state)
  final AgentModel? selectedAgent;

  /// Callback for theme toggle button
  final VoidCallback? onThemeToggle;

  /// Callback for left sidebar toggle
  final VoidCallback? onToggleLeftSidebar;

  /// Callback for right sidebar toggle
  final VoidCallback? onToggleRightSidebar;

  /// Callback for sending messages to selected agent
  final void Function(AgentModel, String)? onSendMessage;

  /// Callback for clearing agent conversation
  final void Function(AgentModel)? onClearConversation;

  /// Callback for editing agent configuration
  final void Function(AgentModel)? onAgentEdit;

  /// Callback for opening debug overlay
  final VoidCallback? onDebugOverlay;

  const CenterChatPanel({
    super.key,
    required this.currentTheme,
    this.selectedAgent,
    this.onThemeToggle,
    this.onToggleLeftSidebar,
    this.onToggleRightSidebar,
    this.onSendMessage,
    this.onClearConversation,
    this.onAgentEdit,
    this.onDebugOverlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Enhanced Panel Header with Agent Context
          ChatPanelHeader(
            currentTheme: currentTheme,
            selectedAgent: selectedAgent,
            onThemeToggle: onThemeToggle,
            onToggleLeftSidebar: onToggleLeftSidebar,
            onToggleRightSidebar: onToggleRightSidebar,
            onAgentEdit: onAgentEdit,
            onClearConversation: onClearConversation,
            onDebugOverlay: onDebugOverlay,
          ),

          // Main Chat Content Area
          Expanded(
            child: selectedAgent != null
                ? ChatInterfaceContainer(
                    selectedAgent: selectedAgent!,
                    onSendMessage: onSendMessage,
                    onClearConversation: onClearConversation,
                  )
                : const ChatEmptyState(),
          ),
        ],
      ),
    );
  }
}
