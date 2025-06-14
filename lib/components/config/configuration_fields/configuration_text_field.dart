import 'package:flutter/material.dart';

/// ConfigurationTextField - Reusable Configuration Input Component
///
/// ## MISSION ACCOMPLISHED
/// Eliminates inconsistent text field implementations by providing standardized
/// configuration input with validation, help text, and accessibility support.
///
/// ## STRATEGIC DECISIONS
/// | Option | Power-Ups | Weaknesses | Victory Reason |
/// |--------|-----------|------------|----------------|
/// | Basic TextField | Simple | No consistency | Rejected - no standard styling |
/// | TextFormField | Validation | Form dependency | Rejected - too heavy |
/// | Custom Component | Reusable | Development time | CHOSEN - consistent UX |
///
/// ## PERFORMANCE CHARACTERISTICS
/// - Text updates: O(1) - direct callback delegation
/// - Validation: O(1) - immediate error display
/// - Rendering: O(1) - simple widget composition
class ConfigurationTextField extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onChanged;
  final String? errorText;
  final String? helpText;
  final int? maxLength;
  final IconData? prefixIcon;
  final bool isRequired;
  final TextInputType keyboardType;

  const ConfigurationTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.helpText,
    this.maxLength,
    this.prefixIcon,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

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

        // Text Field
        TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value.length),
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLength: maxLength,
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
          ),
        ),

        // Help text and character count
        if (helpText != null || maxLength != null) ...[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (helpText != null) ...[
                Expanded(
                  child: Text(
                    helpText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ),
              ],
              if (maxLength != null) ...[
                Text(
                  '${value.length}/${maxLength!}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: value.length > maxLength! * 0.9
                            ? Colors.orange[700]
                            : Colors.grey[600],
                      ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
