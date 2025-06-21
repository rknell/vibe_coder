import 'package:flutter/material.dart';
import 'package:vibe_coder/models/agent_configuration.dart';

/// AiModelSettingsSection - AI Model Configuration Component
///
/// ## MISSION ACCOMPLISHED
/// Eliminates hardcoded AI model parameters by providing user-configurable
/// temperature, token limits, and model feature toggles.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Basic Controls | Simple | Limited control | Rejected - users need precision |
/// | Advanced Sliders | Precise | Complex | CHOSEN - power user features |
/// | Preset Options | Easy | Inflexible | Rejected - one-size-fits-none |
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Slider updates: O(1) - direct value updates
/// - Switch toggles: O(1) - boolean state changes
/// - Configuration updates: O(1) - copyWith pattern
class AiModelSettingsSection extends StatelessWidget {
  final AgentConfiguration configuration;
  final Map<String, String> validationErrors;
  final Function(AgentConfiguration) onConfigurationChanged;

  const AiModelSettingsSection({
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
                const Icon(Icons.psychology, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'AI Model Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Beta Features Toggle
            SwitchListTile(
              title: const Text('Enable Beta Features'),
              subtitle: const Text('Access to experimental AI capabilities'),
              value: configuration.useBetaFeatures,
              onChanged: (value) => _updateBetaFeatures(value),
              secondary: const Icon(Icons.science),
            ),

            const Divider(),

            // Reasoner Model Toggle
            SwitchListTile(
              title: const Text('Use Reasoner Model'),
              subtitle: const Text('Advanced reasoning with chain-of-thought'),
              value: configuration.useReasonerModel,
              onChanged: (value) => _updateReasonerModel(value),
              secondary: const Icon(Icons.auto_awesome),
            ),

            const Divider(),

            // Temperature Control
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.thermostat, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Temperature: ${configuration.temperature.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: configuration.temperature,
                  min: 0.0,
                  max: 2.0,
                  divisions: 20,
                  onChanged: (value) => _updateTemperature(value),
                ),
                Text(
                  'Controls randomness: Lower = more focused, Higher = more creative',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Max Tokens Control
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_list_numbered, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Max Tokens: ${configuration.maxTokens}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: configuration.maxTokens.toDouble(),
                  min: 100,
                  max: 32000,
                  divisions: 100,
                  onChanged: (value) => _updateMaxTokens(value.round()),
                ),
                Text(
                  'Maximum response length (roughly 1 token = 0.75 words)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Model Configuration Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.purple[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Model Configuration Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Temperature 0.0-0.3: Focused, deterministic responses\n'
                    '• Temperature 0.4-0.7: Balanced creativity and consistency\n'
                    '• Temperature 0.8-2.0: Highly creative, varied responses\n'
                    '• Higher token limits allow longer, more detailed responses\n'
                    '• Beta features may be unstable but offer cutting-edge capabilities',
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

  /// Update beta features setting
  ///
  /// PERF: O(1) - direct boolean update
  void _updateBetaFeatures(bool value) {
    configuration.useBetaFeatures = value;
    onConfigurationChanged(configuration);
  }

  /// Update reasoner model setting
  ///
  /// PERF: O(1) - direct boolean update
  void _updateReasonerModel(bool value) {
    configuration.useReasonerModel = value;
    onConfigurationChanged(configuration);
  }

  /// Update temperature setting
  ///
  /// PERF: O(1) - direct double update
  void _updateTemperature(double value) {
    configuration.temperature = value;
    onConfigurationChanged(configuration);
  }

  /// Update max tokens setting
  ///
  /// PERF: O(1) - direct integer update
  void _updateMaxTokens(int value) {
    configuration.maxTokens = value;
    onConfigurationChanged(configuration);
  }
}
