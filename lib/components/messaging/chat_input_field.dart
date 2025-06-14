import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ChatInputFieldComponent - Advanced Text Input with Keyboard Handling
///
/// ## MISSION ACCOMPLISHED
/// Eliminates _buildInputField functional widget builder by creating reusable input component.
/// Provides expandable text input, Ctrl+Enter send functionality, and proper focus management.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Functional Builder | Simple | Not reusable | Rejected - violates architecture |
/// | StatefulWidget | Full state management | More complex | CHOSEN - required for input state |
/// | TextFormField | Validation built-in | Overkill | Simple TextField sufficient |
/// | Shift+Enter | Common pattern | Less professional | Rejected - Ctrl+Enter superior |
/// | Ctrl+Enter | Professional standard | Slightly complex | CHOSEN - industry standard |
///
/// ## PERFORMANCE PROFILE
/// - Time Complexity: O(1) - keyboard event handling and text operations
/// - Space Complexity: O(1) - minimal state storage
/// - Rebuild Frequency: Only on text changes and focus updates
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Builder Elimination**
///    - 🔍 Symptom: `_buildInputField()` method in MessagingUI StatefulWidget
///    - 🎯 Root Cause: Complex input logic embedded in parent widget
///    - 💥 Kill Shot: Extracted to reusable StatefulWidget with proper state management
///
/// 2. **Keyboard Event Complexity**
///    - 🔍 Symptom: Complex keyboard handling scattered in parent logic
///    - 🎯 Root Cause: Multiple responsibilities in single widget
///    - 💥 Kill Shot: Encapsulated keyboard logic in dedicated component
///
/// 3. **Shift+Enter Unprofessional Pattern**
///    - 🔍 Symptom: Shift+Enter shortcut not matching industry standards
///    - 🎯 Root Cause: User experience inconsistency with professional tools
///    - 💥 Kill Shot: Upgraded to Ctrl+Enter for professional coding environment
class ChatInputFieldComponent extends StatefulWidget {
  /// Creates a chat input field with required dependencies
  ///
  /// ARCHITECTURAL: All dependencies injected via constructor
  const ChatInputFieldComponent({
    super.key,
    this.onSendMessage,
    this.inputText,
    this.inputPlaceholder = 'Type a message...',
    this.enabled = true,
  });

  /// Callback triggered when message is sent
  final void Function(String)? onSendMessage;

  /// Initial text value for the input field
  final String? inputText;

  /// Placeholder text for the input field
  final String inputPlaceholder;

  /// Whether the input field is enabled
  final bool enabled;

  @override
  State<ChatInputFieldComponent> createState() =>
      _ChatInputFieldComponentState();
}

class _ChatInputFieldComponentState extends State<ChatInputFieldComponent> {
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.inputText ?? '');
  }

  @override
  void didUpdateWidget(ChatInputFieldComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller text if inputText prop changes
    if (widget.inputText != oldWidget.inputText && widget.inputText != null) {
      _textController.text = widget.inputText!;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Handles message sending with validation and focus management
  ///
  /// PERF: O(1) - simple text validation and callback execution
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

  /// Keyboard event handler for Ctrl+Enter functionality
  ///
  /// PERF: Event handling complexity O(1) - direct key comparison
  /// Checks multiple control key variants for cross-platform compatibility
  /// Prevents Enter propagation when Ctrl is pressed
  bool _handleKeyEvent(KeyEvent event) {
    // Handle Ctrl+Enter to send message - check both KeyDown and KeyRepeat
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.control) ||
          HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.controlLeft) ||
          HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.controlRight) ||
          HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.meta) ||
          HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.metaLeft) ||
          HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.metaRight);

      if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.enter) {
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
                enabled: widget.enabled,
                decoration: InputDecoration(
                  hintText: widget.inputPlaceholder,
                  helperText: 'Ctrl+Enter to send',
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
            onPressed: widget.enabled && widget.onSendMessage != null
                ? _handleSendMessage
                : null,
            icon: const Icon(Icons.send),
            tooltip: 'Send message (Ctrl+Enter)',
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
