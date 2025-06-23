import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibe_coder/models/agent_configuration.dart';
import 'package:vibe_coder/services/configuration_service.dart';
import 'package:vibe_coder/components/config/configuration_sections/agent_settings_section.dart';
import 'package:vibe_coder/components/config/configuration_sections/ai_model_settings_section.dart';
import 'package:vibe_coder/components/config/configuration_sections/ui_settings_section.dart';
import 'package:vibe_coder/components/config/configuration_sections/advanced_settings_section.dart';
import 'package:vibe_coder/components/config/configuration_actions/configuration_actions_bar.dart';

/// AgentConfigurationScreen - Universal Configuration Management UI
///
/// ## MISSION ACCOMPLISHED
/// Eliminates hardcoded agent settings by providing comprehensive, user-friendly configuration interface.
/// Follows Flutter architecture rules with proper component extraction and no functional builders.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Single Mega Widget | Simple | Unmaintainable | ELIMINATED - violates architecture |
/// | Functional Builders | Quick | Not reusable | ELIMINATED - violates Flutter rules |
/// | Component Extraction | Maintainable | More files | CHOSEN - architectural excellence |
/// | Settings UI Package | Fast | Limited control | Rejected - need custom validation |
///
/// ## BOSS FIGHTS DEFEATED
/// 1. **Functional Widget Architecture Violation**
///    - 🔍 Symptom: `_buildSettingsSection()` methods everywhere
///    - 🎯 Root Cause: Lazy UI construction patterns
///    - 💥 Kill Shot: Extracted all sections to proper components
///
/// 2. **Configuration Chaos Management**
///    - 🔍 Symptom: Scattered configuration UI elements
///    - 🎯 Root Cause: No centralized configuration interface
///    - 💥 Kill Shot: Organized settings into logical sections with validation
///
/// 3. **User Experience Complexity**
///    - 🔍 Symptom: Users confused by advanced settings
///    - 🎯 Root Cause: Poor information architecture
///    - 💥 Kill Shot: Sectioned interface with progressive disclosure
///
/// ## PERFORMANCE CHARACTERISTICS
/// - UI updates: O(1) - direct widget updates with proper keys
/// - Validation: O(1) per field - immediate feedback
/// - Persistence: O(1) - atomic configuration updates
class AgentConfigurationScreen extends StatefulWidget {
  final ConfigurationService configurationService;
  final AgentConfiguration initialConfiguration;
  final VoidCallback? onConfigurationChanged;

  const AgentConfigurationScreen({
    super.key,
    required this.configurationService,
    required this.initialConfiguration,
    this.onConfigurationChanged,
  });

  @override
  State<AgentConfigurationScreen> createState() =>
      _AgentConfigurationScreenState();
}

