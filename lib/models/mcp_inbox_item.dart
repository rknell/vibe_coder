/// MCPInboxItem - Specialized content model for inbox messages
///
/// ## MISSION ACCOMPLISHED
/// Eliminates inbox message fragmentation by providing specialized functionality
/// for read status tracking, sender management, and preview generation.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Extends MCPContentItem | Inheritance + Polymorphism | Coupling | Code reuse + Type safety |
/// | Read Status Tracking | User state management | Complexity | Discord-style UX |
/// | Preview Generation | Performance + UX | Memory usage | Fast UI rendering |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) for state operations, O(n) for preview (n = lines)
/// - Space Complexity: O(1) base overhead + content size
/// - Rebuild Frequency: Only on read status or priority changes
library mcp_inbox_item;

import 'package:vibe_coder/models/mcp_content_base.dart';

/// Specialized inbox item for Discord-style message management
class MCPInboxItem extends MCPContentItem {
  /// Read status tracking for message processing
  bool _isRead;

  /// Message sender identification
  // ignore: prefer_final_fields
  String? _sender;

  /// When the message was received
  final DateTime dateReceived;

  MCPInboxItem({
    super.id,
    required super.content,
    super.priority = MCPPriority.medium,
    super.createdAt,
    super.updatedAt,
    super.metadata,
    bool isRead = false,
    String? sender,
    DateTime? dateReceived,
  })  : _isRead = isRead,
        _sender = sender,
        dateReceived = dateReceived ?? DateTime.now(),
        super(contentType: MCPContentType.inbox) {
    // Validate content is not empty
    if (content.trim().isEmpty) {
      throw ArgumentError('Content cannot be empty');
    }
  }

  /// Get the read status
  bool get isRead => _isRead;

  /// Get the sender information
  String? get sender => _sender;

  /// Mark message as read with reactive UI updates
  void markAsRead() {
    if (!_isRead) {
      _isRead = true;
      _updateTimestamp();
      notifyListeners(); // MANDATORY: Reactive UI updates
    }
  }

  /// Mark message as unread with reactive UI updates
  void markAsUnread() {
    if (_isRead) {
      _isRead = false;
      _updateTimestamp();
      notifyListeners(); // MANDATORY: Reactive UI updates
    }
  }

  /// Set priority with specialized inbox handling
  void setPriority(MCPPriority newPriority) {
    updatePriority(newPriority); // Delegates to base class with notifications
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

  /// Convert to JSON with inbox-specific fields
  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({
      'isRead': _isRead,
      'sender': _sender,
      'dateReceived': dateReceived.toIso8601String(),
    });
    return baseJson;
  }

  /// Create from JSON data with inbox-specific field parsing
  static MCPInboxItem fromJson(Map<String, dynamic> json) {
    final baseFields = MCPContentItem.parseBaseFields(json);

    return MCPInboxItem(
      id: baseFields['id'] as String,
      content: baseFields['content'] as String,
      priority: baseFields['priority'] as MCPPriority,
      createdAt: baseFields['createdAt'] as DateTime,
      updatedAt: baseFields['updatedAt'] as DateTime,
      metadata: baseFields['metadata'] as Map<String, dynamic>,
      isRead: json['isRead'] as bool? ?? false,
      sender: json['sender'] as String?,
      dateReceived: json['dateReceived'] != null
          ? DateTime.parse(json['dateReceived'] as String)
          : null,
    );
  }

  /// Enhanced validation including inbox-specific checks
  @override
  bool validate() {
    return super.validate() &&
        dateReceived.isBefore(DateTime.now().add(const Duration(seconds: 1)));
  }

  @override
  String toString() {
    return 'MCPInboxItem(id: $id, type: ${contentType.value}, priority: ${priority.value}, '
        'isRead: $_isRead, sender: $_sender, content: "${content.length > 50 ? "${content.substring(0, 50)}..." : content}")';
  }
}
