import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logic_sim/logic_sim.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riscv_rv32_design/ui/board_colors.dart';
import 'package:riscv_rv32_design/ui/board_view.dart';
import 'package:riscv_rv32_design/ui/lessons.dart';

void main() {
  runApp(const SandboxApp());
}

class SandboxApp extends StatelessWidget {
  const SandboxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logic Sandbox',
      debugShowCheckedModeBanner: false,
      theme: _theme(
        defaultTargetPlatform == TargetPlatform.android
            ? BoardColors.ink
            : BoardColors.dark,
      ),
      home: const SandboxScreen(),
    );
  }
}

ThemeData _theme(BoardColors colors) {
  final ink = colors == BoardColors.ink;
  return ThemeData(
    brightness: ink ? Brightness.light : Brightness.dark,
    scaffoldBackgroundColor: colors.board,
    colorScheme: ColorScheme(
      brightness: ink ? Brightness.light : Brightness.dark,
      surface: colors.bar,
      primary: colors.buttonBorder,
      onPrimary: colors.board,
      secondary: colors.text,
      onSecondary: colors.board,
      error: colors.text,
      onError: colors.board,
      onSurface: colors.text,
    ),
  );
}

class SandboxScreen extends StatefulWidget {
  const SandboxScreen({super.key});

  @override
  State<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  final _parts = initialBoard();
  final _wires = initialWires();
  final _inputLevels = <String, Bit>{};
  final _chips = <ChipDef>[];
  _SuspendedBoard? _suspended;
  String? _editing;
  WireDraft? _draft;
  String? _selectedId;
  int? _lessonIndex;
  var _sandbox = false;
  var _lessonsOpen = true;
  var _spawned = 0;

  static const _chipStoreKey = 'created-chips';

  @override
  void initState() {
    super.initState();
    _applyLevels();
    _loadChips();
  }

  bool get _skipStore => Platform.environment['FLUTTER_TEST'] == 'true';

