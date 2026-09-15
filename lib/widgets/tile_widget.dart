import 'package:flutter/material.dart';

import '../game/game.dart';
import '../theme/game_colors.dart';

/// 타일 하나. 등장(새 타일)과 팝(합쳐진 타일) 애니메이션을 스스로 처리한다.
/// 위치 이동은 부모의 [AnimatedPositioned] 가 담당한다.
class TileWidget extends StatefulWidget {
  final Tile tile;
  final double size;
  const TileWidget({super.key, required this.tile, required this.size});

  @override
  State<TileWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _scale;
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.tile.value;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    if (widget.tile.isNew) {
      _scale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
      _ctrl.forward();
    } else if (widget.tile.merged) {
      _pop();
    } else {
      _scale = const AlwaysStoppedAnimation(1.0);
    }
  }

  void _pop() {
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(_ctrl);
    _ctrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(TileWidget old) {
    super.didUpdateWidget(old);
    if (widget.tile.value != _value) {
      _value = widget.tile.value;
      if (widget.tile.merged) _pop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.tile.value;
    final digits = v.toString().length;
    final fontSize = widget.size * (digits <= 2 ? 0.5 : digits == 3 ? 0.42 : digits == 4 ? 0.34 : 0.28);
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: GameColors.tile(v),
          borderRadius: BorderRadius.circular(widget.size * 0.08),
          boxShadow: v >= 128
              ? [BoxShadow(color: GameColors.tile(v).withValues(alpha: 0.45), blurRadius: widget.size * 0.2)]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$v',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: GameColors.tileText(v),
            height: 1,
          ),
        ),
      ),
    );
  }
}
