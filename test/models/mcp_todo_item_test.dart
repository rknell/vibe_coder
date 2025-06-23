/// MCPTodoItem Test Suite - Comprehensive coverage for todo content management
///
/// ## MISSION ACCOMPLISHED
/// Validates todo item functionality including completion status, due dates,
/// tag management, and priority handling for Discord-style task management.
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **State Transition Validation**: Ensures proper complete/incomplete state management
/// 2. **Due Date Management**: Tests due date validation and overdue detection
/// 3. **Tag Management**: Validates tag addition, removal, and duplicate handling
/// 4. **Priority Operations**: Tests priority setting and reactive updates
library mcp_todo_item_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_coder/models/mcp_content_base.dart';
import 'package:vibe_coder/models/mcp_todo_item.dart';

void main() {
  group('🛡️ REGRESSION: MCPTodoItem Core Functionality', () {
    test('🚀 FEATURE: Basic todo item creation', () {
      final todo = MCPTodoItem(
        content: 'Complete project documentation',
        priority: MCPPriority.high,
        dueDate: DateTime.now().add(const Duration(days: 7)),
        tags: ['work', 'documentation'],
      );

      expect(todo.content, equals('Complete project documentation'));
      expect(todo.priority, equals(MCPPriority.high));
      expect(todo.contentType, equals(MCPContentType.todo));
      expect(todo.isCompleted, isFalse); // Default incomplete
      expect(todo.dueDate, isNotNull);
      expect(todo.tags, containsAll(['work', 'documentation']));
      expect(todo.completedAt, isNull);
      expect(todo.id, isNotEmpty);
    });

    test('🛡️ REGRESSION: Completion status state transitions', () {
      final todo = MCPTodoItem(
        content: 'Test task',
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );

      // Verify initial state
      expect(todo.isCompleted, isFalse);
      expect(todo.completedAt, isNull);

      // Test mark as completed
      final beforeCompletion = DateTime.now();
      todo.markAsCompleted();
      expect(todo.isCompleted, isTrue);
      expect(todo.completedAt, isNotNull);
      expect(todo.completedAt!.isAfter(beforeCompletion), isTrue);

      // Test mark as incomplete
      todo.markAsIncomplete();
      expect(todo.isCompleted, isFalse);
      expect(todo.completedAt, isNull);
    });

    test('⚡ PERFORMANCE: ChangeNotifier integration', () {
      final todo = MCPTodoItem(content: 'Test task');
      bool notificationReceived = false;

      todo.addListener(() {
        notificationReceived = true;
      });

      // Test completion status change notification
      todo.markAsCompleted();
      expect(notificationReceived, isTrue);

      // Reset and test tag addition notification
      notificationReceived = false;
      todo.addTag('urgent');
      expect(notificationReceived, isTrue);
    });

    test('🎯 EDGE_CASE: Due date management', () {
      final todo = MCPTodoItem(
        content: 'Task with due date',
        dueDate: DateTime.now().add(const Duration(days: 3)),
      );

      expect(todo.dueDate, isNotNull);
      expect(todo.isOverdue(), isFalse);

      // Set past due date
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      todo.setDueDate(pastDate);
      expect(todo.isOverdue(), isTrue);

      // Test time until due
      final futureDate = DateTime.now().add(const Duration(hours: 24));
      todo.setDueDate(futureDate);
      final timeUntilDue = todo.timeUntilDue();
      expect(timeUntilDue, isNotNull);
      expect(timeUntilDue!.inHours, greaterThan(20));
    });

    test('🔧 INTEGRATION: Tag management', () {
      final todo = MCPTodoItem(
        content: 'Task with tags',
        tags: ['initial', 'tag'],
      );

      expect(todo.tags, containsAll(['initial', 'tag']));

      // Add new tag
      todo.addTag('urgent');
      expect(todo.tags, contains('urgent'));

      // Prevent duplicate tags
      todo.addTag('urgent');
      expect(todo.tags.where((tag) => tag == 'urgent').length, equals(1));

      // Remove tag
      todo.removeTag('initial');
      expect(todo.tags, isNot(contains('initial')));
      expect(todo.tags, contains('tag'));
    });

    test('🎯 EDGE_CASE: Preview generation with various content lengths', () {
      // Short content (< 5 lines)
      final shortTodo = MCPTodoItem(content: 'Short task');
      expect(shortTodo.getPreview(), equals('Short task'));

      // Long content (> 5 lines)
      final longContent =
          List.generate(10, (i) => 'Task step ${i + 1}').join('\n');
      final longTodo = MCPTodoItem(content: longContent);
      final preview = longTodo.getPreview();
      final previewLines = preview.split('\n');
      expect(previewLines.length, equals(5));
      expect(previewLines.first, equals('Task step 1'));
      expect(previewLines.last, equals('Task step 5'));
    });

    test('🛡️ REGRESSION: JSON serialization round trip', () {
      final originalTodo = MCPTodoItem(
        content: 'Serialization test task',
        priority: MCPPriority.high,
        dueDate: DateTime(2024, 12, 25, 10, 30),
        tags: ['test', 'serialization'],
        isCompleted: true,
        completedAt: DateTime(2024, 12, 20, 15, 45),
      );

      // Convert to JSON
      final json = originalTodo.toJson();

      // Verify JSON structure
      expect(json['isCompleted'], isTrue);
      expect(json['dueDate'], isNotNull);
      expect(json['tags'], containsAll(['test', 'serialization']));
      expect(json['completedAt'], isNotNull);
      expect(json['contentType'], equals('todo'));

      // Convert back from JSON
      final restoredTodo = MCPTodoItem.fromJson(json);

      // Verify all fields restored correctly
      expect(restoredTodo.id, equals(originalTodo.id));
      expect(restoredTodo.content, equals(originalTodo.content));
      expect(restoredTodo.priority, equals(originalTodo.priority));
      expect(restoredTodo.isCompleted, equals(originalTodo.isCompleted));
      expect(restoredTodo.dueDate, equals(originalTodo.dueDate));
      expect(restoredTodo.tags, containsAll(originalTodo.tags));
      expect(restoredTodo.completedAt, equals(originalTodo.completedAt));
      expect(restoredTodo.contentType, equals(MCPContentType.todo));
    });

    test('🎯 EDGE_CASE: Null due date and completed date handling', () {
      final todo = MCPTodoItem(
        content: 'Task without due date',
        dueDate: null,
      );

      expect(todo.dueDate, isNull);
      expect(todo.isOverdue(), isFalse); // No due date = not overdue
      expect(todo.timeUntilDue(), isNull);

      // Test JSON round trip with nulls
      final json = todo.toJson();
      final restored = MCPTodoItem.fromJson(json);
      expect(restored.dueDate, isNull);
      expect(restored.completedAt, isNull);
    });

    test('⚡ PERFORMANCE: Tag operations performance', () {
      final todo = MCPTodoItem(content: 'Performance test task');

      final stopwatch = Stopwatch()..start();

      // Add multiple tags
      for (int i = 0; i < 100; i++) {
        todo.addTag('tag$i');
      }

      stopwatch.stop();

      // Performance requirement: < 10ms for collection operations
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
      expect(todo.tags.length, equals(100));
    });

    test('⚡ PERFORMANCE: State transition timing', () {
      final todo = MCPTodoItem(content: 'Performance test');

      final stopwatch = Stopwatch()..start();
      todo.markAsCompleted();
      stopwatch.stop();

      // Performance requirement: < 1ms for state changes
      expect(stopwatch.elapsedMilliseconds, lessThan(1));
    });

    test('🛡️ REGRESSION: Content validation inheritance', () {
      // Test validation from base class still works
      final todo = MCPTodoItem(content: 'Valid task content');
      expect(todo.validate(), isTrue);

      // Test content sanitization
      todo.updateContent('  Task with whitespace  ');
      expect(todo.content, equals('Task with whitespace'));
    });
  });

  group('🚀 FEATURE: MCPTodoItem Advanced Features', () {
    test('🎯 EDGE_CASE: Empty content handling', () {
      expect(
        () => MCPTodoItem(content: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('🔧 INTEGRATION: Priority management with due dates', () {
      final todo = MCPTodoItem(
        content: 'Priority test task',
        priority: MCPPriority.low,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );

      expect(todo.priority, equals(MCPPriority.low));

      // Test priority update with urgent due to overdue
      todo.setDueDate(DateTime.now().subtract(const Duration(days: 1)));
      expect(todo.isOverdue(), isTrue);

      // Priority should be updateable independently
      todo.updatePriority(MCPPriority.urgent);
      expect(todo.priority, equals(MCPPriority.urgent));
    });

    test('🎯 EDGE_CASE: Tag validation and normalization', () {
      final todo = MCPTodoItem(content: 'Tag validation test');

      // Test empty tag handling
      todo.addTag('');
      expect(todo.tags, isEmpty);

      // Test whitespace normalization
      todo.addTag('  spaced tag  ');
      expect(todo.tags, contains('spaced tag'));

      // Test case sensitivity
      todo.addTag('CaseTest');
      todo.addTag('casetest');
      expect(todo.tags, contains('CaseTest'));
      expect(todo.tags, contains('casetest'));
    });

    test('🔧 INTEGRATION: toString method', () {
      final todo = MCPTodoItem(
        content: 'Test task for toString',
        priority: MCPPriority.high,
        tags: ['test', 'debug'],
        isCompleted: true,
      );

      final stringRepresentation = todo.toString();
      expect(stringRepresentation, contains('MCPTodoItem'));
      expect(stringRepresentation, contains(todo.id));
      expect(stringRepresentation, contains('todo'));
      expect(stringRepresentation, contains('high'));
    });

    test('🎯 EDGE_CASE: Time zone handling for due dates', () {
      final utcDate = DateTime.utc(2024, 12, 25, 12, 0);
      final todo = MCPTodoItem(
        content: 'UTC date test',
        dueDate: utcDate,
      );

      expect(todo.dueDate!.isUtc, isTrue);

      // Test local time conversion in JSON
      final json = todo.toJson();
      final restored = MCPTodoItem.fromJson(json);
      expect(restored.dueDate, equals(utcDate));
    });
  });
}
