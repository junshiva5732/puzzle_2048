import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_2048/game/game.dart';

/// [rows] 로 보드를 만든다 (0 = 빈 칸).
Game boardOf(List<List<int>> rows) {
  final g = Game.newGame(Random(0))..tiles.clear();
  var id = 100;
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 4; c++) {
      if (rows[r][c] != 0) g.tiles.add(Tile(id: id++, value: rows[r][c], row: r, col: c));
    }
  }
  return g;
}

List<List<int>> gridOf(Game g) =>
    List.generate(4, (r) => List.generate(4, (c) => g.at(r, c)?.value ?? 0));

void main() {
  test('new game has two tiles', () {
    final g = Game.newGame(Random(1));
    expect(g.tiles.length, 2);
    expect(g.tiles.every((t) => t.value == 2 || t.value == 4), isTrue);
  });

  test('left merges once per pair and slides', () {
    final g = boardOf([
      [2, 2, 4, 4],
      [2, 0, 2, 0],
      [4, 4, 4, 4],
      [0, 0, 0, 2],
    ]);
    // 스폰이 검증을 흐리지 않도록 이동 후 새 타일은 무시하고 앞쪽 값만 본다
    final r = g.move(Direction.left);
    expect(r.moved, isTrue);
    expect(r.gained, 4 + 8 + 4 + 8 + 8);
    expect(r.ghosts.length, 5);
    final grid = gridOf(g);
    expect(grid[0].sublist(0, 2), [4, 8]);
    expect(grid[1][0], 4);
    expect(grid[2].sublist(0, 2), [8, 8]);
    expect(grid[3][0], 2);
    expect(g.tiles.length, 6 + 1); // 남은 타일 + 새로 스폰된 1개
  });

  test('right / up / down directions', () {
    var g = boardOf([
      [2, 0, 0, 2],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    g.move(Direction.right);
    expect(gridOf(g)[0][3], 4);

    g = boardOf([
      [2, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [2, 0, 0, 0],
    ]);
    g.move(Direction.up);
    expect(gridOf(g)[0][0], 4);

    g = boardOf([
      [4, 0, 0, 0],
      [4, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    g.move(Direction.down);
    expect(gridOf(g)[3][0], 8);
  });

  test('no-op move does not spawn or record history', () {
    final g = boardOf([
      [2, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    final r = g.move(Direction.left);
    expect(r.moved, isFalse);
    expect(g.tiles.length, 1);
    expect(g.canUndo, isFalse);
  });

  test('undo restores board and score, consumes a charge', () {
    final g = boardOf([
      [2, 2, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    g.move(Direction.left);
    expect(g.score, 4);
    expect(g.undo(), isTrue);
    expect(g.score, 0);
    expect(gridOf(g)[0].sublist(0, 2), [2, 2]);
    expect(g.tiles.length, 2);
    expect(g.undosLeft, Game.freeUndos - 1);
  });

  test('undo refused when charges exhausted', () {
    final g = boardOf([
      [2, 2, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ])..undosLeft = 0;
    g.move(Direction.left);
    expect(g.undo(), isFalse);
  });

  test('game over detection', () {
    final g = boardOf([
      [2, 4, 2, 4],
      [4, 2, 4, 2],
      [2, 4, 2, 4],
      [4, 2, 4, 2],
    ]);
    expect(g.isOver, isTrue);
    final g2 = boardOf([
      [2, 4, 2, 4],
      [4, 2, 4, 2],
      [2, 4, 2, 4],
      [4, 2, 4, 4],
    ]);
    expect(g2.isOver, isFalse);
  });

  test('json round trip', () {
    final g = boardOf([
      [2, 2, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 1024, 1024],
    ]);
    g.move(Direction.right);
    g.keepPlaying = true;
    final copy = Game.fromJson(g.toJson());
    expect(gridOf(copy), gridOf(g));
    expect(copy.score, g.score);
    expect(copy.canUndo, isTrue);
    expect(copy.keepPlaying, isTrue);
    expect(copy.hasWon, isTrue);
  });
}
