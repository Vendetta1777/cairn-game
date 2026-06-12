extends Node
## Cairn — PlayerProgress (autoload). The single source of truth for everything
## that PERSISTS across deaths, scene changes, and save files: hard currency
## (Shards), soft currency (Echoes), the unlocked skill nodes, movement
## abilities, permanent heart upgrades, current health, the last checkpoint,
## and story flags. The player's in-run PlayerStats syncs to this on spawn and
## writes back to it, so a death or a trip to the Sanctum never loses progress.
## SaveManager serialises this whole object.
##
## FLAG NAMING CONVENTIONS (all world state lives in `flags`):
##   boss_<id>_dead     — boss kills        (e.g. boss_ashen_warden_dead)
##   cache_<id>         — collected caches  (e.g. cache_a1_loft)
##   used_<id>          — spent heart-shrines
##   seen_<id>          — discovered areas  (world-map fog of war)
##   etched_<id>        — areas already etched onto the map tablet
##   area_<id>_done     — completed descents
## Doors (SealedGates) derive openness from their boss flag — no separate door
## state to drift out of sync.

signal currency_changed(shards: int, echoes: int)
signal node_unlocked(id: String)
signal ability_unlocked(id: String)
signal progress_loaded

# Preloaded rather than referenced by class_name: an autoload parses before global
# class names are guaranteed registered, so the const reference is reliable.
const Skills = preload("res://scenes/systems/SkillTreeData.gd")

const BASE_HEARTS := 3    ## start fragile
const MAX_HEARTS := 5     ## hard cap — hearts are precious

## Every boss in the game (including ones not built yet) — written into the
## save as an explicit ledger so a glance at the JSON answers "what's dead".
const KNOWN_BOSSES := ["mother_bat", "ashen_warden", "drowned_choir"]

var shards: int = 0
var echoes: int = 0
var bonus_half_hearts: int = 0     ## permanent HALF-heart upgrades, from heart-shrines only
var unlocked: Dictionary = {}      ## node_id -> true
var abilities: Dictionary = {}     ## movement abilities: "dash" / "wall_jump" / "double_jump"
var flags: Dictionary = {}         ## story / world flags (see conventions above)
var furthest_area: String = "hollowed_gate"
var health_halves: int = -1        ## current health in half-hearts; -1 = full
var last_checkpoint: Dictionary = {}  ## {"area": id, "x": float, "y": float}
var items: Dictionary = {}         ## item_id -> count (ring inventory; 4 kinds max)
var ng_plus: int = 0               ## New Game+ cycle (enemies +40% health each)
var achievements: Dictionary = {}  ## achievement_id -> true


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


## Max health in HALF-heart units = base + heart-shrine half-hearts, capped at
## MAX_HEARTS. Hearts come ONLY from heart-shrines (every 5 levels, +½ each).
func max_half_hearts() -> int:
	return clampi(BASE_HEARTS * 2 + bonus_half_hearts, BASE_HEARTS * 2, MAX_HEARTS * 2)


func max_hearts() -> int:
	return max_half_hearts() / 2


## A heart-shrine grants +½ a heart, permanently (up to the cap). Returns true if
## it actually raised the max.
func grant_half_heart() -> bool:
	if max_half_hearts() >= MAX_HEARTS * 2:
		return false
	bonus_half_hearts += 1
	return true


# --- movement abilities (metroidvania unlocks) --------------------------------

func has_ability(id: String) -> bool:
	return abilities.get(id, false)


## An Ability Relic grants a movement power permanently. The live player listens
## to ability_unlocked so the power works the moment it's claimed.
func grant_ability(id: String) -> void:
	if has_ability(id):
		return
	abilities[id] = true
	ability_unlocked.emit(id)


# --- items ---------------------------------------------------------------------

## Add one of an item. Fails (false) if it would exceed the 4-kind ring.
func add_item(id: String) -> bool:
	if not items.has(id) and items.size() >= 4:
		return false
	items[id] = int(items.get(id, 0)) + 1
	return true


func use_item(id: String) -> bool:
	if int(items.get(id, 0)) <= 0:
		return false
	items[id] = int(items[id]) - 1
	if items[id] <= 0:
		items.erase(id)
	return true


func item_count(id: String) -> int:
	return int(items.get(id, 0))


# --- New Game+ -----------------------------------------------------------------

## Begin the next cycle: abilities, skills, hearts, shards and items are KEPT;
## the world itself is reborn — bosses alive, caches refilled, doors sealed.
func start_ng_plus() -> void:
	ng_plus += 1
	var kept := {}
	for f in flags:
		# Keep meta flags (endings seen, achievements live separately, map
		# discovery); drop world-state flags so the deep resets.
		if String(f).begins_with("seen_") or String(f).begins_with("ending_") \
				or f == "game_beaten":
			kept[f] = flags[f]
	flags = kept
	health_halves = -1
	last_checkpoint = {}
	echoes = 0
	furthest_area = "hollowed_gate"


# --- flags -------------------------------------------------------------------

func set_flag(flag: String, value: bool = true) -> void:
	flags[flag] = value


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


func boss_defeated(boss_id: String) -> bool:
	return has_flag("boss_%s_dead" % boss_id)


# --- serialisation -----------------------------------------------------------

func to_dict() -> Dictionary:
	# Explicit per-boss ledger (every boss, even unbuilt) for save-file clarity.
	var bosses := {}
	for id in KNOWN_BOSSES:
		bosses[id] = boss_defeated(id)
	return {
		"shards": shards,
		"echoes": echoes,
		"bonus_half_hearts": bonus_half_hearts,
		"health": health_halves,
		"unlocked": unlocked.keys(),
		"abilities": abilities.keys(),
		"bosses": bosses,
		"flags": flags,
		"furthest_area": furthest_area,
		"last_checkpoint": last_checkpoint,
		"items": items,
		"ng_plus": ng_plus,
		"achievements": achievements.keys(),
	}


func from_dict(d: Dictionary) -> void:
	shards = int(d.get("shards", 0))
	echoes = int(d.get("echoes", 0))
	bonus_half_hearts = int(d.get("bonus_half_hearts", 0))
	unlocked = {}
	for id in d.get("unlocked", []):
		unlocked[id] = true
	abilities = {}
	for id in d.get("abilities", []):
		abilities[id] = true
	flags = d.get("flags", {})
	# The boss ledger is also accepted on load (forward compat / hand edits).
	var bosses: Dictionary = d.get("bosses", {})
	for id in bosses:
		if bosses[id]:
			flags["boss_%s_dead" % id] = true
	health_halves = int(d.get("health", -1))
	last_checkpoint = d.get("last_checkpoint", {})
	items = {}
	var _it: Dictionary = d.get("items", {})
	for id in _it:
		items[id] = int(_it[id])
	ng_plus = int(d.get("ng_plus", 0))
	achievements = {}
	for id in d.get("achievements", []):
		achievements[id] = true
	furthest_area = d.get("furthest_area", "hollowed_gate")
	currency_changed.emit(shards, echoes)
	progress_loaded.emit()


func reset() -> void:
	shards = 0
	echoes = 0
	bonus_half_hearts = 0
	unlocked = {}
	abilities = {}
	flags = {}
	health_halves = -1
	last_checkpoint = {}
	items = {}
	ng_plus = 0
	achievements = {}
	furthest_area = "hollowed_gate"
	currency_changed.emit(shards, echoes)
