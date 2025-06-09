import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();
  factory NotificationService() {
    return _notificationService;
  }
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('kriptoin');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showWithdrawalSuccessNotification(double amount) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'withdrawal_channel_id', // ID unik untuk channel
      'Notifikasi Penarikan', // Nama channel yang terlihat di pengaturan
      channelDescription: 'Channel untuk notifikasi status penarikan saldo',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // ID notifikasi
      'Penarikan Berhasil!', // Judul Notifikasi
      'Anda telah berhasil menarik saldo sebesar ${formatter.format(amount)}.',
      platformChannelSpecifics,
    );
  }

  Future<void> showDepositSuccessNotification(double amount) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'deposit_channel_id', // ID unik untuk channel
      'Notifikasi Pemasukan', // Nama channel yang terlihat di pengaturan
      channelDescription: 'Channel untuk notifikasi status pemasukan saldo',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      1, // ID notifikasi
      'pemasukan Berhasil!', // Judul Notifikasi
      'Anda telah berhasil memasukan saldo sebesar ${formatter.format(amount)}.',
      platformChannelSpecifics,
    );
  }

  Future<void> showMarketUpdateNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'market_channel',
      'Market Notifications',
      channelDescription: 'Notifikasi update harga market',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      2, // ID notifikasi unik
      'Cek harga Market terbaru',
      'Market telah diupdate, cek harga terbaru sekarang!',
      platformChannelSpecifics,
    );
  }
}
