extends "res://controllers/player_controller.gd"

signal input_requested(request: Dictionary)

var _request_id := -1
var _propose: Callable


func request_turn(request: Dictionary, propose: Callable) -> void:
	_request_id = request.request_id
	_propose = propose
	input_requested.emit(request)


func submit_player_command(request_id: int, command: Variant) -> Dictionary:
	if request_id != _request_id or not _propose.is_valid():
		return {"error": "This input request is no longer active"}
	return _propose.call(command)


func cancel_turn() -> void:
	_request_id = -1
	_propose = Callable()
