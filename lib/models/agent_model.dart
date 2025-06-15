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
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';

/// AgentModel - Complete agent representation with persistence
///
/// ARCHITECTURAL: This model represents a complete agent instance including
/// configuration, state, and conversation history for multi-agent system support
class AgentModel {
  // Unique identifier for agent
  final String id;

  // Agent configuration
  String name;
  String systemPrompt;
  String notepad;

  // Agent state
  bool isActive;
  bool isProcessing;
  DateTime createdAt;
  DateTime lastActiveAt;

  // Agent behavior settings
  double temperature;
  int maxTokens;
  bool useBetaFeatures;
  bool useReasonerModel;

  // MCP configuration
  String? mcpConfigPath;

  // Agent relationships
  String? supervisorId;
  List<String> contextFiles;
  List<String> toDoList;

  // Conversation history - per agent isolation
  List<ChatMessage> conversationHistory;

  // Agent metadata
  Map<String, dynamic> metadata;

  AgentModel({
    required this.id,
    required this.name,
    required this.systemPrompt,
    this.notepad = '',
    this.isActive = true,
    this.isProcessing = false,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    this.temperature = 0.7,
    this.maxTokens = 4000,
    this.useBetaFeatures = false,
    this.useReasonerModel = false,
    this.mcpConfigPath,
    this.supervisorId,
    List<String>? contextFiles,
    List<String>? toDoList,
    List<ChatMessage>? conversationHistory,
    Map<String, dynamic>? metadata,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActiveAt = lastActiveAt ?? DateTime.now(),
        contextFiles = contextFiles ?? [],
        toDoList = toDoList ?? [],
        conversationHistory = conversationHistory ?? [],
        metadata = metadata ?? {};

  /// Create agent from JSON data
  ///
  /// PERF: O(n) where n = conversation history size
  /// ARCHITECTURAL: Handles version compatibility and data migration
  factory AgentModel.fromJson(Map<String, dynamic> json) {
    // Parse conversation history with proper error handling
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

    return AgentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      systemPrompt: json['systemPrompt'] as String,
      notepad: json['notepad'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      isProcessing: json['isProcessing'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['maxTokens'] as int? ?? 4000,
      useBetaFeatures: json['useBetaFeatures'] as bool? ?? false,
      useReasonerModel: json['useReasonerModel'] as bool? ?? false,
      mcpConfigPath: json['mcpConfigPath'] as String?,
      supervisorId: json['supervisorId'] as String?,
      contextFiles: List<String>.from(json['contextFiles'] as List? ?? []),
      toDoList: List<String>.from(json['toDoList'] as List? ?? []),
      conversationHistory: conversationHistory,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
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
      'notepad': notepad,
      'isActive': isActive,
      'isProcessing': isProcessing,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'temperature': temperature,
      'maxTokens': maxTokens,
      'useBetaFeatures': useBetaFeatures,
      'useReasonerModel': useReasonerModel,
      'mcpConfigPath': mcpConfigPath,
      'supervisorId': supervisorId,
      'contextFiles': contextFiles,
      'toDoList': toDoList,
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
    String? notepad,
    bool? isActive,
    bool? isProcessing,
    DateTime? lastActiveAt,
    double? temperature,
    int? maxTokens,
    bool? useBetaFeatures,
    bool? useReasonerModel,
    String? mcpConfigPath,
    String? supervisorId,
    List<String>? contextFiles,
    List<String>? toDoList,
    List<ChatMessage>? conversationHistory,
    Map<String, dynamic>? metadata,
  }) {
    return AgentModel(
      id: id, // ID never changes
      name: name ?? this.name,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      notepad: notepad ?? this.notepad,
      isActive: isActive ?? this.isActive,
      isProcessing: isProcessing ?? this.isProcessing,
      createdAt: createdAt, // Creation time never changes
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      useBetaFeatures: useBetaFeatures ?? this.useBetaFeatures,
      useReasonerModel: useReasonerModel ?? this.useReasonerModel,
      mcpConfigPath: mcpConfigPath ?? this.mcpConfigPath,
      supervisorId: supervisorId ?? this.supervisorId,
      contextFiles: contextFiles ?? List.from(this.contextFiles),
      toDoList: toDoList ?? List.from(this.toDoList),
      conversationHistory:
          conversationHistory ?? List.from(this.conversationHistory),
      metadata: metadata ?? Map.from(this.metadata),
    );
  }

  /// Add message to conversation history
  ///
  /// PERF: O(1) - direct list append
  void addMessage(ChatMessage message) {
    conversationHistory.add(message);
    lastActiveAt = DateTime.now();
  }

  /// Clear conversation history
  ///
  /// PERF: O(1) - list clear operation
  void clearConversation() {
    conversationHistory.clear();
    lastActiveAt = DateTime.now();
  }

  /// Get conversation history count
  ///
  /// PERF: O(1) - direct list length access
  int get messageCount => conversationHistory.length;

  /// Check if agent has any conversation
  ///
  /// PERF: O(1) - boolean check
  bool get hasConversation => conversationHistory.isNotEmpty;

  /// Get last message timestamp
  ///
  /// PERF: O(1) - direct access to last element
  DateTime? get lastMessageTime {
    if (conversationHistory.isEmpty) return null;
    return lastActiveAt; // Use lastActiveAt as proxy for last message time
  }

  /// Update last active time
  ///
  /// PERF: O(1) - direct property update
  void updateActivity() {
    lastActiveAt = DateTime.now();
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
