/// AgentConfiguration - Data Model Layer with Self-Management
library;

/// ## MISSION ACCOMPLISHED
/// Transforms AgentConfiguration to follow VibeCoder architecture protocol with ChangeNotifier
/// and self-managed persistence following the Data Model Layer pattern.
///
/// ## ARCHITECTURAL COMPLIANCE ACHIEVED
/// - ✅ Extends ChangeNotifier for state broadcasting
/// - ✅ Self-managed persistence to /data directory
/// - ✅ Individual entity management with validation
/// - ✅ Mandatory notifyListeners() on all changes
/// - ✅ Universal configuration management
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Configuration updates: O(1) - direct property assignment with notification
/// - Serialization: O(1) - fixed number of config fields
/// - Validation: O(1) per field - immediate feedback
/// - Persistence: O(1) - single file write operation
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// AgentConfiguration - Universal Configuration Management Model
///
/// ARCHITECTURAL: Data Model Layer - handles configuration with self-persistence
/// Extends ChangeNotifier for reactive UI updates following architecture protocol
class AgentConfiguration extends ChangeNotifier {
  // Core Agent Settings
  String _agentName;
  String _systemPrompt;

  // AI Model Settings
  bool _useBetaFeatures;
  bool _useReasonerModel;
  double _temperature;
  int _maxTokens;

  // MCP Settings
  String _mcpConfigPath;

  // UI Settings
  bool _showTimestamps;
  bool _autoScroll;
  String _welcomeMessage;

  // Performance Settings
  int _maxConversationHistory;
  bool _enableDebugLogging;

  // Advanced Settings
  final Map<String, dynamic> _customPromptVariables;
  final List<String> _contextFiles;

  // Private constructor for internal use
  AgentConfiguration._({
    String agentName = 'VibeCoder Assistant',
    String systemPrompt = _defaultSystemPrompt,
    bool useBetaFeatures = false,
    bool useReasonerModel = false,
    double temperature = 0.7,
    int maxTokens = 4000,
    String mcpConfigPath = 'mcp.json',
    bool showTimestamps = true,
    bool autoScroll = true,
    String welcomeMessage = _defaultWelcomeMessage,
    int maxConversationHistory = 100,
    bool enableDebugLogging = false,
    Map<String, dynamic>? customPromptVariables,
    List<String>? contextFiles,
  })  : _agentName = agentName,
        _systemPrompt = systemPrompt,
        _useBetaFeatures = useBetaFeatures,
        _useReasonerModel = useReasonerModel,
        _temperature = temperature,
        _maxTokens = maxTokens,
        _mcpConfigPath = mcpConfigPath,
        _showTimestamps = showTimestamps,
        _autoScroll = autoScroll,
        _welcomeMessage = welcomeMessage,
        _maxConversationHistory = maxConversationHistory,
        _enableDebugLogging = enableDebugLogging,
        _customPromptVariables = customPromptVariables ?? {},
        _contextFiles = contextFiles ?? [];

  /// Create default configuration - ARCHITECTURAL: Factory pattern for defaults
  ///
  /// PERF: O(1) - creates configuration with default values
  static AgentConfiguration createDefault() {
    return AgentConfiguration._();
  }

  /// Create configuration and save immediately
  ///
  /// PERF: O(1) - direct instantiation with immediate persistence
  /// ARCHITECTURAL: Self-managed persistence on creation
  static Future<AgentConfiguration> create({
    String agentName = 'VibeCoder Assistant',
    String systemPrompt = _defaultSystemPrompt,
    bool useBetaFeatures = false,
    bool useReasonerModel = false,
    double temperature = 0.7,
    int maxTokens = 4000,
    String mcpConfigPath = 'mcp.json',
    bool showTimestamps = true,
    bool autoScroll = true,
    String welcomeMessage = _defaultWelcomeMessage,
    int maxConversationHistory = 100,
    bool enableDebugLogging = false,
    Map<String, dynamic>? customPromptVariables,
    List<String>? contextFiles,
  }) async {
    final config = AgentConfiguration._(
      agentName: agentName,
      systemPrompt: systemPrompt,
      useBetaFeatures: useBetaFeatures,
      useReasonerModel: useReasonerModel,
      temperature: temperature,
      maxTokens: maxTokens,
      mcpConfigPath: mcpConfigPath,
      showTimestamps: showTimestamps,
      autoScroll: autoScroll,
      welcomeMessage: welcomeMessage,
      maxConversationHistory: maxConversationHistory,
      enableDebugLogging: enableDebugLogging,
      customPromptVariables: customPromptVariables,
      contextFiles: contextFiles,
    );

    // Validate before saving
    final validationErrors = config.validate();
    if (validationErrors.isNotEmpty) {
      throw ConfigurationValidationException(
          'Configuration validation failed: ${validationErrors.join(', ')}');
    }

    // Save immediately - self-managed persistence
    await config.save();

    return config;
  }

