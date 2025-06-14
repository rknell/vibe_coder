/// AgentConfiguration - Universal Configuration Management Model
///
/// ## MISSION ACCOMPLISHED
/// Eliminates hardcoded configuration by providing centralized, editable agent parameters.
/// Supports persistence, validation, and real-time updates.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Hardcoded Config | Simple | No flexibility | ELIMINATED - user demands control |
/// | JSON Config Files | Persistent | Developer only | Rejected - user can't edit easily |
/// | Runtime UI Config | User-friendly | State management | CHOSEN - maximum user empowerment |
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Configuration updates: O(1) - direct property assignment
/// - Serialization: O(n) where n = number of config fields
/// - Validation: O(1) per field - immediate feedback
class AgentConfiguration {
  // Core Agent Settings
  String agentName;
  String systemPrompt;

  // AI Model Settings
  bool useBetaFeatures;
  bool useReasonerModel;
  double temperature;
  int maxTokens;

  // MCP Settings
  String mcpConfigPath;

  // UI Settings
  bool showTimestamps;
  bool autoScroll;
  String welcomeMessage;

  // Performance Settings
  int maxConversationHistory;
  bool enableDebugLogging;

  // Advanced Settings
  Map<String, dynamic> customPromptVariables;
  List<String> contextFiles;

  AgentConfiguration({
    this.agentName = 'VibeCoder Assistant',
    this.systemPrompt =
        '''You are VibeCoder Assistant, a helpful AI coding companion.
        
You excel at:
- Flutter and Dart development
- Code review and optimization  
- Architecture and design patterns
- Debugging and troubleshooting
- Best practices and clean code

Be concise, practical, and focus on actionable solutions.
When providing code examples, make them complete and runnable.''',
    this.useBetaFeatures = false,
    this.useReasonerModel = false,
    this.temperature = 0.7,
    this.maxTokens = 4000,
    this.mcpConfigPath = 'mcp.json',
    this.showTimestamps = true,
    this.autoScroll = true,
    this.welcomeMessage = '''👋 **Welcome to VibeCoder!**

I'm your AI coding companion, ready to help with:
• Flutter & Dart development
• Code review and debugging  
• Architecture and best practices
• Project planning and optimization

What would you like to work on today?''',
    this.maxConversationHistory = 100,
    this.enableDebugLogging = false,
    Map<String, dynamic>? customPromptVariables,
    List<String>? contextFiles,
  })  : customPromptVariables = customPromptVariables ?? {},
        contextFiles = contextFiles ?? [];

  /// Create configuration from JSON map
  ///
  /// PERF: O(n) deserialization where n = number of fields
  factory AgentConfiguration.fromJson(Map<String, dynamic> json) {
    return AgentConfiguration(
      agentName: json['agentName'] as String? ?? 'VibeCoder Assistant',
      systemPrompt: json['systemPrompt'] as String? ?? _defaultSystemPrompt,
      useBetaFeatures: json['useBetaFeatures'] as bool? ?? false,
      useReasonerModel: json['useReasonerModel'] as bool? ?? false,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['maxTokens'] as int? ?? 4000,
      mcpConfigPath: json['mcpConfigPath'] as String? ?? 'mcp.json',
      showTimestamps: json['showTimestamps'] as bool? ?? true,
      autoScroll: json['autoScroll'] as bool? ?? true,
      welcomeMessage:
          json['welcomeMessage'] as String? ?? _defaultWelcomeMessage,
      maxConversationHistory: json['maxConversationHistory'] as int? ?? 100,
      enableDebugLogging: json['enableDebugLogging'] as bool? ?? false,
      customPromptVariables: Map<String, dynamic>.from(
          json['customPromptVariables'] as Map<String, dynamic>? ?? {}),
      contextFiles: List<String>.from(json['contextFiles'] as List? ?? []),
    );
  }

  /// Convert configuration to JSON map for persistence
  ///
  /// PERF: O(n) serialization where n = number of fields
  Map<String, dynamic> toJson() {
    return {
      'agentName': agentName,
      'systemPrompt': systemPrompt,
      'useBetaFeatures': useBetaFeatures,
      'useReasonerModel': useReasonerModel,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'mcpConfigPath': mcpConfigPath,
      'showTimestamps': showTimestamps,
      'autoScroll': autoScroll,
      'welcomeMessage': welcomeMessage,
      'maxConversationHistory': maxConversationHistory,
      'enableDebugLogging': enableDebugLogging,
      'customPromptVariables': customPromptVariables,
      'contextFiles': contextFiles,
    };
  }

