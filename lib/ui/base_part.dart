import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Base for every object on the board.
///
/// The board owns [origin]. This widget reports the pan in the padded box's
/// local coordinates so the board can move the body or start a wire.
class BasePart extends StatefulWidget {
  const BasePart({
    required this.origin,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
    required this.onTap,
    required this.onLongPress,
    required this.child,
    super.key,
  });

  final Offset origin;
  final void Function(Offset local) onPanStart;
  final void Function(Offset local, Offset delta) onPanUpdate;
  final void Function(Offset local) onPanEnd;
  final VoidCallback onPanCancel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Widget child;

  @override
  State<BasePart> createState() => _BasePartState();
}

class _BasePartState extends State<BasePart> {
  var _dragging = false;

  void _setDragging(bool dragging) {
    if (_dragging == dragging) return;
    setState(() => _dragging = dragging);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.origin.dx,
      top: widget.origin.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onPanStart: (details) {
          _setDragging(true);
          widget.onPanStart(details.localPosition);
        },
        onPanUpdate: (details) =>
            widget.onPanUpdate(details.localPosition, details.delta),
        onPanEnd: (details) {
          _setDragging(false);
          widget.onPanEnd(details.localPosition);
        },
        onPanCancel: () {
          _setDragging(false);
          widget.onPanCancel();
        },
        child: MouseRegion(
          cursor: _dragging
              ? SystemMouseCursors.grabbing
              : SystemMouseCursors.grab,
          child: widget.child,
        ),
      ),
    );
  }
}
