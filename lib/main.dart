import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fokuskripto/services/notification_service.dart';
import 'package:fokuskripto/services/providers/market_provider.dart';
import 'package:fokuskripto/services/providers/trade_provider.dart';
import 'package:fokuskripto/services/providers/wallet_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'model/coinGecko.dart';
import 'pages/LoginPage.dart';
import 'pages/RegisterPage.dart';
import 'pages/HomePage.dart';
import 'pages/SplashScreen.dart';

final ValueNotifier<Key> appKeyNotifier = ValueNotifier(Key('initial'));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  Hive.registerAdapter(CoinGeckoMarketModelAdapter());

  await Hive.initFlutter();
  await NotificationService().init();

  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });

  runApp(
    ValueListenableBuilder<Key>(
      valueListenable: appKeyNotifier,
      builder: (context, key, _) => MyApp(key: key),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MarketProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProxyProvider2<MarketProvider, WalletProvider,
            TradeProvider>(
          create: (context) => TradeProvider(
            marketProvider: Provider.of<MarketProvider>(context, listen: false),
            walletProvider: Provider.of<WalletProvider>(context, listen: false),
          ),
          update:
              (context, marketProvider, walletProvider, previousTradeProvider) {
            if (previousTradeProvider != null) {
              previousTradeProvider.marketProvider = marketProvider;
              previousTradeProvider.walletProvider = walletProvider;
              return previousTradeProvider;
            }
            return TradeProvider(
              marketProvider: marketProvider,
              walletProvider: walletProvider,
            );
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login_page': (context) => LoginPage(),
          '/register_page': (context) => RegisterPage(),
          '/home_page': (context) => HomePage(),
        },
        theme: ThemeData(
          scaffoldBackgroundColor: Color.fromARGB(255, 255, 255, 255),
          textTheme: TextTheme(
            titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 51, 51, 51),
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 0, 0, 0),
              fontWeight: FontWeight.w500,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color.fromARGB(255, 255, 255, 255),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Color.fromARGB(255, 224, 224, 224),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Color.fromARGB(255, 224, 224, 224),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Color.fromARGB(255, 79, 179, 121),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            labelStyle: TextStyle(
              color: Colors.grey[700],
            ),
            errorStyle: TextStyle(
              color: Colors.red,
            ),
          ),
          appBarTheme: const AppBarTheme(
            elevation: 10,
            shadowColor: Color.fromARGB(255, 240, 240, 240),
            titleTextStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  Color.fromARGB(255, 112, 190, 145)),
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              elevation: MaterialStateProperty.all<double>(2),
              padding: MaterialStateProperty.all<EdgeInsets>(
                const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
