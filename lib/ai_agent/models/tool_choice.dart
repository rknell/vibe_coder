import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:vibe_coder/ai_agent/models/function_tool.dart';
import 'package:vibe_coder/ai_agent/models/named_tool_choice.dart';

/// Represents the tool choice configuration for chat completion requests.
///
/// The tool choice can be specified in two formats:
/// 1. A [ToolChoiceType] enum value: none, auto, or required (serialized as a string)
/// 2. A [NamedToolChoice] object specifying a particular function tool (serialized as an object)
///
/// For DeepSeek API compatibility, the string case must be serialized as a plain string, not an object.
class ToolChoice {
  /// The tool choice value, either a [ToolChoiceType] enum value
  /// or a [NamedToolChoice] object
  ///
  /// Throws [AssertionError] if the value is invalid.
  final dynamic value;

  /// Creates a new instance of [ToolChoice].
  ///
  /// [value] can be either:
  /// - A [ToolChoiceType] enum value
  /// - A [NamedToolChoice] object
  ///
  /// Throws [AssertionError] if the value is invalid.
  ToolChoice(this.value) {
    assert(
      value is ToolChoiceType || value is NamedToolChoice,
      'ToolChoice value must be either a ToolChoiceType enum or a NamedToolChoice object',
    );
  }

  /// Creates a ToolChoice that forces the model to not call any tools.
  static ToolChoice get none => ToolChoice(ToolChoiceType.none);

  /// Creates a ToolChoice that allows the model to pick between generating a message or calling tools.
  static ToolChoice get auto => ToolChoice(ToolChoiceType.auto);

  /// Creates a ToolChoice that forces the model to call one or more tools.
  static ToolChoice get required => ToolChoice(ToolChoiceType.required);

  /// Creates a ToolChoice that forces the model to call a specific function.
  static ToolChoice function(String functionName) => ToolChoice(
        NamedToolChoice(function: FunctionTool(name: functionName)),
      );

  /// Returns a value suitable for JSON serialization (string or object).
  dynamic toJson() {
    if (value is ToolChoiceType) {
      return value.toString().split('.').last;
    } else if (value is NamedToolChoice) {
      return (value as NamedToolChoice).toJson();
    }
    throw AssertionError('Invalid ToolChoice value type');
  }
}
