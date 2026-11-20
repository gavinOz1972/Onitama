extends SceneTree

const Loader = preload("res://rules/card_set_loader.gd")
const Command = preload("res://rules/move_command.gd")
const Serializer = preload("res://rules/state_serializer.gd")
const Session = preload("res://match/match_session.gd")
const Human = preload("res://controllers/human_controller.gd")
const Scripted = preload("res://controllers/scripted_controller.gd")
const FIXTURE := "res://tests/fixtures/original_cards.json"

class Probe extends "res://controllers/player_controller.gd":
	var request: Dictionary
	var propose: Callable
	var cancellations := 0

	func request_turn(data: Dictionary, submit: Callable) -> void:
		request = data
		propose = submit

	func cancel_turn() -> void:
		cancellations += 1


var checks := 0
var failures := 0


func _initialize() -> void:
	var loaded := Loader.load_file(FIXTURE)
	check(loaded.has("card_set"), "load original card fixture")
	if loaded.has("card_set"):
		test_human(loaded.card_set)
		test_cancellation_and_isolation(loaded.card_set)
		test_forced_pass()
		test_simulations(loaded.card_set)
	print("WP2.1: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", label)


func test_human(card_set: Dictionary) -> void:
	var match_session := Session.new()
	var red := Human.new()
	var blue := Human.new()
	var requests: Dictionary
	var lifecycle: Array = []
	var reentrant: Array = []
	var rejections: Array = []
	var reentrant_submissions: Array = []
	red.input_requested.connect(func(data: Dictionary) -> void: requests["red"] = data)
	blue.input_requested.connect(func(data: Dictionary) -> void: requests["blue"] = data)
	match_session.match_started.connect(func(_state: Dictionary) -> void: lifecycle.append("start"))
	var session_ref: WeakRef = weakref(match_session)
	match_session.turn_started.connect(func(player: String, _id: int) -> void:
		lifecycle.append(player)
		reentrant.append(session_ref.get_ref().request_next_turn().has("error"))
	)
	match_session.turn_completed.connect(func(event: Dictionary) -> void:
		lifecycle.append("completed")
		event.command.card = "changed by observer"
	)
	match_session.command_rejected.connect(func(player: String, reason: String) -> void:
		rejections.append(reason)
		var request: Dictionary = requests[player]
		var controller := red if player == "red" else blue
		reentrant_submissions.append(controller.submit_player_command(request.request_id, request.options[0]).has("error"))
	)
	match_session.match_ended.connect(func(reason: String, _state: Dictionary) -> void: lifecycle.append(reason))

	var started := match_session.start_match(card_set, 42, red, blue)
	check(started.has("state"), "start with two human adapters")
	if not started.has("state"):
		return
	var initial := match_session.get_state()
	var player: String = initial.current_player
	var other := "blue" if player == "red" else "red"
	var active := red if player == "red" else blue
	var inactive := blue if player == "red" else red
	check(active.submit_player_command(0, {}).has("error"), "input cannot precede a request")
	var dispatched := match_session.request_next_turn()
	check(dispatched.has("request_id") and requests.keys() == [player], "only the active controller is requested")
	if not requests.has(player):
		return
	var request: Dictionary = requests[player]
	var ticket: int = request.request_id
	check(request.player == player and request.state == initial, "turn includes identity and state")
	check(match_session.request_next_turn().has("error") and match_session.get_state() == initial, "human waits with one open request")
	check(inactive.submit_player_command(ticket, request.options[0]).has("error"), "inactive adapter cannot submit")

	var valid: Dictionary = request.options[0]
	var stale := valid.duplicate(true)
	stale.expected_version += 1
	var wrong_player := valid.duplicate(true)
	wrong_player.player = other
	var illegal := valid.duplicate(true)
	illegal.destination = initial.pieces[valid.piece].position
	for proposal in [stale, wrong_player, illegal, {"kind": "move"}]:
		var rejected := active.submit_player_command(ticket, proposal)
		check(rejected.has("error") and match_session.get_state() == initial, "rejection preserves state and turn")
	check(rejections == ["Stale state version", "Player or selected card is ineligible", "Illegal move", "Malformed command"], "resolver rejection reasons are published")
	check(reentrant_submissions == [true, true, true, true], "reentrant submissions cannot bypass a pending rejection")

	var accepted := active.submit_player_command(ticket, valid)
	check(accepted.has("event") and match_session.get_state().version == 1, "corrected input commits once")
	check(match_session.get_state().history[0].command == valid, "event observers cannot mutate history")
	check(active.submit_player_command(ticket, valid).has("error"), "duplicate input rejected")
	check(not requests.has(other), "next turn waits for the driver")
	match_session.request_next_turn()
	check(requests.has(other), "next request activates opponent")
	match_session.stop_match()
	check(lifecycle == ["start", player, "completed", other, "stopped"] and reentrant == [true, true], "lifecycle order and reentrant dispatch guard")
	if requests.has(other):
		check(inactive.submit_player_command(requests[other].request_id, {}).has("error"), "stop cancels pending human input")
	check(match_session.get_state().version == 1 and match_session.request_next_turn().has("error"), "stop preserves the snapshot and blocks dispatch")


