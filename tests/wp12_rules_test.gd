extends SceneTree

const Loader = preload("res://rules/card_set_loader.gd")
const State = preload("res://rules/game_state.gd")
const Command = preload("res://rules/move_command.gd")
const Rules = preload("res://rules/rules_engine.gd")
const Resolver = preload("res://rules/turn_resolver.gd")
const Serializer = preload("res://rules/state_serializer.gd")
const FIXTURE := "res://tests/fixtures/original_cards.json"
const DEAL := ["surreal.arc", "surreal.hinge", "surreal.gate", "surreal.ladder", "surreal.orbit"]

var checks := 0
var failures := 0

func _initialize() -> void:
	var loaded := Loader.load_file(FIXTURE)
	check(loaded.has("card_set"), "load original fixture")
	if loaded.has("error"):
		quit(1)
		return
	var card_set: Dictionary = loaded.card_set
	test_cards(card_set)
	test_setup_and_movement(card_set)
	test_turns(card_set)
	test_simulations(card_set)
	print("WP1.2: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", label)


func test_cards(card_set: Dictionary) -> void:
	check(card_set.cards.size() == 8, "eight original cards")
	check(card_set.cards["surreal.hinge"].moves == [
		Vector2i(-2, 1), Vector2i(1, 2), Vector2i(1, -1), Vector2i(0, 1),
	], "asymmetric offsets retained")
	check(card_set.cards["surreal.gate"].starting_player == "blue", "stamp retained")
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	var duplicate := source.duplicate(true)
	duplicate.cards.append(duplicate.cards[0])
	check(Loader.validate(duplicate).has("error"), "duplicate card ID rejected")
	for offset in [[0, 0], [3, 0], [0.5, 0], [true, 0], [-2, 2], [1]]:
		var bad := source.duplicate(true)
		bad.cards[0].moves.append(offset)
		check(Loader.validate(bad).has("error"), "invalid offset %s" % [offset])
	source.cards[0].erase("starting_player")
	check(Loader.validate(source).has("error"), "missing stamp rejected")
	check(Loader.load_file("res://missing.json").has("error"), "missing file rejected")


func test_setup_and_movement(card_set: Dictionary) -> void:
	var state: Dictionary = State.from_deal(card_set, DEAL).state
	check(State.SIZE == 5 and state.pieces.size() == 10, "board and pieces")
	check(state.pieces["red-2"].position == [2, 0] and state.pieces["blue-2"].position == [2, 4], "Teacher start")
	check(state.pieces["blue-0"].role == "DISCIPLE", "Disciple role")
	check(state.current_player == "red", "shared stamp starts red")
	check(State.setup(card_set, 42) == State.setup(card_set, 42), "seed repeatability")
	check(State.from_deal(card_set, ["surreal.arc"]).has("error"), "short deal rejected")
	var red := Rules.legal_moves(state, card_set)
	check(Command.move("red", "red-2", "surreal.hinge", [4, 1], 0) in red, "red rotation")
	check(Command.move("red", "red-0", "surreal.hinge", [0, 1], 0) in red, "Disciple offsets")
	for move in red:
		check(move.destination[0] >= 0 and move.destination[0] < 5 and move.destination[1] >= 0 and move.destination[1] < 5, "bounded destination")
	state.current_player = "blue"
	var blue := Rules.legal_moves(state, card_set)
	check(Command.move("blue", "blue-2", "surreal.gate", [1, 2], 0) in blue, "blue orientation")
	check(Command.move("blue", "blue-2", "surreal.gate", [0, 4], 0) not in blue, "friendly landing rejected")
	state.pieces["blue-1"].position = [2, 3]
	check(Command.move("blue", "blue-2", "surreal.ladder", [2, 2], 0) in Rules.legal_moves(state, card_set), "jump over friendly piece")


