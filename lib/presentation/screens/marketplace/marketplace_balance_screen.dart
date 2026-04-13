import 'package:flutter/material.dart';

import '../../../core/services/marketplace_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';

class MarketplaceBalanceScreen extends StatefulWidget {
  const MarketplaceBalanceScreen({super.key, required this.service});

  final MarketplaceService service;

  @override
  State<MarketplaceBalanceScreen> createState() =>
      _MarketplaceBalanceScreenState();
}

class _MarketplaceBalanceScreenState extends State<MarketplaceBalanceScreen> {
  Map<String, dynamic>? _walletData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final wallet = await widget.service.getMyWallet();
      if (!mounted) return;
      setState(() {
        _walletData = wallet;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _money(dynamic value) {
    final n = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return n.toStringAsFixed(2);
  }

  String _shortAddress(String? value) {
    if (value == null || value.isEmpty) return 'Not connected';
    if (value.length < 12) return value;
    return '${value.substring(0, 8)}...${value.substring(value.length - 6)}';
  }

  Future<void> _showTopupDialog() async {
    final pageContext = context;
    final amountController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Top up balance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'e.g. 50',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) return;
                Navigator.of(context).pop();
                try {
                  await widget.service.topup(amount: amount);
                  if (!mounted) return;
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    const SnackBar(content: Text('Top up completed')),
                  );
                  await _loadWallet();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    pageContext,
                  ).showSnackBar(SnackBar(content: Text('Top up failed: $e')));
                }
              },
              child: const Text('Top up'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showWithdrawDialog() async {
    final pageContext = context;
    final amountController = TextEditingController();
    final addrController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Withdraw'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'e.g. 10',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addrController,
                decoration: const InputDecoration(
                  labelText: 'Destination wallet (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) return;
                final destinationAddress = addrController.text.trim();
                if (destinationAddress.isEmpty) {
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Destination wallet is required for on-chain withdraw',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop();
                try {
                  final result = await widget.service.withdraw(
                    amount: amount,
                    destinationAddress: destinationAddress,
                    tokenType: 'USDC',
                  );
                  if (!mounted) return;
                  final txHash = (result['txHash'] ?? '').toString();
                  final token = (result['tokenType'] ?? 'USDC').toString();
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        txHash.isNotEmpty
                            ? 'Withdraw sent on-chain ($token): $txHash'
                            : 'Withdraw completed ($token)',
                      ),
                    ),
                  );
                  await _loadWallet();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(content: Text('Withdraw failed: $e')),
                  );
                }
              },
              child: const Text('Withdraw'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;

    final wallet = _walletData?['wallet'] as Map<String, dynamic>?;
    final txs =
        (_walletData?['transactions'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>();

    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace Balance')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: TextStyle(color: AppColors.error)),
            )
          : RefreshIndicator(
              onRefresh: _loadWallet,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.borderColor.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Balance',
                          style: TextStyle(color: textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_money(wallet?['availableBalance'])} ${wallet?['currency'] ?? 'USDC'}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Wallet: ${_shortAddress(wallet?['walletAddress']?.toString())}',
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _showTopupDialog,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Top up'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showWithdrawDialog,
                          icon: const Icon(Icons.call_made_rounded),
                          label: const Text('Withdraw'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (txs.isEmpty)
                    Text(
                      'No transactions yet',
                      style: TextStyle(color: textSecondary),
                    )
                  else
                    ...txs.map((tx) {
                      final type = (tx['type'] ?? '').toString();
                      final amount = _money(tx['amount']);
                      final created = (tx['createdAt'] ?? '').toString();
                      final status = (tx['status'] ?? '').toString();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(type.toUpperCase()),
                        subtitle: Text(created),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$amount ${tx['currency'] ?? ''}'),
                            Text(
                              status,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
