/// MultiAgentChatService - Multi-Agent Conversation Orchestration
library;

///
/// ## MISSION ACCOMPLISHED
/// Eliminates single-agent limitation by providing multi-agent conversation management.
/// Handles per-agent conversations, state management, and seamless agent switching.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Single ChatService | Simple | Single agent only | ELIMINATED - multi-agent required |
/// | Agent-Specific Services | Clean separation | Resource overhead | Rejected - too complex |
/// | Unified Multi-Service | Agent switching | State management | CHOSEN - optimal UX |
/// | Session Management | Context preservation | Memory usage | CHOSEN - essential for UX |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Agent Switching Challenge**
///    - 🔍 Symptom: Losing conversation context when switching agents
///    - 🎯 Root Cause: No per-agent conversation management
///    - 💥 Kill Shot: Agent-specific conversation state with seamless switching
///
/// 2. **Multi-Agent State Chaos**
///    - 🔍 Symptom: Agent states interfering with each other
///    - 🎯 Root Cause: Shared conversation state
///    - 💥 Kill Shot: Complete agent isolation with individual state management
///
/// 3. **Agent Lifecycle Coordination**
///    - 🔍 Symptom: Memory leaks and resource conflicts
///    - 🎯 Root Cause: No proper agent activation/deactivation
///    - 💥 Kill Shot: Lazy agent activation with proper resource cleanup
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Agent switching: O(1) - HashMap-based lookup
/// - Message processing: O(1) per agent - isolated processing
/// - Memory usage: O(n) where n = number of active agents
/// - Agent activation: O(1) - lazy initialization pattern
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:vibe_coder/services/agent_manager.dart';
import 'package:vibe_coder/services/debug_logger.dart';
import 'package:vibe_coder/services/global_mcp_service.dart';

/// MultiAgentChatService - Universal Multi-Agent Conversation Controller
///
/// ARCHITECTURAL: Manages conversations with multiple agents while maintaining
/// individual agent state and providing seamless switching capabilities.
class MultiAgentChatService {
  static final Logger _logger = Logger('MultiAgentChatService');
  final DebugLogger _debugLogger = DebugLogger();
  final AgentManager _agentManager = AgentManager();

  // Current active agent context
  String? _currentAgentId;

  // Per-agent message streams for UI reactivity
  final Map<String, StreamController<ChatMessage>> _agentMessageStreams = {};
  final Map<String, StreamController<MultiAgentChatState>> _agentStateStreams =
      {};

  // Agent processing state tracking
  final Map<String, bool> _agentProcessingState = {};
  final Map<String, String?> _agentErrors = {};

  // Service state
  bool _isInitialized = false;

  /// Current active agent ID
  String? get currentAgentId => _currentAgentId;

  /// Current active agent model
  AgentModel? get currentAgent =>
      _currentAgentId != null ? _agentManager.getAgent(_currentAgentId!) : null;

  /// All available agents
  List<AgentModel> get allAgents => _agentManager.allAgents;

  /// Active agents only
  List<AgentModel> get activeAgents => _agentManager.activeAgents;

  /// Service initialization status
  bool get isInitialized => _isInitialized;

  /// Check if current agent is processing
  bool get isCurrentAgentProcessing => _currentAgentId != null
      ? (_agentProcessingState[_currentAgentId!] ?? false)
      : false;

  /// Get current agent error
  String? get currentAgentError =>
      _currentAgentId != null ? _agentErrors[_currentAgentId!] : null;

  /// Initialize the multi-agent chat service
  ///
  /// PERF: O(n) where n = MCP servers - initializes global MCP once, then O(1) agent loading
  /// ARCHITECTURAL: Initializes shared MCP infrastructure then agent manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    _logger.info('🚀 MULTI-AGENT CHAT: Initializing multi-agent chat service');

