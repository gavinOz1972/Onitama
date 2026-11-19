# WP1.2 implementation plan

The owner's revised brief is the scope for this work package. The original Word prompt is retained as a historical reference.

Project purpose: Surreal Onitama is a private, noncommercial educational and technical experiment exploring AI-assisted software development, game architecture, procedural animation, and computer game AI. It is not intended for publication or commercial distribution. Original artwork and presentation assets will not be reproduced.

1. Review the Godot project and WP1.1 data contract. Use its versioned JSON field and coordinate conventions with an original fixture.
2. Implement the card loader and deterministic match setup. Represent a square as `[column, row]`, with red on row 0 and blue on row 4.
3. Implement common commands, move generation, victory evaluation, and a resolver that returns one new state and one history event per accepted command.
4. Serialize a versioned snapshot and verify the deal, history, and final state on restoration.
5. Exercise the contracts and complete matches in a dependency-free Godot SceneTree test runner. Record measured results and owner decisions.

Runtime dependencies are Godot 4 and a validated movement collection. The headless suite provides the original test collection. The architecture and owner decisions record the implementation conventions.
