import 'dart:io';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// Session Service - App Session Management & Logging Infrastructure
///
/// ARCHITECTURAL: Manages application sessions with unique session IDs and
/// session-based conversation logging for agents.
class SessionService {
  static final Logger _logger = Logger('SessionService');
  static const String _logsDirectory = 'logs';

  // Session state
  String? _sessionId;
  DateTime? _sessionStartTime;
  bool _isInitialized = false;

  // UUID generator for unique session IDs
  final _uuid = const Uuid();

  /// Current session ID
  String? get sessionId => _sessionId;

  /// Session start time
  DateTime? get sessionStartTime => _sessionStartTime;

  /// Session duration
  Duration? get sessionDuration {
    if (_sessionStartTime == null) return null;
    return DateTime.now().difference(_sessionStartTime!);
  }

  /// Initialization status
  bool get isInitialized => _isInitialized;

  /// Initialize the session service
  ///
  /// PERF: O(1) - session creation and directory setup
  /// ARCHITECTURAL: Creates unique session for each app startup
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('🚀 SESSION SERVICE: Initializing session management');

      // Create logs directory if it doesn't exist
      await _ensureLogsDirectory();

      // Generate new session ID
      _sessionId = _uuid.v4();
      _sessionStartTime = DateTime.now();

      _logger.info('🎯 SESSION CREATED: $_sessionId');
      _logger.info('⏰ SESSION START: ${_sessionStartTime!.toIso8601String()}');

      // Create session-specific log directory
      await _createSessionLogDirectory();

