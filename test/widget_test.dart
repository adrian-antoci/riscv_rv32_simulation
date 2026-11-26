import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riscv_rv32_design/main.dart';
import 'package:riscv_rv32_design/ui/board_view.dart';

void main() {
  testWidgets('sandbox shell shows the palette', (tester) async {
    await tester.pumpWidget(const SandboxApp());

    expect(find.text('AND'), findsNWidgets(2));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('Out'), findsOneWidget);
    expect(find.text('NOT'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
  });

  testWidgets('board parts can be dragged', (tester) async {
    await tester.pumpWidget(const SandboxApp());

    final before = tester.getTopLeft(find.text('A'));
    await tester.drag(find.text('A'), const Offset(48, 24));
    await tester.pump();

    expect(tester.getTopLeft(find.text('A')), before + const Offset(48, 24));
    expect(find.text('B'), findsOneWidget);
    expect(find.text('Out'), findsOneWidget);
  });

  testWidgets('palette places parts that can be dragged', (tester) async {
    await tester.pumpWidget(const SandboxApp());

    await tester.tap(find.widgetWithText(OutlinedButton, 'AND'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'AND'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'NOT'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Input'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Output'));
    await tester.pump();

    expect(find.text('AND'), findsNWidgets(4));
    expect(find.text('NOT'), findsNWidgets(2));
    expect(find.text('In'), findsOneWidget);
    expect(find.text('Out'), findsNWidgets(2));
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Create'))
          .onPressed,
      isNotNull,
    );

    final before = tester.getTopLeft(find.text('In'));
    await tester.drag(find.text('In'), const Offset(30, 16));
    await tester.pump();

    expect(tester.getTopLeft(find.text('In')), before + const Offset(30, 16));

    await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
    await tester.pump();

    expect(find.text('In'), findsNothing);
    expect(find.text('A'), findsOneWidget);
    expect(find.byKey(const Key('wires-3')), findsOneWidget);
  });

  testWidgets('a pin drag wires, a body drag still moves', (tester) async {
    await tester.pumpWidget(const SandboxApp());

    final board = tester.getTopLeft(find.byKey(const Key('board')));
    final parts = initialBoard();
    final a = parts.firstWhere((part) => part.id == 'a');
    final b = parts.firstWhere((part) => part.id == 'b');
    final and = parts.firstWhere((part) => part.id == 'and');
    final fromA = PartGeometry.outputAnchor(a, 0);
    final fromB = PartGeometry.outputAnchor(b, 0);
    final toAnd = PartGeometry.inputAnchor(and, 0);

    expect(find.byKey(const Key('wires-3')), findsOneWidget);
    await tester.tapAt(board + pointOnWire(fromA, toAnd, 0.5));
    await tester.pump();
    expect(find.byKey(const Key('wires-2')), findsOneWidget);

    final aBefore = tester.getTopLeft(find.text('A'));
    await tester.dragFrom(board + fromA, toAnd - fromA);
    await tester.pump();
    expect(find.byKey(const Key('wires-3')), findsOneWidget);
    expect(tester.getTopLeft(find.text('A')), aBefore);

    final bBefore = tester.getTopLeft(find.text('B'));
    await tester.dragFrom(board + fromB, toAnd - fromB);
    await tester.pump();
    expect(find.byKey(const Key('wires-3')), findsOneWidget);
    expect(tester.getTopLeft(find.text('B')), bBefore);
  });

  testWidgets('tapping both inputs lights the AND lamp', (tester) async {
    await tester.pumpWidget(const SandboxApp());

    expect(find.byKey(const Key('level-and-0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('level-a-0')));
    await tester.pump();
    expect(find.byKey(const Key('level-and-0')), findsOneWidget);

    await tester.tap(find.byKey(const Key('level-b-0')));
    await tester.pump();
    expect(find.byKey(const Key('level-and-1')), findsOneWidget);
    expect(find.byKey(const Key('level-out-1')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('lamp-bits'))).data, '1');
  });

  testWidgets('lesson menu ends at the ALU', (tester) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SandboxApp());

    expect(find.byKey(const Key('lesson-panel')), findsOneWidget);
    expect(find.byKey(const Key('lesson-0')), findsOneWidget);
    expect(
      find.textContaining('The last lesson is the ALU'),
      findsOneWidget,
    );
    expect(tester.widget<Text>(find.byKey(const Key('lamp-bits'))).data, '0');

    final item = find.byKey(const Key('lesson-10'));
    final list = find.byKey(const Key('lesson-list'));
    for (var i = 0; i < 12 && item.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -140));
      await tester.pump();
    }
    for (var i = 0; i < 8; i++) {
      if (tester.getRect(item).bottom <= tester.getRect(list).bottom - 4) break;
      await tester.drag(list, const Offset(0, -80));
      await tester.pump();
    }
    expect(find.text('11. ALU'), findsOneWidget);
    expect(find.text('Add and subtract'), findsOneWidget);
    await tester.tap(item);
    await tester.pump();

    expect(find.text('What is going on'), findsOneWidget);
    expect(find.textContaining('This is the last chip'), findsOneWidget);
    final detail = find.descendant(
      of: find.byKey(const Key('lesson-detail')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('What to do'),
      200,
      scrollable: detail,
    );
    expect(find.text('What to do'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('3+4 = 7'),
      240,
      scrollable: detail,
    );
    expect(find.textContaining('3+4 = 7'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Next'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('All lessons'));
    await tester.pump();
    expect(find.byKey(const Key('lesson-list')), findsOneWidget);

    await tester.tap(find.byKey(const Key('lessons-hide')));
    await tester.pump();
    expect(find.byKey(const Key('lesson-panel')), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Lessons'));
    await tester.pump();
    expect(find.byKey(const Key('lesson-panel')), findsOneWidget);
  });

  testWidgets('saved chips stay on the bar in sandbox and every lesson', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SandboxApp());

    await tester.tap(find.widgetWithText(OutlinedButton, 'Create'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'NAND');
    await tester.tap(find.widgetWithText(TextButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'NAND'), findsOneWidget);
    expect(find.byKey(const Key('saved-NAND')), findsOneWidget);

    await tester.tap(find.byKey(const Key('lesson-0')));
    await tester.pump();
    expect(find.widgetWithText(OutlinedButton, 'NAND'), findsOneWidget);
    expect(find.byKey(const Key('saved-NAND')), findsOneWidget);

    await tester.tap(find.text('All lessons'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sandbox-mode')));
    await tester.pump();
    expect(find.byKey(const Key('sandbox-page')), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'NAND'), findsOneWidget);
    expect(find.byKey(const Key('saved-NAND')), findsOneWidget);

    await tester.tap(find.text('All lessons'));
    await tester.pump();
    final last = find.byKey(const Key('lesson-10'));
    final list = find.byKey(const Key('lesson-list'));
    for (var i = 0; i < 12 && last.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -140));
      await tester.pump();
    }
    for (var i = 0; i < 8; i++) {
      if (tester.getRect(last).bottom <= tester.getRect(list).bottom - 4) break;
      await tester.drag(list, const Offset(0, -80));
      await tester.pump();
    }
    await tester.tap(last);
    await tester.pump();
    expect(find.text('Add and subtract'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'NAND'), findsOneWidget);
    expect(find.byKey(const Key('saved-NAND')), findsOneWidget);
  });
}
