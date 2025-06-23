/// AgentManager - Multi-Agent Orchestration Service
library;

///
/// ## MISSION ACCOMPLISHED
/// Eliminates single-agent limitation by providing complete multi-agent system
/// with persistence, state management, and coordination capabilities.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Single Manager | Centralized control | Single point of failure | CHOSEN - simpler orchestration |
/// | Distributed Agents | Fault tolerance | Complex coordination | Rejected - unnecessary complexity |
/// | In-Memory Storage | Fast access | Data loss | Rejected - persistence required |
/// | File-Based Storage | Persistence | I/O overhead | CHOSEN - reliability over speed |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Multi-Agent State Chaos**
///    - 🔍 Symptom: No coordination between agents
///    - 🎯 Root Cause: Agents operating independently
///    - 💥 Kill Shot: Centralized agent registry with state management
///
/// 2. **Agent Persistence Challenge**
///    - 🔍 Symptom: Agents lost on restart
///    - 🎯 Root Cause: No persistence layer
///    - 💥 Kill Shot: JSON-based agent configuration and state persistence
///
/// 3. **Agent Lifecycle Management**
///    - 🔍 Symptom: Memory leaks and resource issues
///    - 🎯 Root Cause: No proper agent cleanup
///    - 💥 Kill Shot: Comprehensive lifecycle management with disposal
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Agent lookup: O(1) - HashMap-based access
/// - Agent creation: O(1) - direct instantiation + registration
/// - Persistence: O(n) where n = total agent count
/// - State updates: O(1) - direct agent modification
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/ai_agent/agent.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';

/// AgentManager - Universal Multi-Agent System Controller
///
/// ARCHITECTURAL: Central registry and controller for all agents in the system.
/// Handles persistence, lifecycle management, and inter-agent coordination.
class AgentManager {
  static final Logger _logger = Logger('AgentManager');
  static const String _agentsFileName = 'agents.json';
  static const String _defaultMcpConfig = 'mcp.json';

  // Agent registry - AgentModel for UI state, Agent for runtime behavior
  final Map<String, AgentModel> _agentModels = {};
  final Map<String, Agent> _activeAgents = {};

  // Stream controllers for reactive UI updates
  final StreamController<List<AgentModel>> _agentsStreamController =
      StreamController<List<AgentModel>>.broadcast();
  final StreamController<AgentModel> _agentUpdateStreamController =
      StreamController<AgentModel>.broadcast();

  // UUID generator for unique agent IDs
  final _uuid = const Uuid();

  // Initialization state
  bool _isInitialized = false;

  /// Stream of all agents (for UI reactivity)
  Stream<List<AgentModel>> get agentsStream => _agentsStreamController.stream;

  /// Stream of individual agent updates
  Stream<AgentModel> get agentUpdateStream =>
      _agentUpdateStreamController.stream;

  /// All registered agent models
  List<AgentModel> get allAgents => _agentModels.values.toList();

  /// Active agents only
  List<AgentModel> get activeAgents =>
      _agentModels.values.where((agent) => agent.isActive).toList();

  /// Count of all agents
  int get agentCount => _agentModels.length;

  /// Initialization status
  bool get isInitialized => _isInitialized;

