# WP2.1 acceptance report

**Recommendation for the owner:** Accept WP2.1. All acceptance criteria passed in the tested headless scope, with no known critical or high-severity defects.

| Criterion | Evidence |
| --- | --- |
| Common contract and local coordinator | `PlayerController` and `MatchSession` support immediate or deferred proposals through the same request boundary. |
| Human and scripted controllers in either slot | All three requested pairings completed 30 matches apiece, with matching results for matching seeds and choices. |
| WP1.2 authority and controller isolation | Setup, legal movement generation and validation use WP1.2. Mutating request state, card definitions, or event payloads cannot change authoritative data. |
| Rejection and recovery | Tests exercise inactive, illegal, malformed, stale, duplicate, reentrant, and expired commands. Corrected input can still commit on the open request. |
| Forced pass, restart, and terminal state | Both adapters executed passes. Tests check card exchange, cancellation across restart and stop, and rejection after victory. |
| Lifecycle events and presentation boundary | Logical start, turn request, rejection, commit and end notifications are exposed. The caller controls when the next turn is requested. |
| Headless scope | Production code uses GDScript and the accepted engine, with no scene, presentation, transport, or external dependency. |
| Verification and documentation | The test report records 4,631 WP2.1 checks and 9,164 WP1.2 regression checks with zero failures. All five WP2.1 documents are present. |

The protected WP1.1 and WP1.2 files remain unchanged. Owner acceptance is pending.
