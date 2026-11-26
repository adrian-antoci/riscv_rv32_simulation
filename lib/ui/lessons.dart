import 'package:flutter/material.dart';

import 'package:riscv_rv32_design/ui/board_colors.dart';

/// One step of the lesson sequence.
/// The last lesson is the ALU.
class Lesson {
  const Lesson({
    required this.kicker,
    required this.title,
    required this.goingOn,
    required this.steps,
    this.table,
  });

  final String kicker;
  final String title;
  final String goingOn;
  final List<String> steps;
  final String? table;
}

const lessons = <Lesson>[
  Lesson(
    kicker: 'AND',
    title: 'Both must be on',
    goingOn: 'A lamp and two switches in a row. Current has to get through both, so the lamp lights only when both are on. That is AND. One input off is enough to kill it. A transistor is just that switch done small. This board only knows AND and NOT. The circuit already on it is an AND.',
    table: 'A B | lamp\n0 0 | 0\n0 1 | 0\n1 0 | 0\n1 1 | 1',
    steps: [
      'Tap A. Only one input is on, so the lamp stays off.',
      'Tap B as well. Both pins on the AND light, and the lamp lights.',
      'Tap either input again. The lamp goes off.',
      'Leave this circuit up. The next lesson puts a NOT in front of the lamp.',
    ],
  ),
  Lesson(
    kicker: 'NOT',
    title: 'The inverting switch',
    goingOn: 'The other switch ties the lamp to ground instead of to power. The lamp is then on only while the switch is off. NOT has one input and always outputs the opposite. Every later chip is AND and NOT, saved and reused. Nothing new gets added to the bar.',
    table: 'In | NOT\n0  | 1\n1  | 0',
    steps: [
      'Tap the wire between the AND and the lamp to delete it.',
      'Tap NOT on the bar. Drag the new gate so it sits between the AND and the lamp.',
      'Drag from the AND’s right pin to the NOT’s left pin, then from the NOT’s right pin to the lamp.',
      'Turn both inputs on. The AND is on, the NOT is off, and the lamp is off.',
      'Turn one input off. The lamp comes back on.',
    ],
  ),
  Lesson(
    kicker: 'NAND',
    title: 'Package a NAND',
    goingOn: 'NAND is an AND followed by a NOT. The output is on unless both inputs are on. There is no NAND button. Build it, then save the board as a chip so you can place that bundle like any other gate. Create reads pins top to bottom: the upper input becomes the top pin of the new chip, and the same for outputs. A NAND is symmetric, so the order will not bite you yet. It will, once a chip has a carry pin.',
    table: 'A B | NAND\n0 0 | 1\n0 1 | 1\n1 0 | 1\n1 1 | 0',
    steps: [
      'Get to two inputs, an AND, a NOT, and one lamp, in that order. Reset and rebuild if the board is a mess. Reset keeps chips you have already saved.',
      'Put one input above the other. Do not sit them on the same row.',
      'Tap Create and name it NAND. The board clears, and NAND appears on the bar.',
      'Place NAND, two inputs, and a lamp. Wire the inputs to the left pins and the right pin to the lamp.',
      'The lamp is off only when both inputs are on. Long-press NAND on the bar if the inside is wrong. Save writes it back. Cancel throws the edit away.',
    ],
  ),
  Lesson(
    kicker: 'OR',
    title: 'Either input',
    goingOn: 'OR lights if A is on, or B is on, or both. There is still no OR gate. Invert each input, then feed those two wires into the NAND. If both inputs are off, both NOTs are on, the NAND sees two 1s, and its output goes off. In every other row the NAND does not see two 1s, so the output stays on. Check the table before you trust the name.',
    table: 'A B | OR\n0 0 | 0\n0 1 | 1\n1 0 | 1\n1 1 | 1',
    steps: [
      'Clear the board. Long-press a part to remove it, or tap it and press Remove. Reset also clears the board and keeps NAND.',
      'Place two inputs, a NOT on each, your NAND, and one lamp.',
      'Wire each input to its own NOT, both NOTs into the NAND, and the NAND to the lamp.',
      'Both off: lamp off. Either one on, or both: lamp on.',
      'Create, and name it OR.',
    ],
  ),
  Lesson(
    kicker: 'XOR',
    title: 'One or the other',
    goingOn: 'XOR is on when the inputs disagree. OR is wrong in exactly one row: both inputs on. Both-on is the case NAND turns off. AND the OR with that NAND and the both-on spike is cut off. The other three rows pass through. That is the last gate you need before addition. One output pin can feed as many inputs as you like. An input pin still takes only one wire.',
    table: 'A B | XOR\n0 0 | 0\n0 1 | 1\n1 0 | 1\n1 1 | 0',
    steps: [
      'Place two inputs. Drag two wires from each input pin: one to your OR, one to your NAND.',
      'Place an AND. Wire the OR’s output to one AND pin and the NAND’s output to the other.',
      'Wire that AND to a lamp.',
      'Check the table. 1 and 1 must stay off. Either input alone must light the lamp.',
      'Create, and name it XOR.',
    ],
  ),
  Lesson(
    kicker: 'Binary',
    title: 'Places worth double',
    goingOn: 'Stop building gates and read a column of lamps as a number. Each place is worth double the place below it: 1, then 2, then 4, then 8. The pattern 1101 is 8 + 4 + 0 + 1 = 13. Four lamps count from 0 to 15. The top lamp is the big place. The readout at the bottom of this panel does that reading: top lamp first.',
    table: '8 4 2 1 | number\n1 1 0 1 | 13\n1 1 1 1 | 15\n0 0 0 1 | 1',
    steps: [
      'Place four inputs in one column, top to bottom. Think of them as 8, 4, 2, 1.',
      'Place four lamps in the same order, and wire each input straight across to its lamp.',
      'Turn on the top, the next, and the bottom. Leave the 2s place off. The panel should read 1 1 0 1, unsigned 13.',
      'Try 1111 (15) and 0001 (1). You do not save a chip in this lesson.',
    ],
  ),
  Lesson(
    kicker: 'Half adder',
    title: 'Sum and carry',
    goingOn: 'Adding two bits has two results. The sum bit is XOR: 0+0 = 0, 1+0 = 1, 0+1 = 1, and 1+1 = 0 with something left over. The leftover is the carry, and that is AND: on only when both bits are 1. A half adder is those two gates sharing the same inputs. It cannot take a carry from the column to the right. That is the next lesson. As a 2-bit total, carry is the 2s place and sum is the 1s place, so 1+1 is the number 2.',
    table:
        'A B | sum carry\n0 0 | 0   0\n0 1 | 1   0\n1 0 | 1   0\n1 1 | 0   1',
    steps: [
      'Place two inputs, your XOR, and an AND. Wire both inputs to both gates.',
      'Place two lamps. While you are checking the addition, put Carry above Sum so the panel reads the total: 1+1 is bits 1 0, unsigned 2.',
      'Before you press Create, drag Sum above Carry. The upper output becomes the top pin of the chip, and the next lesson calls that pin Sum.',
      'Create, and name it HALF. Left pins are the two bits. Right pins, top to bottom, are Sum, then Carry.',
    ],
  ),
  Lesson(
    kicker: 'Full adder',
    title: 'The incoming carry',
    goingOn: 'A real column also receives a carry from the column below. Add that third bit with a second half adder. The sum of the column is the second XOR. A carry leaves the column if either half adder produced one, so the two carry pins go into an OR. Three inputs, two outputs. 1+1+1 is 3, which is binary 11: sum on, carry on.',
    table: 'A B Cin | sum carry\n1 1 0   | 0   1\n1 0 1   | 0   1\n1 1 1   | 1   1',
    steps: [
      'Place three inputs, top to bottom: A, B, Carry in. Place two HALF chips.',
      'Wire A and B into the first HALF. Its top pin is Sum, its lower pin is Carry.',
      'Wire that Sum and Carry in into the second HALF. The second HALF’s top pin is the column sum. Wire it to the upper lamp.',
      'OR the two Carry pins (the lower pin of each HALF). Wire the OR to the lower lamp.',
      'Check 1+1+0: sum off, carry on. Check 1+1+1: both lamps on.',
      'Create, and name it FULL. Pins in, top to bottom: A, B, Cin. Pins out: Sum, then Cout.',
    ],
  ),
  Lesson(
    kicker: '4-bit adder',
    title: 'Four columns',
    goingOn: 'Four full adders side by side are a 4-bit adder. The carry out of the 1s column is the carry in of the 2s column, then the 4s, then the 8s. The first carry in is off, so an unwired pin is enough: an empty pin reads as 0. 15+1 is 1111+0001. Every column sums to 0 and passes a carry, so the four sum lamps go dark and the final carry lights. The number wrapped past 15. If that carry lamp is the top lamp, the panel reads 16.',
    steps: [
      'Place four FULL chips in a column. Top chip is the 8s. Bottom chip is the 1s. On each, the left pins are A, B, Cin. The right pins are Sum, then Cout.',
      'Place eight inputs. Wire A8 and B8 into the top FULL, and so on down to A1 and B1. Leave every Cin empty for now except the ones you are about to chain.',
      'Wire each Cout (lower right pin) to the Cin (bottom left pin) of the FULL above it. Carry flows up. The bottom Cin stays empty.',
      'Place five lamps, top to bottom: Carry, 8, 4, 2, 1. Wire the top Cout to Carry, and each Sum to its lamp.',
      'Set A to 1111 and B to 0001. The panel should read 1 0 0 0 0, unsigned 16. That is 15+1 overflowing.',
      'Set A to 0011 and B to 0100. The panel should read 0 0 1 1 1, unsigned 7.',
      'Before Create, stack every input in one column, top to bottom: A8, A4, A2, A1, B8, B4, B2, B1, Cin. Cin can be a ninth input, wired to the bottom Cin, left off. Outputs stay Carry, 8, 4, 2, 1. Create, and name it ADD4.',
    ],
  ),
  Lesson(
    kicker: 'Two’s complement',
    title: 'Negative numbers',
    goingOn: 'A spare bit used as a minus sign does not add. Sign-magnitude says 0111 is 7 and 1111 is −7, but the adder sums them to 1110, not zero. It never heard about a sign bit. Two’s complement uses the top place as −8 instead of +8. The other places stay +4, +2, +1. Four bits then run from −8 to +7. −7 is 1001, which is −8+1. Negate by inverting every bit, then adding 1. +6 is 0110. Invert to 1001, add 1, get 1010, which is −8+2 = −6. Now 7 + −7 is 0111+1001. The lower four bits are 0000, and a 1 falls out the carry. The adder already did the right thing. Signed, in the readout, treats the top lamp as that minus place.',
    table:
        'bits | signed\n0111 | +7\n1001 | −7\n1010 | −6\n1111 | −1\n1000 | −8',
    steps: [
      'On the 4-bit adder, set A to 0111 (7) and B to 1001 (−7). The four sum lamps go off. Carry lights. That leftover carry is why the sum is zero.',
      'Unplug the carry lamp, or drag it below the four sum lamps, before you trust Signed. With the 8s lamp on top, 0000 is signed 0.',
      'Set B to 1010 (−6) and A to 0110 (+6). Sum lamps off again.',
      'Set A to 0011 (3) and B to 1100 (−4). Sum lamps should read 1111. Signed, that is −1, not 15.',
      'You do not build a new chip here. The same adder is about to grow a subtract wire.',
    ],
  ),
  Lesson(
    kicker: 'ALU',
    title: 'Add and subtract',
    goingOn: 'This is the last chip. An ALU does the arithmetic a CPU will eventually ask for. The only operation so far is add, plus subtract. Subtract is “add the negation”, and negation is invert, then add 1. Do not build a second adder. A subtract input runs each bit of B through an XOR with that signal: subtract off, B passes through; subtract on, B flips. The same wire feeds the adder’s carry in, which is the +1. Three flags let a later program branch. Zero: every result bit is off. Negative: the top result bit, the −8 place. Carry: the adder’s carry out. Check 3+4 = 7, 3−4 = −1, −2−4 = −6, −2−(−4) = 2, and adding two negatives. It does no bitwise AND or OR on the bits yet. Package it and name it ALU.',
    steps: [
      'Use ADD4 if its last input is Cin and its top output is Carry. Otherwise keep the four FULL chips and wire Subtract into the bottom Cin yourself.',
      'Place a Subtract input and four XOR chips. Each B bit goes into an XOR. The other XOR pin is Subtract. Those four XOR outputs feed the adder’s B pins. The A bits go straight in.',
      'Wire Subtract to Cin as well. Subtract off leaves Cin at 0, which is a plain add.',
      'Result lamps, top to bottom: 8, 4, 2, 1. Leave flag lamps off the board until these four match. The panel number includes every lamp.',
      'Subtract off. A = 0011, B = 0100. Lamps 0111, unsigned 7.',
      'Subtract on. Same A and B. Lamps 1111. Signed −1. That is 3−4.',
      'Subtract on. A = 1110 (−2), B = 0100 (4). Lamps 1010, signed −6. That is −2−4.',
      'Subtract on. A = 1110 (−2), B = 1100 (−4). Lamps 0010, unsigned 2. That is −2−(−4).',
      'Subtract off. A = 1110, B = 1100. Lamps 1010, signed −6, and the adder’s carry is on. Two negatives, added.',
      'Subtract on, A = 0011, B = 0011. Lamps 0000. Now add the flags. Zero is the AND of a NOT on each result bit. AND takes two inputs, so pair them. Negative is a second lamp on the 8s result. Carry is the adder carry. Zero lights only for this 0000 row.',
      'Create, and name it ALU. Inputs, top to bottom: A8, A4, A2, A1, B8, B4, B2, B1, Subtract. Outputs: the four result bits, then Zero, Negative, Carry.',
    ],
  ),
];

