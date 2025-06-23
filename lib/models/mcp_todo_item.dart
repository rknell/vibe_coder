/// MCPTodoItem - Specialized content model for task management
///
/// ## MISSION ACCOMPLISHED
/// Eliminates task management fragmentation by providing specialized functionality
/// for completion tracking, due date management, and tag organization.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Extends MCPContentItem | Inheritance + Polymorphism | Coupling | Code reuse + Type safety |
/// | Completion Tracking | Task state management | Complexity | Discord-style task UX |
/// | Tag System | Organization + Filtering | Memory overhead | Flexible categorization |
/// | Due Date Management | Time-based prioritization | Timezone complexity | Deadline tracking |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) for state operations, O(n) for tag operations
/// - Space Complexity: O(1) base overhead + content size + tag storage
/// - Rebuild Frequency: On completion, due date, or tag changes
library mcp_todo_item;

import 'package:vibe_coder/models/mcp_content_base.dart';

/// Specialized todo item for Discord-style task management
class MCPTodoItem extends MCPContentItem {
  /// Completion status tracking
  bool _isCompleted;

  /// Due date for deadline management
  DateTime? _dueDate;

  /// Completion timestamp
  DateTime? _completedAt;

  /// Task categorization tags
  // ignore: prefer_final_fields
  List<String> _tags;

  MCPTodoItem({
    super.id,
    required super.content,
    super.priority = MCPPriority.medium,
    super.createdAt,
    super.updatedAt,
    super.metadata,
    bool isCompleted = false,
    DateTime? dueDate,
    DateTime? completedAt,
    List<String>? tags,
  })  : _isCompleted = isCompleted,
        _dueDate = dueDate,
        _completedAt = completedAt,
        _tags = List<String>.from(tags ?? []),
        super(contentType: MCPContentType.todo) {
    // Validate content is not empty
    if (content.trim().isEmpty) {
      throw ArgumentError('Content cannot be empty');
    }
  }

  /// Get the completion status
  bool get isCompleted => _isCompleted;

  /// Get the due date
  DateTime? get dueDate => _dueDate;

  /// Get the completion timestamp
  DateTime? get completedAt => _completedAt;

  /// Get the tags list (read-only copy)
  List<String> get tags => List<String>.from(_tags);

  /// Mark task as completed with timestamp tracking
  void markAsCompleted() {
    if (!_isCompleted) {
      _isCompleted = true;
      _completedAt = DateTime.now();
      _updateTimestamp();
      notifyListeners(); // MANDATORY: Reactive UI updates
    }
  }

  /// Mark task as incomplete and clear completion timestamp
  void markAsIncomplete() {
    if (_isCompleted) {
      _isCompleted = false;
      _completedAt = null;
      _updateTimestamp();
      notifyListeners(); // MANDATORY: Reactive UI updates
    }
  }

  /// Set due date with validation
  void setDueDate(DateTime? date) {
    _dueDate = date;
    _updateTimestamp();
    notifyListeners(); // MANDATORY: Reactive UI updates
  }

  /// Add tag with duplicate prevention and validation
  void addTag(String tag) {
    final normalizedTag = tag.trim();
    if (normalizedTag.isEmpty) return;

    if (!_tags.contains(normalizedTag)) {
      _tags.add(normalizedTag);
      _updateTimestamp();
      notifyListeners(); // MANDATORY: Reactive UI updates
    }
  }

  /// Remove tag if it exists
  void removeTag(String tag) {
    if (_tags.remove(tag)) {
      _updateTimestamp();
      notifyListeners(); // MANDATORY: Reactive UI updates
    }
  }

  /// Check if task is overdue
  bool isOverdue() {
    if (_dueDate == null || _isCompleted) return false;
    return DateTime.now().isAfter(_dueDate!);
  }

  /// Calculate time remaining until due date
  Duration? timeUntilDue() {
    if (_dueDate == null) return null;
    final now = DateTime.now();
    return _dueDate!.isAfter(now) ? _dueDate!.difference(now) : null;
  }

  /// Generate preview for UI display with configurable line limit
  ///
  /// PERF: O(n) where n = min(maxLines, total lines)
  String getPreview({int maxLines = 5}) {
    final lines = content.split('\n');
    if (lines.length <= maxLines) {
      return content;
    }

    return lines.take(maxLines).join('\n');
  }

  /// Get preview lines as separate list for flexible UI rendering
  List<String> getPreviewLines({int maxLines = 5}) {
    final lines = content.split('\n');
    return lines.take(maxLines).toList();
  }

  /// Update the modification timestamp
  void _updateTimestamp() {
    // Use the base class protected method for timestamp updates
    setMetadata('_internal_timestamp_update', DateTime.now().toIso8601String());
    removeMetadata('_internal_timestamp_update');
  }

  /// Convert to JSON with todo-specific fields
  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({
      'isCompleted': _isCompleted,
      'dueDate': _dueDate?.toIso8601String(),
      'completedAt': _completedAt?.toIso8601String(),
      'tags': _tags,
    });
    return baseJson;
  }

  /// Create from JSON data with todo-specific field parsing
  static MCPTodoItem fromJson(Map<String, dynamic> json) {
    final baseFields = MCPContentItem.parseBaseFields(json);

    return MCPTodoItem(
      id: baseFields['id'] as String,
      content: baseFields['content'] as String,
      priority: baseFields['priority'] as MCPPriority,
      createdAt: baseFields['createdAt'] as DateTime,
      updatedAt: baseFields['updatedAt'] as DateTime,
      metadata: baseFields['metadata'] as Map<String, dynamic>,
      isCompleted: json['isCompleted'] as bool? ?? false,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((tag) => tag.toString())
              .toList() ??
          [],
    );
  }

  /// Enhanced validation including todo-specific checks
  @override
  bool validate() {
    return super.validate() &&
        (_dueDate == null || _dueDate!.isAfter(createdAt)) &&
        (_completedAt == null || _completedAt!.isAfter(createdAt));
  }

  @override
  String toString() {
    return 'MCPTodoItem(id: $id, type: ${contentType.value}, priority: ${priority.value}, '
        'completed: $_isCompleted, tags: $_tags, content: "${content.length > 50 ? "${content.substring(0, 50)}..." : content}")';
  }
}
