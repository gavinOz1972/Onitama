# WP2.1 test report

Both headless runners exited 0 on Godot 4.7.2 Mono for Windows. From the active checkout, with the Godot console executable on PATH, run:

```powershell
godot --headless --path . --log-file "$env:TEMP/wp21_controllers_test.log" --script res://tests/wp21_controllers_test.gd
godot --headless --path . --log-file "$env:TEMP/wp12_rules_test.log" --script res://tests/wp12_rules_test.gd
```

| Suite | Result |
| --- | --- |
| WP2.1 controller and coordination tests | 4,631 checks, zero failures |
| WP1.2 rules regression | 9,164 checks, zero failures. 100/100 complete matches, 2,178 turns, longest match 70 turns. |

WP2.1 covers turn identity and routing, waiting for input, state and card isolation, malformed and illegal proposals, stale versions, inactive players, duplicate proposals, reentrant submission, corrected input, restart and stop cancellation, forced-pass card choice and exchange, lifecycle order, victory, and replay through the accepted serializer.

## WP2.1 simulations

Each configuration ran 30 seeds with a 500-turn test limit. The human adapter received commands from the test harness using the same seeded option selection as the scripted controller in its slot. Every final state and history matched both a repeat run and the corresponding scripted-versus-scripted result.

| Red vs blue | Completed | Turns | Red wins | Blue wins | Capture wins | Temple wins | Passes | Rejected | Unexpected stops | Exact repeats |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Scripted vs scripted | 30 | 420 | 16 | 14 | 26 | 4 | 0 | 0 | 0 | 30 |
| Human adapter vs scripted | 30 | 420 | 16 | 14 | 26 | 4 | 0 | 0 | 0 | 30 |
| Scripted vs human adapter | 30 | 420 | 16 | 14 | 26 | 4 | 0 | 0 | 0 | 30 |
| Total | 90 | 1,260 | 48 | 42 | 78 | 12 | 0 | 0 | 0 | 90 |

Dedicated cases exercise deliberate rejections and two accepted forced passes, one per controller type, using a lateral-only card set derived in memory. The standard simulation uses the unchanged WP1.2 fixture. Completion applies to these seeds and choices. The engine has no draw policy, and the test limit does not apply to production matches.

Godot emitted a Windows root certificate store diagnostic in this environment. Both suites ran to completion without network access or script errors.
