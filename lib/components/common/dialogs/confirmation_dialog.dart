library confirmation_dialog;

/// ConfirmationDialog - Reusable confirmation dialog component
///
/// ## MISSION ACCOMPLISHED
/// **ELIMINATES DIALOG DUPLICATION ANTI-PATTERN** by providing unified confirmation dialogs.
/// Supports destructive and non-destructive actions with consistent styling.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Inline showDialog | Simple | Code duplication | ELIMINATED - violates DRY principle |
/// | ConfirmationDialog | Consistent, reusable | Extra abstraction | CHOSEN - unified dialog pattern |
/// | AlertDialog Extension | Flutter native | No custom styling | REJECTED - need custom destructive styling |
/// | External Package | Feature-rich | Dependency overhead | REJECTED - custom solution for control |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Dialog Code Duplication Elimination**
///    - 🔍 Symptom: Multiple confirmation dialogs with similar structure
///    - 🎯 Root Cause: Repeated AlertDialog patterns across screens
///    - 💥 Kill Shot: Single component with configuration-based styling
///
/// 2. **Destructive Action Safety Achievement**
///    - 🔍 Symptom: Inconsistent destructive action styling
///    - 🎯 Root Cause: No standardized dangerous action indication
///    - 💥 Kill Shot: Destructive flag with red styling for dangerous operations
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Dialog creation: O(1) - single AlertDialog construction
/// - Result handling: O(1) - boolean result return
/// - Theme integration: O(1) - direct theme color access
/// - Memory usage: O(1) - minimal widget tree for dialog
import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final IconData? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmText,
    this.cancelText = 'Cancel',
    this.isDestructive = false,
    this.icon,
  });

  /// Show confirmation dialog
  /// PERF: O(1) - direct dialog display with boolean result
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmText,
    String cancelText = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
  }

  /// Factory constructor for delete confirmation
  /// PERF: O(1) - direct constructor call with delete preset
  static Future<bool?> showDelete(
    BuildContext context, {
    required String itemName,
    String? customContent,
  }) {
    return show(
      context,
      title: 'Delete $itemName',
      content: customContent ??
          'Are you sure you want to delete "$itemName"? This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
      icon: Icons.delete_forever,
    );
  }

  /// Factory constructor for clear confirmation
  /// PERF: O(1) - direct constructor call with clear preset
  static Future<bool?> showClear(
    BuildContext context, {
    required String itemName,
    String? customContent,
  }) {
    return show(
      context,
      title: 'Clear $itemName',
      content: customContent ??
          'Are you sure you want to clear "$itemName"? This action cannot be undone.',
      confirmText: 'Clear',
      isDestructive: true,
      icon: Icons.clear_all,
    );
  }

  /// Factory constructor for discard changes confirmation
  /// PERF: O(1) - direct constructor call with discard preset
  static Future<bool?> showDiscardChanges(
    BuildContext context, {
    String customContent =
        'You have unsaved changes. Are you sure you want to close without saving?',
  }) {
    return show(
      context,
      title: 'Unsaved Changes',
      content: customContent,
      confirmText: 'Discard',
      isDestructive: true,
      icon: Icons.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: icon != null
          ? Icon(
              icon,
              color:
                  isDestructive ? Colors.red : Theme.of(context).primaryColor,
            )
          : null,
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? TextButton.styleFrom(foregroundColor: Colors.red)
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }
}
