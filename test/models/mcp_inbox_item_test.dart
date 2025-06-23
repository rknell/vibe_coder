/// MCPInboxItem Test Suite - Comprehensive coverage for inbox content management
///
/// ## MISSION ACCOMPLISHED
/// Validates inbox item functionality including read status, sender management,
/// priority handling, and preview generation for Discord-style inbox UI.
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **State Transition Validation**: Ensures proper read/unread state management
/// 2. **Preview Generation Testing**: Validates content truncation and formatting
/// 3. **Sender Management**: Tests sender assignment and validation
/// 4. **Priority Operations**: Validates priority setting and reactive updates
library mcp_inbox_item_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/models/mcp_content_base.dart';
import 'package:vibe_coder/models/mcp_inbox_item.dart';

void main() {
  group('🛡️ REGRESSION: MCPInboxItem Core Functionality', () {
    test('🚀 FEATURE: Basic inbox item creation', () {
      final inbox = MCPInboxItem(
        content: 'Test inbox message',
        sender: 'john@example.com',
        priority: MCPPriority.high,
      );

      expect(inbox.content, equals('Test inbox message'));
      expect(inbox.sender, equals('john@example.com'));
      expect(inbox.priority, equals(MCPPriority.high));
      expect(inbox.contentType, equals(MCPContentType.inbox));
      expect(inbox.isRead, isFalse); // Default unread
      expect(inbox.dateReceived, isNotNull);
      expect(inbox.id, isNotEmpty);
    });

    test('🛡️ REGRESSION: Read status state transitions', () {
      final inbox = MCPInboxItem(
        content: 'Test message',
        sender: 'sender@test.com',
      );

      // Verify initial state
      expect(inbox.isRead, isFalse);

      // Test mark as read
      inbox.markAsRead();
      expect(inbox.isRead, isTrue);

      // Test mark as unread
      inbox.markAsUnread();
      expect(inbox.isRead, isFalse);
    });

    test('⚡ PERFORMANCE: ChangeNotifier integration', () {
      final inbox = MCPInboxItem(content: 'Test message');
      bool notificationReceived = false;

      inbox.addListener(() {
        notificationReceived = true;
      });

      // Test read status change notification
      inbox.markAsRead();
      expect(notificationReceived, isTrue);

      // Reset and test priority change notification
      notificationReceived = false;
      inbox.setPriority(MCPPriority.urgent);
      expect(notificationReceived, isTrue);
    });

    test('🎯 EDGE_CASE: Preview generation with various content lengths', () {
      // Short content (< 5 lines)
      final shortInbox = MCPInboxItem(content: 'Short message');
      expect(shortInbox.getPreview(), equals('Short message'));

      // Long content (> 5 lines)
      final longContent = List.generate(10, (i) => 'Line ${i + 1}').join('\n');
      final longInbox = MCPInboxItem(content: longContent);
      final preview = longInbox.getPreview();
      final previewLines = preview.split('\n');
      expect(previewLines.length, equals(5));
      expect(previewLines.first, equals('Line 1'));
      expect(previewLines.last, equals('Line 5'));
    });

    test('🎯 EDGE_CASE: Preview generation with custom max lines', () {
      final content = List.generate(10, (i) => 'Line ${i + 1}').join('\n');
      final inbox = MCPInboxItem(content: content);

      // Test custom max lines
      final preview3 = inbox.getPreview(maxLines: 3);
      expect(preview3.split('\n').length, equals(3));

      final preview7 = inbox.getPreview(maxLines: 7);
      expect(preview7.split('\n').length, equals(7));
    });

    test('🔧 INTEGRATION: Priority management', () {
      final inbox = MCPInboxItem(
        content: 'Priority test message',
        priority: MCPPriority.low,
      );

      expect(inbox.priority, equals(MCPPriority.low));

      // Test priority update
      inbox.setPriority(MCPPriority.urgent);
      expect(inbox.priority, equals(MCPPriority.urgent));

      // Verify timestamp updated
      final oldTimestamp = inbox.updatedAt;
      inbox.setPriority(MCPPriority.medium);
      expect(inbox.updatedAt.isAfter(oldTimestamp), isTrue);
    });

    test('🛡️ REGRESSION: JSON serialization round trip', () {
      final originalInbox = MCPInboxItem(
        content: 'Serialization test',
        sender: 'test@example.com',
        priority: MCPPriority.high,
        isRead: true,
      );

      // Convert to JSON
      final json = originalInbox.toJson();

      // Verify JSON structure
      expect(json['isRead'], isTrue);
      expect(json['sender'], equals('test@example.com'));
      expect(json['dateReceived'], isNotNull);
      expect(json['contentType'], equals('inbox'));

      // Convert back from JSON
      final restoredInbox = MCPInboxItem.fromJson(json);

      // Verify all fields restored correctly
      expect(restoredInbox.id, equals(originalInbox.id));
      expect(restoredInbox.content, equals(originalInbox.content));
      expect(restoredInbox.sender, equals(originalInbox.sender));
      expect(restoredInbox.priority, equals(originalInbox.priority));
      expect(restoredInbox.isRead, equals(originalInbox.isRead));
      expect(restoredInbox.contentType, equals(MCPContentType.inbox));
    });

    test('🎯 EDGE_CASE: Null sender handling', () {
      final inbox = MCPInboxItem(
        content: 'Message without sender',
        sender: null,
      );

      expect(inbox.sender, isNull);

      // Test JSON round trip with null sender
      final json = inbox.toJson();
      final restored = MCPInboxItem.fromJson(json);
      expect(restored.sender, isNull);
    });

    test('⚡ PERFORMANCE: Preview generation performance', () {
      // Generate large content for performance test
      final largeContent =
          List.generate(1000, (i) => 'Line $i with content').join('\n');
      final inbox = MCPInboxItem(content: largeContent);

      final stopwatch = Stopwatch()..start();
      final preview = inbox.getPreview();
      stopwatch.stop();

      // Performance requirement: < 10ms for preview generation (adjusted for test environment)
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
      expect(preview.split('\n').length, equals(5));
    });

    test('🛡️ REGRESSION: Content validation inheritance', () {
      // Test validation from base class still works
      final inbox = MCPInboxItem(content: 'Valid content');
      expect(inbox.validate(), isTrue);

      // Test content sanitization
      inbox.updateContent('  Content with whitespace  ');
      expect(inbox.content, equals('Content with whitespace'));
    });

    test('🔧 INTEGRATION: getPreviewLines method', () {
      final content = 'Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6';
      final inbox = MCPInboxItem(content: content);

      final previewLines = inbox.getPreviewLines();
      expect(previewLines, isA<List<String>>());
      expect(previewLines.length, equals(5));
      expect(previewLines[0], equals('Line 1'));
      expect(previewLines[4], equals('Line 5'));
    });
  });

  group('🚀 FEATURE: MCPInboxItem Advanced Features', () {
    test('🎯 EDGE_CASE: Empty content handling', () {
      expect(
        () => MCPInboxItem(content: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('⚡ PERFORMANCE: State transition timing', () {
      final inbox = MCPInboxItem(content: 'Performance test');

      final stopwatch = Stopwatch()..start();
      inbox.markAsRead();
      stopwatch.stop();

      // Performance requirement: < 1ms for state changes
      expect(stopwatch.elapsedMilliseconds, lessThan(1));
    });

    test('🛡️ REGRESSION: Date received tracking', () {
      final beforeCreation = DateTime.now();
      final inbox = MCPInboxItem(content: 'Date test');
      final afterCreation = DateTime.now();

      expect(
          inbox.dateReceived.isAfter(beforeCreation) ||
              inbox.dateReceived.isAtSameMomentAs(beforeCreation),
          isTrue);
      expect(
          inbox.dateReceived.isBefore(afterCreation) ||
              inbox.dateReceived.isAtSameMomentAs(afterCreation),
          isTrue);
    });

    test('🔧 INTEGRATION: toString method', () {
      final inbox = MCPInboxItem(
        content: 'Test message for toString',
        sender: 'test@example.com',
        priority: MCPPriority.high,
      );

      final stringRepresentation = inbox.toString();
      expect(stringRepresentation, contains('MCPInboxItem'));
      expect(stringRepresentation, contains(inbox.id));
      expect(stringRepresentation, contains('inbox'));
      expect(stringRepresentation, contains('high'));
    });
  });
}
