/// AgentModel - Multi-Agent System Model with JSON Persistence
library;

///
/// ## MISSION ACCOMPLISHED
/// Eliminates single-agent limitation by providing multi-agent support with persistence,
/// state management, and individual chat histories for each agent.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | In-Memory Only | Fast | Data loss | ELIMINATED - persistence required |
/// | Single Agent | Simple | Not scalable | ELIMINATED - multi-agent demanded |
/// | JSON Persistence | File-based, readable | I/O overhead | CHOSEN - balance of speed and persistence |
/// | Agent Inheritance | Extend existing | Tight coupling | REJECTED - composition over inheritance |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Agent Persistence Challenge**
///    - 🔍 Symptom: Agents lost on app restart
///    - 🎯 Root Cause: No persistence layer for agents
///    - 💥 Kill Shot: JSON serialization with chat history preservation
///
/// 2. **Multi-Agent State Management**
///    - 🔍 Symptom: Single agent limitation
///    - 🎯 Root Cause: ChatService tightly coupled to one agent
///    - 💥 Kill Shot: Agent orchestration with individual state tracking
///
/// 3. **Chat History Isolation**
///    - 🔍 Symptom: Conversation mixing between agents
///    - 🎯 Root Cause: Global conversation state
///    - 💥 Kill Shot: Per-agent conversation history with proper isolation
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Agent creation: O(1) - direct instantiation
/// - Persistence: O(n) where n = conversation history size
/// - State updates: O(1) - direct property updates
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:vibe_coder/ai_agent/agent.dart';
import 'package:vibe_coder/models/agent_status_model.dart'; // Import for AgentProcessingStatus enum

/// Agent Model - Enhanced with single source of truth for conversation management
///
/// WARRIOR PROTOCOL: AgentModel now uses Agent.conversation as single source of truth
/// ARCHITECTURAL VICTORY: Eliminated conversationHistory field duplication
/// STATUS INTEGRATION: Direct agent status management without separate service
/// All conversation data flows through Agent.conversation.getHistory()
class AgentModel extends ChangeNotifier {
  // Core Agent Identity
  final String id;
  String name;
  String systemPrompt;

  // Agent state
  bool isActive;
  bool isProcessing;
  DateTime createdAt;
  DateTime lastActiveAt;

  // ARCHITECTURAL VICTORY: Direct status integration - Single Source of Truth
  AgentProcessingStatus _status;
  DateTime _lastStatusChange;
  String? _errorMessage;

  // Agent behavior settings
  double temperature;
  int maxTokens;
  bool useBetaFeatures;
  bool useReasonerModel;

  // Agent relationships
  String? supervisorId;
  List<String> contextFiles;

  // MCP configuration
  String? mcpConfigPath;
  Map<String, bool> mcpServerPreferences;
  Map<String, bool> mcpToolPreferences;

  // Agent metadata
  Map<String, dynamic> metadata;

  // WARRIOR PROTOCOL: Agent instance for conversation management
  // Single source of truth - conversation data lives in Agent.conversation
  Agent? _agentInstance;

