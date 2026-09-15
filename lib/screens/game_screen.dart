import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ads/ad_manager.dart';
import '../game/game.dart';
import '../services/game_storage.dart';
import '../theme/game_colors.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/board_widget.dart';

enum _Overlay { none, gameOver, won }

class GameScreen extends StatefulWidget {
  final GameStorage storage;
  const GameScreen({super.key, required this.storage});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Game _game;
  List<Tile> _ghosts = const [];
  _Overlay _overlay = _Overlay.none;
  int _best = 0;

  /// 점수 옆에 잠깐 떠오르는 "+N" 표시용.
  int _lastGain = 0;
  int _gainSerial = 0;

  // 스와이프 인식
  Offset _dragStart = Offset.zero;
  bool _dragHandled = false;
  static const _swipeThreshold = 24.0;

  @override
  void initState() {
    super.initState();
    _best = widget.storage.best;
    _game = widget.storage.loadGame() ?? Game.newGame();
    if (_game.isOver) _overlay = _Overlay.gameOver;
  }

  // ------------------------------------------------------------------ 게임 조작

  void _move(Direction dir) {
    if (_overlay != _Overlay.none) return;
    final result = _game.move(dir);
    if (!result.moved) return;

    if (result.ghosts.isNotEmpty) HapticFeedback.lightImpact();
    setState(() {
      _ghosts = result.ghosts;
      if (result.gained > 0) {
        _lastGain = result.gained;
        _gainSerial++;
      }
      if (_game.score > _best) {
        _best = _game.score;
        widget.storage.setBest(_best);
      }
    });
    widget.storage.saveGame(_game);

    // 슬라이드가 끝난 뒤 고스트 제거 + 게임오버/승리 판정
    Future.delayed(BoardWidget.slideDuration, () {
      if (!mounted) return;
      setState(() {
        _ghosts = const [];
        if (_game.isOver) {
          _overlay = _Overlay.gameOver;
        } else if (_game.hasWon && !_game.keepPlaying) {
          _overlay = _Overlay.won;
        }
      });
    });
  }

  void _undo() {
    if (!_game.canUndo) return;
    if (_game.undosLeft <= 0) {
      _offerUndoRefill();
      return;
    }
    setState(() {
      _game.undo();
      _ghosts = const [];
      _overlay = _Overlay.none;
    });
    widget.storage.saveGame(_game);
  }