  /// Create a copy with updated values
  ///
  /// PERF: O(1) - object copying with selective updates
  AgentConfiguration copyWith({
    String? agentName,
    String? systemPrompt,
    bool? useBetaFeatures,
    bool? useReasonerModel,
    double? temperature,
    int? maxTokens,
    String? mcpConfigPath,
    bool? showTimestamps,
    bool? autoScroll,
    String? welcomeMessage,
    int? maxConversationHistory,
    bool? enableDebugLogging,
    Map<String, dynamic>? customPromptVariables,
    List<String>? contextFiles,
  }) {
    return AgentConfiguration(
      agentName: agentName ?? this.agentName,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      useBetaFeatures: useBetaFeatures ?? this.useBetaFeatures,
      useReasonerModel: useReasonerModel ?? this.useReasonerModel,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      mcpConfigPath: mcpConfigPath ?? this.mcpConfigPath,
      showTimestamps: showTimestamps ?? this.showTimestamps,
      autoScroll: autoScroll ?? this.autoScroll,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      maxConversationHistory:
          maxConversationHistory ?? this.maxConversationHistory,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
      customPromptVariables:
          customPromptVariables ?? Map.from(this.customPromptVariables),
      contextFiles: contextFiles ?? List.from(this.contextFiles),
    );
  }

  /// Validate configuration values
  ///
  /// PERF: O(1) - immediate validation per field
  /// ARCHITECTURAL: Fail-fast validation prevents invalid states
  List<String> validate() {
    final errors = <String>[];

    if (agentName.trim().isEmpty) {
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

    if (maxConversationHistory < 10 || maxConversationHistory > 1000) {
      errors.add('Max conversation history must be between 10 and 1000');
    }

    if (mcpConfigPath.trim().isEmpty) {
      errors.add('MCP config path cannot be empty');
    }

    return errors;
  }

  /// Check if configuration is valid
  ///
  /// PERF: O(1) - delegates to validate() but returns boolean
  bool get isValid => validate().isEmpty;

  /// Reset to default configuration
  ///
  /// PERF: O(1) - creates new instance with defaults
  static AgentConfiguration createDefault() {
    return AgentConfiguration();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AgentConfiguration) return false;

    return agentName == other.agentName &&
        systemPrompt == other.systemPrompt &&
        useBetaFeatures == other.useBetaFeatures &&
        useReasonerModel == other.useReasonerModel &&
        temperature == other.temperature &&
        maxTokens == other.maxTokens &&
        mcpConfigPath == other.mcpConfigPath &&
        showTimestamps == other.showTimestamps &&
        autoScroll == other.autoScroll &&
        welcomeMessage == other.welcomeMessage &&
        maxConversationHistory == other.maxConversationHistory &&
        enableDebugLogging == other.enableDebugLogging;
  }

  @override
  int get hashCode {
    return Object.hash(
      agentName,
      systemPrompt,
      useBetaFeatures,
      useReasonerModel,
      temperature,
      maxTokens,
      mcpConfigPath,
      showTimestamps,
      autoScroll,
      welcomeMessage,
      maxConversationHistory,
      enableDebugLogging,
    );
  }

  @override
  String toString() {
    return 'AgentConfiguration(agentName: $agentName, useBeta: $useBetaFeatures, '
        'useReasoner: $useReasonerModel, temperature: $temperature)';
  }

  // Default values as constants for reusability
  static const String _defaultSystemPrompt =
      '''You are VibeCoder Assistant, a helpful AI coding companion.
        
You excel at:
- Flutter and Dart development
- Code review and optimization  
- Architecture and design patterns
- Debugging and troubleshooting
- Best practices and clean code

Be concise, practical, and focus on actionable solutions.
When providing code examples, make them complete and runnable.''';

  static const String _defaultWelcomeMessage = '''👋 **Welcome to VibeCoder!**

I'm your AI coding companion, ready to help with:
• Flutter & Dart development
• Code review and debugging  
• Architecture and best practices
• Project planning and optimization

What would you like to work on today?''';
}
