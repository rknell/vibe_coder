/// MCP Content Infrastructure - Foundational classes for unified content management
///
/// ## MISSION ACCOMPLISHED
/// Eliminates content type fragmentation by providing unified base classes
/// for all MCP content types (inbox, todo, notepad) with reactive updates.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Abstract Base Class | Polymorphism + Inheritance | Complexity | Type safety + Code reuse |
/// | Enum Classification | Clear categorization | Limited extensibility | Discord-style categorization |
/// | ChangeNotifier Base | Reactive UI updates | Memory overhead | Real-time content sync |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) for content operations
/// - Space Complexity: O(1) base overhead per content item
/// - Rebuild Frequency: Only on content mutations
library mcp_content_base;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Content type classification for MCP content items
/// Enables Discord-style content categorization and routing
enum MCPContentType {
  /// Inbox items - incoming messages, notifications, tasks
  inbox('inbox'),

  /// Todo items - actionable tasks with completion status
  todo('todo'),

  /// Notepad items - free-form notes and documentation
  notepad('notepad');

  const MCPContentType(this.value);
  final String value;

  /// Convert from string value to enum
  static MCPContentType fromString(String value) {
    return MCPContentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid MCPContentType: $value'),
    );
  }
}

/// Priority levels for MCP content items
/// Enables task prioritization and visual urgency indicators
enum MCPPriority {
  /// Low priority - can be deferred
  low('low', 1),

  /// Medium priority - normal processing
  medium('medium', 2),

  /// High priority - elevated attention
  high('high', 3),

  /// Urgent priority - immediate action required
  urgent('urgent', 4);

  const MCPPriority(this.value, this.level);
  final String value;
  final int level;

  /// Convert from string value to enum
  static MCPPriority fromString(String value) {
    return MCPPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => MCPPriority.medium,
    );
  }

  /// Compare priorities for sorting
  bool isHigherThan(MCPPriority other) => level > other.level;
}

/// Abstract base class for all MCP content items
/// Provides common functionality and reactive update patterns
abstract class MCPContentItem extends ChangeNotifier {
  /// Unique identifier for the content item
  final String id;

  /// The actual content text/data
  String _content;

  /// Content type classification
  final MCPContentType contentType;

  /// Priority level for the content
  MCPPriority _priority;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last modification timestamp
  DateTime _updatedAt;

  /// Flexible metadata storage for content-specific data
  final Map<String, dynamic> _metadata;

  MCPContentItem({
    String? id,
    required String content,
    required this.contentType,
    MCPPriority priority = MCPPriority.medium,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  })  : id = id ?? const Uuid().v4(),
        _content = content,
        _priority = priority,
        createdAt = createdAt ?? DateTime.now(),
        _updatedAt = updatedAt ?? DateTime.now(),
        _metadata = Map<String, dynamic>.from(metadata ?? {});

  /// Get the content value
  String get content => _content;

  /// Get the priority value
  MCPPriority get priority => _priority;

  /// Get the last updated timestamp
  DateTime get updatedAt => _updatedAt;

  /// Get read-only metadata
  Map<String, dynamic> get metadata => Map<String, dynamic>.from(_metadata);

  /// Update content with validation and timestamp tracking
  void updateContent(String newContent) {
    final sanitized = sanitizeContent(newContent);
    if (!MCPContentValidator.validateContent(sanitized)) {
      throw ArgumentError('Invalid content provided');
    }

    _content = sanitized;
    _updateTimestamp();
    notifyListeners(); // MANDATORY: Reactive UI updates
  }

  /// Update priority level
  void updatePriority(MCPPriority newPriority) {
    _priority = newPriority;
    _updateTimestamp();
    notifyListeners(); // MANDATORY: Reactive UI updates
  }

  /// Set metadata value
  void setMetadata(String key, dynamic value) {
    _metadata[key] = value;
    _updateTimestamp();
    notifyListeners(); // MANDATORY: Reactive UI updates
  }

  /// Get metadata value with type safety
  T? getMetadata<T>(String key) {
    final value = _metadata[key];
    return value is T ? value : null;
  }

  /// Remove metadata key
  void removeMetadata(String key) {
    _metadata.remove(key);
    _updateTimestamp();
    notifyListeners(); // MANDATORY: Reactive UI updates
  }

  /// Update the modification timestamp
  void _updateTimestamp() {
    _updatedAt = DateTime.now();
  }

  /// Validate content item
  bool validate() {
    return MCPContentValidator.validateId(id) &&
        MCPContentValidator.validateContent(_content) &&
        createdAt.isBefore(DateTime.now().add(const Duration(seconds: 1))) &&
        _updatedAt.isAfter(createdAt.subtract(const Duration(seconds: 1)));
  }

  /// Sanitize content for security and consistency
  String sanitizeContent(String content) {
    return MCPContentValidator.sanitizeContent(content);
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': _content,
      'contentType': contentType.value,
      'priority': _priority.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': _updatedAt.toIso8601String(),
      'metadata': _metadata,
    };
  }

  /// Create from JSON data
  static MCPContentType parseContentType(Map<String, dynamic> json) {
    return MCPContentType.fromString(json['contentType'] as String);
  }

  /// Parse common fields from JSON (for subclass constructors)
  static Map<String, dynamic> parseBaseFields(Map<String, dynamic> json) {
    return {
      'id': json['id'] as String,
      'content': json['content'] as String,
      'priority': MCPPriority.fromString(json['priority'] as String),
      'createdAt': DateTime.parse(json['createdAt'] as String),
      'updatedAt': DateTime.parse(json['updatedAt'] as String),
      'metadata': Map<String, dynamic>.from(
          json['metadata'] as Map<String, dynamic>? ?? {}),
    };
  }

  @override
  String toString() {
    return '$runtimeType(id: $id, type: ${contentType.value}, priority: ${_priority.value}, content: "${_content.length > 50 ? "${_content.substring(0, 50)}..." : _content}")';
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}

/// Content validation and sanitization utilities
class MCPContentValidator {
  static const int _maxContentLength = 10000; // 10KB content limit
  static const int _maxIdLength = 100;

  /// Validate content string
  static bool validateContent(String content) {
    if (content.isEmpty) return false;
    if (content.length > _maxContentLength) return false;

    // Check for dangerous content patterns
    if (content.contains(
        RegExp(r'<script|javascript:|data:|vbscript:', caseSensitive: false))) {
      return false;
    }

    return true;
  }

  /// Sanitize content for security
  static String sanitizeContent(String content) {
    // Trim whitespace
    String sanitized = content.trim();

    // Remove null bytes and control characters (except newlines and tabs)
    sanitized =
        sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    // Limit content length
    if (sanitized.length > _maxContentLength) {
      sanitized = sanitized.substring(0, _maxContentLength);
    }

    return sanitized;
  }

  /// Validate ID format
  static bool validateId(String id) {
    if (id.isEmpty || id.length > _maxIdLength) return false;

    // UUID format validation (loose check)
    final uuidPattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidPattern.hasMatch(id);
  }

  /// Validate metadata structure
  static bool validateMetadata(Map<String, dynamic> metadata) {
    try {
      // Test JSON serialization
      jsonEncode(metadata);
      return true;
    } catch (e) {
      return false;
    }
  }
}