  /// 되돌리기 횟수 소진 → 보상형 광고로 충전.
  Future<void> _offerUndoRefill() async {
    final watch = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('되돌리기 충전'),
        content: Text('되돌리기를 모두 사용했어요.\n짧은 광고를 보면 ${Game.undoRefill}회가 충전됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('광고 보기'),
          ),
        ],
      ),
    );
    if (watch != true || !mounted) return;

    final shown = AdManager.instance.showRewarded(onReward: () {
      if (!mounted) return;
      setState(() => _game.undosLeft += Game.undoRefill);
      _undo();
    });
    if (!shown && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('광고를 아직 불러오지 못했어요. 잠시 후 다시 시도해 주세요.')),
      );
      AdManager.instance.loadRewarded();
    }
  }

  Future<void> _newGame() async {
    // 진행 중인 게임이 있으면 확인
    if (_overlay == _Overlay.none && _game.score > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('새 게임'),
          content: const Text('현재 진행 상황이 사라집니다.\n새 게임을 시작할까요?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('시작')),
          ],
        ),
      );
      if (ok != true) return;
    }
    AdManager.instance.showInterstitialThen(_startNewGame);
  }

  void _startNewGame() {
    if (!mounted) return;
    setState(() {
      _game = Game.newGame();
      _ghosts = const [];
      _overlay = _Overlay.none;
      _lastGain = 0;
    });
    widget.storage.saveGame(_game);
  }

  void _keepPlaying() {
    setState(() {
      _game.keepPlaying = true;
      _overlay = _Overlay.none;
    });
    widget.storage.saveGame(_game);
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('게임 방법'),
        content: const Text(
          '화면을 상·하·좌·우로 밀어 타일을 움직이세요.\n'
          '같은 숫자의 타일이 부딪히면 하나로 합쳐집니다.\n\n'
          '2048 타일을 만들면 승리! 그 뒤로도 계속 이어서 더 큰 숫자에 도전할 수 있어요.\n\n'
          '되돌리기는 게임당 ${Game.freeUndos}회 무료이며, 광고를 보면 ${Game.undoRefill}회 더 충전됩니다.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인'))],
      ),
    );
  }

  // ------------------------------------------------------------------ 입력

  void _onPanStart(DragStartDetails d) {
    _dragStart = d.localPosition;
    _dragHandled = false;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_dragHandled) return;
    final delta = d.localPosition - _dragStart;
    if (delta.distance < _swipeThreshold) return;
    _dragHandled = true;
    if (delta.dx.abs() > delta.dy.abs()) {
      _move(delta.dx > 0 ? Direction.right : Direction.left);
    } else {
      _move(delta.dy > 0 ? Direction.down : Direction.up);
    }
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final dir = switch (e.logicalKey) {
      LogicalKeyboardKey.arrowUp => Direction.up,
      LogicalKeyboardKey.arrowDown => Direction.down,
      LogicalKeyboardKey.arrowLeft => Direction.left,
      LogicalKeyboardKey.arrowRight => Direction.right,
      _ => null,
    };
    if (dir == null) return KeyEventResult.ignored;
    _move(dir);
    return KeyEventResult.handled;
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final c = GameColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  child: LayoutBuilder(builder: _buildContent),
                ),
              ),
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BoxConstraints box) {
    final c = GameColors.of(context);
    const pad = 16.0;
    // 헤더(약 150) 를 뺀 남은 높이와 너비 중 작은 쪽을 보드 한 변으로
    final side = math.min(box.maxWidth - pad * 2, box.maxHeight - 170).clamp(200.0, 520.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: pad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: side,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '2048',
                  style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: c.text, height: 1),
                ),
                const Spacer(),
                _ScoreBox(label: '점수', value: _game.score, gain: _lastGain, gainSerial: _gainSerial),
                const SizedBox(width: 8),
                _ScoreBox(label: '최고', value: _best),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: side,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '타일을 합쳐 2048을 만드세요',
                    style: TextStyle(color: c.textMuted, fontSize: 14),
                  ),
                ),
                _IconButton(
                  icon: Icons.undo,
                  badge: _game.undosLeft > 0 ? '${_game.undosLeft}' : 'AD',
                  tooltip: '되돌리기',
                  enabled: _game.canUndo,
                  onTap: _undo,
                ),
                const SizedBox(width: 6),
                _IconButton(icon: Icons.refresh, tooltip: '새 게임', onTap: _newGame),
                const SizedBox(width: 6),
                _IconButton(icon: Icons.help_outline, tooltip: '게임 방법', onTap: _showHelp),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              BoardWidget(tiles: _game.tiles, ghosts: _ghosts, size: side),
              Positioned.fill(child: _buildOverlay(side)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(double side) {
    final c = GameColors.of(context);
    final visible = _overlay != _Overlay.none;
    final won = _overlay == _Overlay.won;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 350),
        child: Container(
          decoration: BoxDecoration(
            color: (won ? const Color(0xFFEDC22E) : c.background).withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(side * 0.03),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                won ? '2048 달성!' : '게임 오버',
                style: TextStyle(
                  fontSize: side * 0.13,
                  fontWeight: FontWeight.w900,
                  color: won ? const Color(0xFFF9F6F2) : c.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '점수 ${_game.score}',
                style: TextStyle(fontSize: side * 0.055, color: won ? const Color(0xFFF9F6F2) : c.textMuted),
              ),
              const SizedBox(height: 20),
              if (won)
                _BigButton(label: '계속하기', icon: Icons.play_arrow, onTap: _keepPlaying)
              else if (_game.canUndo)
                _BigButton(
                  label: _game.undosLeft > 0 ? '되돌리기 (${_game.undosLeft}회 남음)' : '광고 보고 되돌리기',
                  icon: _game.undosLeft > 0 ? Icons.undo : Icons.play_circle_outline,
                  onTap: _undo,
                ),
              const SizedBox(height: 10),
              _BigButton(label: '새 게임', icon: Icons.refresh, onTap: _newGame, secondary: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final int value;
  final int gain;
  final int gainSerial;
  const _ScoreBox({required this.label, required this.value, this.gain = 0, this.gainSerial = 0});

  @override
  Widget build(BuildContext context) {
    final c = GameColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 72),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: c.scoreBox, borderRadius: BorderRadius.circular(6)),
          child: Column(
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.scoreLabel)),
              Text('$value',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
            ],
          ),
        ),
        if (gain > 0)
          Positioned(
            right: 8,
            top: 0,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(gainSerial),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              builder: (_, t, child) => Opacity(
                opacity: (1 - t).clamp(0, 1),
                child: Transform.translate(offset: Offset(0, -28 * t), child: child),
              ),
              child: Text('+$gain', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text)),
            ),
          ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final String? badge;
  final bool enabled;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.tooltip, required this.onTap, this.badge, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final c = GameColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: c.button,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: c.buttonText, size: 22),
                  if (badge != null)
                    Positioned(
                      right: 3,
                      bottom: 3,
                      child: Text(badge!,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: c.buttonText, height: 1)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool secondary;
  const _BigButton({required this.label, required this.icon, required this.onTap, this.secondary = false});

  @override
  Widget build(BuildContext context) {
    final c = GameColors.of(context);
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: secondary ? c.buttonText : c.button,
        foregroundColor: secondary ? c.button : c.buttonText,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
