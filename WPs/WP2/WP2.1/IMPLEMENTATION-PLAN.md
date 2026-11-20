# WP2.1 implementation plan

The accepted baseline is Godot 4.7.2 on `main` at `6e9977a81b88d4ea9d8e934328d57fdfc059037c`. The handoff and WP2.1 prompt were untracked before implementation. The active checkout is under `C:\Users\gavin\Documents\Godot\Onitama`.

1. Define a player controller that receives detached turn data and a turn-scoped proposal callback. Implement local human input and a seeded test controller.
2. Add a headless session that initializes with `GameState.setup`, builds turn options with `RulesEngine.legal_moves`, and sends proposals to `TurnResolver.apply`. The session publishes the resolver's history event after a successful commit.
3. Expose explicit turn dispatch so a headless driver can step immediately and a presentation driver can wait for animation. Invalidate pending callbacks when a turn closes, a match restarts, or a match stops.
4. Verify both controller placements, rejection and recovery, cancellation, forced passes, terminal behavior, event order, and seeded replay. Rerun the existing WP1.2 suite and record results separately.

The integration requires no changes to WP1.2, no external dependencies, and no owner decision before implementation.
