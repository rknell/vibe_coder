import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import '../mcp/company_directory_server.dart';

/// 🧪 **COMPANY DIRECTORY EMAIL FUNCTIONALITY TESTS**
///
/// **MISSION**: Verify comprehensive email-like messaging system for agent communication
/// Tests all email features including sending, receiving, replying, forwarding, and inbox management.
void main() {
  group('📧 Company Directory Email System Tests', () {
    late CompanyDirectoryMCPServer server;
    late String tempDir;

    setUp(() async {
      // Create temporary directory for persistence
      final tempDirObj =
          await Directory.systemTemp.createTemp('company_directory_test_');
      tempDir = tempDirObj.path;
      server = CompanyDirectoryMCPServer(persistenceDirectory: tempDir);
      await server.onInitialized();
    });

    tearDown(() async {
      // Clean up temporary directory
      final dir = Directory(tempDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    group('📝 Agent Registration', () {
      test('should register agents for email communication', () async {
        // Register multiple agents
        final result1 = await server.callTool('directory_register_agent', {
          'agentName': 'agent1',
          'name': 'Test Agent 1',
          'role': 'Developer',
          'capabilities': ['coding', 'testing'],
          'status': 'active',
          'description': 'Test agent for email functionality',
        });

        final result2 = await server.callTool('directory_register_agent', {
          'agentName': 'agent2',
          'name': 'Test Agent 2',
          'role': 'Designer',
          'capabilities': ['design', 'ui'],
          'status': 'active',
          'description': 'Test agent for email functionality',
        });

        expect(result1.isError, false);
        expect(result2.isError, false);

        final data1 = jsonDecode(result1.content.first.text ?? '{}');
        final data2 = jsonDecode(result2.content.first.text ?? '{}');

        expect(data1['success'], true);
        expect(data2['success'], true);
        expect(data1['agent_id'], isNotEmpty);
        expect(data2['agent_id'], isNotEmpty);
      });
    });

    group('📧 Email Sending', () {
      test('should send email between agents', () async {
        // Register agents
        await server.callTool('directory_register_agent', {
          'agentName': 'sender',
          'name': 'Sender Agent',
          'role': 'Manager',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'receiver',
          'name': 'Receiver Agent',
          'role': 'Developer',
          'status': 'active',
        });

        // Send email
        final result = await server.callTool('directory_send_email', {
          'agentName': 'sender',
          'to': ['receiver'],
          'subject': 'Test Email',
          'body': 'This is a test email message.',
          'priority': 'normal',
        });

        expect(result.isError, false);
        final data = jsonDecode(result.content.first.text ?? '{}');
        expect(data['success'], true);
        expect(data['email_id'], isNotEmpty);
        expect(data['subject'], 'Test Email');
        expect(data['delivered_to'], contains('Receiver Agent'));
      });

      test('should send email with attachments', () async {
        // Register agents
        await server.callTool('directory_register_agent', {
          'agentName': 'sender',
          'name': 'Sender Agent',
          'role': 'Manager',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'receiver',
          'name': 'Receiver Agent',
          'role': 'Developer',
          'status': 'active',
        });

        // Send email with attachment
        final result = await server.callTool('directory_send_email', {
          'agentName': 'sender',
          'to': ['receiver'],
          'subject': 'Email with Attachment',
          'body': 'Please find the attached file.',
          'priority': 'high',
          'attachments': [
            {
              'filename': 'test.txt',
              'content': 'This is test file content',
              'mime_type': 'text/plain',
            }
          ],
        });

        expect(result.isError, false);
        final data = jsonDecode(result.content.first.text ?? '{}');
        expect(data['success'], true);
        expect(data['email_id'], isNotEmpty);
      });

      test('should send email to multiple recipients', () async {
        // Register multiple agents
        await server.callTool('directory_register_agent', {
          'agentName': 'sender',
          'name': 'Sender Agent',
          'role': 'Manager',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'receiver1',
          'name': 'Receiver 1',
          'role': 'Developer',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'receiver2',
          'name': 'Receiver 2',
          'role': 'Designer',
          'status': 'active',
        });

        // Send email to multiple recipients
        final result = await server.callTool('directory_send_email', {
          'agentName': 'sender',
          'to': ['receiver1'],
          'cc': ['receiver2'],
          'subject': 'Team Update',
          'body': 'Important team update for everyone.',
          'priority': 'high',
        });

        expect(result.isError, false);
        final data = jsonDecode(result.content.first.text ?? '{}');
        expect(data['success'], true);
        expect(data['total_recipients'], 2);
        expect(data['successful_deliveries'], 2);
      });
    });

    group('📬 Inbox Management', () {
      test('should check inbox for new messages', () async {
        // Register agents
        await server.callTool('directory_register_agent', {
          'agentName': 'sender',
          'name': 'Sender Agent',
          'role': 'Manager',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'receiver',
          'name': 'Receiver Agent',
          'role': 'Developer',
          'status': 'active',
        });

        // Send email
        await server.callTool('directory_send_email', {
          'agentName': 'sender',
          'to': ['receiver'],
          'subject': 'Test Email',
          'body': 'This is a test email message.',
        });

        // Check inbox
        final result = await server.callTool('directory_check_inbox', {
          'agentName': 'receiver',
          'include_read': false,
          'limit': 10,
        });

        expect(result.isError, false);
        final data = jsonDecode(result.content.first.text ?? '{}');
        expect(data['success'], true);
        expect(data['total_emails'], 1);
        expect(data['unread_count'], 1);
        expect(data['emails'], hasLength(1));
        expect(data['emails'][0]['subject'], 'Test Email');
        expect(data['emails'][0]['sender_name'], 'Sender Agent');
      });

      test('should mark emails as read when checking', () async {
        // Register agents
        await server.callTool('directory_register_agent', {
          'agentName': 'sender',
          'name': 'Sender Agent',
          'role': 'Manager',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'receiver',
          'name': 'Receiver Agent',
          'role': 'Developer',
          'status': 'active',
        });

        // Send email
        await server.callTool('directory_send_email', {
          'agentName': 'sender',
          'to': ['receiver'],
          'subject': 'Test Email',
          'body': 'This is a test email message.',
        });

        // Check inbox with mark_as_read
        final result = await server.callTool('directory_check_inbox', {
          'agentName': 'receiver',
          'mark_as_read': true,
          'include_read': true,
        });

        expect(result.isError, false);
        final data = jsonDecode(result.content.first.text ?? '{}');
        expect(data['success'], true);
        expect(data['unread_count'], 0); // Should be marked as read
      });
    });

    group('📧 Email Operations', () {
      test('should get specific email by ID', () async {
        // Register agents
        await server.callTool('directory_register_agent', {
          'agentName': 'sender',
          'name': 'Sender Agent',
          'role': 'Manager',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'receiver',
          'name': 'Receiver Agent',
          'role': 'Developer',
          'status': 'active',
        });

        // Send email
        final sendResult = await server.callTool('directory_send_email', {
          'agentName': 'sender',
          'to': ['receiver'],
          'subject': 'Test Email',
          'body': 'This is a test email message with detailed content.',
        });

        final sendData = jsonDecode(sendResult.content.first.text ?? '{}');
        final emailId = sendData['email_id'];

        // Get specific email
        final result = await server.callTool('directory_get_email', {
          'agentName': 'receiver',
          'email_id': emailId,
        });

        expect(result.isError, false);
        final data = jsonDecode(result.content.first.text ?? '{}');
        expect(data['success'], true);
        expect(data['email_id'], emailId);
        expect(data['subject'], 'Test Email');
        expect(data['body'],
            'This is a test email message with detailed content.');
        expect(data['sender_name'], 'Sender Agent');
      });

      test('should reply to email', () async {
        // Register agents
        await server.callTool('directory_register_agent', {
          'agentName': 'sender',
          'name': 'Sender Agent',
          'role': 'Manager',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'receiver',
          'name': 'Receiver Agent',
          'role': 'Developer',
          'status': 'active',
        });

        // Send email
        final sendResult = await server.callTool('directory_send_email', {
          'agentName': 'sender',
          'to': ['receiver'],
          'subject': 'Original Email',
          'body': 'This is the original email.',
        });

        final sendData = jsonDecode(sendResult.content.first.text ?? '{}');
        final emailId = sendData['email_id'];

        // Reply to email
        final result = await server.callTool('directory_reply_to_email', {
          'agentName': 'receiver',
          'email_id': emailId,
          'body': 'This is my reply to your email.',
        });

        expect(result.isError, false);
        final data = jsonDecode(result.content.first.text ?? '{}');
        expect(data['success'], true);
        expect(data['reply_id'], isNotEmpty);
        expect(data['original_email_id'], emailId);
        expect(data['subject'], 'Re: Original Email');
        expect(data['sent_to'], 'Sender Agent');
      });

      test('should forward email', () async {
        // Register agents
        await server.callTool('directory_register_agent', {
          'agentName': 'sender',
          'name': 'Sender Agent',
          'role': 'Manager',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'receiver',
          'name': 'Receiver Agent',
          'role': 'Developer',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'forward_to',
          'name': 'Forward Target',
          'role': 'Designer',
          'status': 'active',
        });

        // Send email
        final sendResult = await server.callTool('directory_send_email', {
          'agentName': 'sender',
          'to': ['receiver'],
          'subject': 'Original Email',
          'body': 'This is the original email to forward.',
        });

        final sendData = jsonDecode(sendResult.content.first.text ?? '{}');
        final emailId = sendData['email_id'];

        // Forward email
        final result = await server.callTool('directory_forward_email', {
          'agentName': 'receiver',
          'email_id': emailId,
          'to': ['forward_to'],
          'forward_note': 'Please review this important message.',
        });

        expect(result.isError, false);
        final data = jsonDecode(result.content.first.text ?? '{}');
        expect(data['success'], true);
        expect(data['forwarded_email_id'], isNotEmpty);
        expect(data['original_email_id'], emailId);
        expect(data['subject'], 'Fwd: Original Email');
        expect(data['delivered_to'], contains('Forward Target'));
      });

      test('should delete email', () async {
        // Register agents
        await server.callTool('directory_register_agent', {
          'agentName': 'sender',
          'name': 'Sender Agent',
          'role': 'Manager',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'receiver',
          'name': 'Receiver Agent',
          'role': 'Developer',
          'status': 'active',
        });

        // Send email
        final sendResult = await server.callTool('directory_send_email', {
          'agentName': 'sender',
          'to': ['receiver'],
          'subject': 'Email to Delete',
          'body': 'This email will be deleted.',
        });

        final sendData = jsonDecode(sendResult.content.first.text ?? '{}');
        final emailId = sendData['email_id'];

        // Delete email
        final result = await server.callTool('directory_delete_email', {
          'agentName': 'receiver',
          'email_id': emailId,
        });

        expect(result.isError, false);
        final data = jsonDecode(result.content.first.text ?? '{}');
        expect(data['success'], true);
        expect(data['email_id'], emailId);
        expect(data['subject'], 'Email to Delete');
      });
    });

    group('📊 Inbox Statistics', () {
      test('should get inbox statistics', () async {
        // Register agent
        await server.callTool('directory_register_agent', {
          'agentName': 'test_agent',
          'name': 'Test Agent',
          'role': 'Developer',
          'status': 'active',
        });

        // Get initial statistics
        final initialResult =
            await server.callTool('directory_get_inbox_stats', {
          'agentName': 'test_agent',
        });

        expect(initialResult.isError, false);
        final initialData =
            jsonDecode(initialResult.content.first.text ?? '{}');
        expect(initialData['success'], true);
        expect(initialData['total_emails'], 0);
        expect(initialData['unread_emails'], 0);
      });

      test('should track email statistics correctly', () async {
        // Create isolated server instance for this test to prevent state leakage
        final isolatedTempDir = await Directory.systemTemp
            .createTemp('company_directory_stats_test_');
        final isolatedServer = CompanyDirectoryMCPServer(
            persistenceDirectory: isolatedTempDir.path);
        await isolatedServer.onInitialized();

        try {
          // Register agents
          await isolatedServer.callTool('directory_register_agent', {
            'agentName': 'stats_sender',
            'name': 'Stats Sender Agent',
            'role': 'Manager',
            'status': 'active',
          });

          await isolatedServer.callTool('directory_register_agent', {
            'agentName': 'stats_receiver',
            'name': 'Stats Receiver Agent',
            'role': 'Developer',
            'status': 'active',
          });

          // Send multiple emails with different priorities
          await isolatedServer.callTool('directory_send_email', {
            'agentName': 'stats_sender',
            'to': ['stats_receiver'],
            'subject': 'Normal Email',
            'body': 'Normal priority email.',
            'priority': 'normal',
          });
          var inbox1 = await isolatedServer.callTool('directory_check_inbox', {
            'agentName': 'stats_receiver',
            'include_read': true,
          });
          // ignore: avoid_print
          print(
              'Inbox after 1st email: \n${inbox1.content.first.text ?? 'null'}');

          await isolatedServer.callTool('directory_send_email', {
            'agentName': 'stats_sender',
            'to': ['stats_receiver'],
            'subject': 'High Priority Email',
            'body': 'High priority email.',
            'priority': 'high',
          });
          var inbox2 = await isolatedServer.callTool('directory_check_inbox', {
            'agentName': 'stats_receiver',
            'include_read': true,
          });
          // ignore: avoid_print
          print(
              'Inbox after 2nd email: \n${inbox2.content.first.text ?? 'null'}');

          await isolatedServer.callTool('directory_send_email', {
            'agentName': 'stats_sender',
            'to': ['stats_receiver'],
            'subject': 'Urgent Email',
            'body': 'Urgent email.',
            'priority': 'urgent',
          });
          var inbox3 = await isolatedServer.callTool('directory_check_inbox', {
            'agentName': 'stats_receiver',
            'include_read': true,
          });
          // ignore: avoid_print
          print(
              'Inbox after 3rd email: \n${inbox3.content.first.text ?? 'null'}');

          // Get statistics
          final result =
              await isolatedServer.callTool('directory_get_inbox_stats', {
            'agentName': 'stats_receiver',
          });

          expect(result.isError, false);
          final data = jsonDecode(result.content.first.text ?? '{}');
          expect(data['success'], true);
          expect(data['total_emails'], 3);
          expect(data['unread_emails'], 3);
          expect(data['high_priority_emails'], 1);
          expect(data['urgent_emails'], 1);
          expect(data['total_threads'], 3);
        } finally {
          // Clean up isolated server
          final dir = Directory(isolatedTempDir.path);
          if (await dir.exists()) {
            await dir.delete(recursive: true);
          }
        }
      });
    });

    group('📋 Available Recipients', () {
      test('should get available recipients for email', () async {
        // Register multiple agents
        await server.callTool('directory_register_agent', {
          'agentName': 'agent1',
          'name': 'Agent 1',
          'role': 'Developer',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'agent2',
          'name': 'Agent 2',
          'role': 'Designer',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'agent3',
          'name': 'Agent 3',
          'role': 'Manager',
          'status': 'busy',
        });

        // Get available recipients
        final result =
            await server.callTool('directory_get_available_recipients', {
          'agentName': 'agent1',
          'status_filter': 'active',
        });

        expect(result.isError, false);
        final data = jsonDecode(result.content.first.text ?? '{}');
        expect(data['success'], true);
        expect(data['total_recipients'], 2); // Only active agents
        expect(data['recipients'], hasLength(2));
      });

      test('should filter recipients by role', () async {
        // Register agents with different roles
        await server.callTool('directory_register_agent', {
          'agentName': 'dev1',
          'name': 'Developer 1',
          'role': 'Developer',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'dev2',
          'name': 'Developer 2',
          'role': 'Developer',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'designer1',
          'name': 'Designer 1',
          'role': 'Designer',
          'status': 'active',
        });

        // Get developers only
        final result =
            await server.callTool('directory_get_available_recipients', {
          'agentName': 'dev1',
          'role_filter': 'Developer',
        });

        expect(result.isError, false);
        final data = jsonDecode(result.content.first.text ?? '{}');
        expect(data['success'], true);
        expect(data['total_recipients'], 2); // Only developers
        expect(data['recipients'], hasLength(2));
      });
    });

    group('🔄 Email Threading', () {
      test('should maintain email threads for replies', () async {
        // Register agents
        await server.callTool('directory_register_agent', {
          'agentName': 'sender',
          'name': 'Sender Agent',
          'role': 'Manager',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'receiver',
          'name': 'Receiver Agent',
          'role': 'Developer',
          'status': 'active',
        });

        // Send original email
        final sendResult = await server.callTool('directory_send_email', {
          'agentName': 'sender',
          'to': ['receiver'],
          'subject': 'Thread Test',
          'body': 'Original message.',
        });

        final sendData = jsonDecode(sendResult.content.first.text ?? '{}');
        final originalEmailId = sendData['email_id'];
        final threadId = sendData['thread_id'];

        // Reply to email
        final replyResult = await server.callTool('directory_reply_to_email', {
          'agentName': 'receiver',
          'email_id': originalEmailId,
          'body': 'Reply to original.',
        });

        final replyData = jsonDecode(replyResult.content.first.text ?? '{}');
        final replyEmailId = replyData['reply_id'];
        final replyThreadId = replyData['thread_id'];

        // Verify thread consistency
        expect(threadId, replyThreadId);

        // Get both emails and verify threading
        final email1 = await server.callTool('directory_get_email', {
          'agentName': 'receiver',
          'email_id': originalEmailId,
        });

        final email2 = await server.callTool('directory_get_email', {
          'agentName': 'sender',
          'email_id': replyEmailId,
        });

        final email1Data = jsonDecode(email1.content.first.text ?? '{}');
        final email2Data = jsonDecode(email2.content.first.text ?? '{}');

        expect(email1Data['thread_id'], threadId);
        expect(email2Data['thread_id'], threadId);
        expect(email2Data['reply_to_id'], originalEmailId);
      });
    });

    group('💾 Persistence', () {
      test('should persist email data across server restarts', () async {
        // Register agents
        await server.callTool('directory_register_agent', {
          'agentName': 'sender',
          'name': 'Sender Agent',
          'role': 'Manager',
          'status': 'active',
        });

        await server.callTool('directory_register_agent', {
          'agentName': 'receiver',
          'name': 'Receiver Agent',
          'role': 'Developer',
          'status': 'active',
        });

        // Send email
        await server.callTool('directory_send_email', {
          'agentName': 'sender',
          'to': ['receiver'],
          'subject': 'Persistent Email',
          'body': 'This email should persist.',
        });

        // Create new server instance (simulating restart)
        final newServer =
            CompanyDirectoryMCPServer(persistenceDirectory: tempDir);
        await newServer.onInitialized();

        // Check if email persists
        final result = await newServer.callTool('directory_check_inbox', {
          'agentName': 'receiver',
          'include_read': true,
        });

        expect(result.isError, false);
        final data = jsonDecode(result.content.first.text ?? '{}');
        expect(data['success'], true);
        expect(data['total_emails'], 1);
        expect(data['emails'][0]['subject'], 'Persistent Email');
      });
    });
  });
}