func test_cancellation_and_isolation(card_set: Dictionary) -> void:
	var match_session := Session.new()
	var red := Probe.new()
	var blue := Probe.new()
	var supplied_set := card_set.duplicate(true)
	match_session.start_match(supplied_set, 42, red, blue)
	var original := match_session.get_state()
	var active := red if original.current_player == "red" else blue
	supplied_set.cards.clear()
	match_session.request_next_turn()
	check(not active.request.get("options", []).is_empty(), "session owns the supplied card set")
	if active.request.get("options", []).is_empty():
		return
	var old_submit := active.propose
	var old_ticket: int = active.request.request_id
	var command: Dictionary = active.request.options[0].duplicate(true)
	active.request.state.pieces.clear()
	active.request.options[0].destination.clear()
	var external_snapshot := match_session.get_state()
	external_snapshot.hands.clear()
	check(match_session.get_state() == original, "nested controller data and returned snapshots are detached")
	var restarted := match_session.start_match(card_set, 42, red, blue)
	check(restarted.get("state") == original and active.cancellations == 1, "restart cancels outstanding controller and recreates initial state")
	match_session.request_next_turn()
	check(active.request.request_id != old_ticket, "restart never reuses a request ID")
	check(old_submit.call(command).has("error") and match_session.get_state() == original, "old callback rejected even at the same player and state version")
	var result: Dictionary = active.propose.call(command)
	check(result.has("event") and match_session.get_state().version == 1, "new callback accepts the same legal command")
	check(active.propose.call(command).has("error") and active.cancellations == 2, "successful callback closes before it can be reused")

	var human := Human.new()
	var opponent := Scripted.new()
	var inputs: Array = []
	human.input_requested.connect(func(request: Dictionary) -> void: inputs.append(request))
	var red_slot = human if original.current_player == "red" else opponent
	var blue_slot = human if original.current_player == "blue" else opponent
	match_session.start_match(card_set, 42, red_slot, blue_slot)
	match_session.request_next_turn()
	match_session.start_match(card_set, 42, red_slot, blue_slot)
	match_session.request_next_turn()
	check(inputs.size() == 2, "human receives fresh input request on restart")
	if inputs.size() == 2:
		check(human.submit_player_command(inputs[0].request_id, inputs[0].options[0]).has("error"), "human rejects stale input after restart")
		check(human.submit_player_command(inputs[1].request_id, inputs[1].options[0]).has("event"), "human accepts fresh input after restart")


func test_forced_pass() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	for card in data.cards:
		card.moves = [[1, 0]]
	var loaded := Loader.validate(data)
	check(loaded.has("card_set"), "load derived lateral-only card set for forced pass")
	if not loaded.has("card_set"):
		return
	var match_session := Session.new()
	var human := Human.new()
	var scripted := Scripted.new(9)
	var requests: Array = []
	human.input_requested.connect(func(request: Dictionary) -> void: requests.append(request))
	var card_set: Dictionary = loaded.card_set
	var started := match_session.start_match(card_set, 42, human, scripted)
	if not started.has("state"):
		check(false, "start forced pass fixture")
		return
	var initial: Dictionary = started.state
	if initial.current_player == "blue":
		match_session.start_match(card_set, 42, scripted, human)
	match_session.request_next_turn()
	check(requests.size() == 1, "forced pass prompts human")
	if requests.is_empty():
		return
	var request: Dictionary = requests[0]
	request.card_set.cards.clear()
	var hand: Array = initial.hands[initial.current_player]
	check(request.options == [
		Command.forced_pass(initial.current_player, hand[0], 0),
		Command.forced_pass(initial.current_player, hand[1], 0),
	], "each hand card is a separate pass option")
	var passed := human.submit_player_command(request.request_id, request.options[1])
	check(passed.has("event"), "human selects which card to exchange and cannot mutate authoritative card definitions")
	var state := match_session.get_state()
	check(state.shared == hand[1] and state.pieces == initial.pieces, "pass exchanges the selected card without moving pieces")
	match_session.request_next_turn()
	state = match_session.get_state()
	check(state.version == 2 and state.history.back().command.kind == "pass", "scripted adapter also submits a forced pass")
	check(state.pieces == initial.pieces and state.current_player == initial.current_player, "both passes leave board intact and alternate turns")


