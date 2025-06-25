/// AgentService - Simplified Service Layer for Agent Management
library;

///
/// ## MISSION ACCOMPLISHED
/// Updated AgentService to work with AgentModel following architectural refactoring.
/// Manages agent collection with persistence loading and proper CRUD operations.
///
/// ## ARCHITECTURAL COMPLIANCE ACHIEVED
/// - ✅ Extends ChangeNotifier for global state management
/// - ✅ Maintains List<DataModel> data field for collections
/// - ✅ Provides filtering functions (getById, getByName)
/// - ✅ Handles multi-record operations and complex workflows
/// - ✅ Mandatory notifyListeners() on all data changes
/// - ✅ Loads agents from persistence in /data directory
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Agent lookup: O(1) - HashMap-based access via index
/// - Agent creation: O(1) - direct model creation + collection update
/// - Collection management: O(n) where n = number of agents
/// - State updates: O(1) - direct collection modification
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:vibe_coder/models/agent_model.dart';
import 'package:vibe_coder/models/agent_status_model.dart';
import 'package:vibe_coder/models/service_statistics.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';

/// AgentService - Universal Agent Collection Management
///
/// ARCHITECTURAL: Service Layer - handles collections with business logic
/// Extends ChangeNotifier for reactive UI updates following architecture protocol
class AgentService extends ChangeNotifier {
  static final Logger _logger = Logger('AgentService');
  final _uuid = const Uuid();

  // ARCHITECTURAL: Mandatory List<DataModel> data field for Service Layer
  List<AgentModel> data = [];

  // Index for O(1) lookups - PERF: HashMap for fast access
  final Map<String, int> _agentIndex = {};

  // Initialization state
  bool _isInitialized = false;

  /// Service initialization status
  bool get isInitialized => _isInitialized;

  /// All agents in the collection
  List<AgentModel> get allAgents => List.unmodifiable(data);

  /// Active agents only
  List<AgentModel> get activeAgents =>
      data.where((agent) => agent.isActive).toList();

  /// Count of all agents
  int get agentCount => data.length;

  /// Initialize agent service - ARCHITECTURAL: Collection setup
  ///
  /// PERF: O(1) - simple initialization
  /// ARCHITECTURAL: Sets up empty collection (no persistence for now)
  Future<void> initialize() async {
    if (_isInitialized) return;

    _logger.info('🚀 AGENT SERVICE: Initializing and loading agents...');
    // Call loadAll to perform the actual loading from persistence.
    // This ensures the service is fully populated before being marked as initialized.
    await loadAll();
    _isInitialized = true;
    _logger.info('✅ AGENT SERVICE: Initialization complete.');
    // No need to call notifyListeners() here, as loadAll() already does it.
  }

  /// Load all agents - ARCHITECTURAL: Collection management
  ///
  /// PERF: O(n) where n = number of persisted agents
  /// ARCHITECTURAL: Loads agents from /data directory following protocol
  Future<void> loadAll() async {
    // This check is removed to prevent a circular dependency when called from initialize().
    // _ensureInitialized();

    _logger.info('📋 AGENT SERVICE: Loading agents from persistence');

    try {
      final dataDir = Directory('data/agents');
      if (!await dataDir.exists()) {
        _logger.info('📁 NO DATA: Agents directory does not exist');
        data = [];
        _rebuildIndex();
        notifyListeners(); // MANDATORY after data changes
        return;
      }

      final files = await dataDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      final loadedAgents = <AgentModel>[];

      for (final file in files) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final agent = AgentModel.fromJson(json);
          loadedAgents.add(agent);
          _logger.fine('✅ LOADED: Agent ${agent.name} (${agent.id})');
        } catch (e, stackTrace) {
          _logger.warning('⚠️ LOAD FAILED: ${file.path} - $e', e, stackTrace);
          // Continue loading other agents, don't fail entire operation
        }
      }

