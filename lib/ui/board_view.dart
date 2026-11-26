import 'package:flutter/material.dart';
import 'package:logic_sim/logic_sim.dart';
import 'package:riscv_rv32_design/ui/base_part.dart';
import 'package:riscv_rv32_design/ui/board_colors.dart';

enum PartKind { input, andGate, notGate, output, chip }

class PlacedPart {
  PlacedPart({
    required this.id,
    required this.kind,
    required this.origin,
    required this.label,
    required this.inputPinCount,
    required this.outputPinCount,
    required this.inputLevels,
    required this.outputLevels,
    this.chipName,
  });

  final String id;
  final PartKind kind;
  final String? chipName;
  Offset origin;
  final String label;
  final int inputPinCount;
  final int outputPinCount;
  List<Bit> inputLevels;
  List<Bit> outputLevels;
}

class WireDraft {
  const WireDraft({
    required this.fromId,
    required this.fromPin,
    required this.tip,
  });

  final String fromId;
  final int fromPin;
  final Offset tip;
}

class PinHit {
  const PinHit(this.partId, this.index);

  final String partId;
  final int index;
}

class PartGeometry {
  static const pinRadius = 6.0;
  static const pinGrab = 18.0;
  static const wireStart = 12.0;
  static const wireDrop = 18.0;
  static const wireTap = 14.0;
  static const chipSize = Size(120, 80);
  static const terminal = 28.0;
  static const labelGap = 18.0;

  static Size boxSize(PlacedPart part) {
    if (part.kind == PartKind.input || part.kind == PartKind.output) {
      return const Size(terminal, terminal + labelGap);
    }
    final pins = part.inputPinCount > part.outputPinCount
        ? part.inputPinCount
        : part.outputPinCount;
    final height = pins <= 1 ? 64.0 : 28.0 + pins * 32.0;
    return Size(chipSize.width, height);
  }

  static Offset outputAnchor(PlacedPart part, int index) =>
      part.origin + outputLocal(part, index);

  static Offset inputAnchor(PlacedPart part, int index) =>
      part.origin + inputLocal(part, index);

  static Offset outputLocal(PlacedPart part, int index) => switch (part.kind) {
    PartKind.andGate || PartKind.notGate || PartKind.chip => Offset(
      chipSize.width - pinRadius,
      _pinY(index, part.outputPinCount, boxSize(part).height),
    ),
    PartKind.input => const Offset(terminal, terminal / 2),
    PartKind.output => throw StateError('output has no outgoing pin'),
  };

  static Offset inputLocal(PlacedPart part, int index) => switch (part.kind) {
    PartKind.andGate || PartKind.notGate || PartKind.chip => Offset(
      pinRadius,
      _pinY(index, part.inputPinCount, boxSize(part).height),
    ),
    PartKind.output => const Offset(0, terminal / 2),
    PartKind.input => throw StateError('input has no incoming pin'),
  };

  static double _pinY(int index, int count, double height) {
    if (count <= 1) return height / 2;
    const gap = 32.0;
    final span = (count - 1) * gap;
    return (height - span) / 2 + index * gap;
  }
}

List<WireLink> initialWires() => [
  const WireLink(fromId: 'a', fromPin: 0, toId: 'and', toPin: 0),
  const WireLink(fromId: 'b', fromPin: 0, toId: 'and', toPin: 1),
  const WireLink(fromId: 'and', fromPin: 0, toId: 'out', toPin: 0),
];

Offset pointOnWire(Offset start, Offset end, double t) {
  final bend = (end.dx - start.dx).abs() * 0.5;
  final c1 = Offset(start.dx + bend, start.dy);
  final c2 = Offset(end.dx - bend, end.dy);
  final u = 1 - t;
  return start * (u * u * u) +
      c1 * (3 * u * u * t) +
      c2 * (3 * u * t * t) +
      end * (t * t * t);
}

int? outputPinNear(PlacedPart part, Offset boardPoint) {
  int? nearest;
  var best = PartGeometry.wireStart;
  for (var i = 0; i < part.outputPinCount; i++) {
    final distance = (PartGeometry.outputAnchor(part, i) - boardPoint).distance;
    if (distance <= best) {
      best = distance;
      nearest = i;
    }
  }
  return nearest;
}

