import 'package:flutter/foundation.dart';
import '../pages/tradetab.dart'; // Untuk enum TradeMode (atau definisikan global)

class PendingTradeInfo {
  final String coinId;
  final String coinSymbol;
  final TradeMode tradeMode;

  PendingTradeInfo({
    required this.coinId,
    required this.coinSymbol,
    required this.tradeMode,
  });
}

class PendingTradeNotifier with ChangeNotifier {
  PendingTradeInfo? _pendingTrade;
  PendingTradeInfo? get pendingTrade => _pendingTrade;

  void setTrade(String coinId, String coinSymbol, TradeMode tradeMode) {
    _pendingTrade = PendingTradeInfo(
      coinId: coinId,
      coinSymbol: coinSymbol,
      tradeMode: tradeMode,
    );
    notifyListeners();
  }

  void clear() {
    if (_pendingTrade != null) {
      _pendingTrade = null;
      // notifyListeners(); 
    }
  }
}
