import 'dart:math';

/// 보드 위의 타일 하나. [id] 는 애니메이션에서 위젯을 추적하는 데 쓰인다.
class Tile {
  final int id;
  int value;
  int row;
  int col;

  /// 이번 턴에 합쳐져서 값이 커졌다 (팝 애니메이션용).
  bool merged;

  /// 이번 턴에 새로 생성됐다 (등장 애니메이션용).
  bool isNew;

  Tile({
    required this.id,
    required this.value,
    required this.row,
    required this.col,
    this.merged = false,
    this.isNew = false,
  });

  Tile copy() => Tile(id: id, value: value, row: row, col: col, merged: merged, isNew: isNew);

  Map<String, dynamic> toJson() => {'id': id, 'v': value, 'r': row, 'c': col};

  factory Tile.fromJson(Map<String, dynamic> j) =>
      Tile(id: j['id'] as int, value: j['v'] as int, row: j['r'] as int, col: j['c'] as int);
}

enum Direction { up, down, left, right }

/// 한 번의 이동 결과.
class MoveResult {
  final bool moved;

  /// 이번 이동으로 얻은 점수.
  final int gained;

  /// 다른 타일에 합쳐져 사라진 타일들. 위치는 합쳐진 자리로 이미 옮겨져 있으므로
  /// 화면에서 슬라이드 애니메이션이 끝난 뒤 제거하면 된다.
  final List<Tile> ghosts;

  const MoveResult({required this.moved, required this.gained, required this.ghosts});
  static const none = MoveResult(moved: false, gained: 0, ghosts: []);
}

class _Snapshot {
  final List<Tile> tiles;
  final int score;
  _Snapshot(this.tiles, this.score);
}

/// 2048 게임 상태와 규칙. UI 와 무관한 순수 로직.
class Game {
  static const size = 4;
  static const winValue = 2048;

  /// 게임당 무료 되돌리기 횟수. 소진하면 보상형 광고로 충전한다.
  static const freeUndos = 3;
  static const undoRefill = 3;
  static const _maxHistory = 20;

  final Random _rng;
  int _nextId = 0;
  List<Tile> tiles = [];
  int score = 0;
  int undosLeft = freeUndos;

  /// 2048 을 만든 뒤 "계속하기"를 눌렀다 (승리 팝업을 다시 띄우지 않기 위해).
  bool keepPlaying = false;

  final List<_Snapshot> _history = [];

  Game.newGame([Random? rng]) : _rng = rng ?? Random() {
    spawn();
    spawn();
  }

  Game._restore(this._rng);

  bool get canUndo => _history.isNotEmpty;
  int get maxTile => tiles.fold(0, (m, t) => max(m, t.value));
  bool get hasWon => maxTile >= winValue;

  Tile? at(int row, int col) {
    for (final t in tiles) {
      if (t.row == row && t.col == col) return t;
    }
    return null;
  }

  bool get canMove {
    if (tiles.length < size * size) return true;
    for (final t in tiles) {
      final right = at(t.row, t.col + 1);
      final down = at(t.row + 1, t.col);
      if (right != null && right.value == t.value) return true;
      if (down != null && down.value == t.value) return true;
    }
    return false;
  }

  bool get isOver => !canMove;

  /// 빈 칸에 타일 하나를 놓는다 (90% 2, 10% 4). 빈 칸이 없으면 null.
  Tile? spawn() {
    final empty = <(int, int)>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (at(r, c) == null) empty.add((r, c));
      }
    }
    if (empty.isEmpty) return null;
    final (r, c) = empty[_rng.nextInt(empty.length)];
    final t = Tile(id: _nextId++, value: _rng.nextInt(10) == 0 ? 4 : 2, row: r, col: c, isNew: true);
    tiles.add(t);
    return t;
  }

  /// [dir] 방향으로 밀고 합친다. 실제로 움직였으면 새 타일을 하나 놓는다.
  MoveResult move(Direction dir) {
    final snapshot = _Snapshot(tiles.map((t) => t.copy()).toList(), score);
    for (final t in tiles) {
      t.merged = false;
      t.isNew = false;
    }

    final vertical = dir == Direction.up || dir == Direction.down;
    final reverse = dir == Direction.right || dir == Direction.down;
    var moved = false;
    var gained = 0;
    final ghosts = <Tile>[];

    for (var line = 0; line < size; line++) {
      // 이동 방향 순서대로 정렬된 한 줄의 타일들
      var lineTiles = tiles.where((t) => (vertical ? t.col : t.row) == line).toList()
        ..sort((a, b) => vertical ? a.row.compareTo(b.row) : a.col.compareTo(b.col));
      if (reverse) lineTiles = lineTiles.reversed.toList();

      var pos = reverse ? size - 1 : 0;
      final step = reverse ? -1 : 1;
      Tile? last;
      for (final t in lineTiles) {
        if (last != null && last.value == t.value && !last.merged) {
          last.value *= 2;
          last.merged = true;
          gained += last.value;
          t.row = last.row;
          t.col = last.col;
          ghosts.add(t);
          moved = true;
        } else {
          final cur = vertical ? t.row : t.col;
          if (cur != pos) {
            moved = true;
            if (vertical) {
              t.row = pos;
            } else {
              t.col = pos;
            }
          }
          pos += step;
          last = t;
        }
      }
    }

    if (!moved) return MoveResult.none;

    tiles.removeWhere(ghosts.contains);
    score += gained;
    _history.add(snapshot);
    if (_history.length > _maxHistory) _history.removeAt(0);
    spawn();
    return MoveResult(moved: true, gained: gained, ghosts: ghosts);
  }

  /// 직전 이동을 취소한다. 되돌리기 횟수가 없거나 기록이 없으면 false.
  bool undo() {
    if (_history.isEmpty || undosLeft <= 0) return false;
    final s = _history.removeLast();
    tiles = s.tiles;
    score = s.score;
    undosLeft--;
    return true;
  }

  // ------------------------------------------------------------------ 저장

  Map<String, dynamic> toJson() => {
        'nextId': _nextId,
        'score': score,
        'undos': undosLeft,
        'keep': keepPlaying,
        'tiles': tiles.map((t) => t.toJson()).toList(),
        'history': _history
            .map((s) => {'score': s.score, 'tiles': s.tiles.map((t) => t.toJson()).toList()})
            .toList(),
      };

  factory Game.fromJson(Map<String, dynamic> j, [Random? rng]) {
    final g = Game._restore(rng ?? Random());
    g._nextId = j['nextId'] as int;
    g.score = j['score'] as int;
    g.undosLeft = j['undos'] as int? ?? freeUndos;
    g.keepPlaying = j['keep'] as bool? ?? false;
    g.tiles = (j['tiles'] as List).map((t) => Tile.fromJson(t as Map<String, dynamic>)).toList();
    for (final h in (j['history'] as List? ?? const [])) {
      final m = h as Map<String, dynamic>;
      g._history.add(_Snapshot(
        (m['tiles'] as List).map((t) => Tile.fromJson(t as Map<String, dynamic>)).toList(),
        m['score'] as int,
      ));
    }
    return g;
  }
}
