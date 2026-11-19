# WP1.2 architecture

## Entry points

- `CardSetLoader.load_file(path)` parses version 1 JSON and returns `{card_set}` or `{error}`. `validate(data)` accepts an already parsed value. Validation covers exact fields, identity, coordinates, stamps, bounded integral offsets and uniqueness. Zero displacement is rejected. Loading permits small sets for validation. Match setup requires at least five cards.
- `GameState.setup(card_set, seed)` deals from sorted IDs using a match-local RNG. `from_deal(card_set, deal)` takes red's two IDs, blue's two IDs, then the shared ID. Both return `{state}` or `{error}`. The shared card's stamp selects the first player.
- `RulesEngine.legal_moves(state, card_set)` returns movement commands for the active player in stable piece, hand-slot, and offset order. An empty list in an active compatible match calls for a pass with a selected hand card.
- `TurnResolver.apply(state, card_set, command)` returns `{state}` or `{error}`. Applications should replace their authoritative state with the returned value on success.
- `StateSerializer.encode(state)` produces JSON. `decode(snapshot, card_set)` returns `{state}` or `{error}`.

## State and command contracts

Board columns and rows run from 0 through 4. Blue's local offset `(x, y)` maps to board displacement `(x, -y)`. Red's maps to `(-x, y)`. The board is represented by the live piece positions. Each stable piece ID maps to owner, role, position and captured flag. A captured piece has a null position. Both roles use the same offsets. Only the landing square is checked for occupancy.

State includes the initial deal, piece map, hands, shared card, current player, status, winner, victory reason, version, history, and card-set identity and version. Treat the input state and loaded card set as read-only values. Publish changed card definitions under a new version.

Commands contain `kind`, `player`, `piece`, `card`, `destination`, and `expected_version`. A move supplies a piece ID and board square. A pass supplies null for both fields. The same command dictionary works across controller types.

## Turn lifecycle

Validate match status, collection version, command shape, turn version and eligibility. Validate the move against generated commands or confirm that a pass is compulsory. Copy the state, apply movement and capture, evaluate victory, swap the selected card with the shared card in its hand slot, increment the version, and append one event. Advance the current player for continuing matches. The terminal state retains the winning actor. A Teacher capture takes precedence if the same move reaches the opposing centre home square.

Events store the command, actor, selected card, origin and destination, capture, exchange, status, winner, victory reason and resulting version. A format-1 snapshot stores the full state. The decoder reconstructs the initial deal, replays the commands through the resolver and checks the entire resulting state against the saved payload. This supports snapshots produced by the public match lifecycle. Replay cost grows with the history, and full state copies include history.
