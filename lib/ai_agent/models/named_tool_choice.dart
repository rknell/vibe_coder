import 'package:vibe_coder/ai_agent/models/function_tool.dart';

/// Represents a named tool choice configuration.
class NamedToolChoice {
  /// The type of the tool. Currently, only "function" is supported.
  final String type;

  /// The function configuration.
  final FunctionTool function;

  NamedToolChoice({required this.function}) : type = 'function';

  Map<String, dynamic> toJson() => {
        'type': type,
        'function': function.toJson(),
      };
}
