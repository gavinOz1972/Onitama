# WP2.1 owner decisions

No unresolved owner decisions remain within WP2.1.

The implementation uses an explicit next-turn request. This lets headless callers advance immediately and lets future presentation callers wait for animation. A simple automatic loop was also possible, with the tradeoff of adding scheduling and pause controls to the session.

The human adapter takes a request ID with each submission. This distinguishes stale input from a previous match even when the same player and state version recur on restart. Scripted verification uses a seeded random legal option to exercise complete games and includes dedicated forced-pass coverage.
