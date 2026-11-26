import 'package:flutter/material.dart';

/// Desktop keeps the dark simulator look. Android is the Supernote Nomad,
/// a grayscale e-ink panel that cannot show that palette.
class BoardColors {
  const BoardColors({
    required this.board,
    required this.bar,
    required this.chip,
    required this.chipBorder,
    required this.text,
    required this.muted,
    required this.signalOn,
    required this.signalOff,
    required this.wire,
    required this.buttonText,
    required this.buttonBorder,
    required this.disabledText,
    required this.disabledBorder,
    required this.wireWidth,
    required this.wireWidthOn,
    required this.borderWidth,
  });

  final Color board;
  final Color bar;
  final Color chip;
  final Color chipBorder;
  final Color text;
  final Color muted;
  final Color signalOn;
  final Color signalOff;
  final Color wire;
  final Color buttonText;
  final Color buttonBorder;
  final Color disabledText;
  final Color disabledBorder;
  final double wireWidth;
  final double wireWidthOn;
  final double borderWidth;

  static const dark = BoardColors(
    board: Color(0xFF12141A),
    bar: Color(0xFF1A1D27),
    chip: Color(0xFF1E2430),
    chipBorder: Color(0xFF2C3140),
    text: Color(0xFFE7EAF0),
    muted: Color(0xFF8B93A7),
    signalOn: Color(0xFF3DDC97),
    signalOff: Color(0xFF3A4154),
    wire: Color(0xFF4E5668),
    buttonText: Color(0xFFE7EAF0),
    buttonBorder: Color(0xFF3DDC97),
    disabledText: Color(0xFF8B93A7),
    disabledBorder: Color(0xFF2C3140),
    wireWidth: 2.5,
    wireWidthOn: 4.5,
    borderWidth: 1,
  );

  static const ink = BoardColors(
    board: Color(0xFFFFFFFF),
    bar: Color(0xFFFFFFFF),
    chip: Color(0xFFFFFFFF),
    chipBorder: Color(0xFF000000),
    text: Color(0xFF000000),
    muted: Color(0xFF000000),
    signalOn: Color(0xFF000000),
    signalOff: Color(0xFFFFFFFF),
    wire: Color(0xFF000000),
    buttonText: Color(0xFF000000),
    buttonBorder: Color(0xFF000000),
    disabledText: Color(0xFF000000),
    disabledBorder: Color(0xFF000000),
    wireWidth: 2,
    wireWidthOn: 6,
    borderWidth: 2,
  );

  static BoardColors of(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.android ? ink : dark;
  }
}
