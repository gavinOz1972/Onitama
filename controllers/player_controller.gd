extends RefCounted

## request contains player, request_id, state, card_set, and allowed command options.
## Call propose with a WP1.2 command now or later. The result contains event or error.
func request_turn(_request: Dictionary, _propose: Callable) -> void:
	pass


## The session closes the proposal callback before notifying the controller.
func cancel_turn() -> void:
	pass
