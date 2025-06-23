/// 📊 SERVICE STATISTICS MODELS
///
/// ARCHITECTURAL: Strongly-typed data models for service statistics
/// Replaces Map<String, dynamic> returns with type-safe structures
/// Provides comprehensive service status and performance information
library;

/// Configuration service statistics
class ConfigurationStatistics {
  final int agentNameLength;
  final int systemPromptLength;
  final int welcomeMessageLength;
  final int customVariablesCount;
  final int contextFilesCount;
  final double temperatureValue;
  final int maxTokensValue;
  final int maxHistoryValue;
  final ConfigurationFeatures featuresEnabled;

  const ConfigurationStatistics({
    required this.agentNameLength,
    required this.systemPromptLength,
    required this.welcomeMessageLength,
    required this.customVariablesCount,
    required this.contextFilesCount,
    required this.temperatureValue,
    required this.maxTokensValue,
    required this.maxHistoryValue,
    required this.featuresEnabled,
  });

  Map<String, dynamic> toJson() => {
        'agentNameLength': agentNameLength,
        'systemPromptLength': systemPromptLength,
        'welcomeMessageLength': welcomeMessageLength,
        'customVariablesCount': customVariablesCount,
        'contextFilesCount': contextFilesCount,
        'temperatureValue': temperatureValue,
        'maxTokensValue': maxTokensValue,
        'maxHistoryValue': maxHistoryValue,
        'featuresEnabled': featuresEnabled.toJson(),
      };

  factory ConfigurationStatistics.fromJson(Map<String, dynamic> json) =>
      ConfigurationStatistics(
        agentNameLength: json['agentNameLength'] as int,
        systemPromptLength: json['systemPromptLength'] as int,
        welcomeMessageLength: json['welcomeMessageLength'] as int,
        customVariablesCount: json['customVariablesCount'] as int,
        contextFilesCount: json['contextFilesCount'] as int,
        temperatureValue: (json['temperatureValue'] as num).toDouble(),
        maxTokensValue: json['maxTokensValue'] as int,
        maxHistoryValue: json['maxHistoryValue'] as int,
        featuresEnabled: ConfigurationFeatures.fromJson(
            json['featuresEnabled'] as Map<String, dynamic>),
      );
}

/// Configuration features status
class ConfigurationFeatures {
  final bool betaFeatures;
  final bool reasonerModel;
  final bool timestamps;
  final bool autoScroll;
  final bool debugLogging;

  const ConfigurationFeatures({
    required this.betaFeatures,
    required this.reasonerModel,
    required this.timestamps,
    required this.autoScroll,
    required this.debugLogging,
  });

  Map<String, dynamic> toJson() => {
        'betaFeatures': betaFeatures,
        'reasonerModel': reasonerModel,
        'timestamps': timestamps,
        'autoScroll': autoScroll,
        'debugLogging': debugLogging,
      };

  factory ConfigurationFeatures.fromJson(Map<String, dynamic> json) =>
      ConfigurationFeatures(
        betaFeatures: json['betaFeatures'] as bool,
        reasonerModel: json['reasonerModel'] as bool,
        timestamps: json['timestamps'] as bool,
        autoScroll: json['autoScroll'] as bool,
        debugLogging: json['debugLogging'] as bool,
      );
}

/// Agent service conversation statistics
class ConversationStatistics {
  final int totalAgents;
  final int activeAgents;
  final int totalMessages;
  final int agentsWithConversations;
  final int averageMessagesPerAgent;

  const ConversationStatistics({
    required this.totalAgents,
    required this.activeAgents,
    required this.totalMessages,
    required this.agentsWithConversations,
    required this.averageMessagesPerAgent,
  });

  Map<String, dynamic> toJson() => {
        'totalAgents': totalAgents,
        'activeAgents': activeAgents,
        'totalMessages': totalMessages,
        'agentsWithConversations': agentsWithConversations,
        'averageMessagesPerAgent': averageMessagesPerAgent,
      };

  factory ConversationStatistics.fromJson(Map<String, dynamic> json) =>
      ConversationStatistics(
        totalAgents: json['totalAgents'] as int,
        activeAgents: json['activeAgents'] as int,
        totalMessages: json['totalMessages'] as int,
        agentsWithConversations: json['agentsWithConversations'] as int,
        averageMessagesPerAgent: json['averageMessagesPerAgent'] as int,
      );

  /// Convenience getters
  double get activeAgentPercentage =>
      totalAgents > 0 ? (activeAgents / totalAgents) * 100 : 0.0;

  double get conversationEngagementRate =>
      totalAgents > 0 ? (agentsWithConversations / totalAgents) * 100 : 0.0;
}

/// MCP service statistics
class MCPServiceStatistics {
  final int totalServers;
  final int connectedServers;
  final int disconnectedServers;
  final int errorServers;
  final int stdioServers;
  final int sseServers;
  final int totalTools;
  final int totalResources;
  final int totalPrompts;

  const MCPServiceStatistics({
    required this.totalServers,
    required this.connectedServers,
    required this.disconnectedServers,
    required this.errorServers,
    required this.stdioServers,
    required this.sseServers,
    required this.totalTools,
    required this.totalResources,
    required this.totalPrompts,
  });

  Map<String, dynamic> toJson() => {
        'totalServers': totalServers,
        'connectedServers': connectedServers,
        'disconnectedServers': disconnectedServers,
        'errorServers': errorServers,
        'stdioServers': stdioServers,
        'sseServers': sseServers,
        'totalTools': totalTools,
        'totalResources': totalResources,
        'totalPrompts': totalPrompts,
      };

  factory MCPServiceStatistics.fromJson(Map<String, dynamic> json) =>
      MCPServiceStatistics(
        totalServers: json['totalServers'] as int,
        connectedServers: json['connectedServers'] as int,
        disconnectedServers: json['disconnectedServers'] as int,
        errorServers: json['errorServers'] as int,
        stdioServers: json['stdioServers'] as int,
        sseServers: json['sseServers'] as int,
        totalTools: json['totalTools'] as int,
        totalResources: json['totalResources'] as int,
        totalPrompts: json['totalPrompts'] as int,
      );

  /// Convenience getters
  double get connectionSuccessRate =>
      totalServers > 0 ? (connectedServers / totalServers) * 100 : 0.0;

  double get errorRate =>
      totalServers > 0 ? (errorServers / totalServers) * 100 : 0.0;

  int get totalCapabilities => totalTools + totalResources + totalPrompts;

  double get averageToolsPerServer =>
      connectedServers > 0 ? totalTools / connectedServers : 0.0;
}
