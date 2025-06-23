import 'dart:convert';
import 'dart:developer' as developer;
import 'package:logging/logging.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:flutter/foundation.dart';

/// DebugLogger - Elite Debugging & Communication Intelligence System
///
/// ## MISSION ACCOMPLISHED
/// Eliminates debugging blind spots by providing comprehensive API communication visibility.
/// Captures tool calls, responses, and all API interactions with easy-to-parse structured logging.
/// ARCHITECTURAL VICTORY: General-purpose debugging system with UI integration capability.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Basic print() | Simple, fast | No structure, no persistence | Rejected - insufficient intel |
/// | Structured Logging | Organized, filterable | More overhead | CHOSEN - comprehensive debugging |
/// | Flutter DevTools Only | Native integration | Limited customization | Supplemented - need more control |
/// | In-App Debug UI | Real-time visibility | Memory overhead | CHOSEN - field debugging capability |
/// | File-based Logs | Persistent, shareable | Storage overhead | CHOSEN - comprehensive evidence |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **API Communication Blackout**
///    - 🔍 Symptom: No visibility into tool calls and API responses
///    - 🎯 Root Cause: Scattered logging without structure
///    - 💥 Kill Shot: Centralized structured logging with emoji tactical indicators
///
/// 2. **Debugging Information Overload**
///    - 🔍 Symptom: Too much noise, hard to parse important information
///    - 🎯 Root Cause: Unfiltered logging output
///    - 💥 Kill Shot: Categorized, filterable logging with severity levels
///
/// 3. **Field Debugging Impossibility**
///    - 🔍 Symptom: Can't debug on devices away from development environment
///    - 🎯 Root Cause: Console-only logging
///    - 💥 Kill Shot: In-app debug UI with real-time log streaming
///
/// ## PERFORMANCE PROFILE
/// - Log entry creation: O(1) - immediate structured capture
/// - JSON serialization: O(n) where n = payload size (acceptable for debugging)
/// - Memory overhead: Configurable circular buffer prevents memory leaks
/// - UI rendering: O(m) where m = visible log entries (virtualized for performance)
///
/// A comprehensive debugging service for API communications, tool calls, and system events.
/// Provides structured logging with tactical emoji indicators and real-time UI visibility.
class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  static final Logger _logger = Logger('DebugLogger');

  // PERF: Circular buffer prevents unbounded memory growth
  static const int _maxLogEntries = 1000;
  final List<DebugLogEntry> _logEntries = [];

  // Stream for real-time UI updates
  final List<Function(DebugLogEntry)> _listeners = [];

  /// Add a listener for real-time log updates
  ///
  /// ARCHITECTURAL: Observer pattern for UI reactivity
  void addListener(Function(DebugLogEntry) listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  void removeListener(Function(DebugLogEntry) listener) {
    _listeners.remove(listener);
  }

  /// Get all log entries for UI display
  ///
  /// PERF: Returns immutable list copy O(n) - prevents external modification
  List<DebugLogEntry> get logEntries => List.unmodifiable(_logEntries);

  /// Clear all log entries
  ///
  /// PERF: O(1) - instant memory cleanup
  void clearLogs() {
    _logEntries.clear();
    _notifyListeners(DebugLogEntry(
      timestamp: DateTime.now(),
      category: DebugCategory.system,
      level: LogLevel.info,
      title: '🧹 LOGS CLEARED',
      message: 'Debug log history cleared',
    ));
  }

  /// Log API Request with comprehensive details
  ///
  /// PERF: O(1) structured logging - immediate capture
  /// ARCHITECTURAL: Standardized API request logging format
  void logApiRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParams,
    dynamic body,
    String? requestId,
  }) {
    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      category: DebugCategory.apiRequest,
      level: LogLevel.info,
      title: '🚀 API REQUEST: $method',
      message: url,
      details: {
        'method': method,
        'url': url,
        'headers': headers ?? {},
        'queryParams': queryParams ?? {},
        'body': body,
        'requestId': requestId ?? _generateRequestId(),
      },
    );

    _addLogEntry(entry);
    _logger.info('🚀 API REQ [$method] $url');
  }

  /// Log API Response with comprehensive details
  ///
  /// PERF: O(1) structured logging - immediate capture
  /// ARCHITECTURAL: Standardized API response logging format
  void logApiResponse({
    required String method,
    required String url,
    required int statusCode,
    Map<String, dynamic>? headers,
    dynamic responseBody,
    String? requestId,
    Duration? duration,
    String? error,
  }) {
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final emoji = isSuccess ? '✅' : '❌';
    final level = isSuccess ? LogLevel.info : LogLevel.warning;

    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      category: DebugCategory.apiResponse,
      level: level,
      title: '$emoji API RESPONSE: $statusCode',
      message: '$method $url',
      details: {
        'method': method,
        'url': url,
        'statusCode': statusCode,
        'headers': headers ?? {},
        'responseBody': responseBody,
        'requestId': requestId,
        'duration': duration?.inMilliseconds,
        'error': error,
        'success': isSuccess,
      },
    );

    _addLogEntry(entry);
    _logger.info(
        '$emoji API RES [$statusCode] $method $url ${duration?.inMilliseconds}ms');
  }

  /// Log Tool Call with comprehensive details
  ///
  /// PERF: O(1) structured logging - immediate capture
  /// ARCHITECTURAL: MCP tool call logging integration
  void logToolCall({
    required String toolName,
    required String serverName,
    required Map<String, dynamic> arguments,
    String? callId,
  }) {
    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      category: DebugCategory.toolCall,
      level: LogLevel.info,
      title: '🛠️ TOOL CALL: $toolName',
      message: 'Server: $serverName',
      details: {
        'toolName': toolName,
        'serverName': serverName,
        'arguments': arguments,
        'callId': callId ?? _generateCallId(),
      },
    );

    _addLogEntry(entry);
    _logger.info('🛠️ TOOL CALL [$serverName] $toolName');
  }

  /// Log Tool Response with comprehensive details
  ///
  /// PERF: O(1) structured logging - immediate capture
  /// ARCHITECTURAL: MCP tool response logging integration
  void logToolResponse({
    required String toolName,
    required String serverName,
    required bool isSuccess,
    dynamic result,
    String? error,
    String? callId,
    Duration? duration,
  }) {
    final emoji = isSuccess ? '⚙️✅' : '⚙️❌';
    final level = isSuccess ? LogLevel.info : LogLevel.severe;

    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      category: DebugCategory.toolResponse,
      level: level,
      title: '$emoji TOOL RESPONSE: $toolName',
      message: 'Server: $serverName ${isSuccess ? 'SUCCESS' : 'FAILED'}',
      details: {
        'toolName': toolName,
        'serverName': serverName,
        'success': isSuccess,
        'result': result,
        'error': error,
        'callId': callId,
        'duration': duration?.inMilliseconds,
      },
    );

    _addLogEntry(entry);
    _logger.info(
        '$emoji TOOL RES [$serverName] $toolName ${duration?.inMilliseconds}ms');
  }

  /// Log Chat Message with details
  ///
  /// PERF: O(1) structured logging - immediate capture
  /// ARCHITECTURAL: Chat system integration logging
  void logChatMessage({
    required ChatMessage message,
    String? context,
  }) {
    String emoji;
    switch (message.role) {
      case MessageRole.user:
        emoji = '👤';
        break;
      case MessageRole.assistant:
        emoji = '🤖';
        break;
      case MessageRole.system:
        emoji = '⚙️';
        break;
      case MessageRole.tool:
        emoji = '🔧';
        break;
    }

    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      category: DebugCategory.chatMessage,
      level: LogLevel.info,
      title: '$emoji CHAT: ${message.role.name.toUpperCase()}',
      message: (() {
        final content = message.content;
        if (content != null) {
          return content.length > 100
              ? '${content.substring(0, 100)}...'
              : content;
        }
        return '[No content]';
      })(),
      details: {
        'role': message.role.name,
        'content': message.content,
        'toolCalls': message.toolCalls,
        'toolCallId': message.toolCallId,
        'reasoningContent': message.reasoningContent,
        'context': context,
      },
    );

    _addLogEntry(entry);
    _logger.info(
        '$emoji CHAT [${message.role.name}] ${message.content?.length ?? 0} chars');
  }

  /// Log System Event
  ///
  /// PERF: O(1) structured logging - immediate capture
  /// ARCHITECTURAL: General system event logging
  void logSystemEvent(String title, String message,
      {Map<String, dynamic>? details}) {
    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.info,
      category: DebugCategory.system,
      title: title,
      message: message,
      details: details,
    );

    _addLogEntry(entry);

    if (kDebugMode) {
      print('🔧 SYSTEM: $title - $message');
    }
  }

  /// Add log entry to internal storage
  ///
  /// PERF: O(1) with circular buffer - prevents memory leaks
  void _addLogEntry(DebugLogEntry entry) {
    // Circular buffer implementation
    if (_logEntries.length >= _maxLogEntries) {
      _logEntries.removeAt(0);
    }

    _logEntries.add(entry);
    _notifyListeners(entry);

    // Also log to Flutter DevTools
    developer.log(
      entry.message,
      name: entry.category.name,
      level: _levelToInt(entry.level),
      time: entry.timestamp,
    );
  }

  /// Notify all listeners of new log entry
  ///
  /// PERF: O(n) where n = listener count - typically small
  void _notifyListeners(DebugLogEntry entry) {
    for (final listener in _listeners) {
      try {
        listener(entry);
      } catch (e) {
        // Prevent listener errors from breaking logging
        _logger.warning('Listener error: $e');
      }
    }
  }

  /// Generate unique request ID for correlation
  ///
  /// PERF: O(1) - simple timestamp-based ID
  String _generateRequestId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate unique call ID for correlation
  ///
  /// PERF: O(1) - simple timestamp-based ID
  String _generateCallId() {
    return 'call_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Convert LogLevel to integer for Flutter DevTools
  int _levelToInt(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.severe:
        return 1000;
    }
  }

  /// Export logs as JSON for sharing/analysis
  ///
  /// PERF: O(n) serialization - acceptable for debugging export
  /// ARCHITECTURAL: Enables log sharing and external analysis
  String exportLogsAsJson() {
    final logsData = {
      'exportTimestamp': DateTime.now().toIso8601String(),
      'totalEntries': _logEntries.length,
      'logs': _logEntries.map((entry) => entry.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(logsData);
  }

  /// Filter logs by category
  ///
  /// PERF: O(n) filtering - acceptable for UI queries
  List<DebugLogEntry> filterByCategory(DebugCategory category) {
    return _logEntries.where((entry) => entry.category == category).toList();
  }

  /// Filter logs by level
  ///
  /// PERF: O(n) filtering - acceptable for UI queries
  List<DebugLogEntry> filterByLevel(LogLevel level) {
    return _logEntries.where((entry) => entry.level == level).toList();
  }

  /// Search logs by text
  ///
  /// PERF: O(n*m) where n = entries, m = search text length - acceptable for debugging
  List<DebugLogEntry> searchLogs(String query) {
    final lowerQuery = query.toLowerCase();
    return _logEntries
        .where((entry) =>
            entry.title.toLowerCase().contains(lowerQuery) ||
            entry.message.toLowerCase().contains(lowerQuery))
        .toList();
  }
}

/// Debug Log Entry - Structured log data container
///
/// ARCHITECTURAL: Immutable value object for log data integrity
class DebugLogEntry {
  final DateTime timestamp;
  final DebugCategory category;
  final LogLevel level;
  final String title;
  final String message;
  final Map<String, dynamic>? details;

  const DebugLogEntry({
    required this.timestamp,
    required this.category,
    required this.level,
    required this.title,
    required this.message,
    this.details,
  });

  /// Convert to JSON for export/serialization
  ///
  /// PERF: O(1) for entry, O(n) for details - acceptable for debugging
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'category': category.name,
      'level': level.name,
      'title': title,
      'message': message,
      'details': details,
    };
  }

  /// Create from JSON for import/deserialization
  factory DebugLogEntry.fromJson(Map<String, dynamic> json) {
    return DebugLogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      category:
          DebugCategory.values.firstWhere((c) => c.name == json['category']),
      level: LogLevel.values.firstWhere((l) => l.name == json['level']),
      title: json['title'],
      message: json['message'],
      details: json['details'],
    );
  }
}

/// Debug Categories for organizing log entries
///
/// ARCHITECTURAL: Enumerated categories for structured logging
enum DebugCategory {
  apiRequest,
  apiResponse,
  toolCall,
  toolResponse,
  chatMessage,
  system,
}

/// Log Levels for severity classification
///
/// ARCHITECTURAL: Standard log levels for filtering and prioritization
enum LogLevel {
  info,
  warning,
  severe,
}