/// Top lamp is the high place. Signed uses that lamp as the minus place.
class LampReadout {
  const LampReadout(this.bits);

  final List<int> bits;

  bool get isEmpty => bits.isEmpty;

  int get unsigned {
    var value = 0;
    for (final bit in bits) {
      value = (value << 1) | (bit == 0 ? 0 : 1);
    }
    return value;
  }

  int? get signed {
    if (bits.length < 2) return null;
    final width = bits.length;
    final signPlace = 1 << (width - 1);
    final raw = unsigned;
    return raw >= signPlace ? raw - (signPlace << 1) : raw;
  }

  String get bitText => bits.isEmpty ? '—' : bits.join(' ');
}

class LessonPanel extends StatelessWidget {
  const LessonPanel({
    required this.sandbox,
    required this.lessonIndex,
    required this.savedChips,
    required this.lamps,
    required this.onSandbox,
    required this.onPick,
    required this.onPlaceSaved,
    required this.onBack,
    required this.onPrevious,
    required this.onNext,
    required this.onHide,
    super.key,
  });

  final bool sandbox;
  final int? lessonIndex;
  final List<String> savedChips;
  final LampReadout lamps;
  final VoidCallback onSandbox;
  final ValueChanged<int> onPick;
  final ValueChanged<String> onPlaceSaved;
  final VoidCallback onBack;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);
    final lesson = lessonIndex == null ? null : lessons[lessonIndex!];
    return DecoratedBox(
      key: const Key('lesson-panel'),
      decoration: BoxDecoration(
        color: colors.bar,
        border: Border(
          right: BorderSide(color: colors.text, width: colors.borderWidth),
        ),
      ),
      child: SizedBox(
        width: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PanelHeader(colors: colors, sandbox: sandbox, onHide: onHide),
            const _Controls(),
            Expanded(
              child: sandbox
                  ? _SandboxPage(onBack: onBack)
                  : lesson == null
                  ? _LessonList(onSandbox: onSandbox, onPick: onPick)
                  : _LessonDetail(
                      index: lessonIndex!,
                      lesson: lesson,
                      onBack: onBack,
                      onPrevious: onPrevious,
                      onNext: onNext,
                    ),
            ),
            _SavedChips(names: savedChips, onPlace: onPlaceSaved),
            _LampFooter(colors: colors, lamps: lamps),
          ],
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.colors,
    required this.sandbox,
    required this.onHide,
  });

  final BoardColors colors;
  final bool sandbox;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              sandbox ? 'Sandbox' : 'Lessons',
              style: TextStyle(
                color: colors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            key: const Key('lessons-hide'),
            onPressed: onHide,
            child: const Text('Hide'),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatefulWidget {
  const _Controls();

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap an input to toggle. Drag a right pin onto a left pin. Tap a wire to delete it.',
            style: TextStyle(color: colors.text, fontSize: 13, height: 1.35),
          ),
          TextButton(
            onPressed: () => setState(() => _open = !_open),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              splashFactory: NoSplash.splashFactory,
            ),
            child: Text(_open ? 'Hide board controls' : 'Board controls'),
          ),
          if (_open)
            Text(
              'One output pin can feed many inputs. An input pin takes one wire. An empty pin reads as 0. Drag a body to move a part. Tap a part to select it, then Remove, or long-press it to remove it now. Create saves this board. Inputs, top to bottom, become the left pins. Outputs, top to bottom, become the right pins. Do not put two pins on the same row. A saved chip stays on the bar in the sandbox and in every lesson. Long-press it to edit the inside. Reset clears the board and keeps your chips.',
              style: TextStyle(color: colors.text, fontSize: 13, height: 1.35),
            ),
        ],
      ),
    );
  }
}

