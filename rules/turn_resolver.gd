extends RefCounted

const State = preload("res://rules/game_state.gd")
const Command = preload("res://rules/move_command.gd")
const Rules = preload("res://rules/rules_engine.gd")
const Victory = preload("res://rules/victory_evaluator.gd")
const History = preload("res://rules/match_history.gd")

static func apply(state: Dictionary, card_set: Dictionary, input: Variant) -> Dictionary:
	if state.status != "active":
		return {"error": "Match is terminal"}
	if not Rules.compatible(state, card_set):
		return {"error": "Incompatible card set"}
	if not Command.valid(input):
		return {"error": "Malformed command"}
	if input.expected_version != state.version:
		return {"error": "Stale state version"}
	if input.player != state.current_player or input.card not in state.hands[state.current_player]:
		return {"error": "Player or selected card is ineligible"}
	var legal := Rules.legal_moves(state, card_set)
	var command: Dictionary
	if input.kind == "pass":
		if not legal.is_empty():
			return {"error": "A legal move is available"}
		command = Command.forced_pass(input.player, input.card, state.version)
	else:
		var destination := [int(input.destination[0]), int(input.destination[1])]
		for move in legal:
			if move.piece == input.piece and move.card == input.card and move.destination == destination:
				command = move
				break
		if command.is_empty():
			return {"error": "Illegal move"}

	var next := state.duplicate(true)
	var origin: Variant = null
	var captured: Variant = null
	if command.kind == "move":
		var piece: Dictionary = next.pieces[command.piece]
		origin = piece.position
		for id in next.pieces:
			var occupant: Dictionary = next.pieces[id]
			if not occupant.captured and occupant.position == command.destination:
				captured = id
				occupant.captured = true
				occupant.position = null
				break
		piece.position = command.destination.duplicate()
		var captured_piece: Variant = next.pieces[captured] if captured != null else null
		next.victory_reason = Victory.evaluate(piece, captured_piece)
		if next.victory_reason != null:
			next.status = "won"
			next.winner = command.player

	var received: String = next.shared
	var hand: Array = next.hands[command.player]
	hand[hand.find(command.card)] = received
	next.shared = command.card
	next.version += 1
	if next.status == "active":
		next.current_player = State.opponent(command.player)
	History.record(next, command, origin, captured, received)
	return {"state": next}
