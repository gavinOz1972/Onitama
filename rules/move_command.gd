extends RefCounted

const CardLoader = preload("res://rules/card_set_loader.gd")

static func move(player: String, piece: String, card: String, destination: Array, version: int) -> Dictionary:
	return {"kind": "move", "player": player, "piece": piece, "card": card,
		"destination": destination.duplicate(), "expected_version": version}


static func forced_pass(player: String, card: String, version: int) -> Dictionary:
	return {"kind": "pass", "player": player, "piece": null, "card": card,
		"destination": null, "expected_version": version}


static func valid(command: Variant) -> bool:
	if not CardLoader.has_fields(command, ["kind", "player", "piece", "card", "destination", "expected_version"]):
		return false
	if command.player not in ["red", "blue"] or not CardLoader.nonempty(command.card) \
			or not CardLoader.whole(command.expected_version, 0, 9007199254740991):
		return false
	if command.kind == "pass":
		return command.piece == null and command.destination == null
	return command.kind == "move" and CardLoader.nonempty(command.piece) \
		and command.destination is Array and command.destination.size() == 2 \
		and CardLoader.whole(command.destination[0], 0, 4) \
		and CardLoader.whole(command.destination[1], 0, 4)