PinHit? inputPinNear(List<PlacedPart> parts, Offset boardPoint) {
  PinHit? nearest;
  var best = PartGeometry.wireDrop;
  for (final part in parts) {
    for (var i = 0; i < part.inputPinCount; i++) {
      final distance =
          (PartGeometry.inputAnchor(part, i) - boardPoint).distance;
      if (distance <= best) {
        best = distance;
        nearest = PinHit(part.id, i);
      }
    }
  }
  return nearest;
}

WireLink? wireNear(
  List<WireLink> wires,
  List<PlacedPart> parts,
  Offset boardPoint,
) {
  WireLink? nearest;
  var best = PartGeometry.wireTap;
  for (final wire in wires) {
    final from = _findPart(parts, wire.fromId);
    final to = _findPart(parts, wire.toId);
    if (from == null || to == null) continue;
    final start = PartGeometry.outputAnchor(from, wire.fromPin);
    final end = PartGeometry.inputAnchor(to, wire.toPin);
    for (var step = 0; step <= 24; step++) {
      final distance =
          (pointOnWire(start, end, step / 24) - boardPoint).distance;
      if (distance <= best) {
        best = distance;
        nearest = wire;
      }
    }
  }
  return nearest;
}

PlacedPart? _findPart(List<PlacedPart> parts, String id) {
  for (final part in parts) {
    if (part.id == id) return part;
  }
  return null;
}

List<PlacedPart> initialBoard() {
  const a = Bit.zero;
  const b = Bit.zero;
  final andOut = a.and(b);
  return [
    PlacedPart(
      id: 'a',
      kind: PartKind.input,
      origin: const Offset(80, 150),
      label: 'A',
      inputPinCount: 0,
      outputPinCount: 1,
      inputLevels: const [],
      outputLevels: const [a],
    ),
    PlacedPart(
      id: 'b',
      kind: PartKind.input,
      origin: const Offset(80, 240),
      label: 'B',
      inputPinCount: 0,
      outputPinCount: 1,
      inputLevels: const [],
      outputLevels: const [b],
    ),
    PlacedPart(
      id: 'and',
      kind: PartKind.andGate,
      origin: const Offset(300, 176),
      label: 'AND',
      inputPinCount: 2,
      outputPinCount: 1,
      inputLevels: const [a, b],
      outputLevels: [andOut],
    ),
    PlacedPart(
      id: 'out',
      kind: PartKind.output,
      origin: const Offset(540, 202),
      label: 'Out',
      inputPinCount: 1,
      outputPinCount: 0,
      inputLevels: [andOut],
      outputLevels: const [],
    ),
  ];
}

PlacedPart spawnPart(
  PartKind kind, {
  required String id,
  required Offset origin,
}) {
  return switch (kind) {
    PartKind.input => PlacedPart(
      id: id,
      kind: kind,
      origin: origin,
      label: 'In',
      inputPinCount: 0,
      outputPinCount: 1,
      inputLevels: const [],
      outputLevels: const [Bit.zero],
    ),
    PartKind.output => PlacedPart(
      id: id,
      kind: kind,
      origin: origin,
      label: 'Out',
      inputPinCount: 1,
      outputPinCount: 0,
      inputLevels: const [Bit.zero],
      outputLevels: const [],
    ),
    PartKind.andGate => PlacedPart(
      id: id,
      kind: kind,
      origin: origin,
      label: 'AND',
      inputPinCount: 2,
      outputPinCount: 1,
      inputLevels: const [Bit.zero, Bit.zero],
      outputLevels: const [Bit.zero],
    ),
    PartKind.notGate => PlacedPart(
      id: id,
      kind: kind,
      origin: origin,
      label: 'NOT',
      inputPinCount: 1,
      outputPinCount: 1,
      inputLevels: const [Bit.zero],
      outputLevels: const [Bit.zero],
    ),
    PartKind.chip => throw ArgumentError('use placeChip for a created chip'),
  };
}

