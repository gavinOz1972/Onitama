extends RefCounted

const State = preload("res://rules/game_state.gd")
const Command = preload("res://rules/move_command.gd")

static func legal_moves(state: Dictionary, card_set: Dictionary) -> Array[Dictionary]:
	var moves: Array[Dictionary] = []
	if state.status != "active" or not compatible(state, card_set):
		return moves
	var player: String = state.current_player
	var occupied := {}
	for id in state.pieces:
		var piece: Dictionary = state.pieces[id]
		if not piece.captured:
			occupied[Vector2i(int(piece.position[0]), int(piece.position[1]))] = piece.owner
	var ids: Array = state.pieces.keys()
	ids.sort()
	for id in ids:
		var piece: Dictionary = state.pieces[id]
		if piece.captured or piece.owner != player:
			continue
		var origin := Vector2i(int(piece.position[0]), int(piece.position[1]))
		for card in state.hands[player]:
			for offset: Vector2i in card_set.cards[card].moves:
				# Blue faces up the board. Red's entire local frame is rotated.
				var delta := Vector2i(offset.x, -offset.y)
				var target := origin + (delta if player == "blue" else -delta)
				if Rect2i(0, 0, State.SIZE, State.SIZE).has_point(target) and occupied.get(target) != player:
					moves.append(Command.move(player, id, card, [target.x, target.y], state.version))
	return moves


static func compatible(state: Dictionary, card_set: Dictionary) -> bool:
	return state.card_set_id == card_set.set_id and state.card_set_version == card_set.version
