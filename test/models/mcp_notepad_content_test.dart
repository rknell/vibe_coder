/// MCPNotepadContent Test Suite - Comprehensive coverage following TDD warrior protocol
///
/// ## TESTING MISSION
/// Validate MCPNotepadContent implementation for Discord-style notepad management
/// with full-text editing, statistics tracking, and reactive updates.
///
/// ## TEST CATEGORIES
/// - Content Operations: Update, append, prepend, clear
/// - Statistics Tracking: Word, line, character counting
/// - Reactive Updates: ChangeNotifier compliance
/// - Performance: Large content handling
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:vibe_coder/models/mcp_notepad_content.dart';
import 'package:vibe_coder/models/mcp_content_base.dart';

void main() {
  group('📝 MCPNotepadContent', () {
    group('🏗️ Construction', () {
      test('creates with valid parameters', () {
        final notepad = MCPNotepadContent(
          content: 'Initial content',
          agentId: 'agent-123',
        );

        expect(notepad.content, equals('Initial content'));
        expect(notepad.agentId, equals('agent-123'));
        expect(notepad.id, isNotEmpty);
        expect(notepad.createdAt, isA<DateTime>());
        expect(notepad.lastModified, isA<DateTime>());
      });

      test('creates with empty content', () {
        final notepad = MCPNotepadContent(
          content: '',
          agentId: 'agent-123',
        );

        expect(notepad.content, equals(''));
        expect(notepad.wordCount, equals(0));
        expect(notepad.lineCount, equals(1)); // Empty content has 1 line
        expect(notepad.characterCount, equals(0));
      });

      test('generates unique IDs for multiple instances', () {
        final notepad1 = MCPNotepadContent(
          content: 'Content 1',
          agentId: 'agent-123',
        );
        final notepad2 = MCPNotepadContent(
          content: 'Content 2',
          agentId: 'agent-123',
        );

        expect(notepad1.id, isNot(equals(notepad2.id)));
      });
    });

    group('📊 Statistics Tracking', () {
      test('calculates word count correctly', () {
        final notepad = MCPNotepadContent(
          content: 'Hello world this is a test',
          agentId: 'agent-123',
        );

        expect(notepad.wordCount, equals(6));
      });

      test('calculates line count correctly', () {
        final notepad = MCPNotepadContent(
          content: 'Line 1\nLine 2\nLine 3',
          agentId: 'agent-123',
        );

        expect(notepad.lineCount, equals(3));
      });

      test('calculates character count correctly', () {
        final notepad = MCPNotepadContent(
          content: 'Hello',
          agentId: 'agent-123',
        );

        expect(notepad.characterCount, equals(5));
      });

      test('handles empty content statistics', () {
        final notepad = MCPNotepadContent(
          content: '',
          agentId: 'agent-123',
        );

        expect(notepad.wordCount, equals(0));
        expect(notepad.lineCount, equals(1));
        expect(notepad.characterCount, equals(0));
      });

      test('handles complex content with punctuation', () {
        final notepad = MCPNotepadContent(
          content: 'Hello, world! This is a test.\nSecond line here.',
          agentId: 'agent-123',
        );

        expect(notepad.wordCount, equals(9));
        expect(notepad.lineCount, equals(2));
        expect(notepad.characterCount, equals(47));
      });
    });

    group('✏️ Content Operations', () {
      test('updates content and notifies listeners', () {
        final notepad = MCPNotepadContent(
          content: 'Initial content',
          agentId: 'agent-123',
        );

        var notifyCount = 0;
        notepad.addListener(() => notifyCount++);

        final originalModified = notepad.lastModified;

        // Allow time passage for timestamp detection
        Future.delayed(const Duration(milliseconds: 1), () {
          notepad.updateContent('Updated content');

          expect(notepad.content, equals('Updated content'));
          expect(notepad.lastModified.isAfter(originalModified), isTrue);
          expect(notifyCount, equals(1));
        });
      });

      test('appends content correctly', () {
        final notepad = MCPNotepadContent(
          content: 'Initial',
          agentId: 'agent-123',
        );

        var notifyCount = 0;
        notepad.addListener(() => notifyCount++);

        notepad.appendContent(' appended');

        expect(notepad.content, equals('Initial appended'));
        expect(notifyCount, equals(1));
      });

      test('prepends content correctly', () {
        final notepad = MCPNotepadContent(
          content: 'content',
          agentId: 'agent-123',
        );

        var notifyCount = 0;
        notepad.addListener(() => notifyCount++);

        notepad.prependContent('Prepended ');

        expect(notepad.content, equals('Prepended content'));
        expect(notifyCount, equals(1));
      });

      test('clears content and notifies', () {
        final notepad = MCPNotepadContent(
          content: 'Some content to clear',
          agentId: 'agent-123',
        );

        var notifyCount = 0;
        notepad.addListener(() => notifyCount++);

        notepad.clearContent();

        expect(notepad.content, equals(''));
        expect(notepad.wordCount, equals(0));
        expect(notepad.characterCount, equals(0));
        expect(notifyCount, equals(1));
      });
    });

    group('📄 Content Access', () {
      test('returns content lines as list', () {
        final notepad = MCPNotepadContent(
          content: 'Line 1\nLine 2\nLine 3',
          agentId: 'agent-123',
        );

        final lines = notepad.getContentLines();

        expect(lines, equals(['Line 1', 'Line 2', 'Line 3']));
      });

      test('handles single line content', () {
        final notepad = MCPNotepadContent(
          content: 'Single line',
          agentId: 'agent-123',
        );

        final lines = notepad.getContentLines();

        expect(lines, equals(['Single line']));
      });

      test('generates content preview with default limit', () {
        final notepad = MCPNotepadContent(
          content:
              'Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8\nLine 9\nLine 10\nLine 11',
          agentId: 'agent-123',
        );

        final preview = notepad.getContentPreview();

        expect(preview.split('\n').length, equals(10)); // Default maxLines
        expect(preview, contains('Line 1'));
        expect(preview, contains('Line 10'));
        expect(preview, isNot(contains('Line 11')));
      });

      test('generates content preview with custom limit', () {
        final notepad = MCPNotepadContent(
          content: 'Line 1\nLine 2\nLine 3\nLine 4\nLine 5',
          agentId: 'agent-123',
        );

        final preview = notepad.getContentPreview(maxLines: 3);

        expect(preview.split('\n').length, equals(3));
        expect(preview, equals('Line 1\nLine 2\nLine 3'));
      });

      test('returns full content when under preview limit', () {
        final notepad = MCPNotepadContent(
          content: 'Short content',
          agentId: 'agent-123',
        );

        final preview = notepad.getContentPreview(maxLines: 10);

        expect(preview, equals('Short content'));
      });
    });

    group('🔄 Reactive Updates', () {
      test('extends ChangeNotifier', () {
        final notepad = MCPNotepadContent(
          content: 'Test content',
          agentId: 'agent-123',
        );

        expect(notepad, isA<ChangeNotifier>());
      });

      test('notifies on all content modifications', () {
        final notepad = MCPNotepadContent(
          content: 'Initial',
          agentId: 'agent-123',
        );

        var notifyCount = 0;
        notepad.addListener(() => notifyCount++);

        notepad.updateContent('Updated');
        notepad.appendContent(' more');
        notepad.prependContent('Pre ');
        notepad.clearContent();

        expect(notifyCount, equals(4));
      });
    });

    group('⚡ Performance Tests', () {
      test('handles large content efficiently', () {
        final largeContent = 'A' * 10000; // 10KB content
        final stopwatch = Stopwatch()..start();

        final notepad = MCPNotepadContent(
          content: largeContent,
          agentId: 'agent-123',
        );

        final wordCount = notepad.wordCount;
        final lineCount = notepad.lineCount;
        final characterCount = notepad.characterCount;

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds,
            lessThan(50)); // < 50ms for large content
        expect(characterCount, equals(10000));
      });

      test('content statistics calculation under 5ms', () {
        final notepad = MCPNotepadContent(
          content:
              'This is a test with multiple words and lines\nSecond line here\nThird line with more content',
          agentId: 'agent-123',
        );

        final stopwatch = Stopwatch()..start();

        // Perform multiple statistics calculations
        for (int i = 0; i < 100; i++) {
          notepad.wordCount;
          notepad.lineCount;
          notepad.characterCount;
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(5)); // < 5ms requirement
      });
    });

    group('🛡️ Edge Cases', () {
      test('handles newline-only content', () {
        final notepad = MCPNotepadContent(
          content: '\n\n\n',
          agentId: 'agent-123',
        );

        expect(notepad.wordCount, equals(0));
        expect(notepad.lineCount, equals(4)); // 3 newlines = 4 lines
        expect(notepad.characterCount, equals(3));
      });

      test('handles whitespace-only content', () {
        final notepad = MCPNotepadContent(
          content: '   \t  \n  \t  ',
          agentId: 'agent-123',
        );

        expect(notepad.wordCount, equals(0));
        expect(notepad.lineCount, equals(2));
      });

      test('handles special characters', () {
        final notepad = MCPNotepadContent(
          content: '🚀 Unicode test with émojis and açcents!',
          agentId: 'agent-123',
        );

        expect(notepad.wordCount, equals(7));
        expect(notepad.characterCount, equals(40));
      });
    });
  });
}
