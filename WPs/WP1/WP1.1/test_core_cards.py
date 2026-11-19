"""WP1.1 contract tests. Run: python -m unittest discover -s tests -v"""
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CORE = json.loads((ROOT / 'core.json').read_text(encoding='utf-8'))

# Independent row/column transcription of the photographed 5x5 diagrams.
# Each pair is (col, row) counting from top left of the pictured card.
# The centre (2, 2) is always the black current-position square.
IMAGE_CELLS = {
    'tiger': [(2,0),(2,3)],
    'dragon':[(0,1),(4,1),(1,3),(3,3)],
    'frog':[(1,1),(0,2),(3,3)],
    'rabbit':[(3,1),(4,2),(1,3)],
    'crab':[(2,1),(0,2),(4,2)],
    'elephant':[(1,1),(3,1),(1,2),(3,2)],
    'goose':[(1,1),(1,2),(3,2),(3,3)],
    'rooster':[(3,1),(1,2),(3,2),(1,3)],
    'monkey':[(1,1),(3,1),(1,3),(3,3)],
    'mantis':[(1,1),(3,1),(2,3)],
    'horse':[(2,1),(1,2),(2,3)],
    'ox':[(2,1),(3,2),(2,3)],
    'crane':[(2,1),(1,3),(3,3)],
    'boar':[(2,1),(1,2),(3,2)],
    'eel':[(1,1),(3,2),(1,3)],
    'cobra':[(3,1),(1,2),(3,3)],
}
IMAGE_STAMPS = {
    'tiger':'blue','dragon':'red','frog':'red','rabbit':'blue',
    'crab':'blue','elephant':'red','goose':'blue','rooster':'red',
    'monkey':'blue','mantis':'red','horse':'red','ox':'blue',
    'crane':'blue','boar':'red','eel':'blue','cobra':'red',
}


def card_offsets(card):
    return {tuple(p) for p in card['moves']}


def transform_to_board(offset, player):
    """Board x grows right, board y grows downward. P1 faces up; P2 faces down."""
    x,y=offset
    return (x,-y) if player == 1 else (-x,y)


class CoreCardTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cards={c['id'].split('.')[1]: c for c in CORE['cards']}

    def test_schema(self):
        import jsonschema
        schema=json.loads((ROOT/'card-set.schema.json').read_text(encoding='utf-8'))
        jsonschema.Draft202012Validator.check_schema(schema)
        jsonschema.validate(CORE, schema)

    def test_sixteen_unique_original_cards(self):
        self.assertEqual(len(CORE['cards']),16)
        self.assertEqual(set(self.cards),set(IMAGE_CELLS))

    def test_offsets_match_image_cells(self):
        for name,cells in IMAGE_CELLS.items():
            with self.subTest(card=name):
                expected={(col-2,2-row) for col,row in cells}
                self.assertEqual(card_offsets(self.cards[name]),expected)
                self.assertNotIn((0,0),expected)

    def test_starting_player_stamp_matches_source(self):
        for name,stamp in IMAGE_STAMPS.items():
            with self.subTest(card=name):
                self.assertEqual(self.cards[name]['starting_player'],stamp)
        self.assertEqual(sum(c['starting_player']=='red' for c in CORE['cards']),8)
        self.assertEqual(sum(c['starting_player']=='blue' for c in CORE['cards']),8)

    def test_player_orientation_rotates_both_axes(self):
        for c in CORE['cards']:
            for move in c['moves']:
                a=transform_to_board(move,1)
                b=transform_to_board(move,2)
                self.assertEqual(b,(-a[0],-a[1]))

    def test_all_moves_fit_5_by_5_diagram(self):
        for c in CORE['cards']:
            self.assertEqual(len(c['moves']),len(card_offsets(c)))
            for x,y in c['moves']:
                self.assertTrue(-2<=x<=2 and -2<=y<=2 and (x,y)!=(0,0))

    def test_card_ids_and_names_are_stable(self):
        self.assertEqual([c['id'] for c in CORE['cards']],['core.'+k for k in IMAGE_CELLS])
        for key,c in self.cards.items():
            self.assertEqual(c['name'],key.title())


if __name__=='__main__':
    unittest.main()
