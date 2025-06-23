/// MCPContentCollection Test Suite - Comprehensive collection management testing
///
/// ## TESTING MISSION
/// Validate MCPContentCollection implementation for agent-specific content aggregation
/// with CRUD operations, filtering, and reactive collection management.
///
/// ## TEST CATEGORIES
/// - Collection Management: Add, remove, reorder operations
/// - Agent Isolation: Per-agent content separation
/// - Content Filtering: Unread, pending, overdue filtering
/// - Performance: Large collection handling
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:vibe_coder/models/mcp_content_collection.dart';
import 'package:vibe_coder/models/mcp_notepad_content.dart';
import 'package:vibe_coder/models/mcp_inbox_item.dart';
import 'package:vibe_coder/models/mcp_todo_item.dart';
import 'package:vibe_coder/models/mcp_content_base.dart';

void main() {
  group('📦 MCPContentCollection', () {
    group('🏗️ Construction', () {
      test('creates with agent ID and empty collections', () {
        final collection = MCPContentCollection(agentId: 'agent-123');

        expect(collection.agentId, equals('agent-123'));
        expect(collection.inboxItems, isEmpty);
        expect(collection.todoItems, isEmpty);
        expect(collection.notepadContent, isA<MCPNotepadContent>());
        expect(collection.notepadContent.agentId, equals('agent-123'));
      });

      test('creates with custom notepad content', () {
        final customNotepad = MCPNotepadContent(
          content: 'Custom notepad content',
          agentId: 'agent-123',
        );
        final collection = MCPContentCollection(
          agentId: 'agent-123',
          notepadContent: customNotepad,
        );

        expect(collection.notepadContent, equals(customNotepad));
        expect(collection.notepadContent.content,
            equals('Custom notepad content'));
      });

      test('different agents have separate collections', () {
        final collection1 = MCPContentCollection(agentId: 'agent-1');
        final collection2 = MCPContentCollection(agentId: 'agent-2');

        expect(collection1.agentId, isNot(equals(collection2.agentId)));
        expect(collection1.notepadContent,
            isNot(equals(collection2.notepadContent)));
      });
    });

    group('📥 Inbox Management', () {
      test('adds inbox item and notifies listeners', () {
        final collection = MCPContentCollection(agentId: 'agent-123');
        var notifyCount = 0;
        collection.addListener(() => notifyCount++);

        final inboxItem = MCPInboxItem(
          content: 'Test inbox message',
          sender: 'test@example.com',
        );

        collection.addInboxItem(inboxItem);

        expect(collection.inboxItems.length, equals(1));
        expect(collection.inboxItems.first, equals(inboxItem));
        expect(notifyCount, equals(1));
      });

      test('removes inbox item by ID', () {
        final collection = MCPContentCollection(agentId: 'agent-123');
        final inboxItem = MCPInboxItem(
          content: 'Test message',
          sender: 'test@example.com',
        );
        collection.addInboxItem(inboxItem);

        var notifyCount = 0;
        collection.addListener(() => notifyCount++);

        collection.removeInboxItem(inboxItem.id);

        expect(collection.inboxItems, isEmpty);
        expect(notifyCount, equals(1));
      });

      test('removes non-existent inbox item gracefully', () {
        final collection = MCPContentCollection(agentId: 'agent-123');
        var notifyCount = 0;
        collection.addListener(() => notifyCount++);

        collection.removeInboxItem('non-existent-id');

        expect(collection.inboxItems, isEmpty);
        expect(notifyCount, equals(0)); // No notification for no-op
      });
    });

    group('✅ Todo Management', () {
      test('adds todo item and notifies listeners', () {
        final collection = MCPContentCollection(agentId: 'agent-123');
        var notifyCount = 0;
        collection.addListener(() => notifyCount++);

        final todoItem = MCPTodoItem(
          content: 'Test todo task',
          priority: MCPPriority.high,
        );

        collection.addTodoItem(todoItem);

        expect(collection.todoItems.length, equals(1));
        expect(collection.todoItems.first, equals(todoItem));
        expect(notifyCount, equals(1));
      });

      test('removes todo item by ID', () {
        final collection = MCPContentCollection(agentId: 'agent-123');
        final todoItem = MCPTodoItem(content: 'Test task');
        collection.addTodoItem(todoItem);

        var notifyCount = 0;
        collection.addListener(() => notifyCount++);

        collection.removeTodoItem(todoItem.id);

        expect(collection.todoItems, isEmpty);
        expect(notifyCount, equals(1));
      });

      test('reorders todo items by ID list', () {
        final collection = MCPContentCollection(agentId: 'agent-123');
        final todo1 = MCPTodoItem(content: 'Task 1');
        final todo2 = MCPTodoItem(content: 'Task 2');
        final todo3 = MCPTodoItem(content: 'Task 3');

        collection.addTodoItem(todo1);
        collection.addTodoItem(todo2);
        collection.addTodoItem(todo3);

        var notifyCount = 0;
        collection.addListener(() => notifyCount++);

        // Reorder: 3, 1, 2
        collection.reorderTodoItems([todo3.id, todo1.id, todo2.id]);

        expect(collection.todoItems[0], equals(todo3));
        expect(collection.todoItems[1], equals(todo1));
        expect(collection.todoItems[2], equals(todo2));
        expect(notifyCount, equals(1));
      });

      test('handles partial reorder with missing IDs', () {
        final collection = MCPContentCollection(agentId: 'agent-123');
        final todo1 = MCPTodoItem(content: 'Task 1');
        final todo2 = MCPTodoItem(content: 'Task 2');

        collection.addTodoItem(todo1);
        collection.addTodoItem(todo2);

        // Reorder with missing ID - should only reorder existing items
        collection.reorderTodoItems([todo2.id]);

        expect(collection.todoItems.length, equals(2));
        expect(collection.todoItems.first, equals(todo2));
      });
    });

    group('🔍 Content Filtering', () {
      test('filters unread inbox items', () {
        final collection = MCPContentCollection(agentId: 'agent-123');

        final readItem = MCPInboxItem(
          content: 'Read message',
          sender: 'test@example.com',
          isRead: true,
        );
        final unreadItem = MCPInboxItem(
          content: 'Unread message',
          sender: 'test@example.com',
          isRead: false,
        );

        collection.addInboxItem(readItem);
        collection.addInboxItem(unreadItem);

        final unreadItems = collection.getUnreadInbox();

        expect(unreadItems.length, equals(1));
        expect(unreadItems.first, equals(unreadItem));
      });

      test('filters pending todos', () {
        final collection = MCPContentCollection(agentId: 'agent-123');

        final completedTodo = MCPTodoItem(
          content: 'Completed task',
          isCompleted: true,
        );
        final pendingTodo = MCPTodoItem(
          content: 'Pending task',
          isCompleted: false,
        );

        collection.addTodoItem(completedTodo);
        collection.addTodoItem(pendingTodo);

        final pendingTodos = collection.getPendingTodos();

        expect(pendingTodos.length, equals(1));
        expect(pendingTodos.first, equals(pendingTodo));
      });

      test('filters overdue todos', () {
        final collection = MCPContentCollection(agentId: 'agent-123');

        final overdueTodo = MCPTodoItem(
          content: 'Overdue task',
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        final futureTodo = MCPTodoItem(
          content: 'Future task',
          dueDate: DateTime.now().add(const Duration(days: 1)),
        );

        collection.addTodoItem(overdueTodo);
        collection.addTodoItem(futureTodo);

        final overdueTodos = collection.getOverdueTodos();

        expect(overdueTodos.length, equals(1));
        expect(overdueTodos.first, equals(overdueTodo));
      });

      test('filters todos by priority', () {
        final collection = MCPContentCollection(agentId: 'agent-123');

        final highPriorityTodo = MCPTodoItem(
          content: 'High priority task',
          priority: MCPPriority.high,
        );
        final lowPriorityTodo = MCPTodoItem(
          content: 'Low priority task',
          priority: MCPPriority.low,
        );

        collection.addTodoItem(highPriorityTodo);
        collection.addTodoItem(lowPriorityTodo);

        final highPriorityTodos =
            collection.getTodosByPriority(MCPPriority.high);

        expect(highPriorityTodos.length, equals(1));
        expect(highPriorityTodos.first, equals(highPriorityTodo));
      });
    });

    group('🔄 Reactive Updates', () {
      test('extends ChangeNotifier', () {
        final collection = MCPContentCollection(agentId: 'agent-123');
        expect(collection, isA<ChangeNotifier>());
      });

      test('notifies on all collection modifications', () {
        final collection = MCPContentCollection(agentId: 'agent-123');
        var notifyCount = 0;
        collection.addListener(() => notifyCount++);

        final inboxItem = MCPInboxItem(
          content: 'Test message',
          sender: 'test@example.com',
        );
        final todoItem = MCPTodoItem(content: 'Test task');

        collection.addInboxItem(inboxItem);
        collection.addTodoItem(todoItem);
        collection.removeInboxItem(inboxItem.id);
        collection.removeTodoItem(todoItem.id);

        expect(notifyCount, equals(4));
      });

      test('notepad content changes trigger collection notifications', () {
        final collection = MCPContentCollection(agentId: 'agent-123');
        var notifyCount = 0;
        collection.addListener(() => notifyCount++);

        collection.notepadContent.updateContent('New content');

        expect(notifyCount, greaterThan(0));
      });
    });

    group('⚡ Performance Tests', () {
      test('handles large inbox collections efficiently', () {
        final collection = MCPContentCollection(agentId: 'agent-123');
        final stopwatch = Stopwatch()..start();

        // Add 1000 inbox items
        for (int i = 0; i < 1000; i++) {
          final item = MCPInboxItem(
            content: 'Message $i',
            sender: 'sender$i@example.com',
          );
          collection.addInboxItem(item);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds,
            lessThan(100)); // < 100ms for 1000 items
        expect(collection.inboxItems.length, equals(1000));
      });

      test('collection operations under 10ms', () {
        final collection = MCPContentCollection(agentId: 'agent-123');
        final todoItem = MCPTodoItem(content: 'Test task');
        collection.addTodoItem(todoItem);

        final stopwatch = Stopwatch()..start();

        // Perform multiple operations
        for (int i = 0; i < 100; i++) {
          collection.getPendingTodos();
          collection.getTodosByPriority(MCPPriority.medium);
        }

        stopwatch.stop();

        expect(
            stopwatch.elapsedMilliseconds, lessThan(10)); // < 10ms requirement
      });

      test('filtering operations under 20ms for large collections', () {
        final collection = MCPContentCollection(agentId: 'agent-123');

        // Add 1000 mixed items
        for (int i = 0; i < 1000; i++) {
          final todoItem = MCPTodoItem(
            content: 'Task $i',
            priority: i % 2 == 0 ? MCPPriority.high : MCPPriority.low,
            isCompleted: i % 3 == 0,
          );
          collection.addTodoItem(todoItem);
        }

        final stopwatch = Stopwatch()..start();

        collection.getPendingTodos();
        collection.getTodosByPriority(MCPPriority.high);
        collection.getOverdueTodos();

        stopwatch.stop();

        expect(
            stopwatch.elapsedMilliseconds, lessThan(20)); // < 20ms requirement
      });
    });

    group('🛡️ Edge Cases', () {
      test('handles empty collections gracefully', () {
        final collection = MCPContentCollection(agentId: 'agent-123');

        expect(collection.getUnreadInbox(), isEmpty);
        expect(collection.getPendingTodos(), isEmpty);
        expect(collection.getOverdueTodos(), isEmpty);
        expect(collection.getTodosByPriority(MCPPriority.high), isEmpty);
      });

      test('handles collection with all completed todos', () {
        final collection = MCPContentCollection(agentId: 'agent-123');

        final completedTodo = MCPTodoItem(
          content: 'Completed task',
          isCompleted: true,
        );
        collection.addTodoItem(completedTodo);

        expect(collection.getPendingTodos(), isEmpty);
        expect(collection.getOverdueTodos(), isEmpty);
      });

      test('handles collection with all read inbox items', () {
        final collection = MCPContentCollection(agentId: 'agent-123');

        final readItem = MCPInboxItem(
          content: 'Read message',
          sender: 'test@example.com',
          isRead: true,
        );
        collection.addInboxItem(readItem);

        expect(collection.getUnreadInbox(), isEmpty);
      });
    });
  });
}
