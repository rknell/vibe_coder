import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';

Map<String, dynamic> safeCastToStringDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return {};
}

MessageRole roleFromString(String role) {
  return MessageRole.values.firstWhere(
    (r) => r.toString().split('.').last == role,
  );
}