func test_turns(card_set: Dictionary) -> void:
	var state: Dictionary = State.from_deal(card_set, DEAL).state
	var original := state.duplicate(true)
	var move := Command.move("red", "red-2", "surreal.hinge", [4, 1], 0)
	var next: Dictionary = Resolver.apply(state, card_set, move).state
	check(next.current_player == "blue" and next.version == 1, "advance once")
	check(next.shared == "surreal.hinge" and next.hands.red == ["surreal.arc", "surreal.orbit"], "exchange selected slot")
	check(next.history[0].origin == [2, 0] and next.history[0].destination == [4, 1], "history positions")
	check(Resolver.apply(next, card_set, move).has("error"), "stale command rejected")
	check(Resolver.apply(state, card_set, Command.forced_pass("red", "surreal.arc", 0)).has("error"), "voluntary pass rejected")
	check(Resolver.apply(state, card_set, Command.move("red", "blue-2", "surreal.arc", [2, 1], 0)).has("error"), "wrong piece rejected")
	check(Resolver.apply(state, card_set, Command.move("red", "red-2", "surreal.gate", [2, 1], 0)).has("error"), "wrong card rejected")
	check(state == original, "input state preserved")
	var stuck := state.duplicate(true)
	for id in stuck.pieces:
		if stuck.pieces[id].owner == "red" and id != "red-2":
			stuck.pieces[id].captured = true
			stuck.pieces[id].position = null
	stuck.pieces["red-2"].position = [0, 3]
	var pass_set := card_set.duplicate(true)
	pass_set.cards["surreal.arc"].moves.assign([Vector2i(1, 0)])
	pass_set.cards["surreal.hinge"].moves.assign([Vector2i(2, 0)])
	check(Rules.legal_moves(stuck, pass_set).is_empty(), "no movement with either card")
	var passed: Dictionary = Resolver.apply(stuck, pass_set, Command.forced_pass("red", "surreal.arc", 0)).state
	check(passed.pieces == stuck.pieces and passed.shared == "surreal.arc" and passed.current_player == "blue" and passed.version == 1, "forced pass exchanges and advances")
	check(passed.history[0].origin == null and passed.history[0].destination == null, "pass history")
	state.pieces["red-2"].position = [2, 3]
	var win: Dictionary = Resolver.apply(state, card_set, Command.move("red", "red-2", "surreal.arc", [2, 4], 0)).state
	check(win.winner == "red" and win.victory_reason == "teacher_capture" and win.pieces["blue-2"].captured, "Teacher capture takes precedence")
	check(win.history[0].captured_piece == "blue-2" and win.shared == "surreal.arc" and Rules.legal_moves(win, card_set).is_empty(), "terminal exchange and history")
	check(Resolver.apply(win, card_set, move).has("error"), "terminal command rejected")
	state.pieces["blue-2"].position = [1, 3]
	win = Resolver.apply(state, card_set, Command.move("red", "red-2", "surreal.arc", [2, 4], 0)).state
	check(win.victory_reason == "opposing_temple", "Teacher on opposing temple")
	state.pieces["red-2"].position = [3, 3]
	state.pieces["red-1"].position = [2, 3]
	next = Resolver.apply(state, card_set, Command.move("red", "red-1", "surreal.arc", [2, 4], 0)).state
	check(next.status == "active", "Disciple on opposing temple")
	state.pieces["blue-0"].position = [2, 4]
	next = Resolver.apply(state, card_set, Command.move("red", "red-1", "surreal.arc", [2, 4], 0)).state
	check(next.status == "active" and next.pieces["blue-0"].captured and next.pieces["blue-0"].position == null, "ordinary capture")


func test_simulations(card_set: Dictionary) -> void:
	var completed := 0
	var total_turns := 0
	var max_turns := 0
	for seed_value in range(100):
		var state: Dictionary = State.setup(card_set, seed_value).state
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value + 10000
		for turn in range(500):
			var moves := Rules.legal_moves(state, card_set)
			var player: String = state.current_player
			var command: Dictionary
			if moves.is_empty():
				command = Command.forced_pass(player, state.hands[player][0], state.version)
			else:
				command = moves[rng.randi_range(0, moves.size() - 1)]
			var result := Resolver.apply(state, card_set, command)
			check(result.has("state"), "generated command is accepted")
			if result.has("error"):
				break
			state = result.state
			var active: Array = state.hands.red + state.hands.blue + [state.shared]
			active.sort()
			var dealt: Array = state.deal.duplicate()
			dealt.sort()
			check(active == dealt and state.hands.red.size() == 2 and state.hands.blue.size() == 2, "five-card ownership invariant")
			check(state.version == turn + 1 and state.version == state.history.size(), "one event per version")
			var occupied := {}
			var valid_positions := true
			for piece in state.pieces.values():
				if piece.captured:
					valid_positions = valid_positions and piece.position == null
				else:
					var square := Vector2i(piece.position[0], piece.position[1])
					valid_positions = valid_positions and Rect2i(0, 0, 5, 5).has_point(square) and not occupied.has(square)
					occupied[square] = true
			check(valid_positions, "unique on-board live positions")
			if turn == 4 or state.status == "won":
				var restored := Serializer.decode(Serializer.encode(state), card_set)
				check(restored.get("state") == state, "snapshot and history round-trip")
				if restored.has("state"):
					check(Rules.legal_moves(restored.state, card_set) == Rules.legal_moves(state, card_set), "restored legal moves")
			if state.status == "won":
				completed += 1
				break
		total_turns += state.version
		max_turns = maxi(max_turns, state.version)
	check(completed == 100, "all seeded matches resolved within the test bound")
	print("Simulation: %d/100 completed, %d total turns, longest %d" % [completed, total_turns, max_turns])
	var state: Dictionary = State.setup(card_set, 1).state
	check(Serializer.decode("{", card_set).has("error"), "malformed snapshot rejected")
	state.version = 1
	check(Serializer.decode(Serializer.encode(state), card_set).has("error"), "tampered snapshot rejected")
	state.card_set_version = "2.0.0"
	check(Serializer.decode(Serializer.encode(state), card_set).has("error"), "incompatible card-set version rejected")
