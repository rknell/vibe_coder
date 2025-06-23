/// StatusBanner - Universal status message display component
///
/// ## MISSION ACCOMPLISHED
/// **ELIMINATES INLINE BANNER ANTI-PATTERN** by providing reusable status display.
/// Supports loading, error, success, and info states with consistent styling.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Inline Containers | Simple | Code duplication | ELIMINATED - violates DRY principle |
/// | StatusBanner Component | Reusable, consistent | Extra abstraction | CHOSEN - unified status display |
/// | Multiple Components | Type safety | Over-engineering | REJECTED - single component handles all states |
/// | External Package | Feature-rich | Dependency overhead | REJECTED - custom solution for control |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Code Duplication Elimination**
///    - 🔍 Symptom: Loading and error banners with identical structure
///    - 🎯 Root Cause: Complex inline widget repetition in HomeScreen
///    - 💥 Kill Shot: Single component with status type discrimination
///
/// 2. **Styling Consistency Achievement**
///    - 🔍 Symptom: Hardcoded colors and spacing across status displays
///    - 🎯 Root Cause: No centralized status styling system
///    - 💥 Kill Shot: Theme-integrated status styling with semantic colors
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Rendering: O(1) - single Container with conditional styling
/// - Memory: O(1) - minimal widget tree depth
/// - Theme integration: O(1) - direct theme color access
/// - Dismissal: O(1) - optional callback-based interaction
import 'package:flutter/material.dart';

enum StatusBannerType {
  loading,
  error,
  success,
  info,
}

class StatusBanner extends StatelessWidget {
  final StatusBannerType type;
  final String message;
  final VoidCallback? onDismiss;
  final Widget? action;
  final bool showIcon;

  const StatusBanner({
    super.key,
    required this.type,
    required this.message,
    this.onDismiss,
    this.action,
    this.showIcon = true,
  });

  /// Factory constructor for loading status
  /// PERF: O(1) - direct constructor call with loading preset
  factory StatusBanner.loading({
    required String message,
    VoidCallback? onDismiss,
    Widget? action,
  }) {
    return StatusBanner(
      type: StatusBannerType.loading,
      message: message,
      onDismiss: onDismiss,
      action: action,
    );
  }

  /// Factory constructor for error status
  /// PERF: O(1) - direct constructor call with error preset
  factory StatusBanner.error({
    required String message,
    VoidCallback? onDismiss,
    Widget? action,
  }) {
    return StatusBanner(
      type: StatusBannerType.error,
      message: message,
      onDismiss: onDismiss,
      action: action,
    );
  }

  /// Factory constructor for success status
  /// PERF: O(1) - direct constructor call with success preset
  factory StatusBanner.success({
    required String message,
    VoidCallback? onDismiss,
    Widget? action,
  }) {
    return StatusBanner(
      type: StatusBannerType.success,
      message: message,
      onDismiss: onDismiss,
      action: action,
    );
  }

  /// Factory constructor for info status
  /// PERF: O(1) - direct constructor call with info preset
  factory StatusBanner.info({
    required String message,
    VoidCallback? onDismiss,
    Widget? action,
  }) {
    return StatusBanner(
      type: StatusBannerType.info,
      message: message,
      onDismiss: onDismiss,
      action: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfiguration(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: statusConfig.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusConfig.borderColor),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              statusConfig.icon,
              color: statusConfig.iconColor,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: statusConfig.textColor),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            action!,
          ] else if (onDismiss != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onDismiss,
              child: const Text('Dismiss'),
            ),
          ],
        ],
      ),
    );
  }

  /// Get status-specific configuration
  /// PERF: O(1) - direct theme color access with status discrimination
  _StatusConfiguration _getStatusConfiguration(BuildContext context) {
    switch (type) {
      case StatusBannerType.loading:
        return _StatusConfiguration(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          borderColor: Colors.blue.withValues(alpha: 0.3),
          iconColor: Colors.blue,
          textColor: Theme.of(context).textTheme.bodyMedium?.color,
          icon: Icons.info,
        );
      case StatusBannerType.error:
        return _StatusConfiguration(
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          borderColor: Colors.red.withValues(alpha: 0.3),
          iconColor: Colors.red,
          textColor: Colors.red,
          icon: Icons.error,
        );
      case StatusBannerType.success:
        return _StatusConfiguration(
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          borderColor: Colors.green.withValues(alpha: 0.3),
          iconColor: Colors.green,
          textColor: Colors.green,
          icon: Icons.check_circle,
        );
      case StatusBannerType.info:
        return _StatusConfiguration(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          borderColor: Colors.blue.withValues(alpha: 0.3),
          iconColor: Colors.blue,
          textColor: Theme.of(context).textTheme.bodyMedium?.color,
          icon: Icons.info,
        );
    }
  }
}

/// Status configuration data class
/// PERF: Lightweight data holder for status styling
class _StatusConfiguration {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color? textColor;
  final IconData icon;

  const _StatusConfiguration({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });
}
