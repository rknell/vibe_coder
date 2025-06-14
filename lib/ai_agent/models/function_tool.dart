/// Represents a function tool configuration.
class FunctionTool {
  /// The name of the function to call.
  final String name;

  FunctionTool({required this.name});

  Map<String, dynamic> toJson() => {'name': name};
}
