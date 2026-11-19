extends RefCounted

const COORDINATES := {
	"origin": "piece_square",
	"positive_x": "player_right",
	"positive_y": "player_forward",
	"opponent_transform": "rotate_180_degrees",
	"unit": "one_board_square",
}

static func load_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "Cannot open card set %s (%s)" % [path, FileAccess.get_open_error()]}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {"error": "Card JSON line %s: %s" % [json.get_error_line(), json.get_error_message()]}
	return validate(json.data)


static func validate(data: Variant) -> Dictionary:
	if not has_fields(data, ["schema_version", "set_id", "name", "version", "coordinate_system", "cards"]):
		return {"error": "Invalid card set fields"}
	if data.schema_version != 1 or not matches(data.set_id, "^[a-z][a-z0-9._-]+$") \
			or not matches(data.version, "^[0-9]+\\.[0-9]+\\.[0-9]+$") or not nonempty(data.name):
		return {"error": "Invalid card set identity or schema version"}
	if data.coordinate_system != COORDINATES:
		return {"error": "Unsupported card coordinates"}
	if not data.cards is Array or data.cards.is_empty():
		return {"error": "Card set must contain at least one card"}
	var cards := {}
	for index in range(data.cards.size()):
		var card: Variant = data.cards[index]
		if not has_fields(card, ["id", "name", "starting_player", "moves"]):
			return {"error": "Invalid fields for card %d" % index}
		if not matches(card.id, "^[a-z][a-z0-9_-]*\\.[a-z][a-z0-9_-]*$") or cards.has(card.id):
			return {"error": "Invalid or duplicate card ID at index %d: %s" % [index, card.id]}
		if not nonempty(card.name) or card.starting_player not in ["red", "blue"]:
			return {"error": "Invalid name or stamp for %s" % card.id}
		if not card.moves is Array or card.moves.is_empty() or card.moves.size() > 24:
			return {"error": "Invalid movement list for %s" % card.id}
		var moves: Array[Vector2i] = []
		for pair in card.moves:
			if not pair is Array or pair.size() != 2 or not whole(pair[0], -2, 2) or not whole(pair[1], -2, 2):
				return {"error": "Invalid offset for %s: %s" % [card.id, pair]}
			var offset := Vector2i(int(pair[0]), int(pair[1]))
			if offset == Vector2i.ZERO or offset in moves:
				return {"error": "Zero or duplicate offset for %s: %s" % [card.id, pair]}
			moves.append(offset)
		cards[card.id] = {"name": card.name, "starting_player": card.starting_player, "moves": moves}
	return {"card_set": {"set_id": data.set_id, "version": data.version, "cards": cards}}


static func has_fields(data: Variant, fields: Array) -> bool:
	return data is Dictionary and data.size() == fields.size() and data.has_all(fields)


static func whole(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and value >= minimum and value <= maximum and value == floor(value)


static func nonempty(value: Variant) -> bool:
	return value is String and not value.is_empty()


static func matches(value: Variant, pattern: String) -> bool:
	if not value is String or value.contains("\n") or value.contains("\r"):
		return false
	var regex := RegEx.create_from_string(pattern)
	return regex.search(value) != null
