import 'package:flutter/material.dart';

import '../game/game.dart';
import '../theme/game_colors.dart';
import 'tile_widget.dart';

/// 4x4 보드. 빈 칸 격자 위에 타일들을 절대 위치로 올리고,
/// 위치 변화는 [AnimatedPositioned] 로 슬라이드한다.
class BoardWidget extends StatelessWidget {
  static const slideDuration = Duration(milliseconds: 110);

  final List<Tile> tiles;

  /// 합쳐져 사라지는 타일. 슬라이드가 끝날 때까지만 타일 아래에 그린다.
  final List<Tile> ghosts;
  final double size;

  const BoardWidget({super.key, required this.tiles, required this.ghosts, required this.size});

  @override
  Widget build(BuildContext context) {
    final c = GameColors.of(context);
    final gap = size * 0.03;
    final cell = (size - gap * (Game.size + 1)) / Game.size;
    double offset(int i) => gap + i * (cell + gap);

    final children = <Widget>[
      for (var r = 0; r < Game.size; r++)
        for (var col = 0; col < Game.size; col++)
          Positioned(
            left: offset(col),
            top: offset(r),
            child: Container(
              width: cell,
              height: cell,
              decoration: BoxDecoration(
                color: c.emptyCell,
                borderRadius: BorderRadius.circular(cell * 0.08),
              ),
            ),
          ),
      // 고스트를 먼저 그려 합쳐지는 타일 아래로 들어가게 한다.
      for (final t in [...ghosts, ...tiles])
        AnimatedPositioned(
          key: ValueKey(t.id),
          duration: slideDuration,
          curve: Curves.easeOut,
          left: offset(t.col),
          top: offset(t.row),
          child: TileWidget(tile: t, size: cell),
        ),
    ];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.board,
        borderRadius: BorderRadius.circular(size * 0.03),
      ),
      child: Stack(children: children),
    );
  }
}
