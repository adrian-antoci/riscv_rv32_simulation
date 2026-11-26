import 'package:logic_sim/logic_sim.dart';
import 'package:test/test.dart';

void main() {
  ChipDef nand() {
    return snapshotChip(
      name: 'NAND',
      placed: const [
        PlacedNode(node: SimNode(id: 'a', gate: Gate.input), x: 0, y: 10, label: 'A'),
        PlacedNode(node: SimNode(id: 'b', gate: Gate.input), x: 0, y: 40, label: 'B'),
        PlacedNode(node: SimNode(id: 'and', gate: Gate.and), x: 80, y: 20, label: 'AND'),
        PlacedNode(node: SimNode(id: 'not', gate: Gate.not), x: 160, y: 20, label: 'NOT'),
        PlacedNode(node: SimNode(id: 'out', gate: Gate.output), x: 240, y: 20, label: 'Out'),
      ],
      wires: const [
        WireLink(fromId: 'a', fromPin: 0, toId: 'and', toPin: 0),
        WireLink(fromId: 'b', fromPin: 0, toId: 'and', toPin: 1),
        WireLink(fromId: 'and', fromPin: 0, toId: 'not', toPin: 0),
        WireLink(fromId: 'not', fromPin: 0, toId: 'out', toPin: 0),
      ],
    )!;
  }

  Bit run(Bit a, Bit b) {
    final chip = nand();
    final levels = evaluate(
      nodes: [
        const SimNode(id: 'a', gate: Gate.input),
        const SimNode(id: 'b', gate: Gate.input),
        const SimNode(id: 'nand', gate: Gate.chip, chip: 'NAND'),
        const SimNode(id: 'out', gate: Gate.output),
      ],
      wires: const [
        WireLink(fromId: 'a', fromPin: 0, toId: 'nand', toPin: 0),
        WireLink(fromId: 'b', fromPin: 0, toId: 'nand', toPin: 1),
        WireLink(fromId: 'nand', fromPin: 0, toId: 'out', toPin: 0),
      ],
      inputLevels: {'a': a, 'b': b},
      chips: {'NAND': chip},
    );
    return levels.inputsOf('out').single;
  }

  test('pin order is top to bottom', () {
    final chip = nand();
    expect(chip.inputIds, ['a', 'b']);
    expect(chip.outputIds, ['out']);
  });

  test('NAND is off only when both inputs are on', () {
    expect(run(Bit.zero, Bit.zero), Bit.one);
    expect(run(Bit.one, Bit.zero), Bit.one);
    expect(run(Bit.zero, Bit.one), Bit.one);
    expect(run(Bit.one, Bit.one), Bit.zero);
  });

  test('a chip survives a save and load', () {
    final restored = decodeChips(encodeChips([nand()])).single;
    expect(restored.name, 'NAND');
    expect(restored.inputIds, ['a', 'b']);
    expect(restored.placed.singleWhere((part) => part.node.id == 'not').label, 'NOT');
    expect(run(Bit.one, Bit.one), Bit.zero);
  });

  test('an empty name or a missing pin side does not create a chip', () {
    expect(
      snapshotChip(name: '  ', placed: const [], wires: const []),
      isNull,
    );
    expect(
      snapshotChip(
        name: 'X',
        placed: const [PlacedNode(node: SimNode(id: 'a', gate: Gate.input), x: 0, y: 0, label: 'A')],
        wires: const [],
      ),
      isNull,
    );
  });
}
