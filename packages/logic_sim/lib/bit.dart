enum Bit {
  zero,
  one;

  static Bit fromInt(int value) => switch (value) {
    0 => zero,
    1 => one,
    _ => throw ArgumentError.value(value, 'value', 'not a bit'),
  };

  int get value => this == one ? 1 : 0;

  Bit get not => this == Bit.one ? Bit.zero : Bit.one;

  Bit and(Bit other) => this == one && other == one ? one : zero;
}
