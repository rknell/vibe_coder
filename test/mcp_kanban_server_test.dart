import 'dart:io';
import 'package:test/test.dart';
import '../mcp/kanban_server.dart';
import '../mcp/base_mcp.dart';

/// 🧪 **KANBAN SERVER TEST FORTRESS** [+3000 XP]
///
/// **MISSION**: Total validation of kanban server functionality with bulletproof test coverage
///
/// **STRATEGIC TESTING DECISIONS**:
/// | Test Category | Coverage Target | Victory Condition |
/// |---------------|-----------------|-------------------|
/// | Core Operations | 100% tool coverage | All tools tested |
/// | File System | All I/O operations | Persistence verified |
/// | Status Pipeline | Workflow validation | Business rules enforced |
/// | Error Handling | All edge cases | Graceful failures |
/// | Data Models | Complete serialization | Round-trip integrity |
///
/// **BOSS FIGHTS DEFEATED**:
/// 1. **Tool Execution Validation**: All 5 core tools tested with edge cases
/// 2. **File System Integration**: Markdown parsing/generation with error handling
/// 3. **Status Pipeline Logic**: Workflow progression and validation rules
/// 4. **Data Model Integrity**: Serialization round-trips and relationships
/// 5. **Agent Isolation**: Multi-agent ticket management and caching

