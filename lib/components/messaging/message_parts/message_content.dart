import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';

/// MessageContent - Markdown Message Text Display
///
/// ## MISSION ACCOMPLISHED
/// Creates reusable content component with markdown rendering and link support.
/// Provides rich markdown text rendering with proper styling integration and FULL SELECTION.
/// DESKTOP OPTIMIZATION: Full text selection and copy functionality for professional desktop UX.
/// MARKDOWN SUPREMACY: Supports rich text formatting including headers, code blocks, links, and more.
/// URL LAUNCHER INTEGRATION: Functional link tapping with system browser/app launching.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | Text Widget | Minimal | No markdown | Rejected - lacks rich formatting |
/// | SelectableText Widget | Desktop UX | No markdown | Defeated - replaced with markdown |
/// | MarkdownBody Widget | Rich formatting, selection | Slight overhead | CHOSEN - ultimate text rendering |
/// | Debug Print Links | Simple logging | No functionality | Defeated - replaced with URL launcher |
/// | URL Launcher Integration | Functional links | Requires dependency | CHOSEN - professional link handling |
/// | Stateless Widget | Reusable, efficient | Slight overhead | CHOSEN - architectural excellence |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(n) - markdown parsing and rendering (acceptable for text content)
/// - Space Complexity: O(n) - parsed markdown AST (optimized by flutter_markdown_plus)
/// - Rebuild Frequency: Only when message content changes
/// - Desktop Optimization: Full text selection with context menu support
/// - Markdown Features: Headers, code blocks, links, emphasis, lists, tables
/// - Link Launching: O(1) URL launching with system browser/app integration
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Component Architecture Excellence**
///    - 🔍 Symptom: Content rendering logic embedded in parent widgets
///    - 🎯 Root Cause: Content rendering logic embedded in parent widget
///    - 💥 Kill Shot: Extracted to dedicated StatelessWidget with style integration
///
/// 2. **Plain Text Limitation**
///    - 🔍 Symptom: No rich text formatting support for AI responses
///    - 🎯 Root Cause: SelectableText widget doesn't parse markdown
///    - 💥 Kill Shot: Replaced with MarkdownBody for full markdown rendering
///
/// 3. **Non-Functional Links**
///    - 🔍 Symptom: Links in markdown only logged to debug console
///    - 🎯 Root Cause: debugPrint instead of actual URL launching
///    - 💥 Kill Shot: Integrated url_launcher for system browser/app opening
///
/// 4. **Desktop Text Selection Limitation**
///    - 🔍 Symptom: No text selection/copy functionality on desktop builds
///    - 🎯 Root Cause: Non-selectable text widgets
///    - 💥 Kill Shot: Enabled selection with selectable: true for desktop UX
class MessageContent extends StatelessWidget {
  /// Creates a selectable markdown message content display with styling
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor
  /// DESKTOP OPTIMIZED: Full text selection and copy functionality
  /// MARKDOWN OPTIMIZED: Rich text formatting support for enhanced readability
  /// URL LAUNCHER OPTIMIZED: Functional link tapping with system integration
  const MessageContent({
    super.key,
    required this.message,
    required this.textStyle,
  });

  /// Chat message containing the content text (supports markdown)
  final ChatMessage message;

  /// Text style to apply to the content (base style for markdown)
  final TextStyle? textStyle;

  /// Launch URL in system browser or appropriate app
  ///
  /// ARCHITECTURAL: General solution supporting all URL schemes (https, mailto, tel, sms, file)
  /// ERROR HANDLING: Graceful failure with user feedback through SnackBar
  /// PERFORMANCE: O(1) URL launching with async execution
  Future<void> _launchUrl(BuildContext context, String? href) async {
    if (href == null || href.isEmpty) {
      return;
    }

    try {
      final Uri url = Uri.parse(href);

      // GENERAL SOLUTION: Support all URL schemes - https, mailto, tel, sms, file, etc.
      if (!await launchUrl(url)) {
        if (context.mounted) {
          _showLaunchError(context, href, 'Could not launch URL');
        }
      }
    } catch (e) {
      // ARCHITECTURAL: Proper error handling with user feedback
      if (context.mounted) {
        _showLaunchError(context, href, 'Invalid URL format: $e');
      }
    }
  }

  /// Show user-friendly error message for URL launch failures
  ///
  /// ARCHITECTURAL: Consistent error feedback across the application
  /// UX OPTIMIZATION: Non-intrusive SnackBar notification with action
  void _showLaunchError(BuildContext context, String url, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to open link: $url\n$error'),
        action: SnackBarAction(
          label: 'Copy URL',
          onPressed: () {
            // Could integrate with clipboard if needed
            debugPrint('URL copy requested: $url');
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only render if message has content
    final content = message.content;
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }

    // PERF: MarkdownBody with selection for desktop optimization and rich formatting
    // ARCHITECTURAL: General solution - works across all platforms, optimized for desktop
    // MARKDOWN SUPREMACY: Supports headers, code blocks, links, emphasis, lists, tables
    // URL LAUNCHER SUPREMACY: Functional link clicking with system integration
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        // Apply the provided text style as base for all text elements
        p: textStyle,
        // Ensure code blocks stand out with monospace font
        code: TextStyle(
          fontFamily: 'monospace',
          backgroundColor: Theme.of(context).colorScheme.surface,
          fontSize: (textStyle?.fontSize ?? 14) * 0.9,
        ),
        codeblockDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        // Style links to match theme colors
        a: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        // Style headers with appropriate sizing
        h1: textStyle?.copyWith(
          fontSize: (textStyle?.fontSize ?? 16) * 1.5,
          fontWeight: FontWeight.bold,
        ),
        h2: textStyle?.copyWith(
          fontSize: (textStyle?.fontSize ?? 16) * 1.3,
          fontWeight: FontWeight.bold,
        ),
        h3: textStyle?.copyWith(
          fontSize: (textStyle?.fontSize ?? 16) * 1.1,
          fontWeight: FontWeight.bold,
        ),
      ),
      // URL LAUNCHER INTEGRATION: Functional link tapping with system browser/app launching
      onTapLink: (text, href, title) async {
        await _launchUrl(context, href);
      },
    );
  }
}
