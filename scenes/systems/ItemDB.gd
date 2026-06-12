extends RefCounted
class_name ItemDB
## Cairn — the usable-item catalogue. Single-use tools bought from the Vestibule
## merchant, traded from the Digger, or found in the world. The ring inventory
## (hold I) holds at most MAX_SLOTS distinct kinds. Effects live in
## PlayerItems.gd; this is pure data.

const MAX_SLOTS := 4

const DB := {
	"ichor": {
		"name": "Vial of Dark Ichor", "cost": 10, "tint": Color(0.7, 0.15, 0.2),
		"desc": "Drink. Restores one heart.",
	},
	"smoke": {
		"name": "Smoke Bomb", "cost": 8, "tint": Color(0.55, 0.58, 0.65),
		"desc": "A breath of the deep dark. Brief invincibility; staggers everything near.",
	},
	"prism": {
		"name": "Soul Prism", "cost": 8, "tint": Color(0.5, 0.8, 0.95),
		"desc": "Shadow energy, crystallised. Fills the soul meter.",
	},
	"charm": {
		"name": "Bone Charm", "cost": 25, "tint": Color(0.9, 0.88, 0.8),
		"desc": "Someone else's luck. Cancels your next death. Consumed.",
	},
	"shatter": {
		"name": "Shatter Shard", "cost": 12, "tint": Color(0.95, 0.6, 0.3),
		"desc": "Unstable vein-glass. Detonates around you — heavy damage, staggers.",
	},
	"lantern": {
		"name": "Pale Lantern", "cost": 10, "tint": Color(0.95, 0.9, 0.6),
		"desc": "Burns what the dark hides. Reveals caches, gates and ways for 30s.",
	},
	"flask": {
		"name": "Ashen Flask", "cost": 12, "tint": Color(1.0, 0.5, 0.2),
		"desc": "Furnace-draught. Your dash leaves burning ash for 10s.",
	},
	"echo": {
		"name": "Echo Stone", "cost": 15, "tint": Color(0.6, 0.55, 0.95),
		"desc": "Crack it: you were somewhere else two seconds ago. Be there again.",
	},
}


static func get_item(id: String) -> Dictionary:
	return DB.get(id, {})
