/// A connection from an output pin to an input pin.
class WireLink {
  const WireLink({
    required this.fromId,
    required this.fromPin,
    required this.toId,
    required this.toPin,
  });

  final String fromId;
  final int fromPin;
  final String toId;
  final int toPin;

  bool drives(String partId, int pin) => toId == partId && toPin == pin;

  @override
  bool operator ==(Object other) =>
      other is WireLink &&
      other.fromId == fromId &&
      other.fromPin == fromPin &&
      other.toId == toId &&
      other.toPin == toPin;

  @override
  int get hashCode => Object.hash(fromId, fromPin, toId, toPin);
}

/// Returns the new link, or null when [toPin] on [toId] is already driven.
WireLink? tryConnect(
  Iterable<WireLink> wires, {
  required String fromId,
  required int fromPin,
  required String toId,
  required int toPin,
}) {
  if (wires.any((wire) => wire.drives(toId, toPin))) return null;
  return WireLink(fromId: fromId, fromPin: fromPin, toId: toId, toPin: toPin);
}
