extends Area2D
## Cairn — a one-shot story/objective trigger. When the player crosses it, it can
## set a new objective line and (optionally) engage a boss + reveal its health
## bar. This is the glue that turns walking right into authored "steps".

@export_multiline var objective: String = ""
@export var engage_boss_path: NodePath
@export var boss_display_name: String = "THE HOLLOW WARDEN"
@export var one_shot: bool = true

var _fired := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2     # the player's Hurtbox
	monitoring = true
	area_entered.connect(_on_area)


func _on_area(area: Area2D) -> void:
	if _fired and one_shot:
		return
	var body := area.get_parent()
	if not (body and body.is_in_group("player")):
		return
	_fired = true
	if objective != "":
		QuestTracker.set_objective(objective)
	if engage_boss_path != NodePath():
		var boss := get_node_or_null(engage_boss_path)
		if boss:
			# Wire the on-screen boss bar first, so it catches the engage signal.
			for bar in get_tree().get_nodes_in_group("boss_bar"):
				if bar.has_method("bind"):
					bar.bind(boss, boss_display_name)
			if "boss_id" in boss:
				GameManager.note_boss_engaged(boss.boss_id)
			if boss.has_method("engage"):
				boss.engage()
