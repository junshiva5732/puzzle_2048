import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ads/ad_manager.dart';
import 'l10n/strings.dart';
import 'screens/game_screen.dart';
import 'services/game_storage.dart';

/// 스크린샷 촬영용 언어 강제 (디버그 빌드에서만 동작).
/// 예: flutter build apk --debug --dart-define=LOCALE=ja
const _localeOverride = String.fromEnvironment('LOCALE');

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
      onGenerateTitle: (context) => S.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark, useMaterial3: true),
      localizationsDelegates: const [S.delegate, ...GlobalMaterialLocalizations.delegates],
      supportedLocales: S.supported,
      locale: kDebugMode && _localeOverride.isNotEmpty ? Locale(_localeOverride) : null,
      home: GameScreen(storage: storage),
    );
  }
}
