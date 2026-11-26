import 'package:logic_sim/bit.dart';
import 'package:test/test.dart';

void main() {
  test('NOT inverts the bit', () {
    expect(Bit.one.not, Bit.zero);
    expect(Bit.zero.not, Bit.one);
  });

  test('AND is 1 only when both inputs are 1', () {
    expect(Bit.one.and(Bit.one), Bit.one);
    expect(Bit.one.and(Bit.zero), Bit.zero);
    expect(Bit.zero.and(Bit.one), Bit.zero);
    expect(Bit.zero.and(Bit.zero), Bit.zero);
  });
}
