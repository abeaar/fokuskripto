import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';

import '../../model/coinGecko.dart';
import '../../services/providers/market_provider.dart';
import '../../services/providers/trade_provider.dart';

class TradeCoinDropdown extends StatelessWidget {
  final MarketProvider marketProvider;
  final TradeProvider tradeProvider;

  const TradeCoinDropdown({
    super.key,
    required this.marketProvider,
    required this.tradeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<CoinGeckoMarketModel>(
      items: marketProvider.allCoins,
      selectedItem: _getSelectedItem(marketProvider, tradeProvider),
      itemAsString: _itemAsString,
      onChanged: _onChanged(tradeProvider),
      filterFn: _filterFn,
      dropdownDecoratorProps: _dropdownDecoratorProps,
      popupProps: _popupProps,
    );
  }

  CoinGeckoMarketModel _getSelectedItem(MarketProvider marketProvider, TradeProvider tradeProvider) {
    return marketProvider.allCoins.firstWhere(
      (coin) => coin.id == tradeProvider.selectedCoinId,
      orElse: () => marketProvider.allCoins.first,
    );
  }

  String _itemAsString(CoinGeckoMarketModel coin) {
    return "${coin.name} (${coin.symbol.toUpperCase()})";
  }

  ValueChanged<CoinGeckoMarketModel?> _onChanged(TradeProvider tradeProvider) {
    return (coin) => coin != null ? tradeProvider.selectCoin(coin) : null;
  }

bool _filterFn(CoinGeckoMarketModel coin, String filter) {
  return coin.name.toLowerCase().contains(filter.toLowerCase()) ||
      coin.symbol.toLowerCase().contains(filter.toLowerCase());
}

  DropDownDecoratorProps get _dropdownDecoratorProps {
    return const DropDownDecoratorProps(
      dropdownSearchDecoration: InputDecoration(
        labelText: "Pilih Koin",
        hintText: "Cari koin untuk trading",
        prefixIcon: Icon(Icons.search),
      ),
    );
  }

  PopupProps<CoinGeckoMarketModel> get _popupProps {
    return PopupProps.menu(
      showSearchBox: true,
      searchFieldProps: TextFieldProps(
        decoration: InputDecoration(
          hintText: "Cari koin...",
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      title: const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text("Cari Koin",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
