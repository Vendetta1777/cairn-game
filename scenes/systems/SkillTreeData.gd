extends RefCounted
class_name SkillTreeData
## Cairn — the permanent skill tree (GDD Section 9): 30 nodes across 3 branches of
## 10 — BLADE (offense), SHADOW (sorcery/utility), BODY (survival/movement).
## Bought with Shards (kept on death), each branch is a linear chain: a node needs
## the one above it. Effects are additive bonuses summed by PlayerProgress and
## applied to the player on spawn, so they persist across runs and saves.

const BRANCHES := ["blade", "shadow", "body"]

const BRANCH_NAME := {
	"blade": "BLADE",
	"shadow": "SHADOW",
	"body": "BODY",
}
const BRANCH_COLOR := {
	"blade": Color(0.85, 0.32, 0.32),
	"shadow": Color(0.55, 0.5, 0.95),
	"body": Color(0.4, 0.78, 0.6),
}

## Each node: id, branch, tier (0..9 down the column), name, desc, cost (Shards),
## and effect = additive bonuses keyed by stat. tier N requires tier N-1 of the
## same branch.
const NODES := [
	# --- BLADE: damage, daggers, parry, finishers --------------------------
	{"id": "blade_0", "branch": "blade", "tier": 0, "name": "Honed Edge", "cost": 4, "desc": "+1 melee damage", "effect": {"damage": 1}},
	{"id": "blade_1", "branch": "blade", "tier": 1, "name": "Quick Draw", "cost": 5, "desc": "+1 dagger charge", "effect": {"dagger_charges": 1}},
	{"id": "blade_2", "branch": "blade", "tier": 2, "name": "Riposte", "cost": 6, "desc": "Wider parry window", "effect": {"parry_window": 0.04}},
	{"id": "blade_3", "branch": "blade", "tier": 3, "name": "Deep Cuts", "cost": 8, "desc": "+1 melee damage", "effect": {"damage": 1}},
	{"id": "blade_4", "branch": "blade", "tier": 4, "name": "Twin Fangs", "cost": 9, "desc": "+1 dagger charge", "effect": {"dagger_charges": 1}},
	{"id": "blade_5", "branch": "blade", "tier": 5, "name": "Bladedancer", "cost": 11, "desc": "Wider parry window", "effect": {"parry_window": 0.04}},
	{"id": "blade_6", "branch": "blade", "tier": 6, "name": "Executioner", "cost": 13, "desc": "+1 finisher damage", "effect": {"finisher_damage": 1}},
	{"id": "blade_7", "branch": "blade", "tier": 7, "name": "Whetstone", "cost": 15, "desc": "+1 melee damage", "effect": {"damage": 1}},
	{"id": "blade_8", "branch": "blade", "tier": 8, "name": "Hailstorm", "cost": 18, "desc": "+1 dagger charge", "effect": {"dagger_charges": 1}},
	{"id": "blade_9", "branch": "blade", "tier": 9, "name": "Severance", "cost": 22, "desc": "+1 finisher damage", "effect": {"finisher_damage": 1, "damage": 1}},
	# --- SHADOW: shadow energy, regen, bolt --------------------------------
	{"id": "shadow_0", "branch": "shadow", "tier": 0, "name": "Inner Well", "cost": 4, "desc": "+10 max shadow", "effect": {"max_shadow": 10}},
	{"id": "shadow_1", "branch": "shadow", "tier": 1, "name": "Drip Feed", "cost": 5, "desc": "Shadow slowly regenerates", "effect": {"shadow_regen": 2.0}},
	{"id": "shadow_2", "branch": "shadow", "tier": 2, "name": "Dark Channel", "cost": 6, "desc": "+10 max shadow", "effect": {"max_shadow": 10}},
	{"id": "shadow_3", "branch": "shadow", "tier": 3, "name": "Cheaper Bolt", "cost": 8, "desc": "Shadow bolt costs 5 less", "effect": {"bolt_discount": 5}},
	{"id": "shadow_4", "branch": "shadow", "tier": 4, "name": "Deep Well", "cost": 9, "desc": "+15 max shadow", "effect": {"max_shadow": 15}},
	{"id": "shadow_5", "branch": "shadow", "tier": 5, "name": "Steady Flow", "cost": 11, "desc": "Faster shadow regen", "effect": {"shadow_regen": 2.0}},
	{"id": "shadow_6", "branch": "shadow", "tier": 6, "name": "Piercing Dark", "cost": 13, "desc": "Bolt pierces +1 enemy", "effect": {"bolt_pierce": 1}},
	{"id": "shadow_7", "branch": "shadow", "tier": 7, "name": "Abyssal Reserve", "cost": 15, "desc": "+15 max shadow", "effect": {"max_shadow": 15}},
	{"id": "shadow_8", "branch": "shadow", "tier": 8, "name": "Cheaper Still", "cost": 18, "desc": "Shadow bolt costs 5 less", "effect": {"bolt_discount": 5}},
	{"id": "shadow_9", "branch": "shadow", "tier": 9, "name": "Voidheart", "cost": 22, "desc": "+20 max shadow, bolt pierces +1", "effect": {"max_shadow": 20, "bolt_pierce": 1}},
	# --- BODY: speed, resilience, the rare precious heart -------------------
	{"id": "body_0", "branch": "body", "tier": 0, "name": "Fleetfoot", "cost": 4, "desc": "+15 run speed", "effect": {"run_speed": 15}},
	{"id": "body_1", "branch": "body", "tier": 1, "name": "Second Wind", "cost": 6, "desc": "Longer dash i-frames", "effect": {"dash_iframes": 0.04}},
	{"id": "body_2", "branch": "body", "tier": 2, "name": "Toughened", "cost": 12, "desc": "+1 heart (max 5)", "effect": {"hearts": 1}},
	{"id": "body_3", "branch": "body", "tier": 3, "name": "Swift", "cost": 8, "desc": "+15 run speed", "effect": {"run_speed": 15}},
	{"id": "body_4", "branch": "body", "tier": 4, "name": "Phantom Step", "cost": 10, "desc": "Longer dash i-frames", "effect": {"dash_iframes": 0.04}},
	{"id": "body_5", "branch": "body", "tier": 5, "name": "Windrunner", "cost": 13, "desc": "+20 run speed", "effect": {"run_speed": 20}},
	{"id": "body_6", "branch": "body", "tier": 6, "name": "Sure-Footed", "cost": 15, "desc": "Longer dash i-frames", "effect": {"dash_iframes": 0.05}},
	{"id": "body_7", "branch": "body", "tier": 7, "name": "Hardened", "cost": 20, "desc": "+1 heart (max 5)", "effect": {"hearts": 1}},
	{"id": "body_8", "branch": "body", "tier": 8, "name": "Tireless", "cost": 24, "desc": "+25 run speed", "effect": {"run_speed": 25}},
	{"id": "body_9", "branch": "body", "tier": 9, "name": "Cairn-Forged", "cost": 30, "desc": "+1 heart (max 5)", "effect": {"hearts": 1}},
]


static func by_id(id: String) -> Dictionary:
	for n in NODES:
		if n.id == id:
			return n
	return {}


static func in_branch(branch: String) -> Array:
	var out: Array = []
	for n in NODES:
		if n.branch == branch:
			out.append(n)
	out.sort_custom(func(a, b): return a.tier < b.tier)
	return out


## The prerequisite node id for a node (the tier above it in the same branch),
## or "" for tier-0 roots.
static func prereq_of(node: Dictionary) -> String:
	if node.tier == 0:
		return ""
	return "%s_%d" % [node.branch, node.tier - 1]
