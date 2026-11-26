import 'package:logic_sim/logic_sim.dart';
import 'package:test/test.dart';

void main() {
  const and = SimNode(id: 'and', gate: Gate.and);
  const a = SimNode(id: 'a', gate: Gate.input);
  const b = SimNode(id: 'b', gate: Gate.input);
  const out = SimNode(id: 'out', gate: Gate.output);
  const not = SimNode(id: 'not', gate: Gate.not);

  CircuitLevels run(Map<String, Bit> levels) {
    return evaluate(
      nodes: const [a, b, and, out, not],
      wires: const [
        WireLink(fromId: 'a', fromPin: 0, toId: 'and', toPin: 0),
        WireLink(fromId: 'b', fromPin: 0, toId: 'and', toPin: 1),
        WireLink(fromId: 'and', fromPin: 0, toId: 'not', toPin: 0),
        WireLink(fromId: 'not', fromPin: 0, toId: 'out', toPin: 0),
      ],
      inputLevels: levels,
    );
  }

  test('AND is on only when both inputs are on', () {
    expect(run({}).outputsOf('and').single, Bit.zero);
    expect(run({'a': Bit.one}).outputsOf('and').single, Bit.zero);
    expect(run({'a': Bit.one, 'b': Bit.one}).outputsOf('and').single, Bit.one);
  });

  test('NOT after AND inverts the lamp', () {
    final both = run({'a': Bit.one, 'b': Bit.one});
    expect(both.outputsOf('not').single, Bit.zero);
    expect(both.inputsOf('out').single, Bit.zero);

    final one = run({'a': Bit.one});
    expect(one.outputsOf('and').single, Bit.zero);
    expect(one.outputsOf('not').single, Bit.one);
    expect(one.inputsOf('out').single, Bit.one);
  });
}
