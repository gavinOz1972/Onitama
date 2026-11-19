extends RefCounted

const SIZE := 5
const PLAYERS := ["red", "blue"]

static func opponent(player: String) -> String:
	return "blue" if player == "red" else "red"


static func home_row(player: String) -> int:
	return 0 if player == "red" else SIZE - 1


static func setup(card_set: Dictionary, seed_value: int) -> Dictionary:
	var ids: Array = card_set.cards.keys()
	if ids.size() < 5:
		return {"error": "A match requires five distinct cards"}
	ids.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var deal: Array = []
	for slot in range(5):
		deal.append(ids.pop_at(rng.randi_range(0, ids.size() - 1)))
	return from_deal(card_set, deal)


static func from_deal(card_set: Dictionary, deal: Array) -> Dictionary:
	if deal.size() != 5:
		return {"error": "A deal must contain five cards"}
	var seen := {}
	for id in deal:
		if not id is String or not card_set.cards.has(id) or seen.has(id):
			return {"error": "Unknown or repeated card in deal"}
		seen[id] = true
	var pieces := {}
	for player in PLAYERS:
		for column in range(SIZE):
			var id := "%s-%d" % [player, column]
			pieces[id] = {
				"owner": player,
				"role": "TEACHER" if column == 2 else "DISCIPLE",
				"position": [column, home_row(player)],
				"captured": false,
			}
	return {"state": {
		"card_set_id": card_set.set_id, "card_set_version": card_set.version,
		"deal": deal.duplicate(), "pieces": pieces,
		"hands": {"red": deal.slice(0, 2), "blue": deal.slice(2, 4)},
		"shared": deal[4], "current_player": card_set.cards[deal[4]].starting_player,
		"status": "active", "winner": null, "victory_reason": null,
		"version": 0, "history": [],
	}}
