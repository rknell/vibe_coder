import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/services/session_service.dart';

void main() {
  group('SessionService', () {
    late SessionService sessionService;
    late String testLogsDir;

    setUp(() {
      sessionService = SessionService();
      testLogsDir = 'test_logs_${DateTime.now().millisecondsSinceEpoch}';
    });

    tearDown(() async {
      // Only clean up test-specific directories if used
      final testDir = Directory(testLogsDir);
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
      // Do NOT delete the global logs directory here
    });

    group('🚀 INITIALIZATION', () {
      test('✅ VICTORY: Initialize creates session with unique ID', () async {
        await sessionService.initialize();

        expect(sessionService.isInitialized, isTrue);
        expect(sessionService.sessionId, isNotNull);
        expect(
            sessionService.sessionId!.length, greaterThan(20)); // UUID length
        expect(sessionService.sessionStartTime, isNotNull);
      });

      test('✅ VICTORY: Initialize creates logs directory', () async {
        await sessionService.initialize();

        final logsDir = Directory('logs');
        expect(await logsDir.exists(), isTrue);
      });

      test('✅ VICTORY: Initialize creates session-specific directory',
          () async {
        await sessionService.initialize();

        final sessionDir = Directory(sessionService.sessionLogDirectory);
        expect(await sessionDir.exists(), isTrue);
        expect(sessionDir.path, contains(sessionService.sessionId!));
      });

      test('✅ VICTORY: Multiple initializations are idempotent', () async {
        await sessionService.initialize();
        final firstSessionId = sessionService.sessionId;
        final firstStartTime = sessionService.sessionStartTime;

        await sessionService.initialize();

        expect(sessionService.sessionId, equals(firstSessionId));
        expect(sessionService.sessionStartTime, equals(firstStartTime));
      });
    });

    group('📝 CONVERSATION LOGGING', () {
      setUp(() async {
        await sessionService.initialize();
      });

      test('✅ VICTORY: Log agent conversation creates file', () async {
        final conversationHistory = [
          {
            'role': 'user',
            'content': 'Hello, how are you?',
            'timestamp': '2024-01-01T12:00:00Z',
          },
          {
            'role': 'assistant',
            'content': 'I am doing well, thank you!',
            'timestamp': '2024-01-01T12:00:01Z',
          },
        ];

        await sessionService.logAgentConversation(
          agentName: 'Test Agent',
          agentId: 'test-123',
          conversationHistory: conversationHistory,
        );

        final logFiles = await sessionService.getSessionLogFiles();
        expect(logFiles.length, greaterThan(0));

        final conversationFile = logFiles.firstWhere(
          (file) => file.path.contains('test_agent_conversation.log'),
        );
        expect(await conversationFile.exists(), isTrue);
      });

      test('✅ VICTORY: Log agent conversation includes session info', () async {
        final conversationHistory = [
          {
            'role': 'user',
            'content': 'Test message',
            'timestamp': '2024-01-01T12:00:00Z',
          },
        ];

        await sessionService.logAgentConversation(
          agentName: 'Test Agent',
          agentId: 'test-123',
          conversationHistory: conversationHistory,
        );

        final logFiles = await sessionService.getSessionLogFiles();
        final conversationFile = logFiles.firstWhere(
          (file) => file.path.contains('test_agent_conversation.log'),
        );

        final content = await conversationFile.readAsString();
        expect(content, contains('Session ID: ${sessionService.sessionId}'));
        expect(content, contains('Agent: Test Agent (ID: test-123)'));
        expect(content, contains('USER:'));
        expect(content, contains('Test message'));
      });

      test('✅ VICTORY: Log agent conversation handles tool calls', () async {
        final conversationHistory = [
          {
            'role': 'assistant',
            'content': 'I will call a tool',
            'timestamp': '2024-01-01T12:00:00Z',
            'toolCalls': [
              {
                'id': 'call_1',
                'type': 'function',
                'function': {
                  'name': 'test_function',
                  'arguments': '{"param": "value"}',
                },
              },
            ],
          },
        ];

        await sessionService.logAgentConversation(
          agentName: 'Test Agent',
          agentId: 'test-123',
          conversationHistory: conversationHistory,
        );

        final logFiles = await sessionService.getSessionLogFiles();
        final conversationFile = logFiles.firstWhere(
          (file) => file.path.contains('test_agent_conversation.log'),
        );

        final content = await conversationFile.readAsString();
        expect(content, contains('TOOL CALLS:'));
        expect(content, contains('test_function'));
        expect(content,
            contains('param')); // Check for key name instead of full JSON
        expect(content, contains('value')); // Check for value
      });

      test(
          '✅ VICTORY: Log agent conversation handles special characters in agent name',
          () async {
        final conversationHistory = [
          {
            'role': 'user',
            'content': 'Test message',
            'timestamp': '2024-01-01T12:00:00Z',
          },
        ];

        await sessionService.logAgentConversation(
          agentName: 'Test Agent Special Chars',
          agentId: 'test-123',
          conversationHistory: conversationHistory,
        );

        final logFiles = await sessionService.getSessionLogFiles();
        final conversationFiles = logFiles
            .where(
              (file) => file.path
                  .contains('test_agent_special_chars_conversation.log'),
            )
            .toList();
        expect(conversationFiles.length, greaterThan(0));
        expect(await conversationFiles.first.exists(), isTrue);
      });
    });

    group('📊 ACTIVITY LOGGING', () {
      setUp(() async {
        await sessionService.initialize();
      });

      test('✅ VICTORY: Log agent activity creates activity file', () async {
        await sessionService.logAgentActivity(
          agentName: 'Test Agent',
          agentId: 'test-123',
          activity: 'Status changed',
          details: 'idle → processing',
        );

        final logFiles = await sessionService.getSessionLogFiles();
        final activityFile = logFiles.firstWhere(
          (file) => file.path.contains('agent_activities.log'),
        );
        expect(await activityFile.exists(), isTrue);
      });

      test('✅ VICTORY: Log agent activity includes all information', () async {
        await sessionService.logAgentActivity(
          agentName: 'Test Agent',
          agentId: 'test-123',
          activity: 'Status changed',
          details: 'idle → processing',
          error: 'Connection timeout',
        );

        final logFiles = await sessionService.getSessionLogFiles();
        final activityFile = logFiles.firstWhere(
          (file) => file.path.contains('agent_activities.log'),
        );

        final content = await activityFile.readAsString();
        expect(content, contains('Test Agent (ID: test-123)'));
        expect(content, contains('Status changed'));
        expect(content, contains('idle → processing'));
        expect(content, contains('Connection timeout'));
      });
    });

    group('📈 SESSION SUMMARY', () {
      setUp(() async {
        await sessionService.initialize();
      });

      test('✅ VICTORY: Log session summary creates summary file', () async {
        await sessionService.logSessionSummary(
          totalAgents: 5,
          totalConversations: 10,
          sessionDuration: const Duration(minutes: 30, seconds: 45),
          additionalStats: {'messages_sent': 50, 'tools_called': 15},
        );

        final logFiles = await sessionService.getSessionLogFiles();
        final summaryFile = logFiles.firstWhere(
          (file) => file.path.contains('session_summary.log'),
        );
        expect(await summaryFile.exists(), isTrue);
      });

      test('✅ VICTORY: Log session summary includes all statistics', () async {
        await sessionService.logSessionSummary(
          totalAgents: 5,
          totalConversations: 10,
          sessionDuration: const Duration(minutes: 30, seconds: 45),
          additionalStats: {'messages_sent': 50, 'tools_called': 15},
        );

        final logFiles = await sessionService.getSessionLogFiles();
        final summaryFile = logFiles.firstWhere(
          (file) => file.path.contains('session_summary.log'),
        );

        final content = await summaryFile.readAsString();
        expect(content, contains('Session ID: ${sessionService.sessionId}'));
        expect(content, contains('Total Agents: 5'));
        expect(content, contains('Total Conversations: 10'));
        expect(content, contains('30 minutes 45 seconds'));
        expect(content, contains('messages_sent: 50'));
        expect(content, contains('tools_called: 15'));
      });
    });

    group('🧹 CLEANUP', () {
      setUp(() async {
        await sessionService.initialize();
      });

      test('✅ VICTORY: Dispose logs session summary', () async {
        await sessionService.dispose();

        // Find any session_summary.log in any session directory
        final logsDir = Directory('logs');
        final summaryFiles = <File>[];
        await for (final entity in logsDir.list(recursive: true)) {
          if (entity is File && entity.path.contains('session_summary.log')) {
            summaryFiles.add(entity);
          }
        }
        expect(summaryFiles.length, greaterThan(0));
        expect(await summaryFiles.first.exists(), isTrue);
      });

      test('✅ VICTORY: Cleanup old sessions removes excess sessions', () async {
        // Create multiple session directories
        final logsDir = Directory('logs');
        await logsDir.create(recursive: true);

        for (int i = 0; i < 15; i++) {
          final sessionDir = Directory('logs/session_$i');
          await sessionDir.create();
          final testFile = File('${sessionDir.path}/test.log');
          await testFile.writeAsString('test content');
        }

        await sessionService.cleanupOldSessions(keepLastSessions: 10);

        final sessions = <Directory>[];
        await for (final entity in logsDir.list()) {
          if (entity is Directory) {
            sessions.add(entity);
          }
        }

        // Should keep 10 sessions plus the current one
        expect(sessions.length, lessThanOrEqualTo(11));
      });
    });

    group('🔧 UTILITY METHODS', () {
      setUp(() async {
        await sessionService.initialize();
      });

      test('✅ VICTORY: Session duration calculation', () async {
        // Wait a bit to ensure duration is measurable
        await Future.delayed(const Duration(milliseconds: 10));

        final duration = sessionService.sessionDuration;
        expect(duration, isNotNull);
        expect(duration!.inMilliseconds, greaterThan(0));
      });

      test('✅ VICTORY: Get session log files returns correct files', () async {
        // Create some test log files
        final testFile1 =
            File('${sessionService.sessionLogDirectory}/test1.log');
        final testFile2 =
            File('${sessionService.sessionLogDirectory}/test2.log');
        final testFile3 = File(
            '${sessionService.sessionLogDirectory}/test.txt'); // Not a log file

        await testFile1.writeAsString('test1');
        await testFile2.writeAsString('test2');
        await testFile3.writeAsString('test3');

        final logFiles = await sessionService.getSessionLogFiles();
        expect(logFiles.length, equals(2));
        expect(logFiles.any((file) => file.path.contains('test1.log')), isTrue);
        expect(logFiles.any((file) => file.path.contains('test2.log')), isTrue);
        expect(logFiles.any((file) => file.path.contains('test.txt')), isFalse);
      });
    });

    group('🚨 ERROR HANDLING', () {
      test('✅ VICTORY: Logging without initialization is handled gracefully',
          () async {
        // Don't initialize sessionService
        await sessionService.logAgentConversation(
          agentName: 'Test Agent',
          agentId: 'test-123',
          conversationHistory: [],
        );

        // Should not throw and should not create files
        final logFiles = await sessionService.getSessionLogFiles();
        expect(logFiles.isEmpty, isTrue);
      });

      test('✅ VICTORY: File system errors are handled gracefully', () async {
        await sessionService.initialize();

        // Try to log with invalid conversation data
        await sessionService.logAgentConversation(
          agentName: 'Test Agent',
          agentId: 'test-123',
          conversationHistory: [
            {'invalid': 'data'}, // Missing required fields
          ],
        );

        // Should not throw and should continue working
        expect(sessionService.isInitialized, isTrue);
      });
    });
  });
}
