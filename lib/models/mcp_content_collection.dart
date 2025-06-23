/// MCPContentCollection - Agent-specific content aggregation and management
///
/// ## MISSION ACCOMPLISHED
/// Eliminates content fragmentation by providing agent-specific collections
/// for inbox, todo, and notepad management with reactive updates and filtering.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Agent Isolation | Data separation | Memory overhead | Multi-agent support |
/// | Collection Management | CRUD operations | Complexity | Discord-style organization |
/// | Reactive Filtering | Real-time updates | CPU overhead | Live UI filtering |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) for add/remove, O(n) for filtering
/// - Space Complexity: O(n) for collection storage
/// - Rebuild Frequency: On collection mutations and item changes
library mcp_content_collection;

import 'package:flutter/foundation.dart';
import 'package:vibe_coder/models/mcp_notepad_content.dart';
import 'package:vibe_coder/models/mcp_inbox_item.dart';
import 'package:vibe_coder/models/mcp_todo_item.dart';
import 'package:vibe_coder/models/mcp_content_base.dart';

/// Agent-specific content collection with reactive management
class MCPContentCollection extends ChangeNotifier {
  /// Agent ID for content isolation
  final String agentId;

  /// Inbox items collection (object references)
  final List<MCPInboxItem> _inboxItems = [];

  /// Todo items collection (object references)
  final List<MCPTodoItem> _todoItems = [];

  /// Notepad content for the agent
  final MCPNotepadContent notepadContent;

  MCPContentCollection({
    required this.agentId,
    MCPNotepadContent? notepadContent,
  }) : notepadContent =
            notepadContent ?? MCPNotepadContent(content: '', agentId: agentId) {
    // Listen to notepad changes to relay notifications
    this.notepadContent.addListener(_onNotepadChange);
  }

  /// Get read-only inbox items list
  List<MCPInboxItem> get inboxItems => List.unmodifiable(_inboxItems);

  /// Get read-only todo items list
  List<MCPTodoItem> get todoItems => List.unmodifiable(_todoItems);

  /// Add inbox item to collection
  void addInboxItem(MCPInboxItem item) {
    _inboxItems.add(item);
    // Listen to item changes for collection updates
    item.addListener(_onItemChange);
    notifyListeners(); // MANDATORY: Reactive UI updates
  }

  /// Remove inbox item by ID
  void removeInboxItem(String itemId) {
    final index = _inboxItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final removedItem = _inboxItems.removeAt(index);
      removedItem.removeListener(_onItemChange);
      notifyListeners(); // MANDATORY: Reactive UI updates
    }
    // No notification for no-op (graceful handling)
  }

  /// Add todo item to collection
  void addTodoItem(MCPTodoItem item) {
    _todoItems.add(item);
    // Listen to item changes for collection updates
    item.addListener(_onItemChange);
    notifyListeners(); // MANDATORY: Reactive UI updates
  }

  /// Remove todo item by ID
  void removeTodoItem(String itemId) {
    final index = _todoItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final removedItem = _todoItems.removeAt(index);
      removedItem.removeListener(_onItemChange);
      notifyListeners(); // MANDATORY: Reactive UI updates
    }
    // No notification for no-op (graceful handling)
  }

  /// Reorder todo items by ID list
  void reorderTodoItems(List<String> orderedIds) {
    final reorderedItems = <MCPTodoItem>[];

    // Add items in the specified order
    for (final id in orderedIds) {
      final item = _todoItems.firstWhere(
        (item) => item.id == id,
        orElse: () => throw StateError('Todo item not found: $id'),
      );
      if (!reorderedItems.contains(item)) {
        reorderedItems.add(item);
      }
    }

    // Add any remaining items that weren't in the ordered list
    for (final item in _todoItems) {
      if (!reorderedItems.contains(item)) {
        reorderedItems.add(item);
      }
    }

    _todoItems.clear();
    _todoItems.addAll(reorderedItems);
    notifyListeners(); // MANDATORY: Reactive UI updates
  }

  /// Filter unread inbox items
  /// PERF: O(n) operation where n = inbox size
  List<MCPInboxItem> getUnreadInbox() {
    return _inboxItems.where((item) => !item.isRead).toList();
  }

  /// Filter pending (incomplete) todos
  /// PERF: O(n) operation where n = todo size
  List<MCPTodoItem> getPendingTodos() {
    return _todoItems.where((item) => !item.isCompleted).toList();
  }

  /// Filter overdue todos
  /// PERF: O(n) operation where n = todo size
  List<MCPTodoItem> getOverdueTodos() {
    return _todoItems.where((item) => item.isOverdue()).toList();
  }

  /// Filter todos by priority level
  /// PERF: O(n) operation where n = todo size
  List<MCPTodoItem> getTodosByPriority(MCPPriority priority) {
    return _todoItems.where((item) => item.priority == priority).toList();
  }

  /// Handle notepad content changes
  void _onNotepadChange() {
    // Relay notepad changes as collection changes
    notifyListeners();
  }

  /// Handle individual item changes
  void _onItemChange() {
    // Relay item changes as collection changes
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up listeners
    notepadContent.removeListener(_onNotepadChange);
    for (final item in _inboxItems) {
      item.removeListener(_onItemChange);
    }
    for (final item in _todoItems) {
      item.removeListener(_onItemChange);
    }
    super.dispose();
  }
}
