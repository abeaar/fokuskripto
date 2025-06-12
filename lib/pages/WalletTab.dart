import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/wallet/wallet_header.dart';
import '../widgets/wallet/wallet_action_buttons.dart';
import '../widgets/wallet/wallet_coin_list.dart';
import '../services/providers/wallet_provider.dart';
import './DepositPage.dart';
import './WithdrawPage.dart';

class WalletTab extends StatefulWidget {
  const WalletTab({super.key});

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => Provider.of<WalletProvider>(context, listen: false).refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        if (walletProvider.isLoading) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final walletSummary = walletProvider.walletSummary;
        // DEBUG: Print marketValue dan staticValue
        print(
            '[DEBUG] WalletTab - marketValue: [32m[1m${walletSummary.marketValue}[0m, staticValue: [34m[1m${walletSummary.staticValue}0m');

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 8),
                WalletHeader(
                  totalAssetValue: walletSummary.marketValue,
                  summary: walletSummary,
                  staticValue: walletSummary.staticValue,
                  isBalanceVisible: _isBalanceVisible,
                  onToggleBalance: () {
                    setState(() {
                      _isBalanceVisible = !_isBalanceVisible;
                    });
                  },
                ),
                const SizedBox(height: 24),
                WalletActionButtons(
                  onDeposit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DepositPage(walletBox: walletProvider.walletBox),
                      ),
                    );
                  },
                  onWithdraw: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WithdrawPage(walletBox: walletProvider.walletBox),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.grey[800],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Your Portfolio',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                WalletCoinList(
                  box: walletProvider.walletBox,
                  marketCoins: walletProvider.marketCoins,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