class _LessonList extends StatelessWidget {
  const _LessonList({required this.onSandbox, required this.onPick});

  final VoidCallback onSandbox;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);
    return ListView(
      key: const Key('lesson-list'),
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        _MenuRow(
          key: const Key('sandbox-mode'),
          title: 'Sandbox',
          subtitle: 'Free board. No lesson.',
          onTap: onSandbox,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'In order. The last lesson is the ALU. Saved chips stay on the bar in every lesson.',
            style: TextStyle(
              color: colors.text,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (var i = 0; i < lessons.length; i++)
          _LessonRow(index: i, lesson: lessons[i], onTap: () => onPick(i)),
      ],
    );
  }
}

class _SandboxPage extends StatelessWidget {
  const _SandboxPage({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);
    return ListView(
      key: const Key('sandbox-page'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onBack,
            child: const Text('All lessons'),
          ),
        ),
        Text(
          'Sandbox',
          style: TextStyle(
            color: colors.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'No lesson and no steps. The board is yours.',
          style: TextStyle(
            color: colors.text,
            fontSize: 15,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Build from AND, NOT, Input, and Output. Create saves the board as a chip. Every saved chip stays on the bar in the sandbox and in every lesson, including ones you have not opened yet. Long-press a saved chip to edit the inside. Reset clears the board and does not delete saved chips.',
          style: TextStyle(color: colors.text, fontSize: 14, height: 1.4),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colors.chipBorder,
              width: colors.borderWidth,
            ),
            bottom: BorderSide(color: colors.text, width: colors.borderWidth),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: colors.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: colors.text, fontSize: 13, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedChips extends StatelessWidget {
  const _SavedChips({required this.names, required this.onPlace});

  final List<String> names;
  final ValueChanged<String> onPlace;

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);
    return Container(
      key: const Key('saved-chips'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.text, width: colors.borderWidth),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved',
            style: TextStyle(
              color: colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          if (names.isEmpty)
            Text(
              'None yet. Create a chip and it shows here, in the sandbox and in every lesson.',
              style: TextStyle(color: colors.text, fontSize: 12, height: 1.3),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final name in names)
                  TextButton(
                    key: Key('saved-$name'),
                    onPressed: () => onPlace(name),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      splashFactory: NoSplash.splashFactory,
                      side: BorderSide(
                        color: colors.text,
                        width: colors.borderWidth,
                      ),
                    ),
                    child: Text(name),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.index,
    required this.lesson,
    required this.onTap,
  });

  final int index;
  final Lesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);
    return InkWell(
      key: Key('lesson-$index'),
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colors.chipBorder,
              width: colors.borderWidth,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${lesson.kicker}',
              style: TextStyle(
                color: colors.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              lesson.title,
              style: TextStyle(color: colors.text, fontSize: 13, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonDetail extends StatelessWidget {
  const _LessonDetail({
    required this.index,
    required this.lesson,
    required this.onBack,
    required this.onPrevious,
    required this.onNext,
  });

  final int index;
  final Lesson lesson;
  final VoidCallback onBack;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);
    final last = index == lessons.length - 1;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              TextButton(onPressed: onBack, child: const Text('All lessons')),
              const Spacer(),
              Text(
                '${index + 1} / ${lessons.length}',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            key: const Key('lesson-detail'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                '${index + 1}. ${lesson.kicker}',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lesson.title,
                style: TextStyle(color: colors.text, fontSize: 15, height: 1.3),
              ),
              const SizedBox(height: 16),
              Text(
                'What is going on',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                lesson.goingOn,
                style: TextStyle(color: colors.text, fontSize: 14, height: 1.4),
              ),
              if (lesson.table != null) ...[
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colors.text,
                      width: colors.borderWidth,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      lesson.table!,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 13,
                        height: 1.35,
                        fontFamily: 'monospace',
                        fontFamilyFallback: const ['Courier'],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'What to do',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              for (var i = 0; i < lesson.steps.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${i + 1}.',
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        lesson.steps[i],
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
          child: Row(
            children: [
              TextButton(
                onPressed: index == 0 ? null : onPrevious,
                child: const Text('Previous'),
              ),
              const Spacer(),
              TextButton(
                onPressed: last ? null : onNext,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LampFooter extends StatelessWidget {
  const _LampFooter({required this.colors, required this.lamps});

  final BoardColors colors;
  final LampReadout lamps;

  @override
  Widget build(BuildContext context) {
    final signed = lamps.signed;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.text, width: colors.borderWidth),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lamps, top to bottom',
            style: TextStyle(
              color: colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lamps.bitText,
            key: const Key('lamp-bits'),
            style: TextStyle(
              color: colors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              fontFamilyFallback: const ['Courier'],
            ),
          ),
          Text(
            lamps.isEmpty
                ? 'No lamps yet'
                : signed == null
                ? 'Unsigned ${lamps.unsigned}. Top lamp is the high place.'
                : 'Unsigned ${lamps.unsigned}. Signed $signed. Top lamp is the high place.',
            key: const Key('lamp-number'),
            style: TextStyle(color: colors.text, fontSize: 13, height: 1.3),
          ),
        ],
      ),
    );
  }
}
