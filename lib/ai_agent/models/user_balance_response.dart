import 'package:vibe_coder/ai_agent/models/balance_info.dart';

/// Represents the response from the user balance endpoint
class UserBalanceResponse {
  final bool isAvailable;
  final List<BalanceInfo> balanceInfos;

  UserBalanceResponse({
    required this.isAvailable,
    required this.balanceInfos,
  });

  factory UserBalanceResponse.fromJson(Map<String, dynamic> json) {
    return UserBalanceResponse(
      isAvailable: json['is_available'] as bool,
      balanceInfos: (json['balance_infos'] as List)
          .map((b) => BalanceInfo.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }
}
