# WP1.1 Validation Record

## Source-to-data mapping

The uploaded card photo presents 16 named cards, each with a black centre and colored destination cells. Each colored cell was transcribed as `(column,row)` on a 5×5 diagram and independently checked in `tests/test_core_cards.py`; `core.json` uses `[column - 2, 2 - row]`.

The first-player stamp is a separate red or blue icon printed at the bottom right of each physical card. It was transcribed individually. There are eight red and eight blue stamps.

The source rulebook's setup section (page 5) establishes that the fifth card's stamp selects the first player, and the movement section (pages 6–7) defines the center square and destination squares. Page 8 establishes that a player who cannot move must still exchange a card. The rules reference does not provide standalone machine-readable definitions.

## Validations performed

- 16 unique card IDs and expected names.
- All 16 photo-derived destination patterns compared against independently recorded grid-cell fixtures.
- All 16 stamp values compared against individually transcribed source fixtures.
- Equal eight/eight red/blue stamp distribution as a sanity check, **not** as a substitute for visual verification.
- Every offset is an integer within the photographed 5×5 grid, not `[0,0]`, and contains no duplicate move.
- Player orientation reverses **both** axes between opposing players.
- Validates the JSON payload against `card-set.schema.json` (Draft 2020-12).

## Interpretation and limitations

- The uploaded photo is not a publisher-supplied data file. Verification here is a careful manual visual transcription backed by tests, **not** an independent publisher certification of digital card data.
- The red/blue `starting_player` values reflect the stamp colors visible in the source photograph; particularly small/dark stamps may warrant a second inspection against physical cards before publishing.
- The JSON Schema validates field structure; tests enforce *core-specific* invariants (16 exact cards, canonical IDs, stamps and movements).
- The grid is player-relative. The engine is responsible for rejecting destinations outside the 5×5 board, destinations occupied by friendly pieces, and illegal turns.
- The card set does not model animations, physical geometry, or visual faction identity.

## Core stamp listing

| Blue stamp | Red stamp |
|---|---|
| Tiger | Dragon |
| Rabbit | Frog |
| Crab | Elephant |
| Goose | Rooster |
| Monkey | Mantis |
| Ox | Horse |
| Crane | Boar |
| Eel | Cobra |

## Acceptance recommendation

Accept WP1.1 as **development-ready** once the project's owner is satisfied with the card photograph's legibility. Treat a physical-card or publisher-data cross-check as an optional pre-distribution quality gate.
