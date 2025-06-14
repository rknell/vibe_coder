import 'dart:async';
import 'package:logging/logging.dart';
import 'package:vibe_coder/ai_agent/agent.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';

/// ChatService - AI Conversation Orchestration Service
///
/// ## MISSION ACCOMPLISHED
/// Eliminates HomeScreen complexity by providing clean interface to Agent+ConversationManager system.
/// Handles async AI responses, error management, and conversation state.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Direct Agent Access | Simple, fast | Tight coupling | Rejected - violates separation |
/// | Service Wrapper | Clean interface, testable | Extra abstraction | CHOSEN - maintainable architecture |
/// | Stream-based API | Real-time updates | Complex state | CHOSEN - better UX for long responses |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Async Response Handling**
///    - 🔍 Symptom: UI freezes during AI processing
///    - 🎯 Root Cause: Synchronous conversation flow
///    - 💥 Kill Shot: Stream-based response delivery with loading states
///
/// 2. **Error State Management**
///    - 🔍 Symptom: App crashes on API failures
///    - 🎯 Root Cause: Unhandled conversation exceptions
///    - 💥 Kill Shot: Comprehensive error wrapping + user feedback
///
/// 3. **Conversation Context**
///    - 🔍 Symptom: Agent loses conversation history
///    - 🎯 Root Cause: Message state not synchronized
///    - 💥 Kill Shot: Centralized message state management
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Message processing: O(1) - direct agent delegation
/// - History retrieval: O(n) where n = message count
/// - Error handling: O(1) - immediate exception wrapping
class ChatService {
  static final Logger _logger = Logger('ChatService');

  Agent? _agent;
  final StreamController<ChatMessage> _messageStreamController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<ChatServiceState> _stateStreamController =
      StreamController<ChatServiceState>.broadcast();

  bool _isProcessing = false;
  String? _lastError;

  /// Stream of new chat messages (both user and assistant messages)
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;

  /// Stream of service state changes (loading, error, ready)
  Stream<ChatServiceState> get stateStream => _stateStreamController.stream;

  /// Current processing state
  bool get isProcessing => _isProcessing;

  /// Last error message if any
  String? get lastError => _lastError;

  /// Initialize the chat service with AI agent
  ///
  /// PERF: O(1) initialization - agent setup is synchronous
  /// ARCHITECTURAL: Lazy loading pattern - agent created on first use
  Future<void> initialize() async {
    try {
      _updateState(ChatServiceState.initializing);
      _logger.info('Initializing ChatService');

      // Create AI agent with conversational system prompt
      _agent = Agent(
        name: 'VibeCoder Assistant',
        systemPrompt:
            '''You are VibeCoder Assistant, a helpful AI coding companion.
        
You excel at:
- Flutter and Dart development
- Code review and optimization  
- Architecture and design patterns
- Debugging and troubleshooting
- Best practices and clean code

Be concise, practical, and focus on actionable solutions.
When providing code examples, make them complete and runnable.''',
        mcpConfigPath: 'mcp.json',
      );

      _updateState(ChatServiceState.ready);
      _logger.info('ChatService initialized successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize ChatService: $e', e, stackTrace);
      _handleError('Failed to initialize chat service: $e');
    }
  }

  /// Send a user message and get AI response
  ///
  /// PERF: Async processing O(API_LATENCY) - non-blocking UI
  /// ERROR HANDLING: Comprehensive exception wrapping prevents UI crashes
  Future<void> sendMessage(String userMessage) async {
    if (_agent == null) {
      _handleError('Chat service not initialized');
      return;
    }

    if (_isProcessing) {
      _logger.warning('Message ignored - already processing');
      return;
    }

    try {
      _isProcessing = true;
      _updateState(ChatServiceState.processing);
      _clearError();

      _logger.info('Processing user message: ${userMessage.length} characters');

      // Add user message to stream immediately for UI responsiveness
      final userChatMessage = ChatMessage(
        role: MessageRole.user,
        content: userMessage,
      );
      _messageStreamController.add(userChatMessage);

      // Send to AI agent and get response
      final response = await _agent!.conversation.sendUserMessageAndGetResponse(
        userMessage,
        useBeta: false,
        isReasoner: false, // Can be made configurable
      );

      // Add assistant response to stream
      final assistantMessage = ChatMessage(
        role: MessageRole.assistant,
        content: response,
      );
      _messageStreamController.add(assistantMessage);

      _logger.info('AI response delivered: ${response.length} characters');
    } catch (e, stackTrace) {
      _logger.severe('Error processing message: $e', e, stackTrace);
      _handleError('Failed to get AI response: $e');

      // Add error message to conversation for user visibility
      final errorMessage = ChatMessage(
        role: MessageRole.assistant,
        content:
            '❌ Sorry, I encountered an error: $e\n\nPlease try again or check your connection.',
      );
      _messageStreamController.add(errorMessage);
    } finally {
      _isProcessing = false;
      _updateState(ChatServiceState.ready);
    }
  }

  /// Get complete conversation history
  ///
  /// PERF: O(n) where n = message count - unavoidable for full history
  List<ChatMessage> getConversationHistory() {
    if (_agent == null) return [];

    return _agent!.conversation.getHistory();
  }

  /// Clear conversation history
  ///
  /// PERF: O(1) - direct agent delegation
  void clearConversation() {
    if (_agent == null) return;

    _logger.info('Clearing conversation history');
    _agent!.conversation.clearConversation();
  }

  /// Get available MCP tools for debugging/info
  List<String> getAvailableTools() {
    if (_agent == null) return [];

    return _agent!.getAvailableTools().map((tool) => tool.uniqueId).toList();
  }

  /// Handle errors with consistent logging and state management
  ///
  /// PERF: O(1) - immediate error processing
  void _handleError(String error) {
    _lastError = error;
    _updateState(ChatServiceState.error);
    _logger.severe('ChatService error: $error');
  }

  /// Clear the last error
  void _clearError() {
    _lastError = null;
  }

  /// Update service state and notify listeners
  ///
  /// PERF: O(1) - direct stream notification
  void _updateState(ChatServiceState state) {
    _stateStreamController.add(state);
  }

  /// Cleanup resources
  ///
  /// PERF: O(1) - resource cleanup
  Future<void> dispose() async {
    _logger.info('Disposing ChatService');

    await _messageStreamController.close();
    await _stateStreamController.close();

    if (_agent != null) {
      await _agent!.dispose();
    }
  }
}

/// Service state enumeration for UI state management
enum ChatServiceState {
  uninitialized,
  initializing,
  ready,
  processing,
  error,
}
