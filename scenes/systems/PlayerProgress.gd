extends Node
## Cairn — PlayerProgress (autoload). The single source of truth for everything
## that PERSISTS across deaths, scene changes, and save files: hard currency
## (Shards), soft currency (Echoes), the unlocked skill nodes, permanent heart
## upgrades, and story flags. The player's in-run PlayerStats syncs to this on
## spawn and writes back to it, so a death or a trip to the Sanctum never loses
## progress. SaveManager serialises this whole object.

signal currency_changed(shards: int, echoes: int)
signal node_unlocked(id: String)
signal progress_loaded

# Preloaded rather than referenced by class_name: an autoload parses before global
# class names are guaranteed registered, so the const reference is reliable.
const Skills = preload("res://scenes/systems/SkillTreeData.gd")

const BASE_HEARTS := 4

var shards: int = 0
var echoes: int = 0
var bonus_hearts: int = 0          ## permanent heart upgrades (Keeper / Body tree adds on top)
var unlocked: Dictionary = {}      ## node_id -> true
var flags: Dictionary = {}         ## story / world flags
var furthest_area: String = "hollowed_gate"


# --- currency ----------------------------------------------------------------

func add_shards(n: int) -> void:
	shards += n
	currency_changed.emit(shards, echoes)


func spend_shards(n: int) -> bool:
	if shards < n:
		return false
	shards -= n
	currency_changed.emit(shards, echoes)
	return true


func add_echoes(n: int) -> void:
	echoes += n
	currency_changed.emit(shards, echoes)


## Roguelite death: Echoes are dropped (lost). Returns how many were lost.
func drop_echoes() -> int:
	var lost := echoes
	echoes = 0
	currency_changed.emit(shards, echoes)
	return lost


# --- skill tree --------------------------------------------------------------

func is_unlocked(id: String) -> bool:
	return unlocked.get(id, false)


## Can this node be bought right now? (exists, not owned, prereq met, affordable)
func can_unlock(id: String) -> bool:
	var node := Skills.by_id(id)
	if node.is_empty() or is_unlocked(id):
		return false
	var pre := Skills.prereq_of(node)
	if pre != "" and not is_unlocked(pre):
		return false
	return shards >= int(node.cost)


func unlock(id: String) -> bool:
	if not can_unlock(id):
		return false
	var node := Skills.by_id(id)
	if not spend_shards(int(node.cost)):
		return false
	unlocked[id] = true
	node_unlocked.emit(id)
	return true


## Sum of one effect key across every unlocked node.
func bonus(key: String) -> float:
	var total := 0.0
	for id in unlocked:
		var node := Skills.by_id(id)
		if node.is_empty():
			continue
		var eff: Dictionary = node.get("effect", {})
		if eff.has(key):
			total += float(eff[key])
	return total


## Final max hearts = base + Keeper upgrades + Body-tree "hearts" nodes.
func max_hearts() -> int:
	return BASE_HEARTS + bonus_hearts + int(bonus("hearts"))


# --- flags -------------------------------------------------------------------

func set_flag(flag: String, value: bool = true) -> void:
	flags[flag] = value


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


# --- serialisation -----------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"shards": shards,
		"echoes": echoes,
		"bonus_hearts": bonus_hearts,
		"unlocked": unlocked.keys(),
		"flags": flags,
		"furthest_area": furthest_area,
	}


func from_dict(d: Dictionary) -> void:
	shards = int(d.get("shards", 0))
	echoes = int(d.get("echoes", 0))
	bonus_hearts = int(d.get("bonus_hearts", 0))
	unlocked = {}
	for id in d.get("unlocked", []):
		unlocked[id] = true
	flags = d.get("flags", {})
	furthest_area = d.get("furthest_area", "hollowed_gate")
	currency_changed.emit(shards, echoes)
	progress_loaded.emit()


func reset() -> void:
	shards = 0
	echoes = 0
	bonus_hearts = 0
	unlocked = {}
	flags = {}
	furthest_area = "hollowed_gate"
	currency_changed.emit(shards, echoes)