class BoardCanvas extends StatelessWidget {
  const BoardCanvas({
    required this.parts,
    required this.wires,
    required this.draft,
    required this.isWiring,
    required this.onLift,
    required this.onDrag,
    required this.onWireStart,
    required this.onWireUpdate,
    required this.onWireEnd,
    required this.onWireCancel,
    required this.onDeleteWire,
    required this.onToggle,
    required this.selectedId,
    required this.onSelect,
    required this.onClearSelection,
    required this.onDeletePart,
    super.key,
  });

  final List<PlacedPart> parts;
  final List<WireLink> wires;
  final WireDraft? draft;
  final bool Function(String partId) isWiring;
  final ValueChanged<PlacedPart> onLift;
  final void Function(PlacedPart part, Offset delta, Size board) onDrag;
  final void Function(PlacedPart part, int pin, Offset tip) onWireStart;
  final ValueChanged<Offset> onWireUpdate;
  final ValueChanged<Offset> onWireEnd;
  final VoidCallback onWireCancel;
  final ValueChanged<WireLink> onDeleteWire;
  final ValueChanged<PlacedPart> onToggle;
  final String? selectedId;
  final ValueChanged<PlacedPart> onSelect;
  final VoidCallback onClearSelection;
  final ValueChanged<PlacedPart> onDeletePart;

  PlacedPart _part(String id) => parts.firstWhere((part) => part.id == id);

  Offset _boardPoint(PlacedPart part, Offset local) =>
      part.origin -
      const Offset(PartGeometry.pinGrab, PartGeometry.pinGrab) +
      local;

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);
    return ColoredBox(
      key: const Key('board'),
      color: colors.board,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final board = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _WirePainter(
                    parts: parts,
                    wires: wires,
                    draft: null,
                    partById: _part,
                    colors: colors,
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (details) {
                    final hit = wireNear(wires, parts, details.localPosition);
                    if (hit != null) onDeleteWire(hit);
                    onClearSelection();
                  },
                ),
              ),
              for (final part in parts)
                BasePart(
                  key: ValueKey(part.id),
                  origin:
                      part.origin -
                      const Offset(PartGeometry.pinGrab, PartGeometry.pinGrab),
                  onPanStart: (local) {
                    final point = _boardPoint(part, local);
                    final pin = outputPinNear(part, point);
                    if (pin != null) {
                      onWireStart(part, pin, point);
                    } else {
                      onLift(part);
                    }
                  },
                  onPanUpdate: (local, delta) {
                    final point = _boardPoint(part, local);
                    if (isWiring(part.id)) {
                      onWireUpdate(point);
                    } else {
                      onDrag(part, delta, board);
                    }
                  },
                  onPanEnd: (local) {
                    if (isWiring(part.id)) onWireEnd(_boardPoint(part, local));
                  },
                  onPanCancel: () {
                    if (isWiring(part.id)) onWireCancel();
                  },
                  onTap: () => onSelect(part),
                  onLongPress: () => onDeletePart(part),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: part.id == selectedId
                            ? colors.text
                            : const Color(0x00000000),
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(PartGeometry.pinGrab),
                      child: PartView(
                        key: PartView.levelKey(part),
                        part: part,
                        onToggle: part.kind == PartKind.input
                            ? () => onToggle(part)
                            : null,
                      ),
                    ),
                  ),
                ),
              if (draft != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _WirePainter(
                        parts: parts,
                        wires: const [],
                        draft: draft,
                        partById: _part,
                        colors: colors,
                      ),
                    ),
                  ),
                ),
              SizedBox.shrink(key: Key('wires-${wires.length}')),
            ],
          );
        },
      ),
    );
  }
}

class _WirePainter extends CustomPainter {
  _WirePainter({
    required this.parts,
    required this.wires,
    required this.draft,
    required this.partById,
    required this.colors,
  });