func test_simulations(card_set: Dictionary) -> void:
	var seeds := 30
	var scripted_results: Array[Dictionary] = []
	for human_slot in ["none", "red", "blue"]:
		var stats := {"completed": 0, "turns": 0, "red": 0, "blue": 0, "teacher_capture": 0,
			"opposing_temple": 0, "passes": 0, "rejections": 0, "unexpected_stops": 0, "reproducible": 0}
		for seed_value in range(seeds):
			var state := simulate(card_set, seed_value, human_slot, stats)
			var repeat := simulate(card_set, seed_value, human_slot, {})
			check(state == repeat, "fixed seed repeats exactly")
			if human_slot == "none":
				scripted_results.append(state)
			else:
				check(state == scripted_results[seed_value], "same command sequence produces identical state across controller types")
			if state == repeat:
				stats.reproducible += 1
		check(stats.completed == seeds and stats.unexpected_stops == 0 and stats.rejections == 0, "all %s games completed cleanly" % human_slot)
		print("Simulation human=%s: %s" % [human_slot, JSON.stringify(stats)])


func simulate(card_set: Dictionary, seed_value: int, human_slot: String, stats: Dictionary) -> Dictionary:
	var match_session := Session.new()
	var human := Human.new()
	var inputs: Array = []
	var human_rng := RandomNumberGenerator.new()
	human_rng.seed = seed_value + (10000 if human_slot == "red" else 20000)
	human.input_requested.connect(func(request: Dictionary) -> void: inputs.append(request))
	var red = human if human_slot == "red" else Scripted.new(seed_value + 10000)
	var blue = human if human_slot == "blue" else Scripted.new(seed_value + 20000)
	var events: Array = []
	var endings: Array = []
	var rejections: Array = []
	match_session.turn_completed.connect(func(event: Dictionary) -> void: events.append(event))
	match_session.match_ended.connect(func(reason: String, state: Dictionary) -> void: endings.append([reason, state]))
	match_session.command_rejected.connect(func(_player: String, reason: String) -> void: rejections.append(reason))
	var result := match_session.start_match(card_set, seed_value, red, blue)
	check(result.has("state"), "simulation starts")
	if not result.has("state"):
		if not stats.is_empty():
			stats.unexpected_stops += 1
		return {}
	var state: Dictionary = result.state
	for turn in range(500):
		if match_session.request_next_turn().has("error"):
			break
		if not inputs.is_empty():
			var request: Dictionary = inputs.pop_front()
			var options: Array = request.options
			var submitted := human.submit_player_command(request.request_id, options[human_rng.randi_range(0, options.size() - 1)])
			check(submitted.has("event"), "external human input completed")
		state = match_session.get_state()
		check(state.version == turn + 1, "exactly one transition on dispatch")
		if state.version != turn + 1 or state.status != "active":
			break

	check(events == state.history, "completion events match authoritative history")
	check(Serializer.decode(Serializer.encode(state), card_set).get("state") == state, "accepted engine replays the match")
	var won: bool = state.status == "won"
	check(won and endings == [["victory", state]], "single victory notification with terminal snapshot")
	check(match_session.request_next_turn().has("error"), "terminal match blocks further requests")
	check(human.submit_player_command(1, {}).has("error"), "terminal match blocks human input")
	if not stats.is_empty():
		stats.turns += state.version
		stats.rejections += rejections.size()
		for event in events:
			if event.command.kind == "pass":
				stats.passes += 1
		if won:
			stats.completed += 1
			stats[state.winner] += 1
			stats[state.victory_reason] += 1
		else:
			stats.unexpected_stops += 1
	return state
