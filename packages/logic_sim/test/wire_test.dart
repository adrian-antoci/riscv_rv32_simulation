import 'package:logic_sim/wire.dart';
import 'package:test/test.dart';

void main() {
  test('an output can drive a free input', () {
    final link = tryConnect(
      const [],
      fromId: 'a',
      fromPin: 0,
      toId: 'and',
      toPin: 0,
    );

    expect(link, const WireLink(fromId: 'a', fromPin: 0, toId: 'and', toPin: 0));
  });

  test('a second wire onto a driven input is rejected', () {
    const existing = WireLink(fromId: 'a', fromPin: 0, toId: 'and', toPin: 0);

    expect(
      tryConnect([existing], fromId: 'b', fromPin: 0, toId: 'and', toPin: 0),
      isNull,
    );
  });

  test('the other input pin of the same part stays free', () {
    const existing = WireLink(fromId: 'a', fromPin: 0, toId: 'and', toPin: 0);

    expect(
      tryConnect([existing], fromId: 'b', fromPin: 0, toId: 'and', toPin: 1),
      isNotNull,
    );
  });

  test('one output can drive two inputs', () {
    const first = WireLink(fromId: 'a', fromPin: 0, toId: 'and', toPin: 0);

    expect(
      tryConnect([first], fromId: 'a', fromPin: 0, toId: 'not', toPin: 0),
      isNotNull,
    );
  });
}
