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

## Status — Milestones 1–5 ✅ · Milestone 6 in progress
- **M1** scaffold · repo + branches · CI · system stubs.
- **M2** full movement controller (run, variable jump, coyote, buffer, dash + i-frames, crouch) · pixel-art player + animator.
- **M3** combat v1: directional 3-hit combo, parry, dagger throw, shadow bolt, hit juice.
- **M4** enemy AI: gloom-bat, husk-crawler, brute (elite) state machines.
- **M5** Area 1 "The Hollowed Gate": paced left→right level, HUD, checkpoints, lore NPC + dialogue, and now the **gameplay loop** — an objective tracker, the **Hollow Warden** boss (3 phases, ground-slam shockwaves, boss bar), the **Sealed Gate** that opens on the warden's death, and an **Area Complete** win state.

- **M6** progression systems: a persistent **`PlayerProgress`** spine, the **skill tree** (30 nodes / 3 branches — Blade · Shadow · Body — bought with Shards, real stat/ability effects), **Echoes** soft currency (dropped on death) vs **Shards** (kept), the **Sanctum** hub (rest, lore, skill altar, descend portal), and **3-slot save/load** with auto-save on checkpoint / boss death / area transition.

Next in M6: roguelite run boons (Shrines) + the fog-of-war map, then **M7: Areas 2–4** with ability unlocks.
