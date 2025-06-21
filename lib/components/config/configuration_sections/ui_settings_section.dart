import 'package:flutter/material.dart';
import 'package:vibe_coder/models/agent_configuration.dart';
import 'package:vibe_coder/components/config/configuration_fields/configuration_text_area.dart';

/// UiSettingsSection - User Interface Configuration Component
///
/// ## MISSION ACCOMPLISHED
/// Eliminates hardcoded UI behavior by providing user control over interface
/// preferences like timestamps, scrolling, and welcome messages.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Basic Toggles | Simple | Limited options | Rejected - users want control |
/// | Advanced Controls | Flexible | Complex UI | CHOSEN - power user features |
/// | Preset Themes | Easy | Inflexible | Rejected - one-size-fits-none |
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Toggle updates: O(1) - direct boolean changes
/// - Text updates: O(1) - direct string updates
/// - Configuration updates: O(1) - copyWith pattern
class UiSettingsSection extends StatelessWidget {
  final AgentConfiguration configuration;
  final Map<String, String> validationErrors;
  final Function(AgentConfiguration) onConfigurationChanged;

  const UiSettingsSection({
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
                const Icon(Icons.palette, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'User Interface Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Show Timestamps Toggle
            SwitchListTile(
              title: const Text('Show Message Timestamps'),
              subtitle: const Text('Display time for each message'),
              value: configuration.showTimestamps,
              onChanged: (value) => _updateShowTimestamps(value),
              secondary: const Icon(Icons.schedule),
            ),

            const Divider(),

            // Auto Scroll Toggle
            SwitchListTile(
              title: const Text('Auto-scroll to New Messages'),
              subtitle:
                  const Text('Automatically scroll when new messages arrive'),
              value: configuration.autoScroll,
              onChanged: (value) => _updateAutoScroll(value),
              secondary: const Icon(Icons.vertical_align_bottom),
            ),

            const Divider(),

            const SizedBox(height: 16),

            // Welcome Message Field
            ConfigurationTextArea(
              label: 'Welcome Message',
              value: configuration.welcomeMessage,
              onChanged: (value) => _updateWelcomeMessage(value),
              errorText: _getFieldError('welcomeMessage'),
              helpText:
                  'The greeting message shown when starting a new conversation',
              maxLines: 8,
              minLines: 4,
              maxLength: 1000,
              prefixIcon: Icons.waving_hand,
            ),

            const SizedBox(height: 16),

            // UI Configuration Tips
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates,
                          color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'UI Personalization Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Use Markdown formatting in welcome messages (**bold**, *italic*)\n'
                    '• Keep welcome messages concise but informative\n'
                    '• Timestamps help track conversation flow\n'
                    '• Auto-scroll improves user experience during long responses\n'
                    '• Welcome messages set the tone for your AI assistant',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Update show timestamps setting
  ///
  /// PERF: O(1) - direct boolean update
  void _updateShowTimestamps(bool value) {
    configuration.showTimestamps = value;
    onConfigurationChanged(configuration);
  }

  /// Update auto scroll setting
  ///
  /// PERF: O(1) - direct boolean update
  void _updateAutoScroll(bool value) {
    configuration.autoScroll = value;
    onConfigurationChanged(configuration);
  }

  /// Update welcome message
  ///
  /// PERF: O(1) - direct string update
  void _updateWelcomeMessage(String value) {
    configuration.welcomeMessage = value;
    onConfigurationChanged(configuration);
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
}
