extends RefCounted

static func record(state: Dictionary, command: Dictionary, origin: Variant, captured: Variant, received: String) -> void:
	state.history.append({
		"command": command.duplicate(true), "player": command.player, "card": command.card,
		"origin": origin, "destination": command.destination, "captured_piece": captured,
		"exchange": {"to_shared": command.card, "to_player": received},
		"winner": state.winner, "victory_reason": state.victory_reason, "status": state.status,
		"version": state.version,
	})