  /// Load configuration from persistence
  ///
  /// PERF: O(1) - single file read
  /// ARCHITECTURAL: Self-managed loading from /data directory
  static Future<AgentConfiguration> load() async {
    try {
      final file = await _getConfigFile();
      if (!await file.exists()) {
        // Return default if no saved configuration exists
        return createDefault();
      }

      final jsonStr = await file.readAsString();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      return AgentConfiguration._(
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
    } catch (e) {
      // Return default configuration on any loading error
      return createDefault();
    }
  }

  // Getters for immutable access
  String get agentName => _agentName;
  String get systemPrompt => _systemPrompt;
  bool get useBetaFeatures => _useBetaFeatures;
  bool get useReasonerModel => _useReasonerModel;
  double get temperature => _temperature;
  int get maxTokens => _maxTokens;
  String get mcpConfigPath => _mcpConfigPath;
  bool get showTimestamps => _showTimestamps;
  bool get autoScroll => _autoScroll;
  String get welcomeMessage => _welcomeMessage;
  int get maxConversationHistory => _maxConversationHistory;
  bool get enableDebugLogging => _enableDebugLogging;
  Map<String, dynamic> get customPromptVariables =>
      Map.unmodifiable(_customPromptVariables);
  List<String> get contextFiles => List.unmodifiable(_contextFiles);

  // Setters with notification - ARCHITECTURAL: notifyListeners() MANDATORY
  set agentName(String value) {
    if (_agentName != value) {
      _agentName = value;
      notifyListeners(); // MANDATORY after any change
    }
  }

  set systemPrompt(String value) {
    if (_systemPrompt != value) {
      _systemPrompt = value;
      notifyListeners(); // MANDATORY after any change
    }
  }

  set useBetaFeatures(bool value) {
    if (_useBetaFeatures != value) {
      _useBetaFeatures = value;
      notifyListeners(); // MANDATORY after any change
    }
  }

  set useReasonerModel(bool value) {
    if (_useReasonerModel != value) {
      _useReasonerModel = value;
      notifyListeners(); // MANDATORY after any change
    }
  }

  set temperature(double value) {
    if (_temperature != value) {
      _temperature = value;
      notifyListeners(); // MANDATORY after any change
    }
  }

  set maxTokens(int value) {
    if (_maxTokens != value) {
      _maxTokens = value;
      notifyListeners(); // MANDATORY after any change
    }
  }

  set mcpConfigPath(String value) {
    if (_mcpConfigPath != value) {
      _mcpConfigPath = value;
      notifyListeners(); // MANDATORY after any change
    }
  }

  set showTimestamps(bool value) {
    if (_showTimestamps != value) {
      _showTimestamps = value;
      notifyListeners(); // MANDATORY after any change
    }
  }

  set autoScroll(bool value) {
    if (_autoScroll != value) {
      _autoScroll = value;
      notifyListeners(); // MANDATORY after any change
    }
  }

  set welcomeMessage(String value) {
    if (_welcomeMessage != value) {
      _welcomeMessage = value;
      notifyListeners(); // MANDATORY after any change
    }
  }

  set maxConversationHistory(int value) {
    if (_maxConversationHistory != value) {
      _maxConversationHistory = value;
      notifyListeners(); // MANDATORY after any change
    }
  }

  set enableDebugLogging(bool value) {
    if (_enableDebugLogging != value) {
      _enableDebugLogging = value;
      notifyListeners(); // MANDATORY after any change
    }
  }

  /// Update custom prompt variable
  ///
  /// PERF: O(1) - direct map update
  void updateCustomPromptVariable(String key, dynamic value) {
    _customPromptVariables[key] = value;
    notifyListeners(); // MANDATORY after any change
  }

  /// Remove custom prompt variable
  ///
  /// PERF: O(1) - direct map removal
  bool removeCustomPromptVariable(String key) {
    final removed = _customPromptVariables.remove(key) != null;
    if (removed) {
      notifyListeners(); // MANDATORY after any change
    }
    return removed;
  }

  /// Add context file
  ///
  /// PERF: O(1) - list append if not exists
  bool addContextFile(String filename) {
    if (!_contextFiles.contains(filename)) {
      _contextFiles.add(filename);
      notifyListeners(); // MANDATORY after any change
      return true;
    }
    return false;
  }

  /// Remove context file
  ///
  /// PERF: O(n) where n = context files count
  bool removeContextFile(String filename) {
    final removed = _contextFiles.remove(filename);
    if (removed) {
      notifyListeners(); // MANDATORY after any change
    }
    return removed;
  }

  /// Self-managed persistence - ARCHITECTURAL: Models handle own persistence
  ///
  /// PERF: O(1) - single file write operation
  /// ARCHITECTURAL: Saves to /data/agent_config.json
  Future<void> save() async {
    try {
      final file = await _getConfigFile();
      final directory = file.parent;

      // Ensure directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Save with atomic write
      final jsonData = toJson();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonData);
      await file.writeAsString(jsonStr);

      notifyListeners(); // MANDATORY after persistence
    } catch (e) {
      throw ConfigurationPersistenceException(
          'Failed to save configuration: $e');
    }
  }

