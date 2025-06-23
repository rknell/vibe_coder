/// MCPNotepadContent - Discord-style notepad content management
///
/// ## MISSION ACCOMPLISHED
/// Eliminates notepad fragmentation by providing full-text editing capabilities
/// with real-time statistics tracking and reactive UI updates.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | ChangeNotifier Extension | Reactive updates | Memory overhead | Real-time UI sync |
/// | Statistics Caching | Performance optimization | Memory usage | Sub-5ms requirements |
/// | Agent Isolation | Data separation | Complexity | Multi-agent support |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(n) for statistics, O(1) for content operations
/// - Space Complexity: O(1) base overhead + content size
/// - Rebuild Frequency: On content mutations only
library mcp_notepad_content;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Full-text notepad content with statistics and editing operations
class MCPNotepadContent extends ChangeNotifier {
  /// Unique identifier for the notepad
  final String id;

  /// Agent ID for content isolation
  final String agentId;

  /// The full content text
  String _content;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last modification timestamp
  DateTime _lastModified;

  /// Cached statistics for performance
  int? _cachedWordCount;
  int? _cachedLineCount;
  int? _cachedCharacterCount;

  MCPNotepadContent({
    String? id,
    required String content,
    required this.agentId,
    DateTime? createdAt,
    DateTime? lastModified,
  })  : id = id ?? const Uuid().v4(),
        _content = content,
        createdAt = createdAt ?? DateTime.now(),
        _lastModified = lastModified ?? DateTime.now();

  /// Get the current content
  String get content => _content;

  /// Get the last modified timestamp
  DateTime get lastModified => _lastModified;

  /// Get word count with caching for performance
  /// PERF: O(n) first call, O(1) subsequent calls until content changes
  int get wordCount {
    return _cachedWordCount ??= _calculateWordCount();
  }

  /// Get line count with caching for performance
  /// PERF: O(n) first call, O(1) subsequent calls until content changes
  int get lineCount {
    return _cachedLineCount ??= _calculateLineCount();
  }

  /// Get character count with caching for performance
  /// PERF: O(1) operation with caching
  int get characterCount {
    return _cachedCharacterCount ??= _content.length;
  }

  /// Update content with validation and cache invalidation
  void updateContent(String newContent) {
    _content = newContent;
    _invalidateCache();
    _updateTimestamp();
    notifyListeners(); // MANDATORY: Reactive UI updates
  }

  /// Append content to existing text
  void appendContent(String additionalContent) {
    _content += additionalContent;
    _invalidateCache();
    _updateTimestamp();
    notifyListeners(); // MANDATORY: Reactive UI updates
  }

  /// Prepend content to existing text
  void prependContent(String additionalContent) {
    _content = additionalContent + _content;
    _invalidateCache();
    _updateTimestamp();
    notifyListeners(); // MANDATORY: Reactive UI updates
  }

  /// Clear all content
  void clearContent() {
    _content = '';
    _invalidateCache();
    _updateTimestamp();
    notifyListeners(); // MANDATORY: Reactive UI updates
  }

  /// Get content as list of lines for flexible UI rendering
  List<String> getContentLines() {
    if (_content.isEmpty) return [''];
    return _content.split('\n');
  }

  /// Generate preview for UI display with configurable line limit
  /// PERF: O(min(n, maxLines)) where n = total lines
  String getContentPreview({int maxLines = 10}) {
    final lines = getContentLines();
    if (lines.length <= maxLines) {
      return _content;
    }

    return lines.take(maxLines).join('\n');
  }

  /// Calculate word count for statistics
  /// PERF: O(n) operation - cached for performance
  int _calculateWordCount() {
    if (_content.trim().isEmpty) return 0;

    // Split by whitespace and filter empty strings
    final words = _content
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    return words.length;
  }

  /// Calculate line count for statistics
  /// PERF: O(n) operation - cached for performance
  int _calculateLineCount() {
    if (_content.isEmpty) return 1;
    return _content.split('\n').length;
  }

  /// Invalidate cached statistics when content changes
  void _invalidateCache() {
    _cachedWordCount = null;
    _cachedLineCount = null;
    _cachedCharacterCount = null;
  }

  /// Update the modification timestamp
  void _updateTimestamp() {
    _lastModified = DateTime.now();
  }
}
