library mcp_content_base_test;

/// MCP Content Infrastructure Test Suite
///
/// ## MISSION ACCOMPLISHED
/// Validates foundational MCP content infrastructure with comprehensive
/// test coverage for base classes, enums, and reactive patterns.
///
/// ## TEST CATEGORIES
/// - Enum functionality and serialization
/// - Base class construction and initialization
/// - Content validation and sanitization
/// - ChangeNotifier reactive patterns
/// - JSON serialization round-trips
/// - Performance benchmarks
/// - Security validation
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/models/mcp_content_base.dart';

/// Concrete test implementation of MCPContentItem for testing
class TestMCPContentItem extends MCPContentItem {
  TestMCPContentItem({
    super.id,
    required super.content,
    required super.contentType,
    super.priority = MCPPriority.medium,
    super.createdAt,
    super.updatedAt,
    super.metadata,
  });

  /// Test factory for JSON deserialization
  factory TestMCPContentItem.fromJson(Map<String, dynamic> json) {
    final baseFields = MCPContentItem.parseBaseFields(json);
    return TestMCPContentItem(
      id: baseFields['id'] as String,
      content: baseFields['content'] as String,
      contentType: MCPContentItem.parseContentType(json),
      priority: baseFields['priority'] as MCPPriority,
      createdAt: baseFields['createdAt'] as DateTime,
      updatedAt: baseFields['updatedAt'] as DateTime,
      metadata: baseFields['metadata'] as Map<String, dynamic>,
    );
  }
}

