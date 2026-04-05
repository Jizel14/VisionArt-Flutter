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
  Map<String, dynamic>? _blockchainProof;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _verifyTxController = TextEditingController();
  Map<String, dynamic>? _verifyResult;
  bool _isVerifyingTx = false;
  bool _isReconcilingTx = false;
  bool _isLoadingBlockchainProof = false;

  @override
  void dispose() {
    _verifyTxController.dispose();
    super.dispose();
  }

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
      final proof = await widget.service.getBlockchainProof();
      if (!mounted) return;
      setState(() {
        _walletData = wallet;
        _blockchainProof = proof;
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

  Future<void> _refreshBlockchainProof() async {
    setState(() => _isLoadingBlockchainProof = true);
    try {
      final proof = await widget.service.getBlockchainProof();
      if (!mounted) return;
      setState(() {
        _blockchainProof = proof;
        _isLoadingBlockchainProof = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingBlockchainProof = false);
    }
  }

  String _money(dynamic value) {
    final n = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return n.toStringAsFixed(2);
  }

  String? _chainStatus(Map<String, dynamic> tx) {
    final metadata = tx['metadata'];
    if (metadata is! Map) return null;
    final value = metadata['chainStatus'];
    if (value is! String) return null;
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ? null : normalized;
  }

  Color _chainStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.success;
      case 'pending':
        return AppColors.chainCyan;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _showTopupDialog() async {
    final pageContext = context;
    final amountController = TextEditingController();
    final refController = TextEditingController();
    final txHashController = TextEditingController();

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
              const SizedBox(height: 10),
              TextField(
                controller: refController,
                decoration: const InputDecoration(
                  labelText: 'Reference (optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: txHashController,
                decoration: const InputDecoration(
                  labelText: 'On-chain tx hash (optional)',
                  hintText: '0x...',
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
                  await widget.service.topup(
                    amount: amount,
                    reference: refController.text.trim().isEmpty
                        ? null
                        : refController.text.trim(),
                    txHash: txHashController.text.trim().isEmpty
                        ? null
                        : txHashController.text.trim(),
                  );
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
    final refController = TextEditingController();
    final txHashController = TextEditingController();
    String selectedTokenType = 'POL';

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
              const SizedBox(height: 10),
              StatefulBuilder(
                builder: (context, setState) {
                  return SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(label: Text('POL'), value: 'POL'),
                      ButtonSegment(label: Text('USDC'), value: 'USDC'),
                    ],
                    selected: {selectedTokenType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        selectedTokenType = newSelection.first;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: refController,
                decoration: const InputDecoration(
                  labelText: 'Reference (optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: txHashController,
                decoration: const InputDecoration(
                  labelText: 'On-chain tx hash (optional)',
                  hintText: '0x...',
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
                    reference: refController.text.trim().isEmpty
                        ? null
                        : refController.text.trim(),
                    txHash: txHashController.text.trim().isEmpty
                        ? null
                        : txHashController.text.trim(),
                    tokenType: selectedTokenType,
                  );
                  if (!mounted) return;
                  final txHash = (result['txHash'] ?? '').toString();
                  final token = (result['tokenType'] ?? selectedTokenType)
                      .toString();
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

  Future<void> _showConnectWalletDialog() async {
    final pageContext = context;
    final addressController = TextEditingController(
      text:
          (_walletData?['wallet'] as Map<String, dynamic>?)?['walletAddress']
              ?.toString() ??
          '',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Connect external wallet'),
          content: TextField(
            controller: addressController,
            decoration: const InputDecoration(hintText: '0x...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final address = addressController.text.trim();
                if (address.isEmpty) return;
                Navigator.of(context).pop();
                await widget.service.connectWallet(address);
                if (!mounted) return;
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  const SnackBar(content: Text('Wallet connected')),
                );
                await _loadWallet();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _verifyTxHash() async {
    final txHash = _verifyTxController.text.trim();
    if (txHash.isEmpty) return;

    setState(() {
      _isVerifyingTx = true;
      _verifyResult = null;
    });

    try {
      final result = await widget.service.verifyTransaction(txHash);
      if (!mounted) return;
      setState(() {
        _verifyResult = result;
        _isVerifyingTx = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifyResult = {'error': e.toString(), 'txHash': txHash};
        _isVerifyingTx = false;
      });
    }
  }

  Future<void> _verifyAndSyncTxHash() async {
    final txHash = _verifyTxController.text.trim();
    if (txHash.isEmpty) return;

    setState(() {
      _isReconcilingTx = true;
      _verifyResult = null;
    });

    try {
      final result = await widget.service.reconcileTransaction(txHash);
      if (!mounted) return;
      setState(() {
        _verifyResult = {
          ...Map<String, dynamic>.from(result),
          'reconciled': true,
        };
        _isReconcilingTx = false;
      });
      await _loadWallet();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifyResult = {
          'error': e.toString(),
          'txHash': txHash,
          'reconciled': true,
        };
        _isReconcilingTx = false;
      });
    }
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
                          'Connected: ${wallet?['walletAddress'] ?? 'Not connected'}',
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
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _showConnectWalletDialog,
                    icon: const Icon(Icons.account_balance_wallet_rounded),
                    label: const Text('Connect external wallet'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Blockchain Proof',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isLoadingBlockchainProof
                            ? null
                            : _refreshBlockchainProof,
                        icon: _isLoadingBlockchainProof
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _BlockchainProofCard(proof: _blockchainProof),
                  const SizedBox(height: 18),
                  Text(
                    'Verify Transaction',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _verifyTxController,
                          decoration: const InputDecoration(
                            hintText: '0x transaction hash',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: (_isVerifyingTx || _isReconcilingTx)
                              ? null
                              : _verifyTxHash,
                          child: _isVerifyingTx
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Check'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (_isVerifyingTx || _isReconcilingTx)
                              ? null
                              : _verifyAndSyncTxHash,
                          child: _isReconcilingTx
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Verify & Sync'),
                        ),
                      ),
                    ],
                  ),
                  if (_verifyResult != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.cardBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: context.borderColor.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        _verifyResult!['error'] != null
                            ? 'Verification failed: ${_verifyResult!['error']}'
                            : _verifyResult!['reconciled'] == true
                            ? 'Tx: ${_verifyResult!['txHash']}\nChain status: ${_verifyResult!['chainStatus']}\nConfirmed: ${_verifyResult!['verification']?['confirmed']}\nSuccess: ${_verifyResult!['verification']?['success']}\nWallet tx updated: ${_verifyResult!['walletTransactionsUpdated']}\nListings updated: ${_verifyResult!['listingsUpdated']}'
                            : 'Tx: ${_verifyResult!['txHash']}\nConfirmed: ${_verifyResult!['confirmed']}\nSuccess: ${_verifyResult!['success']}\nBlock: ${_verifyResult!['blockNumber']}',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
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
                      final chainStatus = _chainStatus(tx);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(type.toUpperCase()),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(created),
                            if (chainStatus != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _chainStatusColor(
                                    chainStatus,
                                  ).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: _chainStatusColor(chainStatus),
                                  ),
                                ),
                                child: Text(
                                  'Chain ${chainStatus.toUpperCase()}',
                                  style: TextStyle(
                                    color: _chainStatusColor(chainStatus),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
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

class _BlockchainProofCard extends StatelessWidget {
  const _BlockchainProofCard({required this.proof});

  final Map<String, dynamic>? proof;

  String _shortAddress(String value) {
    if (value.length < 12) return value;
    return '${value.substring(0, 8)}...${value.substring(value.length - 6)}';
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = context.cardBackgroundColor;
    final border = context.borderColor;
    final textSecondary = context.textSecondaryColor;

    final chain = proof?['chain'] as Map<String, dynamic>?;
    final contracts =
        (proof?['contracts'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>();
    final proofReady = proof?['proofReady'] == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                proofReady
                    ? Icons.verified_rounded
                    : Icons.warning_amber_rounded,
                color: proofReady ? AppColors.success : AppColors.ethGold,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                proofReady ? 'Proof Ready' : 'Proof Incomplete',
                style: TextStyle(
                  color: proofReady ? AppColors.success : AppColors.ethGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Chain: ${chain?['chainName'] ?? '-'} · RPC ChainId: ${chain?['rpcChainId'] ?? '-'} · Block: ${chain?['latestBlockNumber'] ?? '-'}',
            style: TextStyle(color: textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ...contracts.map((contract) {
            final label = (contract['label'] ?? '').toString().toUpperCase();
            final address = (contract['address'] ?? '').toString();
            final deployed = contract['deployed'] == true;
            final configured = contract['configured'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 88,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      configured && address.isNotEmpty
                          ? _shortAddress(address)
                          : 'not configured',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ),
                  Text(
                    deployed ? 'deployed' : 'missing',
                    style: TextStyle(
                      color: deployed ? AppColors.success : AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
