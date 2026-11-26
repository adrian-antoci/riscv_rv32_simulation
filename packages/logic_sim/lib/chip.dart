import 'dart:convert';

import 'eval.dart';
import 'wire.dart';

class ChipDef {
  const ChipDef({
    required this.name,
    required this.nodes,
    required this.wires,
    required this.inputIds,
    required this.outputIds,
    required this.placed,
  });

  final String name;
  final List<SimNode> nodes;
  final List<WireLink> wires;
  final List<String> inputIds;
  final List<String> outputIds;
  final List<PlacedNode> placed;

  int get inputCount => inputIds.length;
  int get outputCount => outputIds.length;
}

class PlacedNode {
  const PlacedNode({
    required this.node,
    required this.x,
    required this.y,
    required this.label,
  });

  final SimNode node;
  final double x;
  final double y;
  final String label;
}

/// Inputs and outputs, top to bottom, become the chip pins.
/// Returns null when the name is empty or a pin side is missing.
ChipDef? snapshotChip({
  required String name,
  required List<PlacedNode> placed,
  required List<WireLink> wires,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return null;
  final inputs = placed.where((part) => part.node.gate == Gate.input).toList()
    ..sort((a, b) => a.y.compareTo(b.y));
  final outputs = placed.where((part) => part.node.gate == Gate.output).toList()
    ..sort((a, b) => a.y.compareTo(b.y));
  if (inputs.isEmpty || outputs.isEmpty) return null;
  return ChipDef(
    name: trimmed,
    nodes: [for (final part in placed) part.node],
    wires: wires.toList(),
    inputIds: [for (final part in inputs) part.node.id],
    outputIds: [for (final part in outputs) part.node.id],
    placed: placed,
  );
}

String encodeChips(List<ChipDef> chips) => jsonEncode([for (final chip in chips) _chipToJson(chip)]);

List<ChipDef> decodeChips(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! List) return const [];
  final chips = <ChipDef>[];
  for (final item in decoded) {
    if (item is! Map) continue;
    final chip = _chipFromJson(Map<String, Object?>.from(item));
    if (chip != null) chips.add(chip);
  }
  return chips;
}

Map<String, Object?> _chipToJson(ChipDef chip) => {
  'name': chip.name,
  'wires': [
    for (final wire in chip.wires)
      {
        'fromId': wire.fromId,
        'fromPin': wire.fromPin,
        'toId': wire.toId,
        'toPin': wire.toPin,
      },
  ],
  'placed': [
    for (final part in chip.placed)
      {
        'id': part.node.id,
        'gate': part.node.gate.name,
        'chip': part.node.chip,
        'x': part.x,
        'y': part.y,
        'label': part.label,
      },
  ],
};

ChipDef? _chipFromJson(Map<String, Object?> json) {
    final name = json['name'];
    final placedRaw = json['placed'];
    final wiresRaw = json['wires'];
    if (name is! String || placedRaw is! List || wiresRaw is! List) return null;
    final placed = <PlacedNode>[];
    for (final item in placedRaw) {
      if (item is! Map) return null;
      final map = Map<String, Object?>.from(item);
      final gate = Gate.values.where((value) => value.name == map['gate']).firstOrNull;
      final id = map['id'];
      final x = map['x'];
      final y = map['y'];
      final label = map['label'];
      if (gate == null || id is! String || x is! num || y is! num || label is! String) {
        return null;
      }
      placed.add(
        PlacedNode(
          node: SimNode(id: id, gate: gate, chip: map['chip'] as String?),
          x: x.toDouble(),
          y: y.toDouble(),
          label: label,
        ),
      );
    }
    final wires = <WireLink>[];
    for (final item in wiresRaw) {
      if (item is! Map) return null;
      final map = Map<String, Object?>.from(item);
      final fromId = map['fromId'];
      final toId = map['toId'];
      final fromPin = map['fromPin'];
      final toPin = map['toPin'];
      if (fromId is! String || toId is! String || fromPin is! int || toPin is! int) return null;
      wires.add(WireLink(fromId: fromId, fromPin: fromPin, toId: toId, toPin: toPin));
    }
    return snapshotChip(name: name, placed: placed, wires: wires);
}
