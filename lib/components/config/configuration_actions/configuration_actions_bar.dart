import 'package:flutter/material.dart';

/// ConfigurationActionsBar - Configuration Management Actions Component
///
/// ## MISSION ACCOMPLISHED
/// Eliminates scattered action buttons by providing centralized configuration
/// management controls with clear state indicators and user feedback.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Floating Actions | Prominent | Screen space | Rejected - too intrusive |
/// | Bottom Bar | Always visible | Fixed position | CHOSEN - consistent access |
/// | Menu Actions | Clean UI | Hidden | Rejected - discoverability issues |
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Button states: O(1) - direct boolean checks
/// - Action triggers: O(1) - callback delegation
/// - UI updates: O(1) - stateless widget rebuilds
class ConfigurationActionsBar extends StatelessWidget {
  final bool hasUnsavedChanges;
  final bool hasValidationErrors;
  final bool isLoading;
  final VoidCallback onSave;
  final VoidCallback onReset;
  final VoidCallback onExport;
  final VoidCallback onImport;

  const ConfigurationActionsBar({
    super.key,
    required this.hasUnsavedChanges,
    required this.hasValidationErrors,
    required this.isLoading,
    required this.onSave,
    required this.onReset,
    required this.onExport,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Indicator
            if (hasUnsavedChanges || hasValidationErrors) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasValidationErrors
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasValidationErrors
                        ? Colors.red.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasValidationErrors ? Icons.error : Icons.edit,
                      size: 16,
                      color: hasValidationErrors
                          ? Colors.red[700]
                          : Colors.orange[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasValidationErrors
                          ? 'Configuration has errors'
                          : 'Unsaved changes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasValidationErrors
                            ? Colors.red[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            Row(
              children: [
                // Save Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: isLoading || hasValidationErrors ? null : onSave,
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(isLoading ? 'Saving...' : 'Save Configuration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasUnsavedChanges && !hasValidationErrors
                          ? Colors.blue
                          : null,
                      foregroundColor: hasUnsavedChanges && !hasValidationErrors
                          ? Colors.white
                          : null,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Reset Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : onReset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Export Button
                IconButton(
                  onPressed: isLoading ? null : onExport,
                  icon: const Icon(Icons.file_upload),
                  tooltip: 'Export Configuration',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(width: 4),

                // Import Button
                IconButton(
                  onPressed: isLoading ? null : onImport,
                  icon: const Icon(Icons.file_download),
                  tooltip: 'Import Configuration',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),

            // Help Text
            if (!hasUnsavedChanges && !hasValidationErrors) ...[
              const SizedBox(height: 8),
              Text(
                'Use Export/Import to share configurations between devices',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
