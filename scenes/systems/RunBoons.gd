extends RefCounted
## Cairn — the pool of run-only boons (GDD Section 9: "Shrines — 3 random run-only
## boons"). Unlike skill nodes these are NOT permanent: they're applied live to
## the current run and vanish when you die or rest (a fresh player simply spawns
## without them). Effects reuse the same stat keys the player already knows how
## to apply.

const POOL := [
	{"name": "Razor Edge", "desc": "+1 melee damage this run", "effect": {"damage": 1}},
	{"name": "Quickblood", "desc": "+30 run speed this run", "effect": {"run_speed": 30}},
	{"name": "Steel Nerve", "desc": "Much wider parry window", "effect": {"parry_window": 0.06}},
	{"name": "Dark Surge", "desc": "+20 max shadow this run", "effect": {"max_shadow": 20}},
	{"name": "Bloodlust", "desc": "+2 melee damage, fragile gift", "effect": {"damage": 2}},
	{"name": "Stillblade", "desc": "+15 speed and a wider parry", "effect": {"run_speed": 15, "parry_window": 0.03}},
]


## Three distinct random boons to offer at a shrine.
static func roll_three() -> Array:
	var idx := range(POOL.size())
	idx.shuffle()
	var out: Array = []
	for i in range(min(3, idx.size())):
		out.append(POOL[idx[i]])
	return out
