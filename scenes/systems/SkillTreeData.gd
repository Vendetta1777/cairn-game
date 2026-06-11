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
	{"id": "blade_0", "branch": "blade", "tier": 0, "name": "Honed Edge", "cost": 1, "desc": "+1 melee damage", "effect": {"damage": 1}},
	{"id": "blade_1", "branch": "blade", "tier": 1, "name": "Quick Draw", "cost": 1, "desc": "+1 dagger charge", "effect": {"dagger_charges": 1}},
	{"id": "blade_2", "branch": "blade", "tier": 2, "name": "Riposte", "cost": 2, "desc": "Wider parry window", "effect": {"parry_window": 0.05}},
	{"id": "blade_3", "branch": "blade", "tier": 3, "name": "Deep Cuts", "cost": 2, "desc": "+1 melee damage", "effect": {"damage": 1}},
	{"id": "blade_4", "branch": "blade", "tier": 4, "name": "Twin Fangs", "cost": 3, "desc": "+1 dagger charge", "effect": {"dagger_charges": 1}},
	{"id": "blade_5", "branch": "blade", "tier": 5, "name": "Bladedancer", "cost": 3, "desc": "Wider parry window", "effect": {"parry_window": 0.05}},
	{"id": "blade_6", "branch": "blade", "tier": 6, "name": "Executioner", "cost": 4, "desc": "+1 finisher damage", "effect": {"finisher_damage": 1}},
	{"id": "blade_7", "branch": "blade", "tier": 7, "name": "Whetstone", "cost": 4, "desc": "+1 melee damage", "effect": {"damage": 1}},
	{"id": "blade_8", "branch": "blade", "tier": 8, "name": "Hailstorm", "cost": 5, "desc": "+1 dagger charge", "effect": {"dagger_charges": 1}},
	{"id": "blade_9", "branch": "blade", "tier": 9, "name": "Severance", "cost": 6, "desc": "+1 finisher damage", "effect": {"finisher_damage": 1, "damage": 1}},
	# --- SHADOW: shadow energy, regen, bolt --------------------------------
	{"id": "shadow_0", "branch": "shadow", "tier": 0, "name": "Inner Well", "cost": 1, "desc": "+10 max shadow", "effect": {"max_shadow": 10}},
	{"id": "shadow_1", "branch": "shadow", "tier": 1, "name": "Drip Feed", "cost": 1, "desc": "Shadow slowly regenerates", "effect": {"shadow_regen": 2.0}},
	{"id": "shadow_2", "branch": "shadow", "tier": 2, "name": "Dark Channel", "cost": 2, "desc": "+10 max shadow", "effect": {"max_shadow": 10}},
	{"id": "shadow_3", "branch": "shadow", "tier": 3, "name": "Cheaper Bolt", "cost": 2, "desc": "Shadow bolt costs 5 less", "effect": {"bolt_discount": 5}},
	{"id": "shadow_4", "branch": "shadow", "tier": 4, "name": "Deep Well", "cost": 3, "desc": "+15 max shadow", "effect": {"max_shadow": 15}},
	{"id": "shadow_5", "branch": "shadow", "tier": 5, "name": "Steady Flow", "cost": 3, "desc": "Faster shadow regen", "effect": {"shadow_regen": 2.0}},
	{"id": "shadow_6", "branch": "shadow", "tier": 6, "name": "Piercing Dark", "cost": 4, "desc": "Bolt pierces +1 enemy", "effect": {"bolt_pierce": 1}},
	{"id": "shadow_7", "branch": "shadow", "tier": 7, "name": "Abyssal Reserve", "cost": 4, "desc": "+15 max shadow", "effect": {"max_shadow": 15}},
	{"id": "shadow_8", "branch": "shadow", "tier": 8, "name": "Cheaper Still", "cost": 5, "desc": "Shadow bolt costs 5 less", "effect": {"bolt_discount": 5}},
	{"id": "shadow_9", "branch": "shadow", "tier": 9, "name": "Voidheart", "cost": 6, "desc": "+20 max shadow, bolt pierces +1", "effect": {"max_shadow": 20, "bolt_pierce": 1}},
	# --- BODY: health, speed, resilience -----------------------------------
	{"id": "body_0", "branch": "body", "tier": 0, "name": "Toughened", "cost": 1, "desc": "+1 heart", "effect": {"hearts": 1}},
	{"id": "body_1", "branch": "body", "tier": 1, "name": "Fleetfoot", "cost": 1, "desc": "+15 run speed", "effect": {"run_speed": 15}},
	{"id": "body_2", "branch": "body", "tier": 2, "name": "Second Wind", "cost": 2, "desc": "Longer dash i-frames", "effect": {"dash_iframes": 0.04}},
	{"id": "body_3", "branch": "body", "tier": 3, "name": "Hardened", "cost": 2, "desc": "+1 heart", "effect": {"hearts": 1}},
	{"id": "body_4", "branch": "body", "tier": 4, "name": "Swift", "cost": 3, "desc": "+15 run speed", "effect": {"run_speed": 15}},
	{"id": "body_5", "branch": "body", "tier": 5, "name": "Ironhide", "cost": 3, "desc": "+1 heart", "effect": {"hearts": 1}},
	{"id": "body_6", "branch": "body", "tier": 6, "name": "Phantom Step", "cost": 4, "desc": "Longer dash i-frames", "effect": {"dash_iframes": 0.04}},
	{"id": "body_7", "branch": "body", "tier": 7, "name": "Unbroken", "cost": 4, "desc": "+1 heart", "effect": {"hearts": 1}},
	{"id": "body_8", "branch": "body", "tier": 8, "name": "Windrunner", "cost": 5, "desc": "+20 run speed", "effect": {"run_speed": 20}},
	{"id": "body_9", "branch": "body", "tier": 9, "name": "Cairn-Forged", "cost": 6, "desc": "+2 hearts", "effect": {"hearts": 2}},
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
