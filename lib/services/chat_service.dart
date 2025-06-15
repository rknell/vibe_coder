import 'dart:async';
import 'package:logging/logging.dart';
import 'package:vibe_coder/ai_agent/agent.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:vibe_coder/services/debug_logger.dart';
import 'package:vibe_coder/models/agent_configuration.dart';
import 'package:vibe_coder/services/configuration_service.dart';

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
  final DebugLogger _debugLogger = DebugLogger();
  final ConfigurationService _configurationService = ConfigurationService();

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
  /// ARCHITECTURAL: Configuration-driven initialization replaces hardcoded values
  Future<void> initialize() async {
    try {
      _updateState(ChatServiceState.initializing);
      _logger.info('Initializing ChatService');

      // Initialize configuration service first
      await _configurationService.initialize();
      final config = _configurationService.currentConfig;

      // Create AI agent with configuration-driven parameters
      _agent = Agent(
        name: config.agentName,
        systemPrompt: config.systemPrompt,
        mcpConfigPath: config.mcpConfigPath,
      );

      // Initialize MCP after agent creation
      _logger.info('Initializing MCP servers...');
      await _agent!.initializeMCP();
      _logger.info('MCP initialization completed');

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

      // 🛡️ DEBUG LOGGING: Log user message
      _debugLogger.logChatMessage(
        message: userChatMessage,
        context: 'ChatService.sendMessage',
      );

      // Send to AI agent and get response with configuration-driven parameters
      // Use two-phase approach to show tool calls in UI
      final stopwatch = Stopwatch()..start();
      final config = _configurationService.currentConfig;
      final response = await _agent!.conversation.sendUserMessageAndGetResponse(
        userMessage,
        useBeta: config.useBetaFeatures,
        isReasoner: config.useReasonerModel,
        processToolCallsImmediately:
            false, // 🔧 NEW: Allow UI to show tool calls
      );
      stopwatch.stop();

      // Add assistant response to stream (this may contain tool calls)
      final assistantMessage = ChatMessage(
        role: MessageRole.assistant,
        content: response,
        toolCalls: _agent!.conversation.lastToolCalls,
      );
      _messageStreamController.add(assistantMessage);

      // 🔧 NEW: Process tool calls if present and continue conversation
      if (_agent!.conversation.hasUnprocessedToolCalls) {
        _logger.info('🔧 Processing tool calls for visible UI display');

        final followUpResponse = await _agent!.conversation.processAndContinue(
          useBeta: config.useBetaFeatures,
          isReasoner: config.useReasonerModel,
        );

        if (followUpResponse != null) {
          // Add the follow-up response to the stream
          final followUpMessage = ChatMessage(
            role: MessageRole.assistant,
            content: followUpResponse,
          );
          _messageStreamController.add(followUpMessage);
        }
      }

      // 🛡️ DEBUG LOGGING: Log assistant response with timing
      _debugLogger.logChatMessage(
        message: assistantMessage,
        context:
            'ChatService.sendMessage - Response time: ${stopwatch.elapsedMilliseconds}ms',
      );

      // 🛡️ DEBUG LOGGING: Log conversation completion
      _debugLogger.logSystemEvent(
        'CONVERSATION TURN COMPLETED',
        'User message processed and response delivered',
        details: {
          'userMessageLength': userMessage.length,
          'responseLength': response.length,
          'processingTimeMs': stopwatch.elapsedMilliseconds,
          'hasToolCalls': assistantMessage.toolCalls?.isNotEmpty ?? false,
          'toolCallCount': assistantMessage.toolCalls?.length ?? 0,
        },
      );

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

    final mcpTools = _agent!.getAvailableTools();
    return mcpTools.map((tool) => tool.uniqueId).toList();
  }

  /// Get detailed MCP server and tool information
  Map<String, dynamic> getMCPServerInfo() {
    if (_agent == null) {
      return {
        'servers': <Map<String, dynamic>>[],
        'totalTools': 0,
        'connectedServers': 0,
        'configuredServers': 0,
      };
    }

    final mcpManager = _agent!.mcpManager;
    final configuredServers = mcpManager.configuredServers;
    final connectedServers = mcpManager.connectedServers;
    final allTools = mcpManager.getAllTools();

    // Get detailed status for all configured servers
    final serverInfo = configuredServers.map((serverName) {
      return mcpManager.getServerStatus(serverName);
    }).toList();

    return {
      'servers': serverInfo,
      'totalTools': allTools.length,
      'connectedServers': connectedServers.length,
      'configuredServers': configuredServers.length,
    };
  }

  /// Get current agent configuration
  ///
  /// PERF: O(1) - direct configuration access
  AgentConfiguration getCurrentConfiguration() {
    return _configurationService.currentConfig;
  }

  /// Get configuration service for advanced management
  ///
  /// PERF: O(1) - direct service access
  ConfigurationService getConfigurationService() {
    return _configurationService;
  }

  /// Update agent configuration and reinitialize if necessary
  ///
  /// PERF: O(1) for config update, O(n) for agent reinitialization if required
  /// ARCHITECTURAL: Configuration changes may require agent recreation
  Future<void> updateConfiguration(AgentConfiguration newConfig) async {
    try {
      _logger.info('🔄 CONFIG UPDATE: Updating agent configuration');

      final oldConfig = _configurationService.currentConfig;
      final result = await _configurationService.updateConfiguration(newConfig);

      if (!result.isSuccess) {
        throw Exception(result.displayMessage);
      }

      // Check if agent needs to be recreated (system prompt, name, or MCP config changed)
      final needsAgentRecreation = oldConfig.agentName != newConfig.agentName ||
          oldConfig.systemPrompt != newConfig.systemPrompt ||
          oldConfig.mcpConfigPath != newConfig.mcpConfigPath;

      if (needsAgentRecreation && _agent != null) {
        _logger.info(
            '🔄 AGENT RECREATION: Configuration changes require agent recreation');

        // Dispose old agent
        await _agent!.dispose();

        // Create new agent with updated configuration
        _agent = Agent(
          name: newConfig.agentName,
          systemPrompt: newConfig.systemPrompt,
          mcpConfigPath: newConfig.mcpConfigPath,
        );

        // Initialize MCP after agent creation
        await _agent!.initializeMCP();

        _logger.info(
            '✅ AGENT UPDATED: Agent successfully recreated with new configuration');
      }

      _logger.info(
          '✅ CONFIG APPLIED: Configuration update completed successfully');
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 CONFIG UPDATE ERROR: Failed to update configuration: $e',
          e,
          stackTrace);
      rethrow;
    }
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

    await _configurationService.dispose();
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