  Future<void> _loadChips() async {
    if (_skipStore) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_chipStoreKey);
      if (raw == null || !mounted) return;
      final chips = decodeChips(raw);
      setState(() {
        _chips
          ..clear()
          ..addAll(chips);
      });
    } catch (_) {}
  }

  Future<void> _storeChips() async {
    if (_skipStore) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chipStoreKey, encodeChips(_chips));
  }

  void _place(PartKind kind) {
    final n = _spawned;
    setState(() {
      _parts.add(
        spawnPart(
          kind,
          id: 'spawn-$n',
          origin: Offset(220 + (n % 5) * 28, 36 + (n % 4) * 24),
        ),
      );
      _selectedId = 'spawn-$n';
      _spawned++;
    });
    _settle();
  }

  void _lift(PlacedPart part) {
    setState(() {
      _parts
        ..remove(part)
        ..add(part);
    });
  }

  void _drag(PlacedPart part, Offset delta, Size board) {
    final size = PartGeometry.boxSize(part);
    final roomX = board.width - size.width;
    final roomY = board.height - size.height;
    setState(() {
      part.origin = Offset(
        (part.origin.dx + delta.dx)
            .clamp(0.0, roomX < 0 ? 0.0 : roomX)
            .toDouble(),
        (part.origin.dy + delta.dy)
            .clamp(0.0, roomY < 0 ? 0.0 : roomY)
            .toDouble(),
      );
    });
  }

  void _startWire(PlacedPart part, int pin, Offset tip) {
    _draft = WireDraft(fromId: part.id, fromPin: pin, tip: tip);
    setState(() {});
  }

  void _updateWire(Offset tip) {
    final draft = _draft;
    if (draft == null) return;
    setState(
      () => _draft = WireDraft(
        fromId: draft.fromId,
        fromPin: draft.fromPin,
        tip: tip,
      ),
    );
  }

  void _endWire(Offset tip) {
    final draft = _draft;
    if (draft == null) return;
    final hit = inputPinNear(_parts, tip);
    final link = hit == null
        ? null
        : tryConnect(
            _wires,
            fromId: draft.fromId,
            fromPin: draft.fromPin,
            toId: hit.partId,
            toPin: hit.index,
          );
    setState(() {
      _draft = null;
      if (link != null) _wires.add(link);
    });
    if (link != null) _settle();
  }

  void _cancelWire() => setState(() => _draft = null);

  void _deleteWire(WireLink wire) {
    _wires.remove(wire);
    _settle();
  }

  void _toggle(PlacedPart part) {
    _selectedId = part.id;
    _inputLevels[part.id] = (_inputLevels[part.id] ?? Bit.zero).not;
    _settle();
  }

  void _select(PlacedPart part) => setState(() => _selectedId = part.id);

  void _removePart(PlacedPart part) {
    setState(() {
      _parts.remove(part);
      _wires.removeWhere(
        (wire) => wire.fromId == part.id || wire.toId == part.id,
      );
      _inputLevels.remove(part.id);
      if (_selectedId == part.id) _selectedId = null;
      if (_draft?.fromId == part.id) _draft = null;
    });
    _settle();
  }

  void _removeSelected() {
    final id = _selectedId;
    if (id == null) return;
    for (final part in _parts) {
      if (part.id == id) {
        _removePart(part);
        return;
      }
    }
  }

  LampReadout get _lamps {
    final outputs = [
      for (final part in _parts)
        if (part.kind == PartKind.output) part,
    ]..sort((a, b) => a.origin.dy.compareTo(b.origin.dy));
    return LampReadout([
      for (final part in outputs)
        part.inputLevels.isEmpty ? 0 : part.inputLevels.single.value,
    ]);
  }

  void _settle() => setState(_applyLevels);

  void _applyLevels() {
    final levels = evaluate(
      nodes: [
        for (final part in _parts)
          SimNode(id: part.id, gate: _gate(part.kind), chip: part.chipName),
      ],
      wires: _wires,
      inputLevels: _inputLevels,
      chips: {for (final chip in _chips) chip.name: chip},
    );
    for (final part in _parts) {
      part.inputLevels = levels.inputsOf(part.id);
      part.outputLevels = levels.outputsOf(part.id);
    }
  }

  Gate _gate(PartKind kind) => switch (kind) {
    PartKind.input => Gate.input,
    PartKind.andGate => Gate.and,
    PartKind.notGate => Gate.not,
    PartKind.output => Gate.output,
    PartKind.chip => Gate.chip,
  };

  Future<void> _create() async {
    final name = await _askName();
    if (name == null || !mounted) return;
    final chip = snapshotChip(
      name: name,
      placed: [
        for (final part in _parts)
          PlacedNode(
            node: SimNode(
              id: part.id,
              gate: _gate(part.kind),
              chip: part.chipName,
            ),
            x: part.origin.dx,
            y: part.origin.dy,
            label: part.label,
          ),
      ],
      wires: _wires,
    );
    if (chip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need a name, an input, and an output.')),
      );
      return;
    }
    setState(() {
      _chips.removeWhere((existing) => existing.name == chip.name);
      _chips.add(chip);
      _parts.clear();
      _wires.clear();
      _inputLevels.clear();
      _draft = null;
      _selectedId = null;
    });
    await _storeChips();
  }

  Future<String?> _askName() {
    return showDialog<String>(
      context: context,
      builder: (context) => const _NameDialog(),
    );
  }

  void _editChip(ChipDef chip) {
    if (_editing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save or cancel $_editing first.')),
      );
      return;
    }
    setState(() {
      _suspended = _SuspendedBoard(
        parts: [..._parts],
        wires: [..._wires],
        inputLevels: Map.of(_inputLevels),
      );
      _editing = chip.name;
      _parts
        ..clear()
        ..addAll(chip.placed.map(_partFrom));
      _wires
        ..clear()
        ..addAll(chip.wires);
      _inputLevels.clear();
      _draft = null;
      _selectedId = null;
    });
    _settle();
  }

  Future<void> _saveEdit() async {
    final name = _editing;
    if (name == null) return;
    final chip = snapshotChip(
      name: name,
      placed: _placedNodes(),
      wires: _wires,
    );
    if (chip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need an input and an output.')),
      );
      return;
    }
    setState(() {
      final index = _chips.indexWhere((existing) => existing.name == name);
      if (index >= 0) {
        _chips[index] = chip;
      } else {
        _chips.add(chip);
      }
      _restoreSuspended();
    });
    _settle();
    await _storeChips();
  }

  void _cancelEdit() {
    setState(_restoreSuspended);
    _settle();
  }

  Future<void> _deleteEdit() async {
    final name = _editing;
    if (name == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $name?'),
        content: const Text(
          'This removes it from the bar. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _chips.removeWhere((chip) => chip.name == name);
      _restoreSuspended();
    });
    _settle();
    await _storeChips();
  }

  void _restoreSuspended() {
    final suspended = _suspended;
    _editing = null;
    _draft = null;
    _inputLevels.clear();
    if (suspended == null) return;
    _parts
      ..clear()
      ..addAll(suspended.parts);
    _wires
      ..clear()
      ..addAll(suspended.wires);
    _inputLevels.addAll(suspended.inputLevels);
    _suspended = null;
  }

  List<PlacedNode> _placedNodes() {
    return [
      for (final part in _parts)
        PlacedNode(
          node: SimNode(
            id: part.id,
            gate: _gate(part.kind),
            chip: part.chipName,
          ),
          x: part.origin.dx,
          y: part.origin.dy,
          label: part.label,
        ),
    ];
  }

  PlacedPart _partFrom(PlacedNode placed) {
    final counts = _pinCounts(placed.node);
    return PlacedPart(
      id: placed.node.id,
      kind: _kind(placed.node.gate),
      chipName: placed.node.chip,
      origin: Offset(placed.x, placed.y),
      label: placed.label,
      inputPinCount: counts.$1,
      outputPinCount: counts.$2,
      inputLevels: List.filled(counts.$1, Bit.zero),
      outputLevels: List.filled(counts.$2, Bit.zero),
    );
  }

  (int, int) _pinCounts(SimNode node) {
    return switch (node.gate) {
      Gate.input => (0, 1),
      Gate.output => (1, 0),
      Gate.not => (1, 1),
      Gate.and => (2, 1),
      Gate.chip => () {
        for (final chip in _chips) {
          if (chip.name == node.chip)
            return (chip.inputCount, chip.outputCount);
        }
        return (0, 0);
      }(),
    };
  }

  PartKind _kind(Gate gate) => switch (gate) {
    Gate.input => PartKind.input,
    Gate.and => PartKind.andGate,
    Gate.not => PartKind.notGate,
    Gate.output => PartKind.output,
    Gate.chip => PartKind.chip,
  };

  void _placeSaved(String name) {
    for (final chip in _chips) {
      if (chip.name == name) {
        _placeChip(chip);
        return;
      }
    }
  }

  void _placeChip(ChipDef chip) {
    final n = _spawned;
    setState(() {
      _parts.add(
        PlacedPart(
          id: 'spawn-$n',
          kind: PartKind.chip,
          chipName: chip.name,
          origin: Offset(220 + (n % 5) * 28, 36 + (n % 4) * 24),
          label: chip.name,
          inputPinCount: chip.inputCount,
          outputPinCount: chip.outputCount,
          inputLevels: List.filled(chip.inputCount, Bit.zero),
          outputLevels: List.filled(chip.outputCount, Bit.zero),
        ),
      );
      _selectedId = 'spawn-$n';
      _spawned++;
    });
    _settle();
  }

  void _reset() {
    setState(() {
      _parts
        ..clear()
        ..addAll(initialBoard());
      _wires
        ..clear()
        ..addAll(initialWires());
      _draft = null;
      _spawned = 0;
      _inputLevels.clear();
      _selectedId = null;
    });
    _settle();
  }

  LessonPanel _lessonPanel() {
    return LessonPanel(
      sandbox: _sandbox,
      lessonIndex: _lessonIndex,
      savedChips: [for (final chip in _chips) chip.name],
      lamps: _lamps,
      onSandbox: () => setState(() {
        _sandbox = true;
        _lessonIndex = null;
      }),
      onPick: (index) => setState(() {
        _sandbox = false;
        _lessonIndex = index;
      }),
      onPlaceSaved: _placeSaved,
      onBack: () => setState(() {
        _sandbox = false;
        _lessonIndex = null;
      }),
      onPrevious: () => setState(() => _lessonIndex = _lessonIndex! - 1),
      onNext: () => setState(() => _lessonIndex = _lessonIndex! + 1),
      onHide: () => setState(() => _lessonsOpen = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.delete): _removeSelected,
        const SingleActivator(LogicalKeyboardKey.backspace): _removeSelected,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final beside = constraints.maxWidth >= 720;
                    return Stack(
                      children: [
                        Row(
                          children: [
                            if (_lessonsOpen && beside) _lessonPanel(),
                            Expanded(
                              child: BoardCanvas(
                                parts: _parts,
                                wires: _wires,
                                draft: _draft,
                                isWiring: (id) => _draft?.fromId == id,
                                onLift: _lift,
                                onDrag: _drag,
                                onWireStart: _startWire,
                                onWireUpdate: _updateWire,
                                onWireEnd: _endWire,
                                onWireCancel: _cancelWire,
                                onDeleteWire: _deleteWire,
                                onToggle: _toggle,
                                selectedId: _selectedId,
                                onSelect: _select,
                                onClearSelection: () =>
                                    setState(() => _selectedId = null),
                                onDeletePart: _removePart,
                              ),
                            ),
                          ],
                        ),
                        if (_lessonsOpen && !beside)
                          Positioned.fill(child: _lessonPanel()),
                        if (!_lessonsOpen)
                          Positioned(
                            left: 12,
                            top: 12,
                            child: _PaletteButton(
                              label: 'Lessons',
                              onPressed: () =>
                                  setState(() => _lessonsOpen = true),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              PaletteBar(
                chips: _chips,
                editing: _editing,
                canRemove: _selectedId != null,
                onPlace: _place,
                onPlaceChip: _placeChip,
                onEditChip: _editChip,
                onCreate: _create,
                onSave: _saveEdit,
                onDeleteEdit: _deleteEdit,
                onRemove: _removeSelected,
                onReset: _reset,
                onCancelEdit: _cancelEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog();

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Name this chip'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(hintText: 'NAND'),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _SuspendedBoard {
  const _SuspendedBoard({
    required this.parts,
    required this.wires,
    required this.inputLevels,
  });

  final List<PlacedPart> parts;
  final List<WireLink> wires;
  final Map<String, Bit> inputLevels;
}

class PaletteBar extends StatelessWidget {
  const PaletteBar({
    required this.chips,
    required this.editing,
    required this.onPlace,
    required this.onPlaceChip,
    required this.onEditChip,
    required this.onCreate,
    required this.onSave,
    required this.onDeleteEdit,
    required this.canRemove,
    required this.onRemove,
    required this.onReset,
    required this.onCancelEdit,
    super.key,
  });

  final List<ChipDef> chips;
  final String? editing;
  final bool canRemove;
  final ValueChanged<PartKind> onPlace;
  final ValueChanged<ChipDef> onPlaceChip;
  final ValueChanged<ChipDef> onEditChip;
  final VoidCallback onCreate;
  final VoidCallback onSave;
  final VoidCallback onDeleteEdit;
  final VoidCallback onRemove;
  final VoidCallback onReset;
  final VoidCallback onCancelEdit;

  static const _items = [
    (label: 'AND', kind: PartKind.andGate),
    (label: 'NOT', kind: PartKind.notGate),
    (label: 'Input', kind: PartKind.input),
    (label: 'Output', kind: PartKind.output),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bar,
        border: Border(
          top: BorderSide(color: colors.text, width: colors.borderWidth),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final item in _items) ...[
                  _PaletteButton(
                    label: item.label,
                    onPressed: () => onPlace(item.kind),
                  ),
                  const SizedBox(width: 8),
                ],
                for (final chip in chips) ...[
                  _PaletteButton(
                    label: chip.name,
                    onPressed: () => onPlaceChip(chip),
                    onLongPress: () => onEditChip(chip),
                  ),
                  const SizedBox(width: 8),
                ],
                const SizedBox(width: 8),
                if (canRemove) ...[
                  _PaletteButton(label: 'Remove', onPressed: onRemove),
                  const SizedBox(width: 8),
                ],
                _PaletteButton(
                  label: editing == null ? 'Create' : 'Save',
                  onPressed: editing == null ? onCreate : onSave,
                ),
                const SizedBox(width: 8),
                if (editing != null) ...[
                  _PaletteButton(label: 'Delete', onPressed: onDeleteEdit),
                  const SizedBox(width: 8),
                ],
                _PaletteButton(
                  label: editing == null ? 'Reset' : 'Cancel',
                  onPressed: editing == null ? onReset : onCancelEdit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteButton extends StatelessWidget {
  const _PaletteButton({
    required this.label,
    required this.onPressed,
    this.onLongPress,
  });

  final String label;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);
    final enabled = onPressed != null;
    return OutlinedButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? colors.buttonText : colors.disabledText,
        disabledForegroundColor: colors.disabledText,
        backgroundColor: colors.board,
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        splashFactory: NoSplash.splashFactory,
        overlayColor: const Color(0x00000000),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(
          color: enabled ? colors.buttonBorder : colors.disabledBorder,
          width: 1.5,
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
