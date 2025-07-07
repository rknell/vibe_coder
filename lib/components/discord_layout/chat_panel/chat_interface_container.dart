import 'package:flutter/material.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/components/messaging_ui.dart';

/// ChatInterfaceContainer - MessagingUI Integration Component
///
/// ## 🏆 MISSION ACCOMPLISHED
/// **MESSAGINGUI INTEGRATION WITH REACTIVE AGENT CONTEXT** - Extracted from functional widget builder
/// to proper component following warrior protocol architecture standards.
///
/// ## ⚔️ STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Component Extraction | Architectural compliance | Code reorganization | CHOSEN - eliminates functional builders |
/// | MessagingUI Integration | Full chat functionality | Component coupling | CHOSEN - preserves all features |
/// | ListenableBuilder Pattern | Reactive updates | Rebuild management | CHOSEN - optimal performance |
/// | Agent Context Display | Dynamic placeholders | State management | CHOSEN - professional UX |
/// | Callback Delegation | Proper separation | Prop passing | CHOSEN - clean architecture |
///
/// ## 💀 BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Elimination**
///    - 🔍 Symptom: _buildChatInterface violates Flutter architecture protocol
///    - 🎯 Root Cause: Widget building logic embedded in parent component
///    - 💥 Kill Shot: Proper StatelessWidget component with MessagingUI integration
///
/// 2. **Reactive Agent Updates**
///    - 🔍 Symptom: Chat interface not updating when agent state changes
///    - 🎯 Root Cause: No proper listener for agent ChangeNotifier updates
///    - 💥 Kill Shot: ListenableBuilder integration with agent reactivity
///
/// 3. **Dynamic Placeholder Management**
///    - 🔍 Symptom: Static placeholder text not reflecting agent state
///    - 🎯 Root Cause: Placeholder logic embedded in parent component
///    - 💥 Kill Shot: Agent-aware placeholder generation with processing state
///
/// ## PERFORMANCE PROFILE
/// - Widget creation: O(1) - ListenableBuilder with MessagingUI
/// - Agent listening: O(1) - direct ChangeNotifier subscription
/// - Message rendering: O(n) where n = message count (MessagingUI optimization)
/// - Placeholder generation: O(1) - simple string interpolation
/// - Memory usage: O(n) - current conversation messages in memory
/// - Rebuild efficiency: O(1) - rebuilds only when agent state changes
///
/// ARCHITECTURAL COMPLIANCE:
/// ✅ StatelessWidget (mandatory for UI components)
/// ✅ Zero functional widget builders (pure component extraction)
/// ✅ Object-oriented callback pattern (message sending via props)
/// ✅ Single source of truth (AgentModel passed as reference)
/// ✅ Proper component separation (interface logic isolated)
/// ✅ Reactive patterns (ListenableBuilder integration)
class ChatInterfaceContainer extends StatelessWidget {
  /// Selected agent for chat interface (must not be null)
  final AgentModel selectedAgent;

  /// Callback for sending messages to selected agent
  final void Function(AgentModel, String)? onSendMessage;

  /// Callback for clearing agent conversation
  final void Function(AgentModel)? onClearConversation;

  /// Callback for opening debug overlay
  final VoidCallback? onDebugOverlay;

  const ChatInterfaceContainer({
    super.key,
    required this.selectedAgent,
    this.onSendMessage,
    this.onClearConversation,
    this.onDebugOverlay,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable:
          selectedAgent, // Listen to AgentModel changes for reactive updates
      builder: (context, child) {
        return MessagingUI(
          messages: selectedAgent.conversationHistory,
          onSendMessage: onSendMessage != null
              ? (message) => onSendMessage!(selectedAgent, message)
              : null,
          onClearConversation: onClearConversation != null
              ? () => onClearConversation!(selectedAgent)
              : null,
          onDebugOverlay: onDebugOverlay,
          showTimestamps: true,
          inputPlaceholder: selectedAgent.isProcessing
              ? '${selectedAgent.name} is thinking...'
              : 'Ask ${selectedAgent.name} anything...',
          showInput: onSendMessage != null && !selectedAgent.isProcessing,
        );
      },
    );
  }
}
