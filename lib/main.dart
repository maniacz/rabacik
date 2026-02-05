

import 'package:flutter/material.dart';
import 'package:rabacik/screens/home_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _initNotifications();
  runApp(const MainApp());
}

Future<void> _initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
      navigatorObservers: [routeObserver],
    );
  }
}