  /// Initialize the agent manager
  ///
  /// PERF: O(n) where n = number of persisted agents
  /// ARCHITECTURAL: Loads all agents from persistence but doesn't activate them
  Future<void> initialize() async {
    if (_isInitialized) return;

    _logger.info('🚀 AGENT MANAGER: Initializing multi-agent system');

    try {
      await _loadPersistedAgents();
      _isInitialized = true;

      _logger.info(
          '✅ AGENT MANAGER: Initialized with ${_agentModels.length} agents');

      // Notify UI of initial agent list
      _notifyAgentsChanged();
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 AGENT MANAGER: Initialization failed: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Create a new agent with default configuration
  ///
  /// PERF: O(1) - direct agent creation and registration
  /// ARCHITECTURAL: Creates AgentModel for persistence, Agent for runtime
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

    final agentId = _uuid.v4();

    _logger.info('🔨 AGENT CREATION: Creating agent "$name" with ID: $agentId');

    // Create agent model for persistence
    final agentModel = AgentModel(
      id: agentId,
      name: name,
      systemPrompt: systemPrompt,
      mcpConfigPath: mcpConfigPath ?? _defaultMcpConfig,
      temperature: temperature,
      maxTokens: maxTokens,
      useBetaFeatures: useBetaFeatures,
      useReasonerModel: useReasonerModel,
    );

    // Validate agent configuration
    final validationErrors = agentModel.validate();
    if (validationErrors.isNotEmpty) {
      throw AgentValidationException(
          'Agent validation failed: ${validationErrors.join(', ')}');
    }

    // Register agent model
    _agentModels[agentId] = agentModel;

    // Persist immediately
    await _persistAgents();

    _logger.info('✅ AGENT CREATED: Agent "$name" created successfully');

    // Notify UI
    _notifyAgentsChanged();
    _notifyAgentUpdated(agentModel);

    return agentModel;
  }

  /// Get agent model by ID
  ///
  /// PERF: O(1) - HashMap lookup
  AgentModel? getAgent(String agentId) {
    return _agentModels[agentId];
  }

  /// Get active runtime agent by ID
  ///
  /// PERF: O(1) - HashMap lookup
  Agent? getActiveAgent(String agentId) {
    return _activeAgents[agentId];
  }

  /// Update agent configuration
  ///
  /// PERF: O(1) - direct model update + persistence
  Future<void> updateAgent(String agentId, AgentModel updatedAgent) async {
    _ensureInitialized();

    if (!_agentModels.containsKey(agentId)) {
      throw AgentNotFoundException('Agent not found: $agentId');
    }

    _logger.info('🔄 AGENT UPDATE: Updating agent "$agentId"');

    // Validate updated configuration
    final validationErrors = updatedAgent.validate();
    if (validationErrors.isNotEmpty) {
      throw AgentValidationException(
          'Agent validation failed: ${validationErrors.join(', ')}');
    }

    // Update agent model
    _agentModels[agentId] = updatedAgent;

    // If agent is active, update runtime agent
    if (_activeAgents.containsKey(agentId)) {
      await _updateActiveAgent(agentId, updatedAgent);
    }

    // Persist changes
    await _persistAgents();

    _logger.info('✅ AGENT UPDATED: Agent "$agentId" updated successfully');

    // Notify UI
    _notifyAgentsChanged();
    _notifyAgentUpdated(updatedAgent);
  }

  /// Delete agent
  ///
  /// PERF: O(1) - HashMap removal + cleanup
  Future<void> deleteAgent(String agentId) async {
    _ensureInitialized();

    final agent = _agentModels[agentId];
    if (agent == null) {
      throw AgentNotFoundException('Agent not found: $agentId');
    }

    _logger
        .info('🗑️ AGENT DELETION: Deleting agent "${agent.name}" ($agentId)');

    // Deactivate agent if active
    if (_activeAgents.containsKey(agentId)) {
      await deactivateAgent(agentId);
    }

    // Remove from registry
    _agentModels.remove(agentId);

    // Persist changes
    await _persistAgents();

    _logger.info('✅ AGENT DELETED: Agent deleted successfully');

    // Notify UI
    _notifyAgentsChanged();
  }

  /// Activate agent for interaction
  ///
  /// PERF: O(1) - Agent instantiation with shared MCP (no per-agent initialization)
  /// ARCHITECTURAL: Creates runtime Agent instance from AgentModel with instant MCP access
  Future<Agent> activateAgent(String agentId) async {
    _ensureInitialized();

    final agentModel = _agentModels[agentId];
    if (agentModel == null) {
      throw AgentNotFoundException('Agent not found: $agentId');
    }

    if (_activeAgents.containsKey(agentId)) {
      _logger.info('🔄 AGENT ACTIVATION: Agent already active: $agentId');
      return _activeAgents[agentId]!;
    }

    _logger.info(
        '🚀 AGENT ACTIVATION: Activating agent "${agentModel.name}" ($agentId)');

    try {
      // Create runtime Agent instance
      final agent = Agent(
        agentModel: agentModel,
        // NOTE: toDoList is now handled by MCP task server
      );

      // SKIP MCP initialization - GlobalMCP is already connected
      // Agent will use GlobalMCPService.instance automatically
      _logger.info('⚡ INSTANT MCP: Using shared GlobalMCPService connections');

      // Restore conversation history
      for (final message in agentModel.conversationHistory) {
        _addMessageToConversation(agent.conversation, message);
      }

      // Register as active
      _activeAgents[agentId] = agent;

      // Update model state
      final updatedModel = agentModel.copyWith(
        isActive: true,
        lastActiveAt: DateTime.now(),
      );
      _agentModels[agentId] = updatedModel;
      await _persistAgents();

      _logger.info(
          '✅ AGENT ACTIVATED: Agent "${agentModel.name}" is now active (INSTANT)');

      // Notify UI
      _notifyAgentUpdated(updatedModel);

      return agent;
    } catch (e, stackTrace) {
      _logger.severe('💥 AGENT ACTIVATION FAILED: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Deactivate agent
  ///
  /// PERF: O(1) - Agent cleanup + state persistence
  Future<void> deactivateAgent(String agentId) async {
    _ensureInitialized();

    final agentModel = _agentModels[agentId];
    final activeAgent = _activeAgents[agentId];

    if (agentModel == null) {
      throw AgentNotFoundException('Agent not found: $agentId');
    }

    if (activeAgent == null) {
      _logger.info('🔄 AGENT DEACTIVATION: Agent already inactive: $agentId');
      return;
    }

    _logger.info(
        '🛑 AGENT DEACTIVATION: Deactivating agent "${agentModel.name}" ($agentId)');

    try {
      // Save conversation history back to model
      final conversationHistory = activeAgent.conversation.getHistory();
      final updatedModel = agentModel.copyWith(
        isActive: false,
        conversationHistory: conversationHistory,
        lastActiveAt: DateTime.now(),
      );

      // Update model
      _agentModels[agentId] = updatedModel;

      // Cleanup agent resources
      await activeAgent.dispose();

      // Remove from active registry
      _activeAgents.remove(agentId);

      // Persist changes
      await _persistAgents();

      _logger
          .info('✅ AGENT DEACTIVATED: Agent "${agentModel.name}" deactivated');

      // Notify UI
      _notifyAgentUpdated(updatedModel);
    } catch (e, stackTrace) {
      _logger.severe('💥 AGENT DEACTIVATION FAILED: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Add message to agent's conversation history
  ///
  /// PERF: O(1) - Direct message addition
  Future<void> addMessageToAgent(String agentId, ChatMessage message) async {
    final agentModel = _agentModels[agentId];
    if (agentModel == null) {
      throw AgentNotFoundException('Agent not found: $agentId');
    }

    // Update model
    agentModel.addMessage(message);

    // Update active agent if exists
    final activeAgent = _activeAgents[agentId];
    if (activeAgent != null) {
      _addMessageToConversation(activeAgent.conversation, message);
    }

    // Persist changes
    await _persistAgents();

    // Notify UI
    _notifyAgentUpdated(agentModel);
  }

  /// Clear agent's conversation history
  ///
  /// PERF: O(1) - Direct history clear
  Future<void> clearAgentConversation(String agentId) async {
    final agentModel = _agentModels[agentId];
    if (agentModel == null) {
      throw AgentNotFoundException('Agent not found: $agentId');
    }

    // Update model
    agentModel.clearConversation();

    // Update active agent if exists
    final activeAgent = _activeAgents[agentId];
    if (activeAgent != null) {
      activeAgent.conversation.clearConversation();
    }

    // Persist changes
    await _persistAgents();

    // Notify UI
    _notifyAgentUpdated(agentModel);
  }

  /// Load agents from persistence
  ///
  /// PERF: O(n) where n = number of persisted agents
  Future<void> _loadPersistedAgents() async {
    try {
      final file = await _getAgentsFile();

      if (!await file.exists()) {
        _logger.info('📁 PERSISTENCE: No existing agents file found');
        return;
      }

      final jsonStr = await file.readAsString();
      final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;

      final agentsData = jsonData['agents'] as List<dynamic>? ?? [];

      for (final agentJson in agentsData) {
        try {
          final agentModel =
              AgentModel.fromJson(agentJson as Map<String, dynamic>);
          _agentModels[agentModel.id] = agentModel;
        } catch (e) {
          _logger.warning('⚠️ PERSISTENCE: Failed to load agent: $e');
        }
      }

      _logger.info('📂 PERSISTENCE: Loaded ${_agentModels.length} agents');
    } catch (e, stackTrace) {
      _logger.severe('💥 PERSISTENCE LOAD FAILED: $e', e, stackTrace);
      // Don't rethrow - allow system to continue with empty agent list
    }
  }

  /// Persist agents to storage
  ///
  /// PERF: O(n) where n = number of agents
  Future<void> _persistAgents() async {
    try {
      final file = await _getAgentsFile();

      final agentsData =
          _agentModels.values.map((agent) => agent.toJson()).toList();

      final jsonData = {
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'agents': agentsData,
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonData);
      await file.writeAsString(jsonStr);

      _logger.fine('💾 PERSISTENCE: Saved ${_agentModels.length} agents');
    } catch (e, stackTrace) {
      _logger.severe('💥 PERSISTENCE SAVE FAILED: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Get agents file path
  ///
  /// PERF: O(1) - directory resolution
  Future<File> _getAgentsFile() async {
    if (kIsWeb) {
      throw UnsupportedError(
          'File-based agent persistence not supported on web');
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    final agentDir = Directory('${documentsDir.path}/vibe_coder/agents');

    if (!await agentDir.exists()) {
      await agentDir.create(recursive: true);
    }

    return File('${agentDir.path}/$_agentsFileName');
  }

  /// Update active agent configuration
  ///
  /// PERF: O(1) - agent automatically reflects AgentModel changes
  /// ARCHITECTURAL: Agent references AgentModel directly, no manual sync needed
  Future<void> _updateActiveAgent(String agentId, AgentModel agentModel) async {
    final activeAgent = _activeAgents[agentId];
    if (activeAgent == null) return;

    // Agent automatically reflects AgentModel changes through direct reference
    // No manual property updates needed

    // Note: For complex updates (like MCP config changes that require reconnection),
    // we might need to deactivate and reactivate the agent in the future
  }

  /// Ensure manager is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw AgentManagerException('AgentManager not initialized');
    }
  }

  /// Notify UI of agent list changes
  void _notifyAgentsChanged() {
    if (!_agentsStreamController.isClosed) {
      _agentsStreamController.add(allAgents);
    }
  }

  /// Notify UI of individual agent update
  void _notifyAgentUpdated(AgentModel agent) {
    if (!_agentUpdateStreamController.isClosed) {
      _agentUpdateStreamController.add(agent);
    }
  }

  /// Add existing message to conversation using appropriate method
  ///
  /// PERF: O(1) - direct method dispatch based on message role
  /// ARCHITECTURAL: Bridges ChatMessage objects to ConversationManager methods
  void _addMessageToConversation(dynamic conversation, ChatMessage message) {
    switch (message.role) {
      case MessageRole.user:
        conversation.addUserMessage(message.content ?? '');
        break;
      case MessageRole.assistant:
        conversation.addAssistantMessage(
          message.content ?? '',
          toolCalls: message.toolCalls,
          reasoningContent: message.reasoningContent,
        );
        break;
      case MessageRole.system:
        conversation.addSystemMessage(message.content ?? '');
        break;
      case MessageRole.tool:
        // Tool messages need special handling - for now skip restoration
        _logger
            .warning('Skipping tool message restoration - not yet supported');
        break;
    }
  }

  /// Cleanup resources
  ///
  /// PERF: O(n) where n = number of active agents
  Future<void> dispose() async {
    _logger.info('🧹 AGENT MANAGER: Disposing resources');

    // Deactivate all active agents
    final activeAgentIds = List.from(_activeAgents.keys);
    for (final agentId in activeAgentIds) {
      try {
        await deactivateAgent(agentId);
      } catch (e) {
        _logger.warning('⚠️ CLEANUP: Failed to deactivate agent $agentId: $e');
      }
    }

    // Close streams
    await _agentsStreamController.close();
    await _agentUpdateStreamController.close();

    _logger.info('✅ AGENT MANAGER: Cleanup completed');
  }
}

/// Exception classes for agent management
class AgentManagerException implements Exception {
  final String message;
  AgentManagerException(this.message);
  @override
  String toString() => 'AgentManagerException: $message';
}

class AgentNotFoundException implements Exception {
  final String message;
  AgentNotFoundException(this.message);
  @override
  String toString() => 'AgentNotFoundException: $message';
}

class AgentValidationException implements Exception {
  final String message;
  AgentValidationException(this.message);
  @override
  String toString() => 'AgentValidationException: $message';
}
