# Cairn

> *A cairn marks a grave. Or a path. In the deep, no one remembers which.*

A dark fantasy action **metroidvania-roguelite** built in **Godot 4** (GDScript). You are a
nameless assassin who wakes in the silent underground kingdom of Cairn with no memory and one
blade. Methodical, punishing, Dark Souls–paced combat with a Hollow Knight–shaped world.

Full design doc: [`CAIRN_GAME_BRIEF.md`](CAIRN_GAME_BRIEF.md).

---

## Getting started

1. **Install Godot 4.3+** (standard, *not* the .NET build) — https://godotengine.org/download
2. Clone, then open the project:
   ```bash
   git clone git@github.com:Vendetta1777/cairn-game.git
   cd cairn-game
   git checkout dev          # all active work lives on dev
   ```
3. In Godot: **Import** → select this folder's `project.godot` → **Open**.
4. Press **F5** (or the play button). `scenes/test/TestLevel.tscn` runs.

### Controls (M1)
| Action | Key |
|---|---|
| Move | A / D or ← / → |
| Jump | Space (hold = higher) |
| Dash | Shift |
| Crouch / crouch-walk | Ctrl |
| Pause | Esc |

---

## Branches
- **`main`** — stable. Only receives merges at milestone completion.
- **`dev`** — active development. All work happens here.

## CI
`.github/workflows/build.yml` exports a **Web build** on every push to `dev` and uploads it as a
downloadable artifact. It pins Godot **4.3** — if you install a different 4.x, bump `GODOT_VERSION`
and the container image tag, then re-save the export preset from the editor (Project → Export).

## Status — Milestones 1–7 ✅ · Milestone 8 next
- **M1** scaffold · repo + branches · CI · system stubs.
- **M2** full movement controller (run, variable jump, coyote, buffer, dash + i-frames, crouch) · pixel-art player + animator.
- **M3** combat v1: directional 3-hit combo, parry, dagger throw, shadow bolt, hit juice.
- **M4** enemy AI: gloom-bat, husk-crawler, brute (elite) state machines.
- **M5** Area 1 "The Hollowed Gate": paced left→right level, HUD, checkpoints, lore NPC + dialogue, and now the **gameplay loop** — an objective tracker, the **Hollow Warden** boss (3 phases, ground-slam shockwaves, boss bar), the **Sealed Gate** that opens on the warden's death, and an **Area Complete** win state.

- **M6** progression systems: a persistent **`PlayerProgress`** spine, the **skill tree** (30 nodes / 3 branches — Blade · Shadow · Body — bought with Shards, real stat/ability effects), **Echoes** soft currency (dropped on death) vs **Shards** (kept), **Shrines** (3 random run-only boons), the **Sanctum** hub (rest, lore, skill altar, descend portal), a hold-**TAB fog-of-war map**, and **3-slot save/load** behind a title screen (auto-save on checkpoint / boss death / area transition). Beating Area 1's Warden grants the Wardstone (+1 heart) and opens a return portal to the hub.

- **M7 (this push)** the descent grows:
  - **Ability relics + gates** — dash, wall jump and double jump are found in the world (The Shadowstep / The Ashen Grip / The Second Breath), persist in saves, and rune-ward gates + shard caches reward backtracking.
  - **Death sequence** — slow-mo desaturation, *YOU PERISHED* with area + time survived + a random epitaph, any-key respawn at the last Remnant Stone; enemies repopulate, Shards stay.
  - **Area 2 "The Ashpits"** — collapsed forge zone: ash vents you can ride, Cinder Wraiths, the wall-jump relic, and **THE ASHEN WARDEN** — a 2-phase furnace-guardian boss with a camera-pan intro, telegraphed slams, ash sweeps, cinder rain, and a staged collapse-and-explode death.
  - **Area 3 "The Sunken Nave"** — drowned cathedral: wading shallows, deadly deep water, Drowned Faithful, the double-jump relic, a bell-tower ascent, and the sealed choir door waiting for a later milestone.
  - **World map (M)** — a carved stone tablet: discovered areas etch themselves in, undiscovered depths stay uncut rock; skull = you, runes = shrines, coloured locks = the ability each gate demands.
  - **Audio** — an `AudioManager` over Master/Music/SFX buses; every sound procedurally synthesized by `tools/gen_audio.gd` (footsteps by surface, combat, bosses, shrines, doors) plus per-area ambient music with 4s crossfades, a separate boss track, and ducking during the death slow-mo.
  - **Main menu** — New Game / Continue / Settings / Quit over the animated backdrop; volume sliders + fullscreen persisted to `user://settings.json`.
  - **Polish + export** — global chromatic-aberration/film-grain post pass, directional wipes + a loading screen (threaded loads, lore quotes) on every scene change, terrain rendering chunked + culled (Area 1: 29ms → 7ms/frame), export presets for Windows / macOS / Web / Android.

Next: **M8 — Area 4+**, the choir behind the sealed door, and the heart-shrine cadence (levels 5/10/15/20).
