# CPRegenerator.gd

extends Node

class CPEntry:
	var target
	var max_cp
	var current_cp
	var regen_rate
	var regen_delay
	var delay_timer := 0.0
	var is_regenerating := false
	var on_cp_changed: Callable

var entries: Array[CPEntry] = []


func _process(delta):
	for entry in entries:
		if entry.current_cp < entry.max_cp:
			if not entry.is_regenerating:
				entry.delay_timer -= delta
				if entry.delay_timer <= 0:
					entry.is_regenerating = true
			else:
				entry.current_cp += entry.regen_rate * delta
				if entry.current_cp > entry.max_cp:
					entry.current_cp = entry.max_cp

				entry.on_cp_changed.call_deferred(entry.current_cp)


func register(target: Node, max_cp: float, current_cp: float, regen_rate: float, regen_delay: float, on_cp_changed: Callable):
	var entry := CPEntry.new()
	entry.target = target
	entry.max_cp = max_cp
	entry.current_cp = current_cp
	entry.regen_rate = regen_rate
	entry.regen_delay = regen_delay
	entry.delay_timer = regen_delay
	entry.on_cp_changed = on_cp_changed
	entries.append(entry)


func unregister(target: Node):
	entries = entries.filter(func(e): return e.target != target)


func reset_regen_delay(target: Node, delay: float):
	for entry in entries:
		if entry.target == target:
			entry.delay_timer = delay
			entry.is_regenerating = false
			break


func update_current_cp(target: Node, value: float):
	for entry in entries:
		if entry.target == target:
			entry.current_cp = value
			break


func is_registered(target: Node) -> bool:
	for entry in entries:
		if entry.target == target:
			return true
	return false
