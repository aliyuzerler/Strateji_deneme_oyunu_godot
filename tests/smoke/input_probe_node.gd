extends Node
## Girdi tesih yardimcisi: ulasan unhandled input olaylarini sayar.

var received_count := 0
var last_types: Array[String] = []


func _unhandled_input(event: InputEvent) -> void:
	received_count += 1
	if last_types.size() < 12:
		last_types.append(event.get_class())
