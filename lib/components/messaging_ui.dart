import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';

/// MessagingUI Component - Enhanced Chat Interface
///
/// ## Purpose
/// Production-ready chat interface with auto-scroll, expandable input (1-10 lines),
/// Shift+Enter send functionality, and automatic focus management for real-time messaging.
///
/// ## Key Architectural Decisions
/// | Option | Pros | Cons | Why Chosen |
/// |--------|------|------|------------|
/// | ScrollController auto-scroll | Smooth UX, precise control | Memory overhead, state management | Required for chat UX standards |
/// | KeyboardListener for Shift+Enter | Cross-platform, granular control | Complex event handling | Alternative TextInputAction insufficient |
/// | TextField minLines/maxLines | Native Flutter expansion | Limited to 10 lines max | Balances usability vs screen space |
/// | FocusNode re-focusing | Continuous typing flow | Additional state complexity | Essential for productivity |
///
/// ## Known Challenges & Solutions
/// 1. **Keyboard Event Handling**
///    - Challenge: Multiple shift key variants across platforms
///    - Solution: Check all shift key variants (shift, shiftLeft, shiftRight)
/// 2. **Scroll Timing**
///    - Challenge: ScrollController not ready during widget updates
///    - Solution: PostFrameCallback ensures scroll controller availability
/// 3. **Focus Management**
///    - Challenge: Focus lost after programmatic text clearing
///    - Solution: Explicit focus request via PostFrameCallback
///
/// ## Performance Characteristics
/// - Auto-scroll animation: O(1) - single animation operation
/// - Message rendering: O(n) where n = message count
/// - Text field expansion: O(1) - native Flutter optimization
/// - Keyboard event handling: O(1) - direct key comparison
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
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Message length tracking for auto-scroll
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.inputText ?? '');
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
    // Update controller text if inputText prop changes
    if (widget.inputText != oldWidget.inputText && widget.inputText != null) {
      _textController.text = widget.inputText!;
    }

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
    _textController.dispose();
    _focusNode.dispose();
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

  /// Handles message sending with validation and focus management
  ///
  /// Validates non-empty trimmed text, calls callback, clears field,
  /// and restores focus for continuous typing workflow
  void _handleSendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && widget.onSendMessage != null) {
      widget.onSendMessage!(text);

      // Clear text field completely and restore focus
      _textController.clear();

      // Ensure focus is restored and no residual text remains
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Double-check text is cleared (prevents carriage return issue)
        if (_textController.text.isNotEmpty) {
          _textController.clear();
        }
        _focusNode.requestFocus();
      });
    }
  }

  /// Keyboard event handler for Shift+Enter functionality
  ///
  /// PERF: Event handling complexity O(1) - direct key comparison
  /// Checks multiple shift key variants for cross-platform compatibility
  /// Prevents Enter propagation when Shift is pressed
  bool _handleKeyEvent(KeyEvent event) {
    // Handle Shift+Enter to send message - check both KeyDown and KeyRepeat
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final isShiftPressed = HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.shift) ||
          HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.shiftLeft) ||
          HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.shiftRight);

      if (isShiftPressed && event.logicalKey == LogicalKeyboardKey.enter) {
        // Prevent any Enter key processing by TextField
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleSendMessage();
        });
        return true; // Consume the event completely
      }
    }
    return false; // Don't consume the event
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = widget.theme ?? MessagingTheme.defaultTheme(context);

    return Column(
      children: [
        Expanded(
          child: _buildMessagesList(context, effectiveTheme),
        ),
        if (widget.showInput) _buildInputField(context),
      ],
    );
  }

  /// Builds the scrollable messages list or empty state
  ///
  /// PERF: ListView.builder provides O(1) visible item rendering
  /// Only renders visible items, efficient for large message lists
  Widget _buildMessagesList(
      BuildContext context, MessagingTheme effectiveTheme) {
    if (widget.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.messages.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final message = widget.messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MessageBubble(
            message: message,
            onTap: widget.onMessageTap != null
                ? () => widget.onMessageTap!(message)
                : null,
            showTimestamps: widget.showTimestamps,
            theme: effectiveTheme,
          ),
        );
      },
    );
  }

  /// Builds the expandable input field with keyboard handling
  ///
  /// Features:
  /// - Expands from 1 to 10 lines automatically
  /// - Shift+Enter to send, Enter for new line
  /// - Focus management and visual feedback
  /// - Helper text and tooltip guidance
  Widget _buildInputField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: _handleKeyEvent,
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: widget.inputPlaceholder,
                  helperText: 'Shift+Enter to send',
                  helperStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.3),
                ),
                minLines: 1,
                maxLines: 10,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: widget.onSendMessage != null ? _handleSendMessage : null,
            icon: const Icon(Icons.send),
            tooltip: 'Send message (Shift+Enter)',
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
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
          if (messageStyle.showAvatar) _buildAvatar(context),
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
                  if (message.name != null) _buildHeader(context),
                  if (message.content != null)
                    _buildContent(context, messageStyle),
                  if (message.toolCalls != null) _buildToolCalls(context),
                  if (message.reasoningContent != null)
                    _buildReasoningContent(context),
                  if (showTimestamps) _buildTimestamp(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the message header showing the participant name.
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        message.name!,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getRoleColor(context).withValues(alpha: 0.8),
            ),
      ),
    );
  }

  /// Builds the main message content.
  Widget _buildContent(BuildContext context, _MessageStyle messageStyle) {
    return Text(
      message.content!,
      style: messageStyle.textStyle,
    );
  }

  /// Builds the tool calls section for assistant messages.
  Widget _buildToolCalls(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tool Calls:',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          ...message.toolCalls!.map((toolCall) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• ${toolCall['function']?['name'] ?? 'Unknown function'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              )),
        ],
      ),
    );
  }

  /// Builds the reasoning content section for deepseek-reasoner model responses.
  Widget _buildReasoningContent(BuildContext context) {
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
          Text(
            'Reasoning:',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            message.reasoningContent!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }

  /// Builds a timestamp for the message.
  Widget _buildTimestamp(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        DateTime.now().toString().substring(11, 19), // Simple time format
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
      ),
    );
  }

  /// Builds an avatar for the message based on its role.
  Widget _buildAvatar(BuildContext context) {
    final color = _getRoleColor(context);
    final icon = _getRoleIcon();

    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  /// Returns the appropriate color for the message role.
  Color _getRoleColor(BuildContext context) {
    switch (message.role) {
      case MessageRole.system:
        return Theme.of(context).colorScheme.outline;
      case MessageRole.user:
        return Theme.of(context).colorScheme.primary;
      case MessageRole.assistant:
        return Theme.of(context).colorScheme.secondary;
      case MessageRole.tool:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  /// Returns the appropriate icon for the message role.
  IconData _getRoleIcon() {
    switch (message.role) {
      case MessageRole.system:
        return Icons.settings;
      case MessageRole.user:
        return Icons.person;
      case MessageRole.assistant:
        return Icons.smart_toy;
      case MessageRole.tool:
        return Icons.build;
    }
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
