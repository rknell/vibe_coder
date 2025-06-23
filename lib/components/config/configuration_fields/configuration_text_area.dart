import 'package:flutter/material.dart';

/// ConfigurationTextArea - Reusable Multiline Configuration Input Component
///
/// ## MISSION ACCOMPLISHED
/// Eliminates inconsistent multiline text field implementations by providing standardized
/// text area with validation, help text, and proper sizing controls.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Basic TextField | Simple | No multiline control | Rejected - inadequate |
/// | TextFormField | Validation | Form dependency | Rejected - too heavy |
/// | Custom Component | Flexible | Development time | CHOSEN - perfect fit |
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Text updates: O(1) - direct callback delegation
/// - Validation: O(1) - immediate error display
/// - Auto-sizing: O(1) - Flutter's intrinsic sizing
class ConfigurationTextArea extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onChanged;
  final String? errorText;
  final String? helpText;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final IconData? prefixIcon;
  final bool isRequired;

  const ConfigurationTextArea({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.helpText,
    this.maxLength,
    this.maxLines,
    this.minLines,
    this.prefixIcon,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorTextValue = errorText;
    final hasError = errorTextValue != null && errorTextValue.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with required indicator
        Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasError ? Colors.red[700] : null,
                  ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 8),

        // Text Area
        TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value.length),
          onChanged: onChanged,
          keyboardType: TextInputType.multiline,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: minLines,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            errorText: hasError ? errorText : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.blue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            counterText: '', // Hide default counter
            alignLabelWithHint: true,
          ),
        ),

        // Help text and character count
        if (helpText != null || maxLength != null) ...[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (helpText != null) ...[
                (() {
                  final helpTextValue = helpText;
                  if (helpTextValue != null) {
                    return Expanded(
                      child: Text(
                        helpTextValue,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                })(),
              ],
              if (maxLength != null) ...[
                const SizedBox(width: 8),
                (() {
                  final maxLengthValue = maxLength;
                  if (maxLengthValue != null) {
                    return Text(
                      '${value.length}/$maxLengthValue',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: value.length > maxLengthValue * 0.9
                                ? Colors.orange[700]
                                : Colors.grey[600],
                            fontWeight: value.length > maxLengthValue * 0.9
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                    );
                  }
                  return const SizedBox.shrink();
                })(),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
