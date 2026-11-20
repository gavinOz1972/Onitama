extends RefCounted

const Controller = preload("res://controllers/player_controller.gd")
const State = preload("res://rules/game_state.gd")
const Rules = preload("res://rules/rules_engine.gd")
const Command = preload("res://rules/move_command.gd")
const Resolver = preload("res://rules/turn_resolver.gd")

signal match_started(state: Dictionary)
signal turn_started(player: String, request_id: int)
signal command_rejected(player: String, reason: String)
signal turn_completed(event: Dictionary)
signal match_ended(reason: String, state: Dictionary)

var _card_set: Dictionary
var _state: Dictionary
var _controllers: Dictionary
var _running := false
var _busy := false
var _dispatching := false
var _request_serial := 0
var _active_request := -1


## card_set must come from the WP1.2 loader. Starting again replaces the match.
func start_match(card_set: Dictionary, seed_value: int, red: Controller, blue: Controller) -> Dictionary:
	if _busy or _dispatching:
		return {"error": "Session is handling a turn or lifecycle notification"}
	if red == null or blue == null or red == blue:
		return {"error": "Assign a distinct controller to each player"}
	var setup := State.setup(card_set, seed_value)
	if setup.has("error"):
		return setup

	_busy = true
	_end_match("restarted")
	_card_set = card_set.duplicate(true)
	_state = setup.state
	_controllers = {"red": red, "blue": blue}
	_running = true
	match_started.emit(get_state())
	_busy = false
	return {"state": get_state()}


func get_state() -> Dictionary:
	return _state.duplicate(true)


## Dispatch at most one request. An asynchronous controller may leave it pending.
func request_next_turn() -> Dictionary:
	if _busy or _dispatching:
		return {"error": "Session is handling a turn or lifecycle notification"}
	if not _running:
		return {"error": "No active match"}
	if _active_request != -1:
		return {"error": "A controller request is already pending"}

	_dispatching = true
	_request_serial += 1
	_active_request = _request_serial
	var request_id := _active_request
	var player: String = _state.current_player
	var options := Rules.legal_moves(_state, _card_set)
	if options.is_empty():
		for card in _state.hands[player]:
			options.append(Command.forced_pass(player, card, _state.version))
	var request := {
		"player": player, "request_id": request_id, "state": get_state(),
		"card_set": _card_set.duplicate(true), "options": options,
	}
	var session: WeakRef = weakref(self)
	var propose := func(command: Variant) -> Dictionary:
		var live_session: Variant = session.get_ref()
		if live_session == null:
			return {"error": "Match session no longer exists"}
		return live_session._submit(player, request_id, command)

	turn_started.emit(player, request_id)
	_controllers[player].request_turn(request, propose)
	_dispatching = false
	return {"request_id": request_id}


func stop_match() -> Dictionary:
	if _busy or _dispatching:
		return {"error": "Session is handling a turn or lifecycle notification"}
	_busy = true
	_end_match("stopped")
	_busy = false
	return {"state": get_state()}


func _submit(player: String, request_id: int, command: Variant) -> Dictionary:
	if _busy:
		return {"error": "Session is handling a command or lifecycle notification"}
	if not _running or request_id != _active_request or player != _state.current_player:
		return {"error": "This turn request is no longer active"}

	_busy = true
	var result := Resolver.apply(_state, _card_set, command)
	if result.has("error"):
		command_rejected.emit(player, result.error)
		_busy = false
		return result

	_close_request()
	_state = result.state
	var event: Dictionary = _state.history.back()
	turn_completed.emit(event.duplicate(true))
	if _state.status != "active":
		_end_match("victory")
	_busy = false
	return {"event": event.duplicate(true)}


func _close_request() -> void:
	if _active_request != -1:
		_active_request = -1
		_controllers[_state.current_player].cancel_turn()


func _end_match(reason: String) -> void:
	if not _running:
		return
	_running = false
	_close_request()
	_controllers.clear()
	match_ended.emit(reason, get_state())