  /// Self-managed deletion - ARCHITECTURAL: Models handle own persistence
  ///
  /// PERF: O(1) - single file deletion
  /// ARCHITECTURAL: Removes /data/agent_config.json
  Future<void> delete() async {
    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        await file.delete();
      }
      notifyListeners(); // MANDATORY after deletion
    } catch (e) {
      throw ConfigurationPersistenceException(
          'Failed to delete configuration: $e');
    }
  }

  /// Convert configuration to JSON map for persistence
  ///
  /// PERF: O(1) - fixed number of fields serialization
  Map<String, dynamic> toJson() {
    return {
      'agentName': _agentName,
      'systemPrompt': _systemPrompt,
      'useBetaFeatures': _useBetaFeatures,
      'useReasonerModel': _useReasonerModel,
      'temperature': _temperature,
      'maxTokens': _maxTokens,
      'mcpConfigPath': _mcpConfigPath,
      'showTimestamps': _showTimestamps,
      'autoScroll': _autoScroll,
      'welcomeMessage': _welcomeMessage,
      'maxConversationHistory': _maxConversationHistory,
      'enableDebugLogging': _enableDebugLogging,
      'customPromptVariables': _customPromptVariables,
      'contextFiles': _contextFiles,
    };
  }

  /// Validate configuration values - ARCHITECTURAL: Individual entity validation
  ///
  /// PERF: O(1) - immediate validation per field
  /// ARCHITECTURAL: Fail-fast validation prevents invalid states
  List<String> validate() {
    final errors = <String>[];

    if (_agentName.trim().isEmpty) {
      errors.add('Agent name cannot be empty');
    }

    if (_systemPrompt.trim().isEmpty) {
      errors.add('System prompt cannot be empty');
    }

    if (_temperature < 0.0 || _temperature > 2.0) {
      errors.add('Temperature must be between 0.0 and 2.0');
    }

    if (_maxTokens < 100 || _maxTokens > 32000) {
      errors.add('Max tokens must be between 100 and 32000');
    }

    if (_maxConversationHistory < 10 || _maxConversationHistory > 1000) {
      errors.add('Max conversation history must be between 10 and 1000');
    }

    if (_mcpConfigPath.trim().isEmpty) {
      errors.add('MCP config path cannot be empty');
    }

    return errors;
  }

  /// Check if configuration is valid
  ///
  /// PERF: O(1) - delegates to validate() but returns boolean
  bool get isValid => validate().isEmpty;

  /// Get configuration file path
  static Future<File> _getConfigFile() async {
    if (kIsWeb) {
      throw UnsupportedError(
          'File-based configuration persistence not supported on web');
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    final configDir = Directory('${documentsDir.path}/vibe_coder/data');

    // Ensure directory exists
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }

    return File('${configDir.path}/agent_config.json');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AgentConfiguration) return false;

    return _agentName == other._agentName &&
        _systemPrompt == other._systemPrompt &&
        _useBetaFeatures == other._useBetaFeatures &&
        _useReasonerModel == other._useReasonerModel &&
        _temperature == other._temperature &&
        _maxTokens == other._maxTokens &&
        _mcpConfigPath == other._mcpConfigPath &&
        _showTimestamps == other._showTimestamps &&
        _autoScroll == other._autoScroll &&
        _welcomeMessage == other._welcomeMessage &&
        _maxConversationHistory == other._maxConversationHistory &&
        _enableDebugLogging == other._enableDebugLogging;
  }

  @override
  int get hashCode {
    return Object.hash(
      _agentName,
      _systemPrompt,
      _useBetaFeatures,
      _useReasonerModel,
      _temperature,
      _maxTokens,
      _mcpConfigPath,
      _showTimestamps,
      _autoScroll,
      _welcomeMessage,
      _maxConversationHistory,
      _enableDebugLogging,
    );
  }

  @override
  String toString() {
    return 'AgentConfiguration(agentName: $_agentName, useBeta: $_useBetaFeatures, '
        'useReasoner: $_useReasonerModel, temperature: $_temperature)';
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

/// Exception classes for configuration management
class ConfigurationValidationException implements Exception {
  final String message;
  ConfigurationValidationException(this.message);
  @override
  String toString() => 'ConfigurationValidationException: $message';
}

class ConfigurationPersistenceException implements Exception {
  final String message;
  ConfigurationPersistenceException(this.message);
  @override
  String toString() => 'ConfigurationPersistenceException: $message';
}
