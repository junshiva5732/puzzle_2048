import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ads/ad_manager.dart';
import '../game/game.dart';
import '../l10n/strings.dart';
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

  S get _s => S.of(context);

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

  void _showAdNotReady() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.adNotReady)));
    AdManager.instance.loadRewarded();
  }

  /// 되돌리기 횟수 소진 → 보상형 광고로 충전.
  Future<void> _offerUndoRefill() async {
    final s = _s;
    final watch = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.refillTitle),
        content: Text(s.refillBody(Game.undoRefill)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.play_circle_outline),
            label: Text(s.watchAd),
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
    if (!shown && mounted) _showAdNotReady();
  }

  /// 게임오버 → 보상형 광고 → 작은 타일을 지우고 이어하기.
  void _continueWithAd() {
    final shown = AdManager.instance.showRewarded(onReward: () {
      if (!mounted) return;
      setState(() {
        _game.revive();
        _ghosts = const [];
        _overlay = _Overlay.none;
      });
      widget.storage.saveGame(_game);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s.revived)));
    });
    if (!shown) _showAdNotReady();
  }

  Future<void> _newGame() async {
    // 진행 중인 게임이 있으면 확인
    if (_overlay == _Overlay.none && _game.score > 0) {
      final s = _s;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.newGame),
          content: Text(s.newGameBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.start)),
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
    final s = _s;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.howToPlay),
        content: Text(s.helpBody(Game.freeUndos, Game.undoRefill)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.ok))],
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
    final s = _s;
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
                _ScoreBox(label: s.score, value: _game.score, gain: _lastGain, gainSerial: _gainSerial),
                const SizedBox(width: 8),
                _ScoreBox(label: s.best, value: _best),
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
                    s.subtitle,
                    style: TextStyle(color: c.textMuted, fontSize: 14),
                  ),
                ),
                _IconButton(
                  icon: Icons.undo,
                  badge: _game.undosLeft > 0 ? '${_game.undosLeft}' : 'AD',
                  tooltip: s.undo,
                  enabled: _game.canUndo,
                  onTap: _undo,
                ),
                const SizedBox(width: 6),
                _IconButton(icon: Icons.refresh, tooltip: s.newGame, onTap: _newGame),
                const SizedBox(width: 6),
                _IconButton(icon: Icons.help_outline, tooltip: s.howToPlay, onTap: _showHelp),
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
    final s = _s;
    final visible = _overlay != _Overlay.none;
    final won = _overlay == _Overlay.won;
    final fg = won ? const Color(0xFFF9F6F2) : c.text;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 350),
        child: Container(
          decoration: BoxDecoration(
            color: (won ? const Color(0xFFEDC22E) : c.background).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(side * 0.03),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                won ? s.youWin : s.gameOver,
                style: TextStyle(fontSize: side * 0.12, fontWeight: FontWeight.w900, color: fg),
              ),
              const SizedBox(height: 4),
              Text(
                s.scoreLine(_game.score),
                style: TextStyle(fontSize: side * 0.055, color: won ? fg : c.textMuted),
              ),
              const SizedBox(height: 20),
              if (won) ...[
                _BigButton(label: s.keepGoing, icon: Icons.play_arrow, onTap: _keepPlaying),
              ] else ...[
                // 이어하기(보상형)는 항상 노출. 되돌리기는 무료 횟수가 남았을 때만.
                _BigButton(label: s.continueWithAd, icon: Icons.play_circle_outline, onTap: _continueWithAd),
                if (_game.canUndo && _game.undosLeft > 0) ...[
                  const SizedBox(height: 10),
                  _BigButton(label: s.undoLeft(_game.undosLeft), icon: Icons.undo, onTap: _undo, secondary: true),
                ],
              ],
              const SizedBox(height: 10),
              _BigButton(label: s.newGame, icon: Icons.refresh, onTap: _newGame, secondary: true),
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
