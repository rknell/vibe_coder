import 'package:flutter/material.dart';
import 'package:vibe_coder/models/agent_configuration.dart';
import 'package:vibe_coder/components/config/configuration_fields/configuration_text_field.dart';

/// AdvancedSettingsSection - Power User Configuration Component
///
/// ## MISSION ACCOMPLISHED
/// Eliminates hidden configuration options by exposing advanced settings
/// for debugging, performance tuning, and technical configuration.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Hidden Settings | Simple UI | No user control | Rejected - power users need access |
/// | Developer Only | Full control | User complexity | Rejected - discriminates users |
/// | Advanced Section | Flexible | Potentially complex | CHOSEN - progressive disclosure |
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Setting updates: O(1) - direct property updates
/// - Validation: O(1) - immediate range checks
/// - Configuration updates: O(1) - copyWith pattern
class AdvancedSettingsSection extends StatelessWidget {
  final AgentConfiguration configuration;
  final Map<String, String> validationErrors;
  final Function(AgentConfiguration) onConfigurationChanged;

  const AdvancedSettingsSection({
    super.key,
    required this.configuration,
    required this.validationErrors,
    required this.onConfigurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                const Icon(Icons.settings_applications, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Advanced Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Debug Logging Toggle
            SwitchListTile(
              title: const Text('Enable Debug Logging'),
              subtitle: const Text('Detailed logging for troubleshooting'),
              value: configuration.enableDebugLogging,
              onChanged: (value) => _updateDebugLogging(value),
              secondary: const Icon(Icons.bug_report),
            ),

            const Divider(),

            const SizedBox(height: 16),

            // Max Conversation History Control
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Max Conversation History: ${configuration.maxConversationHistory}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: configuration.maxConversationHistory.toDouble(),
                  min: 10,
                  max: 1000,
                  divisions: 99,
                  onChanged: (value) =>
                      _updateMaxConversationHistory(value.round()),
                ),
                Text(
                  'Number of messages to keep in memory (affects performance and context)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // MCP Config Path Field
            ConfigurationTextField(
              label: 'MCP Configuration Path',
              value: configuration.mcpConfigPath,
              onChanged: (value) => _updateMcpConfigPath(value),
              errorText: _getFieldError('mcpConfigPath'),
              helpText:
                  'Path to Model Context Protocol (MCP) configuration file',
              maxLength: 200,
              prefixIcon: Icons.integration_instructions,
            ),

            const SizedBox(height: 16),

            // Advanced Configuration Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Advanced Configuration Warning',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• These settings affect performance and stability\n'
                    '• Higher conversation history uses more memory\n'
                    '• Debug logging may impact performance\n'
                    '• Incorrect MCP paths will disable tool functionality\n'
                    '• Only modify if you understand the implications',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Performance Impact Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.speed, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Performance Guidelines',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Conversation History: ${_getPerformanceRecommendation()}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Update debug logging setting
  ///
  /// PERF: O(1) - direct boolean update
  void _updateDebugLogging(bool value) {
    final updatedConfig = configuration.copyWith(enableDebugLogging: value);
    onConfigurationChanged(updatedConfig);
  }

  /// Update max conversation history setting
  ///
  /// PERF: O(1) - direct integer update
  void _updateMaxConversationHistory(int value) {
    final updatedConfig = configuration.copyWith(maxConversationHistory: value);
    onConfigurationChanged(updatedConfig);
  }

  /// Update MCP config path
  ///
  /// PERF: O(1) - direct string update
  void _updateMcpConfigPath(String value) {
    final updatedConfig = configuration.copyWith(mcpConfigPath: value);
    onConfigurationChanged(updatedConfig);
  }

  /// Get validation error for specific field
  ///
  /// PERF: O(1) - map lookup
  String? _getFieldError(String fieldName) {
    // Check for field-specific validation errors
    final fieldError = validationErrors[fieldName];
    if (fieldError != null) return fieldError;

    // Check for general validation errors that mention this field
    for (final entry in validationErrors.entries) {
      if (entry.value.toLowerCase().contains(fieldName.toLowerCase())) {
        return entry.value;
      }
    }

    return null;
  }

  /// Get performance recommendation based on conversation history setting
  ///
  /// PERF: O(1) - simple range checks
  String _getPerformanceRecommendation() {
    final historySize = configuration.maxConversationHistory;
    if (historySize <= 50) {
      return 'Excellent performance, but limited context memory';
    } else if (historySize <= 100) {
      return 'Good balance of performance and context retention';
    } else if (historySize <= 200) {
      return 'Moderate performance impact, extended context memory';
    } else if (historySize <= 500) {
      return 'Higher memory usage, very long context retention';
    } else {
      return 'Significant performance impact, maximum context memory';
    }
  }
}
