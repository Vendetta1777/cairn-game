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

## Status — Milestone 1 ✅
Project scaffold · repo + branches · CI · full movement controller (run, variable jump, coyote
time, jump buffer, dash + i-frames, crouch) · placeholder player · test level · system stubs.

See the milestone table in the design doc for what's next (**M2: AnimationTree + sprites**).
