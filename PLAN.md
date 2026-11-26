# Logic sandbox — resume notes

Last updated: 2026-11-26. Android target added. The test device is a Supernote Nomad (e-ink). Keep Impeller on. Do not chase a higher refresh rate: sideloaded apps cannot select the fast waveform.

This is a Flutter/macOS digital-logic sandbox. Not a RISC-V core. The folder name `riscv_rv32_design` is historical; do not start an RV32 interpreter unless the user changes direction.

Read this file at the start of the next session and continue from **Next step**.

## Goal

A sandbox the user builds in, plus a lesson side menu that tells them what to build. The app only knows **AND**, **NOT**, **Input**, and **Output**. NAND, OR, XOR, the adder, and the ALU are chips the user builds. Lessons explain. They do not place finished circuits.

Combinational only. No clocks, no memory, no latches, no saved projects, until the user asks.

## Lesson order

1. Switches as logic. Two in series = AND. A short-to-ground switch = NOT. Truth tables.
2. Transistors replace fingers. The simulator starts with AND and NOT.
3. Derived gates, all built in the sim: NAND (AND then NOT), OR (NOT both inputs into a NAND), XOR (OR, then force 0 when both inputs are 1, via NAND + AND).
4. Binary places: 1, 2, 4, 8. Example `1101` = 13.
5. Adders. Half adder: sum = XOR, carry = AND. Full adder adds the incoming carry with a second XOR, a second AND, and an OR of the two carries. Four full adders with carry chained = 4-bit adder. `15 + 1` overflows to 0 and lights carry.
6. Two’s complement. Sign-magnitude fails (`7 + -7` is not 0). With 4 bits the top place is −8, so −7 is `1001`. Range is −8..+7. Negate = invert, then add 1. `0110` (+6) becomes `1010` (−6).
7. ALU. A subtract signal XORs the second operand (invert when subtract is on) and is fed into the adder carry-in (the +1). Flags: zero, negative (top bit), carry. Checks: `3+4`, `3−4`, `−2−4`, `−2−(−4)`, and adding two negatives. It does no bitwise logic yet.

## Product decisions (do not reopen unless the user does)

- Do not hardcode NAND, OR, XOR, adders, or the ALU. The user builds those. Lessons in `lib/ui/lessons.dart` only explain.
- Hardcoded primitives: AND (2 in, 1 out), NOT (1 in, 1 out). Input and Output are pins of the board being edited, not gates.
- Create snapshots the current board. Placed inputs, top to bottom, become the new chip’s input pins. Placed outputs, top to bottom, become its output pins. Everything else is the implementation. The new chip appears in the palette and can be nested.
- Simulation is stateless. Set input levels, walk the graph, write output levels. A custom chip runs its inner board. These circuits are acyclic, so one pass is enough. An iterative settle is fine if it is simpler, but do not add clocks.
- Two’s complement is how you read the bits, not a component. The lesson panel reads output lamps top to bottom as an unsigned number, and as signed when there are two or more. Top lamp is the high place. There is no placeable decimal lamp.
- UI: dark full-screen board. Chips are rounded rectangles, name in the middle, round pins on the left and right. Pin and wire dim at 0, bright at 1. Inputs are click toggles. Outputs are lamps. Bottom bar: AND, NOT, Input, Output, created chips, Create.
- Wires are curves drawn behind the chips. Chips are widgets, so hit-testing stays simple.
- Dart and Flutter are separate packages, not just folders. No `get_it`, no `go_router`, no `flutter_bloc`, no API client. This is not one of the production Flutter apps.
- Out of scope until asked: save/load, pan/zoom, clocks, latches, wire colors, dragging pin order, RISC-V.
- Editing a created chip was asked for. Long-press its bar button to open the saved layout. Save writes it back and returns to the board you left. Delete asks for confirmation, then removes the chip from the bar and from local storage. Cancel discards the edit. Tap still places the chip.
- Created chips are stored in local preferences under `created-chips` and loaded onto the bar at startup. Reset does not delete them.

## App facts

- Path: `/Users/adrianantoci/development/riscv_rv32_design`
- Created with `flutter create --platforms=macos --org com.antoci --project-name riscv_rv32_design`
- macOS only. Bundle id prefix `com.antoci`. `publish_to: none`.
- Flutter 3.47.5, Dart 3.13.4 (stable), as of 2026-11-20.
- Entry: `lib/main.dart`. Widgets: `SandboxApp`, `SandboxScreen`, `BoardCanvas` (empty dark `Color(0xFF12141A)`), `PaletteBar`.
- Palette labels, all disabled: AND, NOT, Input, Output, Create. Bar color `Color(0xFF1A1D27)`, accent `Color(0xFF3DDC97)`.
- Widget test in `test/widget_test.dart` checks those labels. The Flutter package does not own the model.

## What is done

Step 1 of the coding order is done: the app shell exists.

Step 3's fixed circuit is on the board: input A, input B, one AND, output Out, and three curved wires. Levels come from `Bit` (`a.and(b)`), not a reimplemented gate. There is still no toggle.

Dragging was pulled forward from step 4 because it was asked for. `lib/ui/base_part.dart` is the base every board object is placed through. A, B, AND, and Out can be dragged inside the board; the dragged part lifts to the front; wires follow pin anchors.

Step 4 is done. AND, NOT, Input, and Output on the bar place a new `BasePart`. Each tap offsets the next part so they do not stack. Create stays disabled. Spawned parts are not wired and do not toggle.

Step 5 is done. A drag that starts on an output pin draws a wire and drops it on an input pin. `tryConnect` rejects a second wire onto a driven pin. Tap a wire to delete it. Dragging the body, away from an output pin, still moves the part.

