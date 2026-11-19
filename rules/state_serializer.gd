extends RefCounted

const State = preload("res://rules/game_state.gd")
const Resolver = preload("res://rules/turn_resolver.gd")

static func encode(state: Dictionary) -> String:
	return JSON.stringify({"format": 1, "state": state})


static func decode(snapshot: String, card_set: Dictionary) -> Dictionary:
	var json := JSON.new()
	if json.parse(snapshot) != OK:
		return {"error": "Invalid snapshot JSON"}
	var envelope: Variant = json.data
	if not envelope is Dictionary or envelope.size() != 2 or envelope.get("format") != 1:
		return {"error": "Unsupported snapshot format"}
	var saved: Variant = envelope.get("state")
	if not saved is Dictionary or saved.get("card_set_id") != card_set.set_id \
			or saved.get("card_set_version") != card_set.version:
		return {"error": "Missing state or incompatible card set"}
	if not saved.get("deal") is Array or not saved.get("history") is Array:
		return {"error": "Missing deal or history"}
	var result := State.from_deal(card_set, saved.deal)
	if result.has("error"):
		return result
	for event in saved.history:
		if not event is Dictionary:
			return {"error": "Malformed history event"}
		result = Resolver.apply(result.state, card_set, event.get("command"))
		if result.has("error"):
			return {"error": "Invalid history command: %s" % result.error}
	var replayed: Variant = JSON.parse_string(JSON.stringify(result.state))
	if replayed != saved:
		return {"error": "Snapshot disagrees with replay"}
	return result