class _AgentConfigurationScreenState extends State<AgentConfigurationScreen> {
  AgentConfiguration?
      _workingConfiguration; // WARRIOR PROTOCOL: Nullable instead of late to eliminate vulnerability
  final Map<String, String> _validationErrors = {};
  bool _hasUnsavedChanges = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _workingConfiguration = widget.initialConfiguration;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Configuration'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleClose(),
        ),
        actions: [
          if (_hasUnsavedChanges)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () => _resetToOriginal(),
              tooltip: 'Reset Changes',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Configuration sections
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Agent Settings Section
                        if (_workingConfiguration != null) ...[
                          (() {
                            final workingConfiguration = _workingConfiguration;
                            if (workingConfiguration != null) {
                              return AgentSettingsSection(
                                configuration: workingConfiguration,
                                validationErrors: _validationErrors,
                                onConfigurationChanged:
                                    _handleConfigurationUpdate,
                              );
                            }
                            return const SizedBox.shrink();
                          })(),
                          const SizedBox(height: 24),

                          // AI Model Settings Section
                          (() {
                            final workingConfiguration = _workingConfiguration;
                            if (workingConfiguration != null) {
                              return AiModelSettingsSection(
                                configuration: workingConfiguration,
                                validationErrors: _validationErrors,
                                onConfigurationChanged:
                                    _handleConfigurationUpdate,
                              );
                            }
                            return const SizedBox.shrink();
                          })(),
                          const SizedBox(height: 24),

                          // UI Settings Section
                          (() {
                            final workingConfiguration = _workingConfiguration;
                            if (workingConfiguration != null) {
                              return UiSettingsSection(
                                configuration: workingConfiguration,
                                validationErrors: _validationErrors,
                                onConfigurationChanged:
                                    _handleConfigurationUpdate,
                              );
                            }
                            return const SizedBox.shrink();
                          })(),
                          const SizedBox(height: 24),

                          // Advanced Settings Section
                          (() {
                            final workingConfiguration = _workingConfiguration;
                            if (workingConfiguration != null) {
                              return AdvancedSettingsSection(
                                configuration: workingConfiguration,
                                validationErrors: _validationErrors,
                                onConfigurationChanged:
                                    _handleConfigurationUpdate,
                              );
                            }
                            return const SizedBox.shrink();
                          })(),
                        ],

                        const SizedBox(
                            height: 80), // Space for floating action bar
                      ],
                    ),
                  ),
                ),

                // Configuration Actions Bar
                ConfigurationActionsBar(
                  hasUnsavedChanges: _hasUnsavedChanges,
                  hasValidationErrors: _validationErrors.isNotEmpty,
                  isLoading: _isLoading,
                  onSave: () => _saveConfiguration(),
                  onReset: () => _resetToDefaults(),
                  onExport: () => _exportConfiguration(),
                  onImport: () => _importConfiguration(),
                ),
              ],
            ),
    );
  }

  /// Handle configuration updates with validation
  ///
  /// PERF: O(1) - direct property updates with validation
  /// ARCHITECTURAL: Immediate validation feedback prevents invalid states
  void _handleConfigurationUpdate(AgentConfiguration newConfiguration) {
    setState(() {
      _workingConfiguration = newConfiguration;
      _hasUnsavedChanges = _workingConfiguration != widget.initialConfiguration;

      // Clear existing validation errors
      _validationErrors.clear();

      // Validate new configuration
      final validationErrors = newConfiguration.validate();
      for (int i = 0; i < validationErrors.length; i++) {
        final error = validationErrors[i];
        _validationErrors['validation_$i'] = error;
      }
    });
  }

  /// Save configuration with user feedback
  ///
  /// PERF: O(1) - atomic configuration save operation
  /// UI/UX: Provides immediate feedback and error handling
  Future<void> _saveConfiguration() async {
    if (_validationErrors.isNotEmpty) {
      _showErrorSnackBar('Please fix validation errors before saving');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final workingConfiguration = _workingConfiguration;
      if (workingConfiguration == null) {
        _showErrorSnackBar('No configuration to save');
        return;
      }

      final result = await widget.configurationService
          .updateConfiguration(workingConfiguration);

      if (result.isSuccess) {
        setState(() {
          _hasUnsavedChanges = false;
        });

        _showSuccessSnackBar('Configuration saved successfully');

        // Notify parent about configuration change
        widget.onConfigurationChanged?.call();

        // Return to previous screen
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
      } else {
        _showErrorSnackBar(result.displayMessage);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save configuration: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Reset to default configuration
  ///
  /// PERF: O(1) - creates new default instance
  Future<void> _resetToDefaults() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Reset to Defaults',
      content:
          'Are you sure you want to reset all settings to default values? This action cannot be undone.',
      confirmText: 'Reset',
      isDestructive: true,
    );

    if (confirmed == true) {
      setState(() {
        _workingConfiguration = AgentConfiguration.createDefault();
        _hasUnsavedChanges =
            _workingConfiguration != widget.initialConfiguration;
        _validationErrors.clear();
      });

      _showInfoSnackBar('Configuration reset to defaults');
    }
  }

  /// Reset to original configuration
  ///
  /// PERF: O(1) - direct object assignment
  void _resetToOriginal() {
    setState(() {
      _workingConfiguration = widget.initialConfiguration;
      _hasUnsavedChanges = false;
      _validationErrors.clear();
    });

    _showInfoSnackBar('Changes reverted');
  }

  /// Export configuration to clipboard
  ///
  /// PERF: O(1) - JSON serialization with clipboard copy
  Future<void> _exportConfiguration() async {
    try {
      final configJson = widget.configurationService.exportConfiguration();
      await Clipboard.setData(ClipboardData(text: configJson));
      _showSuccessSnackBar('Configuration exported to clipboard');
    } catch (e) {
      _showErrorSnackBar('Failed to export configuration: $e');
    }
  }

  /// Import configuration from clipboard
  ///
  /// PERF: O(1) - clipboard read with JSON parsing
  Future<void> _importConfiguration() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final jsonString = clipboardData?.text;

      if (jsonString == null || jsonString.trim().isEmpty) {
        _showErrorSnackBar('No configuration data found in clipboard');
        return;
      }

      final confirmed = await _showConfirmationDialog(
        title: 'Import Configuration',
        content:
            'Are you sure you want to import configuration from clipboard? This will replace current settings.',
        confirmText: 'Import',
        isDestructive: true,
      );

      if (confirmed == true) {
        final result =
            await widget.configurationService.importConfiguration(jsonString);

        if (result.isSuccess) {
          setState(() {
            _workingConfiguration = widget.configurationService.currentConfig;
            _hasUnsavedChanges =
                _workingConfiguration != widget.initialConfiguration;
            _validationErrors.clear();
          });

          _showSuccessSnackBar('Configuration imported successfully');
        } else {
          _showErrorSnackBar(result.displayMessage);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to import configuration: $e');
    }
  }

  /// Handle screen close with unsaved changes check
  ///
  /// PERF: O(1) - simple state check
  /// UI/UX: Prevents accidental loss of unsaved changes
  Future<void> _handleClose() async {
    if (_hasUnsavedChanges) {
      final shouldDiscard = await _showConfirmationDialog(
        title: 'Unsaved Changes',
        content:
            'You have unsaved changes. Are you sure you want to close without saving?',
        confirmText: 'Discard',
        isDestructive: true,
      );

      if (shouldDiscard == true && context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
    } else if (context.mounted) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    }
  }

  /// Show confirmation dialog for destructive actions
  ///
  /// PERF: O(1) - simple dialog display
  /// UI/UX: Consistent confirmation pattern across app
  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Show success feedback to user
  ///
  /// PERF: O(1) - immediate UI feedback
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error feedback to user
  ///
  /// PERF: O(1) - immediate UI feedback
  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show info feedback to user
  ///
  /// PERF: O(1) - immediate UI feedback
  void _showInfoSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
