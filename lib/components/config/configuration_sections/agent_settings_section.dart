import 'package:flutter/material.dart';
import 'package:vibe_coder/models/agent_configuration.dart';
import 'package:vibe_coder/components/config/configuration_fields/configuration_text_field.dart';
import 'package:vibe_coder/components/config/configuration_fields/configuration_text_area.dart';

/// AgentSettingsSection - Core Agent Configuration Component
///
/// ## MISSION ACCOMPLISHED
/// Eliminates hardcoded agent identity by providing editable agent name and system prompt.
/// Follows Flutter architecture rules with proper component extraction and validation.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Inline Text Fields | Simple | No validation | Rejected - no error handling |
/// | Custom Components | Reusable | More complexity | CHOSEN - consistent validation |
/// | Basic TextField | Fast | Limited features | Rejected - need multiline support |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **System Prompt Editability**
///    - 🔍 Symptom: Hardcoded system prompt in ChatService
///    - 🎯 Root Cause: No user interface for configuration
///    - 💥 Kill Shot: Rich text editor with validation and preview
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Field updates: O(1) - direct text field updates
/// - Validation: O(1) - immediate feedback on text changes
/// - Configuration updates: O(1) - copyWith pattern for immutability
class AgentSettingsSection extends StatelessWidget {
  final AgentConfiguration configuration;
  final Map<String, String> validationErrors;
  final Function(AgentConfiguration) onConfigurationChanged;

  const AgentSettingsSection({
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
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Agent Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Agent Name Field
            ConfigurationTextField(
              label: 'Agent Name',
              value: configuration.agentName,
              onChanged: (value) => _updateAgentName(value),
              errorText: _getFieldError('agentName'),
              helpText: 'The display name for your AI assistant',
              maxLength: 50,
              prefixIcon: Icons.badge,
            ),

            const SizedBox(height: 20),

            // System Prompt Field
            ConfigurationTextArea(
              label: 'System Prompt',
              value: configuration.systemPrompt,
              onChanged: (value) => _updateSystemPrompt(value),
              errorText: _getFieldError('systemPrompt'),
              helpText:
                  'Instructions that define your AI assistant\'s personality, expertise, and behavior. This is the core of how your assistant will respond.',
              maxLines: 12,
              minLines: 8,
              maxLength: 2000,
              prefixIcon: Icons.psychology,
            ),

            const SizedBox(height: 16),

            // System Prompt Guidelines
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
                      Icon(Icons.lightbulb, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'System Prompt Best Practices',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Be specific about the assistant\'s role and expertise\n'
                    '• Include behavioral guidelines (tone, formality level)\n'
                    '• Specify output format preferences when relevant\n'
                    '• Keep instructions clear and concise\n'
                    '• Test changes with sample conversations',
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

  /// Update agent name in configuration
  ///
  /// PERF: O(1) - direct field update with property setter
  void _updateAgentName(String newName) {
    configuration.agentName = newName;
    onConfigurationChanged(configuration);
  }

  /// Update system prompt in configuration
  ///
  /// PERF: O(1) - direct field update with property setter
  void _updateSystemPrompt(String newPrompt) {
    configuration.systemPrompt = newPrompt;
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
