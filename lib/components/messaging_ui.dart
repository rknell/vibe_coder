import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:vibe_coder/components/messaging/messages_list.dart';
import 'package:vibe_coder/components/messaging/chat_input_field.dart';
import 'package:vibe_coder/components/messaging/message_parts/message_header.dart';
import 'package:vibe_coder/components/messaging/message_parts/message_content.dart';
import 'package:vibe_coder/components/messaging/message_parts/message_tool_calls.dart';
import 'package:vibe_coder/components/messaging/message_parts/message_reasoning_content.dart';
import 'package:vibe_coder/components/messaging/message_parts/message_timestamp.dart';
import 'package:vibe_coder/components/messaging/message_parts/message_avatar.dart';

/// MessagingUI Component - Enhanced Chat Interface
///
/// ## MISSION ACCOMPLISHED
/// Production-ready chat interface with component-based architecture eliminating all functional widget builders.
/// Provides auto-scroll, expandable input, and real-time messaging using proper component separation.
/// ARCHITECTURAL VICTORY: All functional widget builders extracted to reusable components.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | ScrollController auto-scroll | Smooth UX, precise control | Memory overhead | Required for chat UX standards |
/// | Component Architecture | Reusable, testable | More files | CHOSEN - architectural excellence |
/// | Functional Builders | Simple | Not reusable | ELIMINATED - violates architecture |
/// | MessagesListComponent | Clean separation | Slight overhead | CHOSEN - proper component design |
/// | ChatInputFieldComponent | Encapsulated state | More complex | CHOSEN - single responsibility |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Elimination**
///    - 🔍 Symptom: `_buildMessagesList()` and `_buildInputField()` methods
///    - 🎯 Root Cause: UI logic embedded in parent widget
///    - 💥 Kill Shot: Extracted to MessagesListComponent and ChatInputFieldComponent
///
/// 2. **Component Reusability Achievement**
///    - 🔍 Symptom: Tightly coupled UI elements
///    - 🎯 Root Cause: Mixed responsibilities in single widget
///    - 💥 Kill Shot: Clean component separation with prop injection
///
/// ## PERFORMANCE PROFILE
/// - Auto-scroll animation: O(1) - single animation operation
/// - Message rendering: O(n) where n = message count (delegated to MessagesListComponent)
/// - Component composition: O(1) - efficient widget tree construction
/// - State management: O(1) - simplified with component extraction
///
/// A UI component that displays a list of chat messages with an input field.
///
/// This component receives a list of [ChatMessage] objects and renders them
/// with the oldest messages at the top and the newest at the bottom.
/// Each message is styled differently based on its role (system, user, assistant, tool).
/// Includes a text input field at the bottom for sending new messages.
class MessagingUI extends StatefulWidget {
  /// The list of chat messages to display.
  /// Messages are displayed in the order provided, with newer messages at the bottom.
  final List<ChatMessage> messages;

  /// Optional callback triggered when a message is tapped.
  final void Function(ChatMessage)? onMessageTap;

  /// Callback triggered when a message is sent from the input field.
  /// The string parameter contains the message text.
  final void Function(String)? onSendMessage;

  /// Whether to show timestamps for messages.
  final bool showTimestamps;

  /// Optional custom styling for messages.
  final MessagingTheme? theme;

  /// The current text value for the input field.
  /// Can be used to populate the input field from parent state.
  final String? inputText;

  /// Placeholder text for the input field.
  final String inputPlaceholder;

  /// Whether to show the input field at the bottom.
  final bool showInput;

  const MessagingUI({
    super.key,
    required this.messages,
    this.onMessageTap,
    this.onSendMessage,
    this.showTimestamps = false,
    this.theme,
    this.inputText,
    this.inputPlaceholder = 'Type a message...',
    this.showInput = true,
  });

  @override
  State<MessagingUI> createState() => _MessagingUIState();
}

class _MessagingUIState extends State<MessagingUI> {
  final ScrollController _scrollController = ScrollController();

  // Message length tracking for auto-scroll
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _previousMessageCount = widget.messages.length;

