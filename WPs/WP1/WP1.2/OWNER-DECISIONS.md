# WP1.2 owner decisions

The owner authorized original test movement cards for the private educational project and retained the original WP1.1 references. The eight-card fixture is the test collection for the revised acceptance gate.

No material owner decision is open for WP1.2. Implementation conventions are recorded here for review.

- Blue starts at the bottom of the logical board. Red's movement frame is rotated 180 degrees relative to blue's.
- If a move captures the opposing Teacher on the opposing temple, record Teacher capture as the victory reason. Both conditions produce the same winner.
- Keep the selected hand slot on exchange. On a winning turn, retain the winning actor as the current player and include the exchange in the terminal history.
- Accept snapshots reachable from their recorded deal. If a later work package needs arbitrary position imports or bounded snapshot replay, it can define a separate contract.
- The test runner stops a simulation after 500 turns. Any future gameplay policy for repeats or draws would require an owner decision.
