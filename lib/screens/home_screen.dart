import 'package:flutter/material.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/components/messaging_ui.dart';
import 'package:vibe_coder/components/common/indicators/chat_status_indicator.dart';
import 'package:vibe_coder/components/common/dialogs/tools_info_dialog.dart';
import 'package:vibe_coder/components/config/agent_configuration_screen.dart';
import 'package:vibe_coder/models/agent_configuration.dart';
import 'package:vibe_coder/services/chat_service.dart';
import 'dart:async';

/// HomeScreen - AI Chat Interface
///
/// ## MISSION ACCOMPLISHED
/// Eliminates static mock data by integrating real AI conversation capabilities.
/// Provides loading states, error handling, and real-time message streaming.
/// ARCHITECTURAL VICTORY: All functional widget builders extracted to proper components.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Direct Agent Integration | Simple | Tight coupling | Rejected - violates separation |
/// | ChatService Wrapper | Clean interface | Extra layer | CHOSEN - maintainable + testable |
/// | Stream-based Updates | Real-time UX | State complexity | CHOSEN - superior user experience |
/// | Functional Builders | Simple | Not reusable | ELIMINATED - violates architecture |
/// | Component Extraction | Reusable + testable | Extra files | CHOSEN - architectural excellence |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Static Mock Data Elimination**
///    - 🔍 Symptom: Non-functional chat interface
///    - 🎯 Root Cause: Hardcoded sample messages
///    - 💥 Kill Shot: Real-time AI conversation via ChatService
///
/// 2. **Loading State Management**
///    - 🔍 Symptom: No user feedback during processing
///    - 🎯 Root Cause: Missing UI state indicators
///    - 💥 Kill Shot: Typing indicators + processing states
///
/// 3. **Error Recovery**
///    - 🔍 Symptom: App crashes on API failures
///    - 🎯 Root Cause: Unhandled service exceptions
///    - 💥 Kill Shot: Graceful error display + retry options
///
/// 4. **Functional Widget Architecture Violation**
///    - 🔍 Symptom: `_buildStatusIndicator()` and `_showToolsInfo()` methods
///    - 🎯 Root Cause: UI components embedded in StatefulWidget logic
///    - 💥 Kill Shot: Extracted to ChatStatusIndicator and ToolsInfoDialog components
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChatService _chatService = ChatService();
  final List<ChatMessage> _messages = [];

  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<ChatServiceState>? _stateSubscription;

  bool _isLoading = false;
  String? _errorMessage;
  ChatServiceState _serviceState = ChatServiceState.uninitialized;

  @override
  void initState() {
    super.initState();
    _initializeChatService();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _stateSubscription?.cancel();
    _chatService.dispose();
    super.dispose();
  }

  /// Initialize chat service and set up stream listeners
  ///
  /// PERF: O(1) setup - async initialization doesn't block UI
  /// ARCHITECTURAL: Stream-based architecture for reactive UI updates
  Future<void> _initializeChatService() async {
    // Listen to new messages
    _messageSubscription = _chatService.messageStream.listen(
      (message) {
        setState(() {
          _messages.add(message);
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Message stream error: $error';
        });
      },
    );

    // Listen to service state changes
    _stateSubscription = _chatService.stateStream.listen(
      (state) {
        setState(() {
          _serviceState = state;
          _isLoading = state == ChatServiceState.processing ||
              state == ChatServiceState.initializing;

          // Clear error when service becomes ready
          if (state == ChatServiceState.ready) {
            _errorMessage = null;
          } else if (state == ChatServiceState.error) {
            _errorMessage = _chatService.lastError ?? 'Unknown service error';
          }
        });
      },
    );

    // Initialize the service
    await _chatService.initialize();

    // Add welcome message after initialization
    if (_serviceState == ChatServiceState.ready) {
      _addWelcomeMessage();
    }
  }

  /// Add welcome message to start conversation
  ///
  /// PERF: O(1) - single message addition with configuration-driven content
  /// ARCHITECTURAL: Configuration-driven welcome message replaces hardcoded content
  void _addWelcomeMessage() {
    try {
      final config = _chatService.getCurrentConfiguration();
      final welcomeMessage = ChatMessage(
        role: MessageRole.assistant,
        content: config.welcomeMessage,
      );

      setState(() {
        _messages.add(welcomeMessage);
      });
    } catch (e) {
      // Fallback to default welcome message if configuration fails
      final fallbackMessage = ChatMessage(
        role: MessageRole.assistant,
        content: '''👋 **Welcome to VibeCoder!**

I'm your AI coding companion, ready to help with:
• Flutter & Dart development
• Code review and debugging  
• Architecture and best practices
• Project planning and optimization

What would you like to work on today?''',
      );

      setState(() {
        _messages.add(fallbackMessage);
      });
    }
  }

  /// Handle user message sending with error recovery
  ///
  /// PERF: O(1) - direct service delegation, non-blocking UI
  /// ERROR HANDLING: Comprehensive exception catching with user feedback
  Future<void> _handleSendMessage(String messageText) async {
    if (_serviceState != ChatServiceState.ready || _isLoading) {
      _showSnackBar('Please wait - service is not ready yet');
      return;
    }

    if (messageText.trim().isEmpty) {
      _showSnackBar('Message cannot be empty');
      return;
    }

    try {
      await _chatService.sendMessage(messageText);
    } catch (e) {
      _showSnackBar('Failed to send message: $e');
    }
  }

  /// Show user feedback via SnackBar
  ///
  /// PERF: O(1) - immediate UI feedback
  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Clear conversation with confirmation
  ///
  /// PERF: O(1) - direct service call
  Future<void> _clearConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text(
            'Are you sure you want to clear the conversation history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _messages.clear();
      });
      _chatService.clearConversation();
      _addWelcomeMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VibeCoder Assistant'),
        actions: [
          // Service status indicator
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: ChatStatusIndicator(serviceState: _serviceState),
            ),
          ),

          // Clear conversation button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _serviceState == ChatServiceState.ready
                ? _clearConversation
                : null,
            tooltip: 'Clear Conversation',
          ),

          // Configuration button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showConfiguration(),
            tooltip: 'Agent Configuration',
          ),

          // Tools info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showToolsInfo(),
            tooltip: 'Available Tools',
          ),
        ],
      ),
      body: Column(
        children: [
          // Error banner
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),

          // Main messaging interface
          Expanded(
            child: MessagingUI(
              messages: _messages,
              onSendMessage: _handleSendMessage,
              showTimestamps: _getCurrentConfigSafely()?.showTimestamps ?? true,
              inputPlaceholder: _isLoading
                  ? 'AI is thinking...'
                  : 'Ask me anything about coding...',
              showInput: _serviceState == ChatServiceState.ready && !_isLoading,
            ),
          ),
        ],
      ),
    );
  }

  /// Show available MCP tools information
  ///
  /// PERF: O(1) - direct delegation to component
  void _showToolsInfo() {
    final mcpInfo = _chatService.getMCPServerInfo();
    ToolsInfoDialog.show(context, mcpInfo);
  }

  /// Show agent configuration screen
  ///
  /// PERF: O(1) - navigation to configuration screen
  /// ARCHITECTURAL: Following Flutter architecture rules with proper component navigation
  void _showConfiguration() async {
    if (_serviceState != ChatServiceState.ready) {
      _showSnackBar('Please wait - service is not ready yet');
      return;
    }

    try {
      final currentConfig = _chatService.getCurrentConfiguration();
      final configService = _chatService.getConfigurationService();

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AgentConfigurationScreen(
            configurationService: configService,
            initialConfiguration: currentConfig,
            onConfigurationChanged: () => _handleConfigurationChanged(),
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('Failed to open configuration: $e');
    }
  }

  /// Handle configuration changes by updating the welcome message and other UI elements
  ///
  /// PERF: O(1) - direct configuration refresh
  /// ARCHITECTURAL: Reactive configuration updates without full restart
  void _handleConfigurationChanged() {
    try {
      // Update welcome message if conversation is empty or only has welcome message
      if (_messages.length <= 1) {
        setState(() {
          _messages.clear();
        });
        _addWelcomeMessage();
      }

      _showSnackBar('Configuration updated successfully');
    } catch (e) {
      _showSnackBar('Failed to apply configuration changes: $e');
    }
  }

  /// Safely get current configuration with null handling
  ///
  /// PERF: O(1) - direct configuration access with error handling
  /// ARCHITECTURAL: Defensive programming pattern for UI safety
  AgentConfiguration? _getCurrentConfigSafely() {
    try {
      if (_serviceState == ChatServiceState.ready) {
        return _chatService.getCurrentConfiguration();
      }
    } catch (e) {
      // Configuration not available yet or service error
    }
    return null;
  }
}