      data = loadedAgents;
      _rebuildIndex();
      _logger.info('📋 LOADED: ${data.length} agents from persistence');
      notifyListeners(); // MANDATORY after data changes
    } catch (e, stackTrace) {
      _logger.severe('💥 LOAD ALL FAILED: $e', e, stackTrace);
      rethrow; // Bubble stack trace to surface
    }
  }

  /// Get agent by ID - ARCHITECTURAL: Filtering function
  ///
  /// PERF: O(1) - HashMap lookup via index
  AgentModel? getById(String id) {
    final index = _agentIndex[id];
    return index != null ? data[index] : null;
  }

  /// Get agent by name - ARCHITECTURAL: Filtering function
  ///
  /// PERF: O(n) where n = number of agents (names not indexed)
  AgentModel? getByName(String name) {
    try {
      return data.firstWhere((agent) => agent.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Create new agent - ARCHITECTURAL: Business logic
  ///
  /// PERF: O(1) - direct model creation + collection update
  /// ARCHITECTURAL: Creates agent and adds to collection with persistence
  Future<AgentModel> createAgent({
    required String name,
    required String systemPrompt,
    String notepad = '',
    bool isActive = true,
    bool isProcessing = false,
    double temperature = 0.7,
    int maxTokens = 4000,
    bool useBetaFeatures = false,
    bool useReasonerModel = false,
    String? mcpConfigPath,
    String? supervisorId,
    List<String>? contextFiles,
    List<String>? toDoList,
    List<ChatMessage>? conversationHistory,
    Map<String, dynamic>? metadata,
  }) async {
    _ensureInitialized();

    final agentId = _uuid.v4();

    _logger.info('🔨 AGENT SERVICE: Creating agent "$name" with ID: $agentId');

    try {
      // Create agent using model constructor
      final agent = AgentModel(
        id: agentId,
        name: name,
        systemPrompt: systemPrompt,
        // NOTE: notepad and toDoList are now handled by MCP servers
        isActive: isActive,
        isProcessing: isProcessing,
        temperature: temperature,
        maxTokens: maxTokens,
        useBetaFeatures: useBetaFeatures,
        useReasonerModel: useReasonerModel,
        mcpConfigPath: mcpConfigPath,
        supervisorId: supervisorId,
        contextFiles: contextFiles,
        conversationHistory: conversationHistory,
        metadata: metadata,
      );

      // ARCHITECTURAL: Model handles its own persistence
      await agent.save();

      // Add to collection and update index
      data.add(agent);
      _agentIndex[agentId] = data.length - 1;

      _logger.info('✅ AGENT SERVICE: Agent "$name" created successfully');

      notifyListeners(); // MANDATORY after data changes

      return agent;
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 AGENT SERVICE: Agent creation failed: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Update agent - ARCHITECTURAL: Business logic with collection sync
  ///
  /// PERF: O(1) - direct model update + collection maintenance
  /// ARCHITECTURAL: Updates agent properties and maintains collection with persistence
  Future<void> updateAgent(
    String agentId, {
    String? name,
    String? systemPrompt,
    // NOTE: notepad is now handled by MCP notepad server
    bool? isActive,
    bool? isProcessing,
    double? temperature,
    int? maxTokens,
    bool? useBetaFeatures,
    bool? useReasonerModel,
    String? mcpConfigPath,
    String? supervisorId,
  }) async {
    _ensureInitialized();

    final agentIndex = _agentIndex[agentId];
    if (agentIndex == null) {
      throw AgentServiceException('Agent not found: $agentId');
    }

    final agent = data[agentIndex];

    _logger.info('🔄 AGENT SERVICE: Updating agent "${agent.name}" ($agentId)');

    try {
      // Create updated agent with new properties
      final updatedAgent = agent.copyWith(
        name: name,
        systemPrompt: systemPrompt,
        // NOTE: notepad is now handled by MCP notepad server
        isActive: isActive,
        isProcessing: isProcessing,
        temperature: temperature,
        maxTokens: maxTokens,
        useBetaFeatures: useBetaFeatures,
        useReasonerModel: useReasonerModel,
        mcpConfigPath: mcpConfigPath,
        supervisorId: supervisorId,
      );

      // ARCHITECTURAL: Model handles its own persistence
      await updatedAgent.save();

      // Replace in collection
      data[agentIndex] = updatedAgent;

      _logger.info('✅ AGENT SERVICE: Agent updated successfully: $agentId');

      notifyListeners(); // MANDATORY after data changes
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 AGENT SERVICE: Agent update failed: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Delete agent - ARCHITECTURAL: Business logic with collection cleanup
  ///
  /// PERF: O(n) - list removal + index rebuild
  /// ARCHITECTURAL: Removes agent from collection and persistence
  Future<void> deleteAgent(String agentId) async {
    _ensureInitialized();

    final agent = getById(agentId);
    if (agent == null) {
      throw AgentServiceException('Agent not found: $agentId');
    }

    _logger
        .info('🗑️ AGENT SERVICE: Deleting agent "${agent.name}" ($agentId)');

    try {
      // ARCHITECTURAL: Model handles its own deletion
      await agent.delete();

      // Remove from collection and rebuild index
      data.removeWhere((a) => a.id == agentId);
      _rebuildIndex();

      _logger.info('✅ AGENT SERVICE: Agent deleted successfully');

      notifyListeners(); // MANDATORY after data changes
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 AGENT SERVICE: Agent deletion failed: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Add message to agent's conversation
  ///
  /// PERF: O(1) - direct agent method call
  /// ARCHITECTURAL: Business logic delegation to model
  Future<void> addMessageToAgent(String agentId, ChatMessage message) async {
    _ensureInitialized();

    final agent = getById(agentId);
    if (agent == null) {
      throw AgentServiceException('Agent not found: $agentId');
    }

    // Add message using model's method
    agent.addMessage(message);

    notifyListeners(); // MANDATORY after data changes
  }

  /// Clear agent's conversation history
  ///
  /// PERF: O(1) - direct agent method call
  /// ARCHITECTURAL: Business logic delegation to model
  Future<void> clearAgentConversation(String agentId) async {
    _ensureInitialized();

    final agent = getById(agentId);
    if (agent == null) {
      throw AgentServiceException('Agent not found: $agentId');
    }

    // Clear conversation using model's method
    agent.clearConversation();

    notifyListeners(); // MANDATORY after data changes
  }

  /// Get agents by status - ARCHITECTURAL: Filtering function
  ///
  /// PERF: O(n) where n = number of agents
  List<AgentModel> getAgentsByStatus({required bool isActive}) {
    return data.where((agent) => agent.isActive == isActive).toList();
  }

  /// Get agents with recent activity - ARCHITECTURAL: Business logic
  ///
  /// PERF: O(n) where n = number of agents
  List<AgentModel> getRecentlyActiveAgents({Duration? since}) {
    final threshold = since ?? const Duration(hours: 24);
    final cutoffTime = DateTime.now().subtract(threshold);

    return data
        .where((agent) => agent.lastActiveAt.isAfter(cutoffTime))
        .toList();
  }

  /// Get conversation statistics - ARCHITECTURAL: Business logic
  ///
  /// PERF: O(n) where n = number of agents
  /// ARCHITECTURAL: Returns strongly-typed conversation statistics
  ConversationStatistics getConversationStatistics() {
    final totalAgents = data.length;
    final activeAgents = data.where((agent) => agent.isActive).length;
    final totalMessages =
        data.fold<int>(0, (sum, agent) => sum + agent.messageCount);
    final agentsWithConversations =
        data.where((agent) => agent.hasConversation).length;

    return ConversationStatistics(
      totalAgents: totalAgents,
      activeAgents: activeAgents,
      totalMessages: totalMessages,
      agentsWithConversations: agentsWithConversations,
      averageMessagesPerAgent:
          totalAgents > 0 ? (totalMessages / totalAgents).round() : 0,
    );
  }

  /// Get conversation statistics (legacy format)
  ///
  /// DEPRECATED: Use getConversationStatistics() which returns strongly-typed data
  /// ARCHITECTURAL: Temporary bridge during migration period
  Map<String, dynamic> getConversationStatisticsLegacy() {
    return getConversationStatistics().toJson();
  }

  // DR004 INTEGRATION: Status query methods (eliminates need for separate AgentStatusService)

  /// Get agents by processing status - ARCHITECTURAL: Status filtering
  ///
  /// PERF: O(n) where n = number of agents
  /// ARCHITECTURAL: Single source of truth - queries AgentModel status directly
  List<AgentModel> getProcessingAgents() {
    _ensureInitialized();
    return data
        .where((agent) =>
            agent.processingStatus == AgentProcessingStatus.processing)
        .toList();
  }

  /// Get idle agents - ARCHITECTURAL: Status filtering
  ///
  /// PERF: O(n) where n = number of agents
  /// ARCHITECTURAL: Single source of truth - queries AgentModel status directly
  List<AgentModel> getIdleAgents() {
    _ensureInitialized();
    return data
        .where((agent) => agent.processingStatus == AgentProcessingStatus.idle)
        .toList();
  }

  /// Get agents with errors - ARCHITECTURAL: Status filtering
  ///
  /// PERF: O(n) where n = number of agents
  /// ARCHITECTURAL: Single source of truth - queries AgentModel status directly
  List<AgentModel> getErrorAgents() {
    _ensureInitialized();
    return data
        .where((agent) => agent.processingStatus == AgentProcessingStatus.error)
        .toList();
  }

  /// Get status summary - ARCHITECTURAL: Business logic aggregation
  ///
  /// PERF: O(n) where n = number of agents
  /// ARCHITECTURAL: Single pass through collection for efficiency
  Map<String, int> getStatusSummary() {
    _ensureInitialized();

    int processingCount = 0;
    int idleCount = 0;
    int errorCount = 0;

    for (final agent in data) {
      switch (agent.processingStatus) {
        case AgentProcessingStatus.processing:
          processingCount++;
          break;
        case AgentProcessingStatus.idle:
          idleCount++;
          break;
        case AgentProcessingStatus.error:
          errorCount++;
          break;
      }
    }

    return {
      'total': data.length,
      'processing': processingCount,
      'idle': idleCount,
      'error': errorCount,
    };
  }

  /// Get agents with recent status changes - ARCHITECTURAL: Time-based filtering
  ///
  /// PERF: O(n) where n = number of agents
  /// ARCHITECTURAL: Uses AgentModel status timestamps directly
  List<AgentModel> getRecentStatusChanges({Duration? since}) {
    _ensureInitialized();
    final threshold = since ?? const Duration(minutes: 5);
    final cutoffTime = DateTime.now().subtract(threshold);

    return data
        .where((agent) => agent.lastStatusChange.isAfter(cutoffTime))
        .toList();
  }

  /// Add agent directly to collection - ARCHITECTURAL: Direct mutation support
  ///
  /// PERF: O(1) - direct collection addition with index update
  /// ARCHITECTURAL: Supports single source of truth pattern
  void addAgentDirectly(AgentModel agent) {
    _ensureInitialized();

    data.add(agent);
    _agentIndex[agent.id] = data.length - 1;

    notifyListeners(); // MANDATORY after data changes
  }

  /// Replace agent in collection - ARCHITECTURAL: Direct mutation support
  ///
  /// PERF: O(1) - direct collection replacement with persistence
  /// ARCHITECTURAL: Supports single source of truth pattern with disk persistence
  Future<void> replaceAgent(String agentId, AgentModel updatedAgent) async {
    _ensureInitialized();

    final index = _agentIndex[agentId];
    if (index != null && index < data.length) {
      // Invalidate the old agent's instance cache to force recreation with new preferences
      final oldAgent = data[index];
      oldAgent.invalidateAgentInstance();

      // ARCHITECTURAL: Model handles its own persistence
      await updatedAgent.save();

      // Replace with updated agent
      data[index] = updatedAgent;
      notifyListeners(); // MANDATORY after data changes
    } else {
      throw AgentServiceException('Agent not found for replacement: $agentId');
    }
  }

  /// Rebuild agent index for O(1) lookups
  ///
  /// PERF: O(n) where n = number of agents
  void _rebuildIndex() {
    _agentIndex.clear();
    for (int i = 0; i < data.length; i++) {
      _agentIndex[data[i].id] = i;
    }
  }

  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw AgentServiceException('AgentService not initialized');
    }
  }

  /// Cleanup resources - ARCHITECTURAL: Service cleanup
  ///
  /// PERF: O(1) - service state cleanup
  @override
  void dispose() {
    _logger.info('🧹 AGENT SERVICE: Disposing resources');

    data.clear();
    _agentIndex.clear();
    _isInitialized = false;

    super.dispose();

    _logger.info('✅ AGENT SERVICE: Cleanup completed');
  }
}

/// Exception for agent service operations
class AgentServiceException implements Exception {
  final String message;

  AgentServiceException(this.message);

  @override
  String toString() => 'AgentServiceException: $message';
}
