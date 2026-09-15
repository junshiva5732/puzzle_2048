import 'package:flutter/material.dart';

/// 2048 고유 색상. Material 테마와 별개로 보드/타일에만 쓴다.
class GameColors {
  final Color background;
  final Color board;
  final Color emptyCell;
  final Color text;
  final Color textMuted;
  final Color scoreBox;
  final Color scoreLabel;
  final Color button;
  final Color buttonText;

  const GameColors._({
    required this.background,
    required this.board,
    required this.emptyCell,
    required this.text,
    required this.textMuted,
    required this.scoreBox,
    required this.scoreLabel,
    required this.button,
    required this.buttonText,
  });

  static const light = GameColors._(
    background: Color(0xFFFAF8EF),
    board: Color(0xFFBBADA0),
    emptyCell: Color(0xFFCDC1B4),
    text: Color(0xFF776E65),
    textMuted: Color(0xFF9E948A),
    scoreBox: Color(0xFFBBADA0),
    scoreLabel: Color(0xFFEEE4DA),
    button: Color(0xFF8F7A66),
    buttonText: Color(0xFFF9F6F2),
  );

  static const dark = GameColors._(
    background: Color(0xFF1C1A17),
    board: Color(0xFF3B3630),
    emptyCell: Color(0xFF4B443C),
    text: Color(0xFFE8E0D5),
    textMuted: Color(0xFFA39B90),
    scoreBox: Color(0xFF3B3630),
    scoreLabel: Color(0xFFBDB2A5),
    button: Color(0xFF8F7A66),
    buttonText: Color(0xFFF9F6F2),
  );

  static GameColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// 타일 배경색.
  static Color tile(int value) => switch (value) {
        2 => const Color(0xFFEEE4DA),
        4 => const Color(0xFFEDE0C8),
        8 => const Color(0xFFF2B179),
        16 => const Color(0xFFF59563),
        32 => const Color(0xFFF67C5F),
        64 => const Color(0xFFF65E3B),
        128 => const Color(0xFFEDCF72),
        256 => const Color(0xFFEDCC61),
        512 => const Color(0xFFEDC850),
        1024 => const Color(0xFFEDC53F),
        2048 => const Color(0xFFEDC22E),
        _ => const Color(0xFF3C3A32),
      };

  /// 타일 글자색. 2·4 만 어두운 글자.
  static Color tileText(int value) => value <= 4 ? const Color(0xFF776E65) : const Color(0xFFF9F6F2);
}
