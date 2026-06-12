extends RefCounted
class_name CharmDB
## Cairn — the charm catalogue: twenty carved tokens that reshape a build.
## Equip and unequip ONLY at a lit Remnant Stone (press E to attune). Slots:
## three notches to start; Notch Stones found in the world add more (cap 6).
## `effect` keys are aggregated by PlayerProgress.charm_bonus() and read by the
## player's components on spawn. Synergies live in PlayerProgress too.

const DB := {
	# --- blade -------------------------------------------------------------
	"long_nail": {
		"name": "Long Nail", "slots": 1, "effect": {"range_mult": 0.4},
		"lore": "An unusually long fighting nail, honed to a perfect edge. Whoever carried it before you had long arms, or very short patience.",
	},
	"quick_slash": {
		"name": "Quick Slash", "slots": 1, "effect": {"atk_speed": 0.35, "damage_mult": -0.15},
		"lore": "A sliver of the forge's last quench. The blade remembers being faster than thought, and resents the hand that slows it.",
	},
	"mark_of_pride": {
		"name": "Mark of Pride", "slots": 2, "effect": {"range_mult": 0.55},
		"lore": "Worn by the Warden's smiths, who never once stepped back from the heat. Reach like this is not given. It is insisted upon.",
	},
	"fragile_strength": {
		"name": "Fragile Strength", "slots": 1, "effect": {"damage_mult": 0.45}, "fragile": true,
		"lore": "Strength borrowed against a debt you will not enjoy paying. It shatters the moment death touches you.",
	},
	"stalwart_shell": {
		"name": "Stalwart Shell", "slots": 1, "effect": {"iframes": 0.4},
		"lore": "A plate of mineshell, polished by three hundred years of falling rock. It does not stop the blow. It buys you the moment after.",
	},
	# --- soul --------------------------------------------------------------
	"soul_catcher": {
		"name": "Soul Catcher", "slots": 1, "effect": {"soul_gain": 0.2},
		"lore": "A reliquary that drinks what the dying let go. The archivists wore them to funerals, which the kingdom held daily.",
	},
	"soul_eater": {
		"name": "Soul Eater", "slots": 2, "effect": {"soul_gain": 0.4},
		"lore": "The reliquary's elder sibling, fed too well for too long. It no longer waits politely for the dying to finish.",
	},
	"shaman_stone": {
		"name": "Shaman Stone", "slots": 1, "effect": {"bolt_damage": 1, "bolt_size": 0.2},
		"lore": "A river-stone with a hole worn through its heart. Look through it and the dark looks back, slightly larger.",
	},
	"spell_twister": {
		"name": "Spell Twister", "slots": 1, "effect": {"bolt_cost_mult": -0.25},
		"lore": "Braided wick from the Nave's drowned candles. The faithful learned to pray cheaper as the water rose.",
	},
	# --- defense -----------------------------------------------------------
	"jonis_blessing": {
		"name": "Joni's Blessing", "slots": 2, "effect": {"hp_mult": 0.4, "heal_mult": -0.5},
		"lore": "A blue benediction from a saint the kingdom drowned. More life, freely given — but mending it is another matter.",
	},
	"hiveblood": {
		"name": "Hiveblood", "slots": 2, "effect": {"regen": 1.0},
		"lore": "Amber from something that refused, on principle, to stop living. Wounds close on their own, if you let them be.",
	},
	"quick_focus": {
		"name": "Quick Focus", "slots": 1, "effect": {"shadow_regen": 2.0},
		"lore": "A meditation bead rubbed smooth by a very frightened monk. The soul gathers faster when it has somewhere to hide.",
	},
	"deep_focus": {
		"name": "Deep Focus", "slots": 2, "effect": {"heal_bonus": 1},
		"lore": "Carved from the bell tower's silence. Healing reaches deeper — the kind of mending that takes its time.",
	},
	# --- utility -----------------------------------------------------------
	"wayward_compass": {
		"name": "Wayward Compass", "slots": 1, "effect": {"compass": 1.0},
		"lore": "The Cartographer's first instrument, retired for being too honest. It always knows where you are. It is not impressed.",
	},
	"gathering_swarm": {
		"name": "Gathering Swarm", "slots": 1, "effect": {"gather": 1.0},
		"lore": "A husk that hums with small, devoted wings. What the dead drop, it brings to you, tirelessly, like a grim retriever.",
	},
	"sprintmaster": {
		"name": "Sprintmaster", "slots": 1, "effect": {"run_speed_mult": 0.25},
		"lore": "A courier's anklet from the deep rails. The mail did not survive the kingdom. The urgency did.",
	},
	"stalkers_mark": {
		"name": "Stalker's Mark", "slots": 1, "effect": {"stealth": 1.0},
		"lore": "A brand taken from something that hunted the hunters. Stand still, and the dark agrees not to mention you.",
	},
	"grubsong": {
		"name": "Grubsong", "slots": 1, "effect": {"hurt_soul": 15.0},
		"lore": "A caged creature's lullaby, pressed into wax. Pain has a melody, and this charm hums along — and pays you for it.",
	},
	# --- overcharms ----------------------------------------------------------
	"unbreakable_strength": {
		"name": "Unbreakable Strength", "slots": 2, "effect": {"damage_mult": 0.45},
		"lore": "The same borrowed strength, debt forgiven. The Forger reworked it in pale ore and dared death to collect.",
	},
	"void_heart": {
		"name": "Void Heart", "slots": 2, "effect": {"void_heart": 1.0},
		"lore": "What was left in the throne when the Sovereign stopped needing it. Once between rests, death arrives — and is asked to wait.",
	},
}

## Synergies: both equipped -> a bonus effect layered on top.
const SYNERGIES := [
	{"pair": ["long_nail", "mark_of_pride"], "effect": {"range_mult": 0.35}},
	{"pair": ["soul_catcher", "shaman_stone"], "effect": {"bolt_burn": 1.0}},
	{"pair": ["hiveblood", "stalwart_shell"], "effect": {"iframes": 0.3, "regen_fast": 1.0}},
]


static func get_charm(id: String) -> Dictionary:
	return DB.get(id, {})
