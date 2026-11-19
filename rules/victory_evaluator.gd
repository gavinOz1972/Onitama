extends RefCounted

const State = preload("res://rules/game_state.gd")

static func evaluate(piece: Dictionary, captured: Variant) -> Variant:
	if captured != null and captured.role == "TEACHER":
		return "teacher_capture"
	if piece.role == "TEACHER" and piece.position == [2, State.home_row(State.opponent(piece.owner))]:
		return "opposing_temple"
	return null