  final List<PlacedPart> parts;
  final List<WireLink> wires;
  final WireDraft? draft;
  final PlacedPart Function(String id) partById;
  final BoardColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    for (final wire in wires) {
      final from = partById(wire.fromId);
      final to = partById(wire.toId);
      final start = PartGeometry.outputAnchor(from, wire.fromPin);
      final end = PartGeometry.inputAnchor(to, wire.toPin);
      final level = from.outputLevels[wire.fromPin];
      final on = level == Bit.one;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = on ? colors.wireWidthOn : colors.wireWidth
        ..strokeCap = StrokeCap.round
        ..color = on ? colors.signalOn : colors.wire;
      _drawCurve(canvas, start, end, paint);
    }
    final draft = this.draft;
    if (draft == null) return;
    final from = _findPart(parts, draft.fromId);
    if (from == null) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = colors.wireWidth
      ..strokeCap = StrokeCap.round
      ..color = colors.wire;
    _drawCurve(
      canvas,
      PartGeometry.outputAnchor(from, draft.fromPin),
      draft.tip,
      paint,
    );
  }

  void _drawCurve(Canvas canvas, Offset start, Offset end, Paint paint) {
    final bend = (end.dx - start.dx).abs() * 0.5;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx + bend,
        start.dy,
        end.dx - bend,
        end.dy,
        end.dx,
        end.dy,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WirePainter oldDelegate) => true;
}

class PartView extends StatelessWidget {
  const PartView({required this.part, this.onToggle, super.key});

  final VoidCallback? onToggle;

  static Key levelKey(PlacedPart part) {
    final level = part.outputLevels.isNotEmpty
        ? part.outputLevels.single
        : part.inputLevels.single;
    return Key('level-${part.id}-${level.value}');
  }

  final PlacedPart part;

  @override
  Widget build(BuildContext context) {
    return switch (part.kind) {
      PartKind.input => _Terminal(
        label: part.label,
        level: part.outputLevels.single,
        onToggle: onToggle,
      ),
      PartKind.output => _Terminal(
        label: part.label,
        level: part.inputLevels.single,
        filled: false,
      ),
      PartKind.andGate ||
      PartKind.notGate ||
      PartKind.chip => _GateChip(part: part),
    };
  }
}

class _GateChip extends StatelessWidget {
  const _GateChip({required this.part});

  final PlacedPart part;

  @override
  Widget build(BuildContext context) {
    final size = PartGeometry.boxSize(part);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: BoardColors.of(context).chip,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: BoardColors.of(context).chipBorder,
                width: BoardColors.of(context).borderWidth,
              ),
            ),
            child: Center(
              child: Text(
                part.label,
                style: TextStyle(
                  color: BoardColors.of(context).text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          for (var i = 0; i < part.inputLevels.length; i++)
            _Pin(
              level: part.inputLevels[i],
              at: PartGeometry.inputLocal(part, i),
            ),
          for (var i = 0; i < part.outputLevels.length; i++)
            _Pin(
              level: part.outputLevels[i],
              at: PartGeometry.outputLocal(part, i),
            ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.level, required this.at});

  final Bit level;
  final Offset at;

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);
    final on = level == Bit.one;
    return Positioned(
      left: at.dx - PartGeometry.pinRadius,
      top: at.dy - PartGeometry.pinRadius,
      child: Container(
        width: PartGeometry.pinRadius * 2,
        height: PartGeometry.pinRadius * 2,
        decoration: BoxDecoration(
          color: on ? colors.signalOn : colors.signalOff,
          shape: BoxShape.circle,
          border: Border.all(color: colors.text, width: colors.borderWidth),
        ),
      ),
    );
  }
}

class _Terminal extends StatelessWidget {
  const _Terminal({
    required this.label,
    required this.level,
    this.filled = true,
    this.onToggle,
  });

  final String label;
  final Bit level;
  final bool filled;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);
    final on = level == Bit.one;
    final mark = on ? colors.signalOn : colors.signalOff;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: PartGeometry.terminal,
            height: PartGeometry.terminal,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled || on ? mark : colors.board,
              border: Border.all(
                color: colors.text,
                width: on ? colors.wireWidthOn / 2 : colors.borderWidth,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: colors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