      _isInitialized = true;
      _logger.info('✅ SESSION SERVICE: Initialized successfully');
    } catch (e, stackTrace) {
      _logger.severe(
          '💥 SESSION SERVICE: Initialization failed - $e', e, stackTrace);
      rethrow;
    }
  }

  /// Ensure logs directory exists
  ///
  /// PERF: O(1) - directory creation check
  Future<void> _ensureLogsDirectory() async {
    final dir = Directory(_logsDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      _logger.info('📁 LOGS DIRECTORY: Created $_logsDirectory');
    }
  }

  /// Create session-specific log directory
  ///
  /// PERF: O(1) - directory creation
  Future<void> _createSessionLogDirectory() async {
    if (_sessionId == null) {
      throw StateError('Session ID not available');
    }

    final sessionDir = Directory('$_logsDirectory/$_sessionId');
    if (!await sessionDir.exists()) {
      await sessionDir.create(recursive: true);
      _logger
          .info('📁 SESSION LOGS: Created directory for session $_sessionId');
    }
  }

  /// Get session log directory path
  ///
  /// PERF: O(1) - path construction
  String get sessionLogDirectory {
    if (_sessionId == null) {
      throw StateError('Session ID not available');
    }
    return '$_logsDirectory/$_sessionId';
  }

  /// Log agent conversation to session-specific file
  ///
  /// PERF: O(n) where n = conversation history size
  /// ARCHITECTURAL: Session-based logging with structured format
  Future<void> logAgentConversation({
    required String agentName,
    required String agentId,
    required List<Map<String, dynamic>> conversationHistory,
    String? additionalContext,
  }) async {
    if (!_isInitialized) {
      _logger.warning('⚠️ LOGGING SKIPPED: Session service not initialized');
      return;
    }

    try {
      // Create safe filename from agent name
      final safeAgentName = _sanitizeFilename(agentName);
      final logFile =
          File('$sessionLogDirectory/${safeAgentName}_conversation.log');

      final buffer = StringBuffer();

      // Add session header
      buffer.writeln('=== VIBE CODER CONVERSATION LOG ===');
      buffer.writeln('Session ID: $_sessionId');
      buffer.writeln('Session Start: ${_sessionStartTime!.toIso8601String()}');
      buffer.writeln('Agent: $agentName (ID: $agentId)');
      buffer.writeln('Log Time: ${DateTime.now().toIso8601String()}');
      if (additionalContext != null) {
        buffer.writeln('Context: $additionalContext');
      }
      buffer.writeln('');

      // Add conversation history
      for (final message in conversationHistory) {
        final role = message['role']?.toString().toUpperCase() ?? 'UNKNOWN';
        final content = message['content']?.toString() ?? '';
        final timestamp = message['timestamp']?.toString() ??
            DateTime.now().toIso8601String();

        buffer.writeln('[$timestamp] $role:');
        buffer.writeln(content);
        buffer.writeln('');

        // Add tool calls if present
        final toolCalls = message['toolCalls'] as List<dynamic>?;
        if (toolCalls != null && toolCalls.isNotEmpty) {
          buffer.writeln('TOOL CALLS:');
          for (final toolCall in toolCalls) {
            final toolJson =
                const JsonEncoder.withIndent('  ').convert(toolCall);
            buffer.writeln(toolJson);
            buffer.writeln('');
          }
        }

        // Add tool response if present
        final toolCallId = message['toolCallId']?.toString();
        if (toolCallId != null) {
          buffer.writeln('TOOL RESPONSE for call ID: $toolCallId');
          buffer.writeln('');
        }

        buffer.writeln('---');
        buffer.writeln('');
      }

      buffer.writeln('=== END OF CONVERSATION ===');
      buffer.writeln('');

      // Append to file
      await logFile.writeAsString(buffer.toString(), mode: FileMode.append);
      _logger.fine('💾 CONVERSATION LOGGED: ${logFile.path}');
    } catch (e, stackTrace) {
      _logger.severe('💥 CONVERSATION LOGGING FAILED: $e', e, stackTrace);
      // Don't rethrow - logging failure shouldn't break conversation flow
    }
  }

  /// Log agent activity (status changes, errors, etc.)
  ///
  /// PERF: O(1) - single log entry
  Future<void> logAgentActivity({
    required String agentName,
    required String agentId,
    required String activity,
    String? details,
    String? error,
  }) async {
    if (!_isInitialized) {
      _logger.warning(
          '⚠️ ACTIVITY LOGGING SKIPPED: Session service not initialized');
      return;
    }

    try {
      final logFile = File('$sessionLogDirectory/agent_activities.log');
      final timestamp = DateTime.now().toIso8601String();

      final buffer = StringBuffer();
      buffer.writeln('[$timestamp] AGENT ACTIVITY:');
      buffer.writeln('Agent: $agentName (ID: $agentId)');
      buffer.writeln('Activity: $activity');
      if (details != null) {
        buffer.writeln('Details: $details');
      }
      if (error != null) {
        buffer.writeln('Error: $error');
      }
      buffer.writeln('');

      await logFile.writeAsString(buffer.toString(), mode: FileMode.append);
      _logger.fine('📝 ACTIVITY LOGGED: $activity for $agentName');
    } catch (e) {
      _logger.warning('⚠️ ACTIVITY LOGGING FAILED: $e');
      // Don't rethrow - logging failure shouldn't break agent operations
    }
  }

  /// Log session summary
  ///
  /// PERF: O(1) - summary generation
  Future<void> logSessionSummary({
    required int totalAgents,
    required int totalConversations,
    required Duration sessionDuration,
    Map<String, dynamic>? additionalStats,
  }) async {
    if (!_isInitialized) {
      _logger.warning(
          '⚠️ SUMMARY LOGGING SKIPPED: Session service not initialized');
      return;
    }

    try {
      final logFile = File('$sessionLogDirectory/session_summary.log');
      final timestamp = DateTime.now().toIso8601String();

      final buffer = StringBuffer();
      buffer.writeln('=== SESSION SUMMARY ===');
      buffer.writeln('Session ID: $_sessionId');
      buffer.writeln('Start Time: ${_sessionStartTime!.toIso8601String()}');
      buffer.writeln('End Time: $timestamp');
      buffer.writeln(
          'Duration: ${sessionDuration.inMinutes} minutes ${sessionDuration.inSeconds % 60} seconds');
      buffer.writeln('Total Agents: $totalAgents');
      buffer.writeln('Total Conversations: $totalConversations');

      if (additionalStats != null) {
        buffer.writeln('Additional Stats:');
        for (final entry in additionalStats.entries) {
          buffer.writeln('  ${entry.key}: ${entry.value}');
        }
      }

      buffer.writeln('=== END OF SESSION ===');
      buffer.writeln('');

      await logFile.writeAsString(buffer.toString());
      _logger.info('📊 SESSION SUMMARY: Logged session statistics');
    } catch (e) {
      _logger.warning('⚠️ SESSION SUMMARY LOGGING FAILED: $e');
    }
  }

  /// Get all session log files
  ///
  /// PERF: O(n) where n = number of log files
  Future<List<File>> getSessionLogFiles() async {
    if (!_isInitialized) {
      return [];
    }

    try {
      final sessionDir = Directory(sessionLogDirectory);
      if (!await sessionDir.exists()) {
        return [];
      }

      final files = <File>[];
      await for (final entity in sessionDir.list()) {
        if (entity is File && entity.path.endsWith('.log')) {
          files.add(entity);
        }
      }

      return files;
    } catch (e) {
      _logger.warning('⚠️ FAILED TO GET SESSION LOG FILES: $e');
      return [];
    }
  }

  /// Cleanup old session logs (keep last N sessions)
  ///
  /// PERF: O(n) where n = number of old sessions
  Future<void> cleanupOldSessions({int keepLastSessions = 10}) async {
    try {
      final logsDir = Directory(_logsDirectory);
      if (!await logsDir.exists()) {
        return;
      }

      final sessions = <Directory>[];
      await for (final entity in logsDir.list()) {
        if (entity is Directory) {
          sessions.add(entity);
        }
      }

      // Sort by creation time (oldest first)
      sessions.sort(
          (a, b) => a.statSync().accessed.compareTo(b.statSync().accessed));

      // Remove old sessions
      final sessionsToRemove = sessions.length - keepLastSessions;
      if (sessionsToRemove > 0) {
        for (int i = 0; i < sessionsToRemove; i++) {
          try {
            await sessions[i].delete(recursive: true);
            _logger.info('🧹 CLEANUP: Removed old session ${sessions[i].path}');
          } catch (e) {
            _logger.warning(
                '⚠️ CLEANUP FAILED: Could not remove ${sessions[i].path}: $e');
          }
        }
      }
    } catch (e) {
      _logger.warning('⚠️ SESSION CLEANUP FAILED: $e');
    }
  }

  /// Sanitize filename for safe file system usage
  ///
  /// PERF: O(n) where n = filename length
  String _sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') // Replace invalid characters
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscores
        .toLowerCase();
  }

  /// Cleanup resources
  ///
  /// PERF: O(1) - cleanup operations
  Future<void> dispose() async {
    _logger.info('🧹 SESSION SERVICE: Disposing resources');

    // Log session summary before cleanup
    if (_isInitialized && _sessionStartTime != null) {
      final duration = DateTime.now().difference(_sessionStartTime!);
      await logSessionSummary(
        totalAgents: 0, // Will be updated by calling service
        totalConversations: 0, // Will be updated by calling service
        sessionDuration: duration,
      );
    }

    _isInitialized = false;
    _logger.info('✅ SESSION SERVICE: Cleanup completed');
  }
}
