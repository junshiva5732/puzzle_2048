import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 앱 문자열 (en / ko / ja). 시스템 언어를 따르고, 지원하지 않는 언어는 영어.
///
/// 새 언어를 추가하려면 [supported] 에 로케일을 넣고 [_t] 의 switch 에 분기를 추가한다.
class S {
  final Locale locale;
  const S(this.locale);

  static S of(BuildContext context) => Localizations.of<S>(context, S)!;
  static const LocalizationsDelegate<S> delegate = _SDelegate();
  static const supported = [Locale('en'), Locale('ko'), Locale('ja')];

  String _t(String en, String ko, String ja) => switch (locale.languageCode) {
        'ko' => ko,
        'ja' => ja,
        _ => en,
      };

  String get appTitle => _t('2048 Puzzle', '2048 퍼즐', '2048 パズル');
  String get subtitle => _t('Join the tiles, get to 2048!', '타일을 합쳐 2048을 만드세요', 'タイルを合わせて2048を作ろう');
  String get score => _t('SCORE', '점수', 'スコア');
  String get best => _t('BEST', '최고', 'ベスト');

  String get undo => _t('Undo', '되돌리기', '戻す');
  String get newGame => _t('New game', '새 게임', '新しいゲーム');
  String get howToPlay => _t('How to play', '게임 방법', '遊び方');
  String get cancel => _t('Cancel', '취소', 'キャンセル');
  String get start => _t('Start', '시작', 'スタート');
  String get ok => _t('OK', '확인', 'OK');
  String get watchAd => _t('Watch ad', '광고 보기', '広告を見る');

  String get refillTitle => _t('Refill undos', '되돌리기 충전', '「戻す」をチャージ');
  String refillBody(int n) => _t(
        'You have used all your undos.\nWatch a short ad to get $n more.',
        '되돌리기를 모두 사용했어요.\n짧은 광고를 보면 $n회가 충전됩니다.',
        '「戻す」を使い切りました。\n短い広告を見ると$n回チャージされます。',
      );
  String get adNotReady => _t(
        'The ad is not ready yet. Please try again in a moment.',
        '광고를 아직 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
        '広告をまだ読み込めていません。しばらくしてからもう一度お試しください。',
      );

  String get newGameBody => _t(
        'Your current progress will be lost.\nStart a new game?',
        '현재 진행 상황이 사라집니다.\n새 게임을 시작할까요?',
        '現在の進行状況が失われます。\n新しいゲームを始めますか？',
      );

  String helpBody(int freeUndos, int refill) => _t(
        'Swipe up, down, left or right to move the tiles.\n'
            'When two tiles with the same number touch, they merge into one.\n\n'
            'Reach the 2048 tile to win — then keep going for an even higher score!\n\n'
            'You get $freeUndos free undos per game. Watch an ad to get $refill more.',
        '화면을 상·하·좌·우로 밀어 타일을 움직이세요.\n'
            '같은 숫자의 타일이 부딪히면 하나로 합쳐집니다.\n\n'
            '2048 타일을 만들면 승리! 그 뒤로도 계속 이어서 더 큰 숫자에 도전할 수 있어요.\n\n'
            '되돌리기는 게임당 $freeUndos회 무료이며, 광고를 보면 $refill회 더 충전됩니다.',
        '画面を上下左右にスワイプしてタイルを動かします。\n'
            '同じ数字のタイルがぶつかると1つに合体します。\n\n'
            '2048のタイルを作れば勝利！その後も続けてさらに大きな数字に挑戦できます。\n\n'
            '「戻す」は1ゲームにつき$freeUndos回無料。広告を見るとさらに$refill回チャージされます。',
      );

  String get youWin => _t('You win!', '2048 달성!', '2048達成！');
  String get gameOver => _t('Game over', '게임 오버', 'ゲームオーバー');
  String scoreLine(int n) => _t('Score $n', '점수 $n', 'スコア $n');
  String get keepGoing => _t('Keep going', '계속하기', '続ける');
  String get continueWithAd => _t('Watch ad to continue', '광고 보고 이어하기', '広告を見て続ける');
  String undoLeft(int n) => _t('Undo ($n left)', '되돌리기 ($n회 남음)', '戻す（残り$n回）');
  String get revived => _t(
        'Cleared the smallest tiles. Keep going!',
        '작은 타일을 정리했어요. 계속 이어가세요!',
        '小さいタイルを片付けました。続けましょう！',
      );
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) => S.supported.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<S> load(Locale locale) => SynchronousFuture(S(locale));

  @override
  bool shouldReload(_SDelegate old) => false;
}
