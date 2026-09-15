import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads/ad_manager.dart';
import 'screens/game_screen.dart';
import 'services/game_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 광고 SDK 초기화는 앱 표시를 막지 않도록 기다리지 않는다.
  AdManager.instance.init();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final storage = await GameStorage.create();
  runApp(PuzzleApp(storage: storage));
}

class PuzzleApp extends StatelessWidget {
  final GameStorage storage;
  const PuzzleApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF8F7A66);
    return MaterialApp(
      title: '2048 퍼즐',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark, useMaterial3: true),
      home: GameScreen(storage: storage),
    );
  }
}
