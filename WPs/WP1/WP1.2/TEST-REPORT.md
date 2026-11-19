# WP1.2 test report

Godot 4.7.2 on Windows reported **9,164 checks passed and zero failures**.

```powershell
godot --headless --path C:\Onitama --script res://tests/wp12_rules_test.gd
```

Use the local Godot console executable in place of `godot` if it is outside PATH. The runner returns exit code 1 on a failed check.

| Category | Coverage |
| --- | --- |
| Card loading | Eight original cards, retained offsets and stamps, missing fields, duplicate ID, and invalid offset variants |
| Setup and moves | Starting rows and roles, shared-card stamp, seeded repeatability, orientation, borders, friendly occupancy and jumping |
| Resolution | Atomic exchange, version and history, stale and ineligible commands, forced and voluntary pass cases, capture and terminal rejection |
| Victory | Teacher capture, opposing temple, ordinary capture, Disciple occupation and simultaneous victory precedence |
| Snapshots | Active and terminal round-trips, reproducible replay, equal legal moves, malformed, changed and incompatible snapshots |
| Simulation | Card ownership, occupied squares and event/version invariants after every accepted turn |

The fixed simulation ran 100 seeds with uniformly sampled legal moves. All 100 matches reached victory within the 500-turn test bound. The suite processed 2,178 simulation turns, and the longest match lasted 70 turns. The bound is a test limit. Other card sets and strategies can cycle.
