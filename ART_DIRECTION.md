# Cairn — Art Direction

> Underground dark fantasy. A silent rogue assassin in a kingdom that stopped breathing.
> Mood words: **cold, hushed, buried, grave-lit.** More shadow than light. Light is precious.

## Pillars
- **Darkness is the default.** Areas are lit in pools, not floods. The player reads as a *silhouette* first, detail second.
- **One cold accent in the dark.** Faint teal/cyan bioluminescence (moss, motes, the assassin's eye) is the only "alive" colour in the deep.
- **One warm wound.** A muted, desaturated crimson — scarves, banners, old blood, cairn-cloth. Used *sparingly*; it should feel like a memory of life.
- **Stone is blue-grey, never brown.** This is a cold, deep place — greys lean cool, never earthy.

## Core palette
| Role | Hex | Notes |
|---|---|---|
| Void / sky black | `#08090e` | deepest background |
| Cavern dark | `#0e111a` | far silhouettes |
| Stone shadow | `#161a26` | platform/wall bodies |
| Stone mid | `#222838` | lit faces, top lips |
| Stone highlight | `#2e3547` | edges catching light |
| Cloak black | `#14161d` | assassin's outer cloak |
| Cloak fold | `#20242f` | cloak depth/drape |
| Mask bone | `#b3ad9d` | the pale masked face |
| Cold accent (alive) | `#74d6cb` | eye-glow, moss, motes |
| Warm wound (crimson) | `#8a2f33` | scarf, blood, cairn-cloth |
| Steel | `#99a2b2` | the dagger |

## The assassin
Cloaked, hooded, masked — **gender-ambiguous, slight build**. Reads as a hooded silhouette
with: a pale bone mask, a single faint **cyan eye-glow** (the only bright thing on them — they
are the one thing still moving in the deep), a crimson scarf at the throat, and a single dagger
held in a reverse grip. No skin, no face beyond the mask. Movement is light and low.

## The biome (Area 1 vibe — The Hollowed Gate)
Collapsed grandeur. Cold dust hanging in still air. A `CanvasModulate` cools and dims the whole
scene; faint dust motes drift; rare teal spores hint that *something* down here is alive. Stone is
carved and layered (body + a lighter top lip catching the dim light). Far silhouette layers
suggest a vast space beyond the play area.

## Technique (now vs later)
- **Now:** everything is layered `Polygon2D` shapes + `CanvasModulate` + `CPUParticles2D`. Fully
  editable, establishes palette + silhouette + mood, zero external assets.
- **Later (with art):** swap the assassin rig's shapes for a sprite-sheet `Sprite2D`/`AnimatedSprite2D`
  and stone for tilesets — the palette and mood targets in this doc stay the law.
