extends Node2D
## Cairn — Area 1 root. Seeds the opening objective when the Hollowed Gate loads,
## kicking off the quest flow that the triggers, boss, and gate carry forward.

func _ready() -> void:
	QuestTracker.begin_area("Explore the Hollowed Gate")
