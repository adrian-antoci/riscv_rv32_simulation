import 'bit.dart';
import 'chip.dart';
import 'wire.dart';

enum Gate { input, and, not, output, chip }

class SimNode {
  const SimNode({required this.id, required this.gate, this.chip});

  final String id;
  final Gate gate;
  final String? chip;
}

class CircuitLevels {
  const CircuitLevels({required this.inputs, required this.outputs});

  final Map<String, List<Bit>> inputs;
  final Map<String, List<Bit>> outputs;

  List<Bit> inputsOf(String id) => inputs[id] ?? const [];

  List<Bit> outputsOf(String id) => outputs[id] ?? const [];
}

/// Walks an acyclic circuit. An undriven pin reads as 0.
/// A [Gate.chip] node runs its [ChipDef] from [chips].
CircuitLevels evaluate({
  required Iterable<SimNode> nodes,
  required Iterable<WireLink> wires,
  required Map<String, Bit> inputLevels,
  Map<String, ChipDef> chips = const {},
  int depth = 0,
}) {
  final nodeList = nodes.toList();
  final outputs = <String, List<Bit>>{
    for (final node in nodeList) node.id: _initialOutputs(node, chips, inputLevels),
  };
  final driven = <String, Map<int, WireLink>>{};
  for (final wire in wires) {
    driven.putIfAbsent(wire.toId, () => {})[wire.toPin] = wire;
  }

  Bit read(String id, int pin) {
    final wire = driven[id]?[pin];
    if (wire == null) return Bit.zero;
    final source = outputs[wire.fromId];
    if (source == null || wire.fromPin >= source.length) return Bit.zero;
    return source[wire.fromPin];
  }

  for (var pass = 0; pass < nodeList.length + 1; pass++) {
    var changed = false;
    for (final node in nodeList) {
      final next = _nextOutputs(node, read, chips, depth);
      if (next == null || _same(outputs[node.id]!, next)) continue;
      outputs[node.id] = next;
      changed = true;
    }
    if (!changed) break;
  }

  final inputs = <String, List<Bit>>{};
  for (final node in nodeList) {
    final count = _inputCount(node, chips);
    inputs[node.id] = [for (var i = 0; i < count; i++) read(node.id, i)];
  }
  return CircuitLevels(inputs: inputs, outputs: outputs);
}

List<Bit> _initialOutputs(
  SimNode node,
  Map<String, ChipDef> chips,
  Map<String, Bit> inputLevels,
) {
  return switch (node.gate) {
    Gate.input => [inputLevels[node.id] ?? Bit.zero],
    Gate.output => const [],
    Gate.and || Gate.not => [Bit.zero],
    Gate.chip => List.filled(_outputCount(node, chips), Bit.zero),
  };
}

List<Bit>? _nextOutputs(
  SimNode node,
  Bit Function(String id, int pin) read,
  Map<String, ChipDef> chips,
  int depth,
) {
  return switch (node.gate) {
    Gate.and => [read(node.id, 0).and(read(node.id, 1))],
    Gate.not => [read(node.id, 0).not],
    Gate.chip => _chipOutputs(node, read, chips, depth),
    Gate.input || Gate.output => null,
  };
}

List<Bit> _chipOutputs(
  SimNode node,
  Bit Function(String id, int pin) read,
  Map<String, ChipDef> chips,
  int depth,
) {
  final def = node.chip == null ? null : chips[node.chip];
  if (def == null || depth > 12) return List.filled(def?.outputCount ?? 0, Bit.zero);
  final inner = evaluate(
    nodes: def.nodes,
    wires: def.wires,
    inputLevels: {
      for (var i = 0; i < def.inputIds.length; i++) def.inputIds[i]: read(node.id, i),
    },
    chips: chips,
    depth: depth + 1,
  );
  return [
    for (final id in def.outputIds)
      inner.inputsOf(id).isEmpty ? Bit.zero : inner.inputsOf(id).single,
  ];
}

int _inputCount(SimNode node, Map<String, ChipDef> chips) => switch (node.gate) {
  Gate.input => 0,
  Gate.output || Gate.not => 1,
  Gate.and => 2,
  Gate.chip => node.chip == null ? 0 : chips[node.chip]?.inputCount ?? 0,
};

int _outputCount(SimNode node, Map<String, ChipDef> chips) => switch (node.gate) {
  Gate.output => 0,
  Gate.input || Gate.and || Gate.not => 1,
  Gate.chip => node.chip == null ? 0 : chips[node.chip]?.outputCount ?? 0,
};

bool _same(List<Bit> a, List<Bit> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