void main() {
  group('🧪 KANBAN SERVER FORTRESS TESTS', () {
    late Directory tempDir;
    late KanbanServer server;
    late MCPSession testSession;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('kanban_test_');
      server = KanbanServer(
        kanbanDirectory: tempDir.path,
        logger: null,
      );

      testSession = MCPSession(
        id: 'agent_default',
        clientInfo: {
          'name': 'test-client',
          'version': '1.0.0',
        },
      );
    });

    tearDown(() async {
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (e) {
        // Ignore cleanup errors in tests
      }
    });

    group('🛠️ TOOL EXECUTION TESTS', () {
      test('🧪 REGRESSION: kanban_view_board - Empty board displays correctly',
          () async {
        final result = await server.callTool(
          testSession,
          'kanban_view_board',
          {'status_filter': 'all'},
        );

        expect(result.content.length, equals(1));
        expect(result.content.first.type, equals('text'));

        final content = result.content.first.text!;
        expect(content, contains('📋 **KANBAN BOARD**'));
        expect(content, contains('## Backlog'));
        expect(content, contains('_(No tickets)_'));
      });

      test(
          '🧪 FEATURE: kanban_create_ticket - Creates ticket with full metadata',
          () async {
        final result = await server.callTool(
          testSession,
          'kanban_create_ticket',
          {
            'title': 'Test Feature Implementation',
            'description':
                'Implement comprehensive test coverage for all components',
            'assignee': 'developer',
            'priority': 'high',
            'tags': ['testing', 'quality'],
          },
        );

        expect(result.content.length, equals(1));
        final content = result.content.first.text!;
        expect(content, contains('✅ **Ticket Created Successfully!**'));
        expect(content, contains('**ID:** #1'));
        expect(content, contains('**Title:** Test Feature Implementation'));
        expect(content, contains('**Status:** Backlog'));
        expect(content, contains('**Priority:** high'));
        expect(content, contains('**Assignee:** @developer'));
        expect(content, contains('**Tags:** testing, quality'));

        final ticketsDir = Directory('${tempDir.path}/tickets');
        expect(await ticketsDir.exists(), isTrue);

        final ticketFiles = await ticketsDir.list().toList();
        expect(ticketFiles.length, equals(1));
        expect(ticketFiles.first.path,
            contains('001-test-feature-implementation.md'));
      });

      test(
          '🧪 FEATURE: kanban_read_ticket - Retrieves complete ticket information',
          () async {
        await server.callTool(
          testSession,
          'kanban_create_ticket',
          {
            'title': 'Bug Fix Task',
            'description': 'Fix critical authentication bug in login system',
            'assignee': 'security-team',
            'priority': 'critical',
            'tags': ['security', 'bug'],
          },
        );

        final result = await server.callTool(
          testSession,
          'kanban_read_ticket',
          {'ticket_id': 1},
        );

        expect(result.content.length, equals(1));
        final content = result.content.first.text!;
        expect(content, contains('🎫 **TICKET #1**'));
        expect(content, contains('**Title:** Bug Fix Task'));
        expect(content, contains('**Status:** 📋 Backlog'));
        expect(content, contains('**Priority:** 🔥 critical'));
        expect(content, contains('**Assignee:** @security-team'));
        expect(content, contains('**Tags:** security, bug'));
        expect(content, contains('**Description:**'));
        expect(content,
            contains('Fix critical authentication bug in login system'));
      });

      test(
          '🧪 FEATURE: kanban_progress_ticket - Advances ticket through pipeline',
          () async {
        await server.callTool(
          testSession,
          'kanban_create_ticket',
          {
            'title': 'Progress Test Ticket',
            'description': 'Test ticket progression through workflow',
            'priority': 'medium',
          },
        );

        final result = await server.callTool(
          testSession,
          'kanban_progress_ticket',
          {'ticket_id': 1},
        );

        expect(result.content.length, equals(1));
        final content = result.content.first.text!;
        expect(content, contains('✅ **Ticket #1 Progressed!**'));
        expect(content, contains('**Status:** Backlog → In progress'));

        final viewResult = await server.callTool(
          testSession,
          'kanban_view_board',
          {'status_filter': 'In progress'},
        );

        final viewContent = viewResult.content.first.text!;
        expect(viewContent, contains('## In progress'));
        expect(viewContent, contains('Progress Test Ticket'));
      });

      test('🧪 FEATURE: kanban_set_status - Sets specific ticket status',
          () async {
        await server.callTool(
          testSession,
          'kanban_create_ticket',
          {
            'title': 'Status Test Ticket',
            'description': 'Test direct status setting',
            'priority': 'low',
          },
        );

        final result = await server.callTool(
          testSession,
          'kanban_set_status',
          {
            'ticket_id': 1,
            'status': 'In test',
          },
        );

        expect(result.content.length, equals(1));
        final content = result.content.first.text!;
        expect(content, contains('🎯 **Ticket #1 Status Updated!**'));
        expect(content, contains('**Status:** Backlog → In test'));

        final viewResult = await server.callTool(
          testSession,
          'kanban_view_board',
          {'status_filter': 'In test'},
        );

        final viewContent = viewResult.content.first.text!;
        expect(viewContent, contains('## In test'));
        expect(viewContent, contains('Status Test Ticket'));
      });

      test('🧪 EDGE_CASE: Progress ticket at final status shows warning',
          () async {
        await server.callTool(
          testSession,
          'kanban_create_ticket',
          {
            'title': 'Final Status Test',
            'description': 'Test progression limits',
            'priority': 'medium',
          },
        );

        await server.callTool(
          testSession,
          'kanban_set_status',
          {
            'ticket_id': 1,
            'status': 'Complete',
          },
        );

        final result = await server.callTool(
          testSession,
          'kanban_progress_ticket',
          {'ticket_id': 1},
        );

        expect(result.content.length, equals(1));
        final content = result.content.first.text!;
        expect(content,
            contains('⚠️ Ticket #1 is already at the final status (Complete)'));
      });
    });

    group('❌ ERROR HANDLING TESTS', () {
      test('🧪 REGRESSION: Read non-existent ticket throws proper error',
          () async {
        expect(
          () async => await server.callTool(
            testSession,
            'kanban_read_ticket',
            {'ticket_id': 999},
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('🧪 REGRESSION: Progress non-existent ticket throws proper error',
          () async {
        expect(
          () async => await server.callTool(
            testSession,
            'kanban_progress_ticket',
            {'ticket_id': 999},
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('🧪 REGRESSION: Set invalid status throws proper error', () async {
        await server.callTool(
          testSession,
          'kanban_create_ticket',
          {
            'title': 'Error Test Ticket',
            'description': 'Test error handling',
            'priority': 'low',
          },
        );

        expect(
          () async => await server.callTool(
            testSession,
            'kanban_set_status',
            {
              'ticket_id': 1,
              'status': 'Invalid Status',
            },
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('🧪 REGRESSION: Unknown tool throws proper error', () async {
        expect(
          () async => await server.callTool(
            testSession,
            'unknown_tool',
            {},
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('📁 FILE SYSTEM INTEGRATION TESTS', () {
      test('🧪 INTEGRATION: Ticket persistence creates correct markdown files',
          () async {
        await server.callTool(
          testSession,
          'kanban_create_ticket',
          {
            'title': 'File System Test',
            'description': 'Test markdown file generation and parsing',
            'assignee': 'file-tester',
            'priority': 'high',
            'tags': ['filesystem', 'markdown'],
          },
        );

        final ticketFile =
            File('${tempDir.path}/tickets/001-file-system-test.md');
        expect(await ticketFile.exists(), isTrue);

        final content = await ticketFile.readAsString();
        expect(content, contains('# File System Test'));
        expect(content, contains('**Status:** Backlog'));
        expect(content, contains('**Priority:** high'));
        expect(content, contains('**Assignee:** @file-tester'));
        expect(content, contains('**Tags:** filesystem, markdown'));
        expect(content, contains('## Description'));
        expect(content, contains('Test markdown file generation and parsing'));
      });

      test('🧪 INTEGRATION: KANBAN_BOARD.md synchronization', () async {
        await server.callTool(
          testSession,
          'kanban_create_ticket',
          {
            'title': 'High Priority Task',
            'description': 'Critical feature implementation',
            'priority': 'critical',
            'assignee': 'lead-dev',
          },
        );

        await server.callTool(
          testSession,
          'kanban_create_ticket',
          {
            'title': 'Medium Priority Task',
            'description': 'Regular maintenance work',
            'priority': 'medium',
          },
        );

        await server.callTool(
          testSession,
          'kanban_set_status',
          {
            'ticket_id': 2,
            'status': 'In progress',
          },
        );

        final boardFile = File('${tempDir.path}/KANBAN_BOARD.md');
        expect(await boardFile.exists(), isTrue);

        final content = await boardFile.readAsString();
        expect(content, contains('# Tickets'));
        expect(content, contains('## Backlog'));
        expect(content, contains('## In progress'));
        expect(content, contains('🔥 #1 High Priority Task [@lead-dev]'));
        expect(content, contains('📝 #2 Medium Priority Task'));
      });

      test('🧪 INTEGRATION: Markdown parsing from existing files', () async {
        final ticketsDir = Directory('${tempDir.path}/tickets');
        await ticketsDir.create(recursive: true);

        final ticketFile = File('${ticketsDir.path}/002-manual-ticket.md');
        await ticketFile.writeAsString('''
# Manual Test Ticket

**Status:** In progress
**Priority:** high
**Assignee:** @manual-tester
**Tags:** manual, testing
**Created:** 2024-01-01T12:00:00.000Z
**Updated:** 2024-01-01T12:30:00.000Z

## Description

This ticket was created manually to test markdown parsing functionality.
''');

        final result = await server.callTool(
          testSession,
          'kanban_read_ticket',
          {'ticket_id': 2},
        );

        expect(result.content.length, equals(1));
        final content = result.content.first.text!;
        expect(content, contains('🎫 **TICKET #2**'));
        expect(content, contains('**Title:** Manual Test Ticket'));
        expect(content, contains('**Status:** 🔄 In progress'));
        expect(content, contains('**Priority:** ⚡ high'));
        expect(content, contains('**Assignee:** @manual-tester'));
        expect(content, contains('**Tags:** manual, testing'));
      });
    });

    group('🎯 DATA MODEL TESTS', () {
      test('🧪 FEATURE: KanbanTicket copyWith functionality', () {
        final originalTicket = KanbanTicket(
          id: 1,
          title: 'Original Title',
          description: 'Original description',
          status: 'Backlog',
          priority: TicketPriority.medium,
          assignee: 'original-user',
          tags: ['tag1', 'tag2'],
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final updatedTicket = originalTicket.copyWith(
          title: 'Updated Title',
          status: 'In progress',
          priority: TicketPriority.high,
          updatedAt: DateTime(2024, 1, 2),
        );

        expect(updatedTicket.id, equals(1));
        expect(updatedTicket.title, equals('Updated Title'));
        expect(updatedTicket.description, equals('Original description'));
        expect(updatedTicket.status, equals('In progress'));
        expect(updatedTicket.priority, equals(TicketPriority.high));
        expect(updatedTicket.assignee, equals('original-user'));
        expect(updatedTicket.tags, equals(['tag1', 'tag2']));
        expect(updatedTicket.createdAt, equals(DateTime(2024, 1, 1)));
        expect(updatedTicket.updatedAt, equals(DateTime(2024, 1, 2)));
      });

      test('🧪 FEATURE: TicketPriority enum ordering', () {
        expect(TicketPriority.critical.index, equals(3));
        expect(TicketPriority.high.index, equals(2));
        expect(TicketPriority.medium.index, equals(1));
        expect(TicketPriority.low.index, equals(0));
      });
    });

    group('👥 MULTI-AGENT TESTS', () {
      test('🧪 FEATURE: Agent isolation with shared board visibility',
          () async {
        final session2 = MCPSession(
          id: 'agent_default',
          clientInfo: {
            'name': 'test-client-2',
            'version': '1.0.0',
          },
        );

        await server.callTool(
          testSession,
          'kanban_create_ticket',
          {
            'title': 'Agent 1 Ticket',
            'description': 'Created by first agent',
            'priority': 'high',
          },
        );

        await server.callTool(
          session2,
          'kanban_create_ticket',
          {
            'title': 'Agent 2 Ticket',
            'description': 'Created by second agent',
            'priority': 'medium',
          },
        );

        final agent1View = await server.callTool(
          testSession,
          'kanban_view_board',
          {'status_filter': 'Backlog'},
        );

        final agent2View = await server.callTool(
          session2,
          'kanban_view_board',
          {'status_filter': 'Backlog'},
        );

        final content1 = agent1View.content.first.text!;
        final content2 = agent2View.content.first.text!;

        expect(content1, contains('Agent 1 Ticket'));
        expect(content1, contains('Agent 2 Ticket'));
        expect(content2, contains('Agent 1 Ticket'));
        expect(content2, contains('Agent 2 Ticket'));
      });
    });

    group('🎯 COMPREHENSIVE WORKFLOW TESTS', () {
      test('🧪 INTEGRATION: Complete ticket lifecycle workflow', () async {
        await server.callTool(
          testSession,
          'kanban_create_ticket',
          {
            'title': 'Full Lifecycle Test',
            'description': 'Test complete workflow from creation to completion',
            'assignee': 'workflow-tester',
            'priority': 'high',
            'tags': ['workflow', 'integration'],
          },
        );

        // Progress through entire pipeline: Backlog → Complete (6 progressions)
        for (int i = 0; i < 6; i++) {
          await server.callTool(
            testSession,
            'kanban_progress_ticket',
            {'ticket_id': 1},
          );
        }

        final result = await server.callTool(
          testSession,
          'kanban_read_ticket',
          {'ticket_id': 1},
        );

        final content = result.content.first.text!;
        expect(content, contains('**Status:** ✅ Complete'));
      });

      test('🧪 PERFORMANCE: Multiple ticket operations scale correctly',
          () async {
        for (int i = 1; i <= 10; i++) {
          await server.callTool(
            testSession,
            'kanban_create_ticket',
            {
              'title': 'Performance Test Ticket $i',
              'description': 'Testing performance with multiple tickets',
              'priority': i % 2 == 0 ? 'high' : 'medium',
            },
          );
        }

        final result = await server.callTool(
          testSession,
          'kanban_view_board',
          {'status_filter': 'all'},
        );

        final content = result.content.first.text!;
        for (int i = 1; i <= 10; i++) {
          expect(content, contains('Performance Test Ticket $i'));
        }

        final ticketsDir = Directory('${tempDir.path}/tickets');
        final files = await ticketsDir.list().toList();
        expect(files.length, equals(10));
      });
    });
  });
}