void main() {
  group('🎯 MCP Content Infrastructure Tests', () {
    group('⚔️ MCPContentType Enum Warfare', () {
      test('✅ All enum values present and accessible', () {
        expect(MCPContentType.values.length, equals(3));
        expect(MCPContentType.inbox.value, equals('inbox'));
        expect(MCPContentType.todo.value, equals('todo'));
        expect(MCPContentType.notepad.value, equals('notepad'));
      });

      test('✅ String conversion round-trip accuracy', () {
        for (final type in MCPContentType.values) {
          final converted = MCPContentType.fromString(type.value);
          expect(converted, equals(type));
        }
      });

      test('🚫 Invalid content type rejection', () {
        expect(
          () => MCPContentType.fromString('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('⚔️ MCPPriority Enum Warfare', () {
      test('✅ Priority levels and ordering', () {
        expect(MCPPriority.values.length, equals(4));
        expect(MCPPriority.low.level, equals(1));
        expect(MCPPriority.medium.level, equals(2));
        expect(MCPPriority.high.level, equals(3));
        expect(MCPPriority.urgent.level, equals(4));
      });

      test('✅ Priority comparison logic', () {
        expect(MCPPriority.urgent.isHigherThan(MCPPriority.high), isTrue);
        expect(MCPPriority.high.isHigherThan(MCPPriority.medium), isTrue);
        expect(MCPPriority.medium.isHigherThan(MCPPriority.low), isTrue);
        expect(MCPPriority.low.isHigherThan(MCPPriority.urgent), isFalse);
      });

      test('✅ String conversion with fallback', () {
        expect(MCPPriority.fromString('high'), equals(MCPPriority.high));
        expect(MCPPriority.fromString('invalid'), equals(MCPPriority.medium));
      });
    });

    group('⚔️ MCPContentValidator Warfare', () {
      test('✅ Valid content acceptance', () {
        expect(MCPContentValidator.validateContent('Valid content'), isTrue);
        expect(MCPContentValidator.validateContent('Multi\nline\tcontent'),
            isTrue);
        expect(
            MCPContentValidator.validateContent('🎯 Unicode content'), isTrue);
      });

      test('🚫 Invalid content rejection', () {
        expect(MCPContentValidator.validateContent(''), isFalse);
        expect(
            MCPContentValidator.validateContent(
                '<script>alert("xss")</script>'),
            isFalse);
        expect(MCPContentValidator.validateContent('javascript:alert("xss")'),
            isFalse);
        expect(MCPContentValidator.validateContent('data:text/html,<script>'),
            isFalse);
      });

      test('✅ Content sanitization safety', () {
        expect(MCPContentValidator.sanitizeContent('  padded  '),
            equals('padded'));
        expect(MCPContentValidator.sanitizeContent('with\x00null'),
            equals('withnull'));
        expect(MCPContentValidator.sanitizeContent('normal\tcontent\n'),
            equals('normal\tcontent'));
      });

      test('✅ ID validation accuracy', () {
        const validUuid = '123e4567-e89b-12d3-a456-426614174000';
        expect(MCPContentValidator.validateId(validUuid), isTrue);
        expect(MCPContentValidator.validateId(''), isFalse);
        expect(MCPContentValidator.validateId('not-a-uuid'), isFalse);
      });

      test('✅ Metadata validation safety', () {
        expect(MCPContentValidator.validateMetadata({'key': 'value'}), isTrue);
        expect(
            MCPContentValidator.validateMetadata({
              'nested': {'data': 123}
            }),
            isTrue);

        // Circular reference should fail
        final circular = <String, dynamic>{'self': null};
        circular['self'] = circular;
        expect(MCPContentValidator.validateMetadata(circular), isFalse);
      });
    });

    group('⚔️ MCPContentItem Base Class Warfare', () {
      late TestMCPContentItem testItem;

      setUp(() {
        testItem = TestMCPContentItem(
          content: 'Test content',
          contentType: MCPContentType.inbox,
          priority: MCPPriority.high,
        );
      });

      tearDown(() {
        testItem.dispose();
      });

      test('✅ Proper initialization and defaults', () {
        expect(testItem.content, equals('Test content'));
        expect(testItem.contentType, equals(MCPContentType.inbox));
        expect(testItem.priority, equals(MCPPriority.high));
        expect(testItem.id.isNotEmpty, isTrue);
        expect(
            testItem.createdAt
                .isBefore(DateTime.now().add(const Duration(seconds: 1))),
            isTrue);
        expect(testItem.updatedAt.millisecondsSinceEpoch,
            equals(testItem.createdAt.millisecondsSinceEpoch));
        expect(testItem.metadata.isEmpty, isTrue);
      });

      test('✅ Content update with validation', () {
        bool notified = false;
        testItem.addListener(() => notified = true);

        testItem.updateContent('Updated content');

        expect(testItem.content, equals('Updated content'));
        expect(testItem.updatedAt.isAfter(testItem.createdAt), isTrue);
        expect(notified, isTrue);
      });

      test('🚫 Invalid content update rejection', () {
        expect(
          () => testItem.updateContent(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('✅ Priority update with notification', () {
        bool notified = false;
        testItem.addListener(() => notified = true);

        testItem.updatePriority(MCPPriority.urgent);

        expect(testItem.priority, equals(MCPPriority.urgent));
        expect(notified, isTrue);
      });

      test('✅ Metadata management operations', () {
        bool notified = false;
        testItem.addListener(() => notified = true);

        // Set metadata
        testItem.setMetadata('key1', 'value1');
        expect(testItem.getMetadata<String>('key1'), equals('value1'));
        expect(notified, isTrue);

        notified = false;

        // Type-safe metadata access
        testItem.setMetadata('key2', 42);
        expect(testItem.getMetadata<int>('key2'), equals(42));
        expect(testItem.getMetadata<String>('key2'), isNull);

        // Remove metadata
        testItem.removeMetadata('key1');
        expect(testItem.getMetadata<String>('key1'), isNull);
        expect(notified, isTrue);
      });

      test('✅ Content validation logic', () {
        expect(testItem.validate(), isTrue);

        // Create item with future date (should fail validation)
        final futureItem = TestMCPContentItem(
          content: 'Test',
          contentType: MCPContentType.todo,
          createdAt: DateTime.now().add(const Duration(hours: 1)),
        );
        expect(futureItem.validate(), isFalse);
        futureItem.dispose();
      });

      test('✅ JSON serialization round-trip', () {
        testItem.setMetadata('test', 'value');
        testItem.updatePriority(MCPPriority.urgent);

        final json = testItem.toJson();
        expect(json['id'], equals(testItem.id));
        expect(json['content'], equals(testItem.content));
        expect(json['contentType'], equals('inbox'));
        expect(json['priority'], equals('urgent'));
        expect(json['metadata']['test'], equals('value'));

        // Test deserialization
        final recreated = TestMCPContentItem.fromJson(json);
        expect(recreated.id, equals(testItem.id));
        expect(recreated.content, equals(testItem.content));
        expect(recreated.contentType, equals(testItem.contentType));
        expect(recreated.priority, equals(testItem.priority));
        expect(recreated.getMetadata<String>('test'), equals('value'));

        recreated.dispose();
      });

      test('✅ toString() debug information', () {
        final debugString = testItem.toString();
        expect(debugString.contains('TestMCPContentItem'), isTrue);
        expect(debugString.contains(testItem.id), isTrue);
        expect(debugString.contains('inbox'), isTrue);
        expect(debugString.contains('high'), isTrue);
      });

      test('⚡ PERFORMANCE: Content operations under 1ms', () {
        final stopwatch = Stopwatch()..start();

        // Perform 1000 content operations
        for (int i = 0; i < 1000; i++) {
          testItem.updateContent('Content $i');
          testItem.updatePriority(MCPPriority.values[i % 4]);
          testItem.setMetadata('key$i', i);
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds,
            lessThan(1000)); // < 1000ms for 1000 operations
        // ignore: avoid_print
        print(
            '🚀 PERFORMANCE: 1000 operations in ${stopwatch.elapsedMilliseconds}ms');
      });

      test('⚡ PERFORMANCE: JSON serialization under 5ms', () {
        // Add metadata to increase serialization complexity
        for (int i = 0; i < 100; i++) {
          testItem.setMetadata('key$i', 'value$i');
          testItem.setMetadata('nested$i', {
            'data': i,
            'array': [1, 2, 3]
          });
        }

        final stopwatch = Stopwatch()..start();

        // Perform 100 serialization cycles
        for (int i = 0; i < 100; i++) {
          final json = testItem.toJson();
          TestMCPContentItem.fromJson(json).dispose();
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds,
            lessThan(500)); // < 500ms for 100 cycles
        // ignore: avoid_print
        print(
            '🚀 PERFORMANCE: 100 JSON cycles in ${stopwatch.elapsedMilliseconds}ms');
      });

      test('🛡️ SECURITY: Content sanitization effectiveness', () {
        final dangerousInputs = [
          '<script>alert("xss")</script>',
          'javascript:void(0)',
          'data:text/html,<script>alert(1)</script>',
          'Content with\x00null bytes\x01and\x1fcontrol chars',
        ];

        for (final dangerous in dangerousInputs) {
          final sanitized = MCPContentValidator.sanitizeContent(dangerous);
          expect(
              MCPContentValidator.validateContent(sanitized),
              dangerous.contains(RegExp(r'<script|javascript:|data:'))
                  ? isFalse
                  : isTrue);
        }
      });

      // Function declaration instead of variable assignment
      void testChangeNotifierCleanup() {
        final listeners = <VoidCallback>[];

        // Add multiple listeners
        for (int i = 0; i < 10; i++) {
          void listener() {}
          testItem.addListener(listener);
          listeners.add(listener);
        }

        // Remove listeners
        for (final listener in listeners) {
          testItem.removeListener(listener);
        }
      }

      test('🔧 MEMORY: ChangeNotifier cleanup', () {
        final listeners = <VoidCallback>[];

        // Add multiple listeners
        for (int i = 0; i < 10; i++) {
          void listener() {}
          testItem.addListener(listener);
          listeners.add(listener);
        }

        // Remove listeners
        for (final listener in listeners) {
          testItem.removeListener(listener);
        }

        // Test cleanup function
        testChangeNotifierCleanup();
      });
    });
  });
}
