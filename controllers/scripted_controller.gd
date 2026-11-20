extends "res://controllers/player_controller.gd"

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	_rng.seed = seed_value


func request_turn(request: Dictionary, propose: Callable) -> void:
	var options: Array = request.options
	propose.call(options[_rng.randi_range(0, options.size() - 1)])
