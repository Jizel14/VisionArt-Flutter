class TokenBalanceModel {
  const TokenBalanceModel({
    required this.symbol,
    required this.contractAddress,
    required this.balance,
    required this.decimals,
  });

  final String symbol;
  final String contractAddress;
  final String balance;
  final int decimals;

  factory TokenBalanceModel.fromJson(Map<String, dynamic> json) {
    return TokenBalanceModel(
      symbol: (json['symbol'] ?? '').toString(),
      contractAddress: (json['contractAddress'] ?? '').toString(),
      balance: (json['balance'] ?? '0').toString(),
      decimals: (json['decimals'] as num?)?.toInt() ?? 0,
    );
  }
}

class WalletBalanceModel {
  const WalletBalanceModel({
    required this.address,
    required this.chainId,
    required this.nativeSymbol,
    required this.nativeBalance,
    required this.tokens,
  });

  final String address;
  final int chainId;
  final String nativeSymbol;
  final String nativeBalance;
  final List<TokenBalanceModel> tokens;

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    final native =
        json['native'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final rawTokens = json['tokens'] as List<dynamic>? ?? const <dynamic>[];

    return WalletBalanceModel(
      address: (json['address'] ?? '').toString(),
      chainId: (json['chainId'] as num?)?.toInt() ?? 0,
      nativeSymbol: (native['symbol'] ?? '').toString(),
      nativeBalance: (native['balance'] ?? '0').toString(),
      tokens: rawTokens
          .map(
            (item) => TokenBalanceModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
