import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';

/// MessageReasoningContent - Markdown Reasoning Section Display
///
/// ## MISSION ACCOMPLISHED
/// Eliminates _buildReasoningContent functional widget builder by creating reusable reasoning component.
/// Provides rich markdown reasoning content display with proper theming for deepseek-reasoner model responses.
/// DESKTOP OPTIMIZATION: Full text selection and copy functionality for reasoning content.
/// MARKDOWN SUPREMACY: Supports rich text formatting in reasoning content including code blocks and emphasis.
/// URL LAUNCHER INTEGRATION: Functional link tapping in reasoning content with system browser/app launching.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | Text Widget | Minimal | No markdown | Rejected - lacks rich formatting |
/// | SelectableText Widget | Desktop UX | No markdown | Defeated - replaced with markdown |
/// | MarkdownBody Widget | Rich formatting, selection | Slight overhead | CHOSEN - ultimate text rendering |
/// | Debug Print Links | Simple logging | No functionality | Defeated - replaced with URL launcher |
/// | URL Launcher Integration | Functional links | Requires dependency | CHOSEN - professional reasoning link handling |
/// | Stateless Widget | Reusable, themed | Slight overhead | CHOSEN - architectural excellence |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(n) - markdown parsing and rendering (acceptable for reasoning content)
/// - Space Complexity: O(n) - parsed markdown AST (optimized by flutter_markdown_plus)
/// - Rebuild Frequency: Only when reasoning content changes
/// - Desktop Optimization: Full text selection with context menu support
/// - Markdown Features: Headers, code blocks, links, emphasis, lists for reasoning clarity
/// - Link Launching: O(1) URL launching with system browser/app integration
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Elimination**
///    - 🔍 Symptom: `_buildReasoningContent()` method in MessageBubble
///    - 🎯 Root Cause: Reasoning display logic embedded in parent widget
///    - 💥 Kill Shot: Extracted to dedicated StatelessWidget with tertiary theming
///
/// 2. **Plain Text Reasoning Limitation**
///    - 🔍 Symptom: No rich text formatting support for reasoning content
///    - 🎯 Root Cause: SelectableText widget doesn't parse markdown
///    - 💥 Kill Shot: Replaced with MarkdownBody for enhanced reasoning readability
///
/// 3. **Non-Functional Reasoning Links**
///    - 🔍 Symptom: Links in reasoning content only logged to debug console
///    - 🎯 Root Cause: debugPrint instead of actual URL launching
///    - 💥 Kill Shot: Integrated url_launcher for reasoning link functionality
///
/// 4. **Desktop Text Selection Limitation**
///    - 🔍 Symptom: No text selection/copy functionality for reasoning content
///    - 🎯 Root Cause: Non-selectable text widgets
///    - 💥 Kill Shot: Enabled selection with selectable: true for desktop UX
class MessageReasoningContent extends StatelessWidget {
  /// Creates a selectable markdown reasoning content display section
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor
  /// DESKTOP OPTIMIZED: Full text selection and copy functionality
  /// MARKDOWN OPTIMIZED: Rich text formatting support for enhanced reasoning readability
  /// URL LAUNCHER OPTIMIZED: Functional reasoning link tapping with system integration
  const MessageReasoningContent({
    super.key,
    required this.message,
  });

  /// Chat message containing reasoning content (supports markdown)
  final ChatMessage message;

  /// Launch URL in system browser or appropriate app from reasoning content
  ///
  /// ARCHITECTURAL: General solution supporting all URL schemes (https, mailto, tel, sms, file)
  /// ERROR HANDLING: Graceful failure with user feedback through SnackBar
  /// PERFORMANCE: O(1) URL launching with async execution
  /// REASONING SPECIFIC: Specialized handling for reasoning content links
  Future<void> _launchReasoningUrl(BuildContext context, String? href) async {
    if (href == null || href.isEmpty) {
      return;
    }

    try {
      final Uri url = Uri.parse(href);

      // GENERAL SOLUTION: Support all URL schemes - https, mailto, tel, sms, file, etc.
      if (!await launchUrl(url)) {
        if (context.mounted) {
          _showReasoningLaunchError(
              context, href, 'Could not launch reasoning URL');
        }
      }
    } catch (e) {
      // ARCHITECTURAL: Proper error handling with user feedback
      if (context.mounted) {
        _showReasoningLaunchError(
            context, href, 'Invalid reasoning URL format: $e');
      }
    }
  }

  /// Show user-friendly error message for reasoning URL launch failures
  ///
  /// ARCHITECTURAL: Consistent error feedback with reasoning-specific context
  /// UX OPTIMIZATION: Non-intrusive SnackBar notification with reasoning context
  void _showReasoningLaunchError(
      BuildContext context, String url, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to open reasoning link: $url\n$error'),
        action: SnackBarAction(
          label: 'Copy URL',
          onPressed: () {
            // Could integrate with clipboard if needed
            debugPrint('Reasoning URL copy requested: $url');
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only render if message has reasoning content
    final reasoningContent = message.reasoningContent;
    if (reasoningContent == null || reasoningContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DESKTOP OPTIMIZATION: Selectable label text (keeping as SelectableText for consistency)
          SelectableText(
            'Reasoning:',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
            enableInteractiveSelection: true,
            contextMenuBuilder: (context, editableTextState) {
              return AdaptiveTextSelectionToolbar.buttonItems(
                anchors: editableTextState.contextMenuAnchors,
                buttonItems: editableTextState.contextMenuButtonItems,
              );
            },
          ),
          const SizedBox(height: 4),
          // MARKDOWN SUPREMACY: Rich markdown reasoning content with theming
          // URL LAUNCHER SUPREMACY: Functional reasoning link clicking with system integration
          MarkdownBody(
            data: reasoningContent,
            selectable: true,
            styleSheet:
                MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              // Apply reasoning-specific styling
              p: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                  ),
              // Style code blocks for reasoning
              code: TextStyle(
                fontFamily: 'monospace',
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.5),
                fontSize:
                    (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) *
                        0.9,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.9),
              ),
              codeblockDecoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.2),
                ),
              ),
              // Style links in reasoning content
              a: TextStyle(
                color: Theme.of(context).colorScheme.tertiary,
                decoration: TextDecoration.underline,
              ),
              // Style headers with reasoning-appropriate sizing
              h1: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.bodySmall?.fontSize ??
                                12) *
                            1.3,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
              h2: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.bodySmall?.fontSize ??
                                12) *
                            1.2,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
              h3: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.bodySmall?.fontSize ??
                                12) *
                            1.1,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
            ),
            // URL LAUNCHER INTEGRATION: Functional reasoning link tapping with system browser/app launching
            onTapLink: (text, href, title) async {
              await _launchReasoningUrl(context, href);
            },
          ),
        ],
      ),
    );
  }
}
