import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';

/// Represents balance information for a specific currency
class BalanceInfo {
  final Currency currency;
  final String totalBalance;
  final String grantedBalance;
  final String toppedUpBalance;

  BalanceInfo({
    required this.currency,
    required this.totalBalance,
    required this.grantedBalance,
    required this.toppedUpBalance,
  });

  factory BalanceInfo.fromJson(Map<String, dynamic> json) {
    return BalanceInfo(
      currency: Currency.values.firstWhere(
        (c) => c.name.toUpperCase() == json['currency'] as String,
      ),
      totalBalance: json['total_balance'] as String,
      grantedBalance: json['granted_balance'] as String,
      toppedUpBalance: json['topped_up_balance'] as String,
    );
  }
}