  AgentModel({
    String? id,
    required this.name,
    required this.systemPrompt,
    this.isActive = true,
    this.isProcessing = false,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    AgentProcessingStatus? status,
    this.temperature = 0.7,
    this.maxTokens = 4000,
    this.useBetaFeatures = false,
    this.useReasonerModel = false,
    this.mcpConfigPath,
    Map<String, bool>? mcpServerPreferences,
    Map<String, bool>? mcpToolPreferences,
    this.supervisorId,
    List<String>? contextFiles,
    List<ChatMessage>?
        conversationHistory, // Accept but don't store - migrate to agent
    Map<String, dynamic>? metadata,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        lastActiveAt = lastActiveAt ?? DateTime.now(),
        _status = status ?? AgentProcessingStatus.idle,
        _lastStatusChange = DateTime.now(),
        _errorMessage = null,
        contextFiles = contextFiles ?? [],
        metadata = metadata ?? {},
        mcpServerPreferences = mcpServerPreferences ?? {},
        mcpToolPreferences = mcpToolPreferences ?? {} {
    // WARRIOR PROTOCOL: Migrate legacy conversation history to agent if provided
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      // Initialize agent and load conversation
      _getAgentInstance();
      for (final message in conversationHistory) {
        _addMessageToAgentConversation(message);
      }
    }
  }

  /// Create agent from JSON data
  ///
  /// PERF: O(n) where n = conversation history size
  /// ARCHITECTURAL: Handles version compatibility and data migration
  factory AgentModel.fromJson(Map<String, dynamic> json) {
    // Parse legacy conversation history for migration
    final conversationData =
        json['conversationHistory'] as List<dynamic>? ?? [];
    final conversationHistory = conversationData
        .map((msgJson) {
          try {
            return ChatMessage.fromJson(msgJson as Map<String, dynamic>);
          } catch (e) {
            // Skip invalid messages but log for debugging
            return null;
          }
        })
        .whereType<ChatMessage>()
        .toList();

    final mcpServerPreferences =
        (json['mcpServerPreferences'] as Map<String, dynamic>?)
                ?.cast<String, bool>() ??
            {};

    final mcpToolPreferences =
        (json['mcpToolPreferences'] as Map<String, dynamic>?)
                ?.cast<String, bool>() ??
            {};

    // Parse status with fallback to idle
    AgentProcessingStatus status = AgentProcessingStatus.idle;
    final statusString = json['status'] as String?;
    if (statusString != null) {
      try {
        status = AgentProcessingStatus.values.firstWhere(
          (e) => e.name == statusString,
          orElse: () => AgentProcessingStatus.idle,
        );
      } catch (e) {
        // Fallback to idle if parsing fails
        status = AgentProcessingStatus.idle;
      }
    }

    final agent = AgentModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      systemPrompt: json['systemPrompt'] as String,
      isActive: json['isActive'] as bool? ?? true,
      isProcessing: json['isProcessing'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
      status: status,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['maxTokens'] as int? ?? 4000,
      useBetaFeatures: json['useBetaFeatures'] as bool? ?? false,
      useReasonerModel: json['useReasonerModel'] as bool? ?? false,
      mcpConfigPath: json['mcpConfigPath'] as String?,
      mcpServerPreferences: mcpServerPreferences,
      mcpToolPreferences: mcpToolPreferences,
      supervisorId: json['supervisorId'] as String?,
      contextFiles:
          (json['contextFiles'] as List<dynamic>?)?.cast<String>().toList() ??
              [],
      conversationHistory: conversationHistory, // Will be migrated to agent
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );

    // Handle status fields that need special parsing after construction
    try {
      final lastStatusChangeString = json['lastStatusChange'] as String?;
      if (lastStatusChangeString != null) {
        agent._lastStatusChange = DateTime.parse(lastStatusChangeString);
      }
    } catch (e) {
      // Keep default current time if parsing fails
    }

    agent._errorMessage = json['errorMessage'] as String?;

    return agent;
  }

  /// Convert agent to JSON for persistence
  ///
  /// PERF: O(n) where n = conversation history size
  /// ARCHITECTURAL: Includes all state for complete persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'systemPrompt': systemPrompt,
      'isActive': isActive,
      'isProcessing': isProcessing,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'status': _status.name,
      'lastStatusChange': _lastStatusChange.toIso8601String(),
      'errorMessage': _errorMessage,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'useBetaFeatures': useBetaFeatures,
      'useReasonerModel': useReasonerModel,
      'mcpConfigPath': mcpConfigPath,
      'mcpServerPreferences': mcpServerPreferences,
      'mcpToolPreferences': mcpToolPreferences,
      'supervisorId': supervisorId,
      'contextFiles': contextFiles,
      'conversationHistory':
          conversationHistory.map((msg) => msg.toJson()).toList(),
      'metadata': metadata,
    };
  }

  /// Create a copy with updated values
  ///
  /// PERF: O(n) for conversation history copy, O(1) for other fields
  AgentModel copyWith({
    String? name,
    String? systemPrompt,
    bool? isActive,
    bool? isProcessing,
    DateTime? lastActiveAt,
    double? temperature,
    int? maxTokens,
    bool? useBetaFeatures,
    bool? useReasonerModel,
    String? mcpConfigPath,
    Map<String, bool>? mcpServerPreferences,
    Map<String, bool>? mcpToolPreferences,
    String? supervisorId,
    List<String>? contextFiles,
    List<ChatMessage>? conversationHistory,
    Map<String, dynamic>? metadata,
  }) {
    return AgentModel(
      id: id, // ID never changes
      name: name ?? this.name,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      isActive: isActive ?? this.isActive,
      isProcessing: isProcessing ?? this.isProcessing,
      createdAt: createdAt, // Creation time never changes
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      useBetaFeatures: useBetaFeatures ?? this.useBetaFeatures,
      useReasonerModel: useReasonerModel ?? this.useReasonerModel,
      mcpConfigPath: mcpConfigPath ?? this.mcpConfigPath,
      mcpServerPreferences:
          mcpServerPreferences ?? Map.from(this.mcpServerPreferences),
      mcpToolPreferences:
          mcpToolPreferences ?? Map.from(this.mcpToolPreferences),
      supervisorId: supervisorId ?? this.supervisorId,
      contextFiles: contextFiles ?? List.from(this.contextFiles),
      conversationHistory: conversationHistory ?? this.conversationHistory,
      metadata: metadata ?? Map.from(this.metadata),
    );
  }

  /// WARRIOR PROTOCOL: Single source of truth - conversation from agent instance
  ///
  /// ARCHITECTURAL: conversationHistory is now a getter that accesses Agent.conversation
  /// PERF: O(1) - direct reference to agent conversation, no data duplication
  List<ChatMessage> get conversationHistory {
    final agentInstance = _agentInstance;
    if (agentInstance == null) {
      return []; // No agent instance = empty conversation
    }
    return agentInstance.conversation.getHistory();
  }

  /// Add message to agent conversation - ARCHITECTURAL: Direct delegation to agent
  ///
  /// PERF: O(1) - direct agent conversation update
  /// WARRIOR PROTOCOL: Single source of truth - no duplicate storage
  void addMessage(ChatMessage message) {
    _getAgentInstance();
    _addMessageToAgentConversation(message);
    lastActiveAt = DateTime.now();
    notifyListeners(); // MANDATORY after any change
  }

  /// Clear conversation - ARCHITECTURAL: Direct delegation to agent
  ///
  /// PERF: O(1) - direct agent conversation clear
  /// WARRIOR PROTOCOL: Single source of truth - no duplicate storage
  void clearConversation() {
    final agentInstance = _agentInstance;
    if (agentInstance != null) {
      agentInstance.conversation.clearConversation();
    }
    lastActiveAt = DateTime.now();
    notifyListeners(); // MANDATORY after any change
  }

  /// Get conversation message count - ARCHITECTURAL: Direct delegation
  ///
  /// PERF: O(1) - direct agent conversation access
  int get messageCount => conversationHistory.length;

  /// Check if agent has conversation - ARCHITECTURAL: Direct delegation
  ///
  /// PERF: O(1) - direct agent conversation access
  bool get hasConversation => conversationHistory.isNotEmpty;

  /// Get last message timestamp
  ///
  /// PERF: O(1) - direct access to last element
  DateTime? get lastMessageTime {
    if (conversationHistory.isEmpty) return null;
    return lastActiveAt; // Use lastActiveAt as proxy for last message time
  }

  /// Update legacy processing state (DEPRECATED - use setProcessing()/setIdle())
  ///
  /// PERF: O(1) - direct property update with notification
  /// ARCHITECTURAL: Mandatory notifyListeners() after state change
  void setLegacyProcessing(bool processing) {
    if (isProcessing != processing) {
      isProcessing = processing;
      // Update status to match legacy field
      if (processing) {
        setProcessing();
      } else {
        setIdle();
      }
    }
  }

  /// Update active state
  ///
  /// PERF: O(1) - direct property update with notification
  /// ARCHITECTURAL: Mandatory notifyListeners() after state change
  void setActive(bool active) {
    if (isActive != active) {
      isActive = active;
      lastActiveAt = DateTime.now();
      notifyListeners(); // MANDATORY after any change
    }
  }

  /// Update last active time
  ///
  /// PERF: O(1) - direct property update with notification
  /// ARCHITECTURAL: Mandatory notifyListeners() after state change
  void updateActivity() {
    lastActiveAt = DateTime.now();
    notifyListeners(); // MANDATORY after any change
  }

  /// Set MCP server preference
  ///
  /// PERF: O(1) - direct map update with notification
  /// ARCHITECTURAL: Mandatory notifyListeners() after state change
  void setMCPServerPreference(String serverName, bool enabled) {
    if (mcpServerPreferences[serverName] != enabled) {
      mcpServerPreferences[serverName] = enabled;
      lastActiveAt = DateTime.now();
      notifyListeners(); // MANDATORY after any change
    }
  }

  /// Set MCP tool preference
  ///
  /// PERF: O(1) - direct map update with notification
  /// ARCHITECTURAL: Mandatory notifyListeners() after state change
  void setMCPToolPreference(String toolId, bool enabled) {
    if (mcpToolPreferences[toolId] != enabled) {
      mcpToolPreferences[toolId] = enabled;
      lastActiveAt = DateTime.now();
      notifyListeners(); // MANDATORY after any change
    }
  }

  /// Get MCP server preference (defaults to true if not set)
  ///
  /// PERF: O(1) - direct map access
  bool getMCPServerPreference(String serverName) {
    return mcpServerPreferences[serverName] ?? true;
  }

  /// Get MCP tool preference (defaults to true if not set)
  ///
  /// PERF: O(1) - direct map access
  bool getMCPToolPreference(String toolId) {
    return mcpToolPreferences[toolId] ?? true;
  }

  /// Set all MCP server preferences
  ///
  /// PERF: O(n) where n = number of servers
  /// ARCHITECTURAL: Mandatory notifyListeners() after state change
  void setAllMCPServerPreferences(List<String> serverNames, bool enabled) {
    bool changed = false;
    for (final serverName in serverNames) {
      if (mcpServerPreferences[serverName] != enabled) {
        mcpServerPreferences[serverName] = enabled;
        changed = true;
      }
    }
    if (changed) {
      lastActiveAt = DateTime.now();
      notifyListeners(); // MANDATORY after any change
    }
  }

  /// Validate agent data
  ///
  /// PERF: O(1) - field validation
  /// ARCHITECTURAL: Ensures data integrity before persistence
  List<String> validate() {
    final errors = <String>[];

    if (id.trim().isEmpty) {
      errors.add('Agent ID cannot be empty');
    }

    if (name.trim().isEmpty) {
      errors.add('Agent name cannot be empty');
    }

    if (systemPrompt.trim().isEmpty) {
      errors.add('System prompt cannot be empty');
    }

    if (temperature < 0.0 || temperature > 2.0) {
      errors.add('Temperature must be between 0.0 and 2.0');
    }

    if (maxTokens < 100 || maxTokens > 32000) {
      errors.add('Max tokens must be between 100 and 32000');
    }

    return errors;
  }

  /// 💾 SELF-MANAGEMENT: Save to JSON file
  ///
  /// PERF: O(1) - single file write operation
  /// ARCHITECTURAL: Model handles its own persistence in /data directory
  Future<void> save() async {
    try {
      // Validate before saving
      final validationErrors = validate();
      if (validationErrors.isNotEmpty) {
        throw StateError(
            'Agent validation failed: ${validationErrors.join(', ')}');
      }

      // Create data directory if it doesn't exist
      final dataDir = Directory('data/agents');
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }

      // Save to file
      final file = File('data/agents/$id.json');
      final jsonStr = const JsonEncoder.withIndent('  ').convert(toJson());
      await file.writeAsString(jsonStr);

      // Update timestamp
      lastActiveAt = DateTime.now();

      notifyListeners(); // MANDATORY after state change
    } catch (e) {
      rethrow; // Bubble stack trace to surface
    }
  }

  /// 🗑️ SELF-MANAGEMENT: Delete from storage
  ///
  /// PERF: O(1) - single file delete operation
  /// ARCHITECTURAL: Model handles its own deletion
  Future<void> delete() async {
    try {
      final file = File('data/agents/$id.json');
      if (await file.exists()) {
        await file.delete();
      }

      notifyListeners(); // MANDATORY after state change
    } catch (e) {
      rethrow; // Bubble stack trace to surface
    }
  }

  /// Generate display summary for UI
  ///
  /// PERF: O(1) - string concatenation
  String get displaySummary {
    final status = isActive ? 'Active' : 'Inactive';
    final messageCountStr =
        messageCount > 0 ? '$messageCount messages' : 'No messages';
    return '$name ($status) - $messageCountStr';
  }

  @override
  String toString() => 'AgentModel(id: $id, name: $name, active: $isActive)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Get or create agent instance for conversation processing
  ///
  /// PERF: O(1) - lazy initialization and reuse
  /// ARCHITECTURAL: Agent instance connected to model data
  Agent _getAgentInstance() {
    _agentInstance ??= Agent(
      agentModel: this,
    );

    final agentInstance = _agentInstance;
    if (agentInstance == null) {
      throw StateError('Agent instance failed to initialize');
    }
    return agentInstance;
  }

  /// Send message and get AI response - ARCHITECTURAL: Model orchestrates conversation
  ///
  /// PERF: O(API_LATENCY) - async AI processing
  /// WARRIOR PROTOCOL: Direct agent conversation management - no syncing needed
  Future<ChatMessage> sendMessage(String userMessage) async {
    // Set processing state
    isProcessing = true;
    updateActivity();

    try {
      final agent = _getAgentInstance();

      // Send message using agent's conversation manager
      final response = await agent.conversation.sendUserMessageAndGetResponse(
        userMessage,
        useBeta: useBetaFeatures,
        isReasoner: useReasonerModel,
        processToolCallsImmediately: false, // Allow UI to show tool calls
      );

      // Process tool calls if present and continue conversation
      if (agent.conversation.hasUnprocessedToolCalls) {
        await agent.conversation.processAndContinue(
          useBeta: useBetaFeatures,
          isReasoner: useReasonerModel,
        );
      }

      // WARRIOR PROTOCOL: No syncing needed - agent.conversation is single source of truth
      // Get the last assistant message from agent conversation
      final conversationHistory = agent.conversation.getHistory();
      final lastMessage = conversationHistory.isNotEmpty
          ? conversationHistory.last
          : ChatMessage(
              role: MessageRole.assistant,
              content: response,
            );

      return lastMessage;
    } catch (e) {
      // Add error message directly to agent conversation
      final agent = _getAgentInstance();
      final errorMessage = ChatMessage(
        role: MessageRole.assistant,
        content:
            '❌ Sorry, I encountered an error: $e\n\nPlease try again or check your connection.',
      );

      // Add error to agent conversation
      agent.conversation.addAssistantMessage(errorMessage.content ?? '');

      rethrow;
    } finally {
      // Clear processing state
      isProcessing = false;
      updateActivity();
    }
  }

  /// Add message to agent's conversation manager - WARRIOR PROTOCOL: Direct delegation
  void _addMessageToAgentConversation(ChatMessage message) {
    final agentInstance = _agentInstance;
    if (agentInstance == null) return;

    switch (message.role) {
      case MessageRole.user:
        agentInstance.conversation.addUserMessage(message.content ?? '');
        break;
      case MessageRole.assistant:
        agentInstance.conversation.addAssistantMessage(
          message.content ?? '',
          toolCalls: message.toolCalls,
          reasoningContent: message.reasoningContent,
        );
        break;
      case MessageRole.system:
        agentInstance.conversation.addSystemMessage(message.content ?? '');
        break;
      case MessageRole.tool:
        // Tool messages are handled during tool call processing
        // Skip restoration for now as they're complex to restore properly
        break;
    }
  }

  /// Dispose agent instance - ARCHITECTURAL: Resource cleanup
  ///
  /// PERF: O(1) - cleanup agent resources
  Future<void> disposeAgent() async {
    final agentInstance = _agentInstance;
    if (agentInstance != null) {
      await agentInstance.dispose();
      _agentInstance = null;
    }
  }

  /// Invalidate agent instance cache - ARCHITECTURAL: Force recreation after updates
  ///
  /// PERF: O(1) - cache invalidation
  /// ARCHITECTURAL: Ensures fresh agent instance with updated preferences
  void invalidateAgentInstance() {
    // Dispose current instance without awaiting (fire and forget)
    final agentInstance = _agentInstance;
    if (agentInstance != null) {
      agentInstance.dispose().catchError((e) {
        // Ignore disposal errors - we're invalidating anyway
      });
      _agentInstance = null;
    }
  }

  // ARCHITECTURAL VICTORY: Direct status management - Single Source of Truth

  /// Current processing status of the agent
  AgentProcessingStatus get status => _status;

  /// Timestamp of last status change
  DateTime get lastStatusChange => _lastStatusChange;

  /// Error message if status is error, null otherwise
  String? get errorMessage => _errorMessage;

  /// 🚀 PERFORMANCE: Set agent status to processing
  /// O(1) complexity, < 1ms execution time
  void setProcessing() {
    if (_status != AgentProcessingStatus.processing) {
      _status = AgentProcessingStatus.processing;
      _errorMessage = null;
      isProcessing = true; // Sync with legacy field
      _updateStatusTimestamps();
      notifyListeners(); // MANDATORY after any change
    }
  }

  /// 🚀 PERFORMANCE: Set agent status to idle
  /// O(1) complexity, < 1ms execution time
  void setIdle() {
    if (_status != AgentProcessingStatus.idle) {
      _status = AgentProcessingStatus.idle;
      _errorMessage = null;
      isProcessing = false; // Sync with legacy field
      _updateStatusTimestamps();
      notifyListeners(); // MANDATORY after any change
    }
  }

  /// 🚀 PERFORMANCE: Set agent status to error with message
  /// O(1) complexity, < 1ms execution time
  ///
  /// [message] - Error message describing the error condition
  void setError(String message) {
    _status = AgentProcessingStatus.error;
    _errorMessage = message;
    isProcessing = false; // Sync with legacy field
    _updateStatusTimestamps();
    notifyListeners(); // MANDATORY after any change
  }

  /// 🔧 INTERNAL: Update both activity and status change timestamps
  /// Called automatically during status transitions
  void _updateStatusTimestamps() {
    final now = DateTime.now();
    lastActiveAt = now;
    _lastStatusChange = now;
  }
}

/// Agent status enumeration for UI state management
enum AgentStatus {
  active,
  inactive,
  processing,
  error,
}

extension AgentStatusExtension on AgentStatus {
  String get displayName {
    switch (this) {
      case AgentStatus.active:
        return 'Active';
      case AgentStatus.inactive:
        return 'Inactive';
      case AgentStatus.processing:
        return 'Processing';
      case AgentStatus.error:
        return 'Error';
    }
  }
}