    // PERF: Auto-scroll complexity O(1) - single animation operation
    // Auto-scroll to bottom when messages are updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.messages.isNotEmpty) {
        _scrollToBottom();
      }
    });
  }

  @override
  void didUpdateWidget(MessagingUI oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-scroll to bottom when message count increases
    // PERF: O(1) length comparison - efficient message change detection
    if (widget.messages.length > _previousMessageCount) {
      _previousMessageCount = widget.messages.length;

      // Use PostFrameCallback to ensure ListView rebuild completion
      // ARCHITECTURAL: Eliminates timer-based workarounds for reliable scrolling
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } else {
      // Update count for unchanged or decreased length scenarios
      _previousMessageCount = widget.messages.length;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Smoothly scrolls ListView to bottom with animation
  ///
  /// PERF: Animation complexity O(1) - single scroll operation
  /// ARCHITECTURAL: Eliminates timer complexity - PostFrameCallback ensures proper timing
  /// CHALLENGE SOLVED: Scroll timing issues resolved by removing timer workarounds
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    // Direct scroll with proper timing guaranteed by PostFrameCallback
    if (_scrollController.position.maxScrollExtent > 0) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = widget.theme ?? MessagingTheme.defaultTheme(context);

    return Column(
      children: [
        Expanded(
          child: MessagesListComponent(
            messages: widget.messages,
            scrollController: _scrollController,
            onMessageTap: widget.onMessageTap,
            showTimestamps: widget.showTimestamps,
            theme: effectiveTheme,
          ),
        ),
        if (widget.showInput)
          ChatInputFieldComponent(
            onSendMessage: widget.onSendMessage,
            inputText: widget.inputText,
            inputPlaceholder: widget.inputPlaceholder,
            enabled: true,
          ),
      ],
    );
  }
}

/// A widget that displays a single chat message with appropriate styling.
///
/// The message appearance changes based on its role:
/// - System messages: Centered, subtle styling
/// - User messages: Right-aligned, primary color
/// - Assistant messages: Left-aligned, secondary color
/// - Tool messages: Centered, monospace font for code-like appearance
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onTap;
  final bool showTimestamps;
  final MessagingTheme theme;

  const MessageBubble({
    super.key,
    required this.message,
    this.onTap,
    required this.showTimestamps,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final messageStyle = _getMessageStyle(context);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: messageStyle.alignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (messageStyle.showAvatar) MessageAvatar(message: message),
          if (messageStyle.showAvatar) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              decoration: BoxDecoration(
                color: messageStyle.backgroundColor,
                borderRadius: messageStyle.borderRadius,
                border: messageStyle.border,
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MessageHeader(message: message),
                  MessageContent(
                    message: message,
                    textStyle: messageStyle.textStyle,
                  ),
                  MessageToolCalls(message: message),
                  MessageReasoningContent(message: message),
                  MessageTimestamp(showTimestamp: showTimestamps),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Determines the styling for the message based on its role.
  _MessageStyle _getMessageStyle(BuildContext context) {
    switch (message.role) {
      case MessageRole.system:
        return _MessageStyle(
          alignment: MainAxisAlignment.center,
          backgroundColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
          showAvatar: false,
        );
      case MessageRole.user:
        return _MessageStyle(
          alignment: MainAxisAlignment.end,
          backgroundColor: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
          showAvatar: true,
        );
      case MessageRole.assistant:
        return _MessageStyle(
          alignment: MainAxisAlignment.start,
          backgroundColor:
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          textStyle: Theme.of(context).textTheme.bodyMedium,
          border: Border.all(
            color:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
            width: 1,
          ),
          showAvatar: true,
        );
      case MessageRole.tool:
        return _MessageStyle(
          alignment: MainAxisAlignment.center,
          backgroundColor:
              Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.tertiary,
              ),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5),
            width: 1,
          ),
          showAvatar: true,
        );
    }
  }
}

/// Internal class to hold message styling information.
class _MessageStyle {
  final MainAxisAlignment alignment;
  final Color backgroundColor;
  final BorderRadius borderRadius;
  final TextStyle? textStyle;
  final Border? border;
  final bool showAvatar;

  const _MessageStyle({
    required this.alignment,
    required this.backgroundColor,
    required this.borderRadius,
    this.textStyle,
    this.border,
    required this.showAvatar,
  });
}

/// Theme configuration for the messaging UI.
///
/// Allows customization of colors, typography, and spacing for different message types.
class MessagingTheme {
  final Color systemMessageColor;
  final Color userMessageColor;
  final Color assistantMessageColor;
  final Color toolMessageColor;
  final TextStyle? messageTextStyle;
  final double messagePadding;
  final double messageSpacing;

  const MessagingTheme({
    required this.systemMessageColor,
    required this.userMessageColor,
    required this.assistantMessageColor,
    required this.toolMessageColor,
    this.messageTextStyle,
    this.messagePadding = 12.0,
    this.messageSpacing = 12.0,
  });

  /// Creates a default theme based on the current Material theme.
  static MessagingTheme defaultTheme(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MessagingTheme(
      systemMessageColor: colorScheme.outline,
      userMessageColor: colorScheme.primary,
      assistantMessageColor: colorScheme.secondary,
      toolMessageColor: colorScheme.tertiary,
      messageTextStyle: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