Step 6 is done. Tap an input to toggle it. `evaluate` recomputes the circuit. Pins, wires, and lamps follow. An undriven pin reads as 0. Reset clears toggles too.

Step 7 is done. Create asks for a name, snapshots the board, clears it, and adds the chip to the bar. Inputs and outputs, top to bottom, become its pins. Placing it runs the inner circuit. Reset restores the demo board and keeps created chips. The user built NAND (AND, then NOT) and checked it.

Step 8 is done. No new code. The user built OR by putting a NOT on each input into that NAND. Either input on turns the output on, including both.

Signal drawing, on the Nomad ink theme: an active wire is thicker than an idle wire (`wireWidth` 2, `wireWidthOn` 6). An output lamp is an empty ring when off and fills with a thicker ring when on. The name dialog owns its `TextEditingController`. Do not dispose that controller from `whenComplete`. The bottom bar is a short, centered, horizontally scrolling row of outlines, not stretched buttons.

`flutter run -d macos` built `build/macos/Build/Products/Debug/riscv_rv32_design.app` successfully (Impeller/Metal). Then `Failed to foreground app; open returned 1`, files synced, and the `flutter run` session was interrupted (`Lost connection to device`). The binary is fine; foregrounding failed because the run was cut off. Re-run with `flutter run -d macos` from this directory.

## Coding order

Stop at each “done when”. Do not start the next step early.

1. **App shell.** Dark empty board, bottom bar with disabled buttons. **Done.**
2. **AND and NOT, no UI.** Pure Dart. `AND(1,1) = 1`, `AND(1,0) = 0`, `NOT(1) = 0`, `NOT(0) = 1`. Done when those tests pass.
3. **Draw a fixed circuit.** Hard-place one AND, two inputs, one output, and two wires. No interaction. Done when it shows a chip, pins, and curved wires. **Done.** Drag was added early; see What is done.
4. **Spawn from the bar.** Tap AND, NOT, Input, or Output and it appears. Drag to move. Done when you can scatter a few of each. **Done.**
5. **Wire pins.** Drag from an output pin to an input pin. Reject a wire onto an already-driven pin. Tap a wire to delete it. Done when an input can be wired through an AND to an output by hand. **Done.** Body drag still moves the part.
6. **Live signal.** Click an input to toggle. Recompute. Pins, wires, and lamps update. Done when both inputs on lights the AND lamp, and a NOT after it inverts that. **Done.**
7. **Create chip.** Create asks for a name, snapshots the board, clears it, adds the chip to the bar. Placing it runs the inner circuit. Done when NAND can be built (AND, then NOT, then Create), placed, and checked: output off only when both inputs are on. **Done.**
8. **Nesting check.** No new code if step 7 is right. Build OR: NOT on each input, into a NAND. Done when either input on turns the output on, including both. **Done.** The user checked it.
9. **Delete and select.** Tap to select a chip, Delete removes it and its wires. Done when a mistaken gate does not force a restart.
10. **Decimal lamp.** A display attached to 2–8 output pins, read top to bottom as bits, shown as an unsigned integer. Done when four outputs can show 0–15.

After step 10 the sandbox can do the rest of the lessons with no more features: XOR, half adder, full adder, 4-bit adder, ALU.

## Package split

The simulator is a pure Dart package. The Flutter app is a shell. Do not put model code under the Flutter `lib/`.

```
riscv_rv32_design/                 # Flutter macOS app. Paints and forwards input.
  lib/main.dart
  pubspec.yaml                     # workspace root; depends on logic_sim
  packages/logic_sim/              # pure Dart. `dart test` here, no Flutter SDK.
    lib/logic_sim.dart
    test/
```

Rules:

- `packages/logic_sim` must not import Flutter, `dart:ui`, or any widget library. It does not use `ChangeNotifier`, `Listenable`, or `BuildContext`.
- Gate tests live in `packages/logic_sim/test` and run with `dart test`, not `flutter test`.
- The Flutter app may import `package:logic_sim/logic_sim.dart` and nothing else from that package's internals unless a file is exported.
- Flutter owns position, color, hit targets, and gestures. When a gesture matters to the model, the app calls a Dart method and then repaints. It does not reimplement AND, NOT, wiring rules, or chip creation.
- A `ChangeNotifier` or `ValueNotifier`, if one is needed later, lives in the Flutter package and wraps the Dart board. It is not part of `logic_sim`.

## What is done in the model

`packages/logic_sim/lib/bit.dart` has `Bit.zero` / `Bit.one`, `fromInt`, `value`, `not`, and `and`. `lib/wire.dart` has `WireLink` and `tryConnect`. `lib/eval.dart` has `evaluate`, which walks the circuit, including a `Gate.chip` node. `lib/chip.dart` has `ChipDef` and `snapshotChip`. All are exported from `logic_sim.dart`. `lib/operators.dart` is an empty file. Run `dart test` from `packages/logic_sim`.

## Lessons

The side menu is open on launch. Sandbox is the free board: no lesson, same parts. Eleven lessons follow, in order. The last one is the ALU, including subtract, the zero / negative / carry flags, and the checks `3+4`, `3−4`, `−2−4`, `−2−(−4)`, and adding two negatives. One board is shared. A chip saved with Create stays on the bar and in the Saved strip in the sandbox and in every lesson. Hide collapses the menu to a Lessons button. The panel footer is the lamp readout.

Tap a part to select it. Remove, Delete, or Backspace deletes it and its wires. Long-press deletes it immediately. Reset does not delete saved chips.

## Next step

Nothing required for these lessons. Do not add clocks, memory, or a placeable decimal lamp unless the user asks. Save/load of the board and pan/zoom are still out of scope.
