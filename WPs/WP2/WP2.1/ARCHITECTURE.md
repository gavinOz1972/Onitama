# WP2.1 controller and session architecture

`MatchSession` owns a single headless match and its two controller instances. Call `start_match(card_set, seed, red, blue)` with a card set from the WP1.2 loader and a distinct controller per slot. The session copies the card set and creates the initial state through `GameState.setup`. Its `get_state()` accessor returns a deep copy.

## Turn contract

The caller invokes `request_next_turn()` when ready for the current player to act. The session derives the active player from its state and builds options from `RulesEngine.legal_moves`. With no legal moves it offers a WP1.2 forced-pass command for each card in the player's hand.

The assigned controller receives `request_turn(request, propose)`. The request carries the logical player, a session-local request ID, and detached copies of the state, card set and command options. The controller may call `propose(command)` immediately, retain it for later use, or wait for input. A submission returns `{event}` or `{error}`. A rejection from WP1.2 leaves the request available for corrected input. `cancel_turn()` tells the controller to discard pending work after the session has invalidated the callback.

`HumanController.input_requested` supplies the request to a local input adapter. The adapter calls `submit_player_command(request_id, command)` using the ID from that same request. `ScriptedController` chooses from the supplied options using its own seeded RNG. A restart with the same controller instances preserves their RNG progress. Use freshly seeded instances to reproduce an entire scripted match.

## Authority and lifecycle

The callback is bound to the requested player and a monotonically increasing ID that survives restart on the same session. The coordinator rejects callbacks from closed requests and prevents reentrant handling during notifications. For an open request, `TurnResolver.apply` validates the original WP1.2 command, including the active player and expected state version. The session only replaces state after a successful resolver result. Successful submission closes the request before any observer can submit again. Controller calls and signal delivery run on the Godot main thread. A future background worker must return its proposal to that thread.

| Signal | Payload and timing |
| --- | --- |
| `match_started` | Detached opening state after successful setup |
| `turn_started` | Player and request ID before controller activation |
| `command_rejected` | Player and resolver error for a rejected proposal on an open request. Expired callbacks return their own error directly. |
| `turn_completed` | Detached WP1.2 history event after commit, including the command and piece ID, card, capture, exchange, and victory fields as applicable |
| `match_ended` | `victory`, `stopped`, or `restarted`, with the detached final or last state |

A winning action emits `turn_completed` before `match_ended`. `stop_match()` cancels pending input and retains the last authoritative snapshot. Starting again ends any active match before publishing the new start. Failed setup leaves the active match intact. Assign each controller instance to one live session.

Headless drivers can request the following turn immediately after the current call returns. Future presentation can render the confirmed event and request the following turn once its animations finish. The history event identifies the acting player and exchange for AD-01. The fixed exchange position in AD-02 belongs to presentation. Future AI can evaluate detached positions, and a future remote adapter can submit the same command through a current request.