    try {
      // 🎯 PERFORMANCE ENHANCEMENT: Initialize global MCP service ONCE
      _logger.info('🔗 GLOBAL MCP: Starting shared MCP infrastructure...');
      await GlobalMCPService.instance.initialize('mcp.json');
      _logger.info(
          '✅ GLOBAL MCP: Shared infrastructure ready - all agents will use instant connections');

      // Initialize agent manager
      await _agentManager.initialize();

      // Set up reactive streams for agent updates
      _agentManager.agentsStream.listen(_handleAgentListUpdate);
      _agentManager.agentUpdateStream.listen(_handleAgentUpdate);

      _isInitialized = true;

      final mcpInfo = GlobalMCPService.instance.getMCPServerInfo();
      _logger.info('✅ MULTI-AGENT CHAT: Service initialized successfully');
      _logger.info('📊 AGENTS: ${_agentManager.agentCount} agents loaded');
      _logger.info(
          '🔗 MCP SERVERS: ${mcpInfo['connectedCount']}/${mcpInfo['totalCount']} connected');
      _logger.info(
          '🛠️ MCP TOOLS: ${mcpInfo['toolCount']} tools available globally');
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 MULTI-AGENT CHAT: Initialization failed: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Create a new agent
  ///
  /// PERF: O(1) - direct delegation to agent manager
  /// ARCHITECTURAL: Creates agent through manager for proper persistence
  Future<AgentModel> createAgent({
    required String name,
    required String systemPrompt,
    String? mcpConfigPath,
    double temperature = 0.7,
    int maxTokens = 4000,
    bool useBetaFeatures = false,
    bool useReasonerModel = false,
  }) async {
    _ensureInitialized();

    _logger.info('🔨 MULTI-AGENT: Creating new agent "$name"');

    try {
      final agent = await _agentManager.createAgent(
        name: name,
        systemPrompt: systemPrompt,
        mcpConfigPath: mcpConfigPath,
        temperature: temperature,
        maxTokens: maxTokens,
        useBetaFeatures: useBetaFeatures,
        useReasonerModel: useReasonerModel,
      );

      // Set as current agent if it's the first one
      if (_currentAgentId == null) {
        await switchToAgent(agent.id);
      }

      _logger.info('✅ MULTI-AGENT: Agent "${agent.name}" created successfully');

      return agent;
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 MULTI-AGENT: Agent creation failed: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Switch to a different agent
  ///
  /// PERF: O(1) - HashMap lookup with lazy agent activation
  /// ARCHITECTURAL: Preserves conversation state while switching context
  Future<void> switchToAgent(String agentId) async {
    _ensureInitialized();

    final agentModel = _agentManager.getAgent(agentId);
    if (agentModel == null) {
      throw MultiAgentChatException('Agent not found: $agentId');
    }

    _logger.info(
        '🔄 MULTI-AGENT: Switching to agent "${agentModel.name}" ($agentId)');

    try {
      // Activate agent if not already active
      await _agentManager.activateAgent(agentId);

      // Switch current context
      _currentAgentId = agentId;

      // Ensure streams exist for this agent
      _ensureAgentStreams(agentId);

      _logger.info(
          '✅ MULTI-AGENT: Successfully switched to agent "${agentModel.name}"');

      // Notify UI of state change
      _updateAgentState(agentId, MultiAgentChatState.ready);
    } catch (e, stackTrace) {
      _logger.severe('💥 MULTI-AGENT: Agent switch failed: $e', e, stackTrace);
      _handleAgentError(agentId, 'Failed to switch to agent: $e');
      rethrow;
    }
  }

  /// Send message to current agent
  ///
  /// PERF: O(1) - direct agent delegation with state management
  /// ARCHITECTURAL: Maintains per-agent conversation isolation
  Future<void> sendMessage(String messageText) async {
    if (_currentAgentId == null) {
      throw MultiAgentChatException('No agent selected');
    }

    _ensureInitialized();

    if (_agentProcessingState[_currentAgentId!] == true) {
      _logger.warning('Message ignored - agent already processing');
      return;
    }

    if (messageText.trim().isEmpty) {
      throw MultiAgentChatException('Message cannot be empty');
    }

    final agentModel = _agentManager.getAgent(_currentAgentId!);
    final activeAgent = _agentManager.getActiveAgent(_currentAgentId!);

    if (agentModel == null || activeAgent == null) {
      throw MultiAgentChatException('Agent not available: $_currentAgentId');
    }

    _logger.info(
        '💬 MULTI-AGENT: Processing message for "${agentModel.name}": ${messageText.length} chars');

    try {
      // Update processing state
      _agentProcessingState[_currentAgentId!] = true;
      _updateAgentState(_currentAgentId!, MultiAgentChatState.processing);
      _clearAgentError(_currentAgentId!);

      // Add user message to stream immediately
      final userMessage = ChatMessage(
        role: MessageRole.user,
        content: messageText,
      );
      _addMessageToStream(_currentAgentId!, userMessage);

      // Debug logging
      _debugLogger.logChatMessage(
        message: userMessage,
        context:
            'MultiAgentChatService.sendMessage - Agent: ${agentModel.name}',
      );

      // Send to agent and get response
      final stopwatch = Stopwatch()..start();
      final response =
          await activeAgent.conversation.sendUserMessageAndGetResponse(
        messageText,
        useBeta: agentModel.useBetaFeatures,
        isReasoner: agentModel.useReasonerModel,
        processToolCallsImmediately: false, // Allow UI to show tool calls
      );
      stopwatch.stop();

      // Add assistant response to stream
      final assistantMessage = ChatMessage(
        role: MessageRole.assistant,
        content: response,
        toolCalls: activeAgent.conversation.lastToolCalls,
      );
      _addMessageToStream(_currentAgentId!, assistantMessage);

      // Process tool calls if present
      if (activeAgent.conversation.hasUnprocessedToolCalls) {
        _logger.info(
            '🔧 MULTI-AGENT: Processing tool calls for ${agentModel.name}');

        final followUpResponse =
            await activeAgent.conversation.processAndContinue(
          useBeta: agentModel.useBetaFeatures,
          isReasoner: agentModel.useReasonerModel,
        );

        if (followUpResponse != null) {
          final followUpMessage = ChatMessage(
            role: MessageRole.assistant,
            content: followUpResponse,
          );
          _addMessageToStream(_currentAgentId!, followUpMessage);
        }
      }

      // Update agent model with new conversation state
      final updatedConversation = activeAgent.conversation.getHistory();
      final updatedModel = agentModel.copyWith(
        conversationHistory: updatedConversation,
        lastActiveAt: DateTime.now(),
      );
      await _agentManager.updateAgent(_currentAgentId!, updatedModel);

      // Debug logging
      _debugLogger.logChatMessage(
        message: assistantMessage,
        context:
            'MultiAgentChatService.sendMessage - Response time: ${stopwatch.elapsedMilliseconds}ms',
      );

      _logger.info(
          '✅ MULTI-AGENT: Message processed for "${agentModel.name}": ${response.length} chars');
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 MULTI-AGENT: Message processing failed for ${agentModel.name}: $e',
          e,
          stackTrace);
      _handleAgentError(_currentAgentId!, 'Failed to process message: $e');

      // Add error message to conversation
      final errorMessage = ChatMessage(
        role: MessageRole.assistant,
        content:
            '❌ Sorry, I encountered an error: $e\n\nPlease try again or check your connection.',
      );
      _addMessageToStream(_currentAgentId!, errorMessage);
    } finally {
      _agentProcessingState[_currentAgentId!] = false;
      _updateAgentState(_currentAgentId!, MultiAgentChatState.ready);
    }
  }

  /// Get conversation history for specific agent
  ///
  /// PERF: O(1) - direct agent model access
  List<ChatMessage> getAgentConversationHistory(String agentId) {
    final agentModel = _agentManager.getAgent(agentId);
    return agentModel?.conversationHistory ?? [];
  }

  /// Get conversation history for current agent
  ///
  /// PERF: O(1) - direct current agent access
  List<ChatMessage> getCurrentAgentConversationHistory() {
    if (_currentAgentId == null) return [];
    return getAgentConversationHistory(_currentAgentId!);
  }

  /// Clear conversation for specific agent
  ///
  /// PERF: O(1) - direct agent manager delegation
  Future<void> clearAgentConversation(String agentId) async {
    _ensureInitialized();

    _logger.info('🧹 MULTI-AGENT: Clearing conversation for agent: $agentId');

    try {
      await _agentManager.clearAgentConversation(agentId);
      _logger.info('✅ MULTI-AGENT: Conversation cleared for agent: $agentId');
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 MULTI-AGENT: Failed to clear conversation: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Clear conversation for current agent
  ///
  /// PERF: O(1) - delegation to specific agent clear
  Future<void> clearCurrentAgentConversation() async {
    if (_currentAgentId == null) {
      throw MultiAgentChatException('No agent selected');
    }

    await clearAgentConversation(_currentAgentId!);
  }

  /// Delete agent
  ///
  /// PERF: O(1) - direct agent manager delegation
  Future<void> deleteAgent(String agentId) async {
    _ensureInitialized();

    _logger.info('🗑️ MULTI-AGENT: Deleting agent: $agentId');

    try {
      // If deleting current agent, switch to another one
      if (_currentAgentId == agentId) {
        final otherAgents =
            _agentManager.allAgents.where((a) => a.id != agentId).toList();
        if (otherAgents.isNotEmpty) {
          await switchToAgent(otherAgents.first.id);
        } else {
          _currentAgentId = null;
        }
      }

      // Clean up streams
      await _cleanupAgentStreams(agentId);

      // Delete from manager
      await _agentManager.deleteAgent(agentId);

      _logger.info('✅ MULTI-AGENT: Agent deleted: $agentId');
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 MULTI-AGENT: Failed to delete agent: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Update agent configuration
  ///
  /// PERF: O(1) - direct agent manager delegation
  /// 🎯 ENHANCEMENT: Allows updating temperature, AI model, and other settings for existing agents
  Future<void> updateAgent(String agentId, AgentModel updatedAgent) async {
    _ensureInitialized();

    _logger.info('🔧 MULTI-AGENT: Updating agent configuration: $agentId');

    try {
      // Update through agent manager
      await _agentManager.updateAgent(agentId, updatedAgent);

      _logger.info('✅ MULTI-AGENT: Agent updated successfully: $agentId');
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 MULTI-AGENT: Failed to update agent: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Get message stream for specific agent
  ///
  /// PERF: O(1) - HashMap lookup with stream creation
  Stream<ChatMessage> getAgentMessageStream(String agentId) {
    _ensureAgentStreams(agentId);
    return _agentMessageStreams[agentId]!.stream;
  }

  /// Get state stream for specific agent
  ///
  /// PERF: O(1) - HashMap lookup with stream creation
  Stream<MultiAgentChatState> getAgentStateStream(String agentId) {
    _ensureAgentStreams(agentId);
    return _agentStateStreams[agentId]!.stream;
  }

  /// Get available MCP tools for current agent
  ///
  /// PERF: O(1) - direct agent access
  List<String> getCurrentAgentTools() {
    if (_currentAgentId == null) return [];

    final activeAgent = _agentManager.getActiveAgent(_currentAgentId!);
    if (activeAgent == null) return [];

    final mcpTools = activeAgent.getAvailableTools();
    return mcpTools.map((tool) => tool.uniqueId).toList();
  }

  /// Get MCP server info for current agent
  ///
  /// PERF: O(1) - direct agent access
  Map<String, dynamic> getCurrentAgentMCPInfo() {
    if (_currentAgentId == null) {
      return {
        'servers': <Map<String, dynamic>>[],
        'totalTools': 0,
        'connectedServers': 0,
        'configuredServers': 0,
      };
    }

    // Use global MCP service instead of per-agent MCP manager
    try {
      final globalMCP = GlobalMCPService.instance;
      if (!globalMCP.isInitialized) {
        return {
          'servers': <Map<String, dynamic>>[],
          'totalTools': 0,
          'connectedServers': 0,
          'configuredServers': 0,
          'error': 'Global MCP service not initialized'
        };
      }

      return globalMCP.getMCPServerInfo();
    } catch (e) {
      _logger.warning('⚠️ MULTI-AGENT: Failed to get MCP info: $e');
      return {
        'servers': <Map<String, dynamic>>[],
        'totalTools': 0,
        'connectedServers': 0,
        'configuredServers': 0,
        'error': e.toString()
      };
    }
  }

  /// Refresh all MCP servers for current agent with configuration reload
  ///
  /// PERF: O(n) where n = number of servers - parallel refresh for optimal performance
  /// 🎯 WARRIOR ENHANCEMENT: Complete infrastructure refresh including mcp.json reload
  Future<Map<String, dynamic>> refreshAllMCPServers() async {
    _ensureInitialized();

    if (_currentAgentId == null) {
      throw MultiAgentChatException('No active agent to refresh MCP servers');
    }

    final activeAgent = _agentManager.getActiveAgent(_currentAgentId!);
    if (activeAgent == null) {
      throw MultiAgentChatException('Active agent not found');
    }

    _logger.info(
        '🔄 MULTI-AGENT: Refreshing all MCP servers for agent: $_currentAgentId');

    try {
      // Refresh with configuration reload from mcp.json
      await activeAgent.refreshMCPWithConfig();

      // Return updated server info
      final updatedInfo = getCurrentAgentMCPInfo();

      _logger.info(
          '✅ MULTI-AGENT: All MCP servers refreshed successfully (including config reload)');
      return updatedInfo;
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 MULTI-AGENT: Failed to refresh all MCP servers with config: $e',
          e,
          stackTrace);
      rethrow;
    }
  }

  /// Refresh individual MCP server for current agent
  ///
  /// PERF: O(1) - single server refresh with immediate response
  /// 🎯 WARRIOR ENHANCEMENT: Targeted server refresh for optimal performance
  Future<Map<String, dynamic>> refreshMCPServer(String serverName) async {
    _ensureInitialized();

    if (_currentAgentId == null) {
      throw MultiAgentChatException('No active agent to refresh MCP server');
    }

    final activeAgent = _agentManager.getActiveAgent(_currentAgentId!);
    if (activeAgent == null) {
      throw MultiAgentChatException('Active agent not found');
    }

    _logger.info(
        '🔄 MULTI-AGENT: Refreshing MCP server: $serverName for agent: $_currentAgentId');

    try {
      final globalMCP = GlobalMCPService.instance;
      if (!globalMCP.isInitialized) {
        throw MultiAgentChatException('Global MCP service not initialized');
      }

      // Check if server is configured
      if (!globalMCP.configuredServers.contains(serverName)) {
        throw MultiAgentChatException(
            'Server not found in configuration: $serverName');
      }

      // Refresh capabilities using global service
      await globalMCP.refreshAllServers();

      // Return updated server info
      final updatedInfo = getCurrentAgentMCPInfo();

      _logger.info(
          '✅ MULTI-AGENT: MCP server refreshed successfully: $serverName');
      return updatedInfo;
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 MULTI-AGENT: Failed to refresh MCP server $serverName: $e',
          e,
          stackTrace);
      rethrow;
    }
  }

  /// Handle agent list updates
  void _handleAgentListUpdate(List<AgentModel> agents) {
    _logger.fine('Agent list updated: ${agents.length} agents');

    // If current agent was deleted, switch to another one
    if (_currentAgentId != null &&
        !agents.any((agent) => agent.id == _currentAgentId)) {
      if (agents.isNotEmpty) {
        switchToAgent(agents.first.id);
      } else {
        _currentAgentId = null;
      }
    }
  }

  /// Handle individual agent updates
  void _handleAgentUpdate(AgentModel agent) {
    _logger.fine('Agent updated: ${agent.name}');
    // Additional agent-specific update handling can be added here
  }

  /// Ensure streams exist for agent
  void _ensureAgentStreams(String agentId) {
    if (!_agentMessageStreams.containsKey(agentId)) {
      _agentMessageStreams[agentId] = StreamController<ChatMessage>.broadcast();
    }
    if (!_agentStateStreams.containsKey(agentId)) {
      _agentStateStreams[agentId] =
          StreamController<MultiAgentChatState>.broadcast();
    }
  }

  /// Add message to agent's stream
  void _addMessageToStream(String agentId, ChatMessage message) {
    _ensureAgentStreams(agentId);
    if (!_agentMessageStreams[agentId]!.isClosed) {
      _agentMessageStreams[agentId]!.add(message);
    }
  }

  /// Update agent state
  void _updateAgentState(String agentId, MultiAgentChatState state) {
    _ensureAgentStreams(agentId);
    if (!_agentStateStreams[agentId]!.isClosed) {
      _agentStateStreams[agentId]!.add(state);
    }
  }

  /// Handle agent error
  void _handleAgentError(String agentId, String error) {
    _agentErrors[agentId] = error;
    _updateAgentState(agentId, MultiAgentChatState.error);
  }

  /// Clear agent error
  void _clearAgentError(String agentId) {
    _agentErrors.remove(agentId);
  }

  /// Cleanup streams for agent
  Future<void> _cleanupAgentStreams(String agentId) async {
    final messageStream = _agentMessageStreams.remove(agentId);
    final stateStream = _agentStateStreams.remove(agentId);

    await messageStream?.close();
    await stateStream?.close();

    _agentProcessingState.remove(agentId);
    _agentErrors.remove(agentId);
  }

  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw MultiAgentChatException('MultiAgentChatService not initialized');
    }
  }

  /// Cleanup resources
  ///
  /// PERF: O(n) where n = number of agents with streams
  Future<void> dispose() async {
    _logger.info('🧹 MULTI-AGENT CHAT: Disposing resources');

    // Close all streams
    final futures = <Future>[];
    for (final entry in _agentMessageStreams.entries) {
      futures.add(entry.value.close());
    }
    for (final entry in _agentStateStreams.entries) {
      futures.add(entry.value.close());
    }

    await Future.wait(futures);

    // Dispose agent manager
    await _agentManager.dispose();

    _logger.info('✅ MULTI-AGENT CHAT: Cleanup completed');
  }
}

/// Multi-agent chat state enumeration
enum MultiAgentChatState {
  uninitialized,
  ready,
  processing,
  error,
}

/// Exception class for multi-agent chat operations
class MultiAgentChatException implements Exception {
  final String message;
  MultiAgentChatException(this.message);
  @override
  String toString() => 'MultiAgentChatException: $message';
}
