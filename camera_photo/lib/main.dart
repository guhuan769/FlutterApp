// lib/main.dart
import 'package:camera_photo/providers/bluetooth_provider.dart';
import 'package:camera_photo/screens/bluetooth_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/photo_provider.dart';
import 'providers/project_provider.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '相机项目管理',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/bluetooth': (context) => const BluetoothScanScreen(),
      },
    );
  }
}