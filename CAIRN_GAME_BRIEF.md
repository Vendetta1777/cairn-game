# CAIRN — Full Game Design Document & Claude Code Brief

> Authoritative reference for all build decisions. Update this file as the game evolves.

---

## 1. Game Identity

**Title:** Cairn
**Tagline:** "A cairn marks a grave. Or a path. In the deep, no one remembers which."
**Genre:** Dark fantasy action metroidvania-roguelite hybrid
**Feel:** Methodical and punishing — Dark Souls pace, not arcade speed
**Engine:** Godot 4 (GDScript)
**Target platforms:** PC (Steam / itch.io), iOS (App Store), Android (Google Play)
**Repo name:** `cairn-game`

---

## 2. Premise & Lore

You are a nameless assassin who wakes in the deep with no memory, no master, and one blade.

The underground kingdom of Cairn has been silent for a hundred years. Its people are gone. Its rulers rot on thrones no one remembers building. No one from the surface has descended and returned. The stones remember what happened — you just have to follow them down.

A **cairn** is a pile of stones left to mark a grave, or to mark a path for those who come after. In the deep, the two have become indistinguishable.

### World history (environmental storytelling layer)
- Cairn was once a thriving underground kingdom — a full civilisation that chose the deep over the surface world centuries ago
- A century ago, something called **The Silencing** happened — every living thing in Cairn stopped, mid-motion
- The player character is the only thing moving. They are either the cause, the cure, or something the kingdom made as a last resort
- The truth is discovered through corpse-notes, architecture, murals, and NPC fragments — never told directly
- Three possible endings depending on what the player concludes and chooses in the final area

---

## 3. Player Character

**Class:** Agile rogue / assassin · **Visual:** Cloaked, masked, gender-ambiguous · **Voice:** Silent
**Starting loadout:** Single dagger, no ranged, no magic — everything is earned

### Core stats
- **Health:** 6 HP at start (upgradeable to 12)
- **Shadow energy:** Resource bar for magic/stealth (starts 50, up to 100)
- **Echoes:** Soft roguelite currency, dropped on death, used for run boons
- **Shards:** Hard currency kept on death, used for permanent skill tree upgrades

---

## 4. Movement System (CharacterBody2D, pixel-perfect)

| Action | Spec |
|---|---|
| Run | 200px/s base, up to 260px/s |
| Jump | Variable height — tap = short hop, hold = full jump |
| Coyote time | 6 frames after leaving a ledge |
| Jump buffer | 8 frames |
| Double jump | Unlocked Area 3 |
| Dash | 0.15s duration, 0.5s cooldown, i-frames during |
| Wall slide / Wall run | Unlocked Area 4 |
| Swim | Unlocked Area 3 |
| Grapple hook | Unlocked Area 5 |
| Crouch / Crouch-walk | Reduced hitbox; silent movement (-60% detection) |

**AnimationTree states:** idle → run → jump → fall → dash → crouch → crawl → wall_slide → swim → hurt → dead

---

## 5. Combat System

**Melee:** 4-hit dagger combo (tightening windows), upward slash, downward pogo, parry (4-frame window → slow-mo + full shadow refill + stagger), dash-cancel.
**Weapons (3, swappable):** Dagger (fast/low/long combo), Short sword (medium, wide arc), Chain blade (slow/high/reach, pulls enemies).
**Ranged:** Throwable daggers (3 charges), Shadow bolt (20 energy, pierces one).
**Magic:** Shadow cloak (15/sec, invisible + silent takedowns), Smoke bomb (25, AoE stun 2s), Shadow step (30, teleport-dash through enemies, Area 2).
**Stealth:** sight cones + sound radii (visible when crouching), unalerted/alerted states, silent takedown, environmental distractions.
**Feel targets:** 3-frame hit-stop, screen shake (light hit / heavy boss / none on miss), frame-by-frame death anims, visceral parry (white flash, 0.2s slow-mo).

---

## 6. Enemy Roster

**Base (Areas 1–2):** Crawler, Fly, Brute, Shade, Spitter.
**Advanced (Areas 3–7):** Drowned (A3), Thornling (A4), Clockwork Guard (A5), Warden (A6), Pale Knight (A7).
**Shared AI state machine:** idle → patrol → alerted (2s search) → chase → attack → hurt → dead. Drops Echoes, occasionally Shards.

---

## 7. Boss Roster

Every boss: pre-fight lore inscription on the door, unique arena, no health bar until fight begins, dedicated death cutscene.

**Mini-bosses (1/area, optional, reward Shards):** Gate Warden, Ashmother, Tide Lurker, Thornweave, Gearbreaker, Hollow Eye, Shade of Self.
**Area bosses (required):** Ashveil the Forgotten (A1, unlock Shadow bolt), Pale Magistrate (A2, Shadow step), Tidecaller Voss (A3, Swim+Double jump), The Root (A4, Wall-run), Ironclad Serevah (A5, Grapple), The Unseeing (A6, Lantern upgrade), **The Pale Sovereign (A7, 4 phases → ending)**.

**Pale Sovereign phases:** (1) aggressive melee, (2) shadow clone splits, (3) arena transforms — needs all traversal, (4) mirrors the player's own abilities. Death returns to arena entrance.

---

## 8. World Map — 7 Areas

1. **The Hollowed Gate** — tutorial, collapsed entry. Checkpoint system (Remnant Stones).
2. **Ashen Warrens** — frozen tunnel city. Dagger throw + Shadow step. NPC: Remnant. Hidden Sable Trader.
3. **Weeping Vaults** — flooded crypts. Swim + Double jump. NPC: The Archivist.
4. **Thornmere Forest** — petrified jungle. Wall-run. NPC: The Groundskeeper. Backtrack → Chain blade.
5. **Iron Reliquary** — clockwork fortress. Grapple hook. NPC: Serevah's Echo.
6. **Sable Depths** — total darkness, lantern, deep-cold drain. No NPC. Names the player character.
7. **The Pale Court** — throne room. The Sovereign (only voiced character). Three endings:
   - **The Burial** — destroy + seal Cairn; the assassin becomes the new cairn.
   - **The Path** — destroy + leave Cairn open; the deep breathes again.
   - **The Truth** — spare the Sovereign; learn you were made by it.

---

## 9. Progression Systems

**Skill tree (permanent, Shards, 30 nodes / 3 branches, respec 50):** Blade / Shadow / Body (10 each).
**Metroidvania:** abilities reopen old areas (≥2 secrets each); map tracks % explored.
**Roguelite:** death loses Echoes (keeps Shards/abilities/map/story); Remnant Stones (checkpoints, 10 Echoes); Shrines (3 random run-only boons); **The Sanctum** hub (spend Shards, NPCs, lore).

---

## 10. UI & HUD

Health = row of masks (top-left); shadow bar below; throwable count; Echoes (bottom-left, subtle); map on hold-TAB (fog of war); boss bar at bottom (name hidden until post-fight); dialogue as faded bottom-third band (no box). **Mobile:** virtual d-pad left, 4 action buttons right (opacity adjustable).

---

## 11. Audio Direction

Original dark-orchestral + ambient electronics; one theme per area + per boss; area themes sparse/architectural; boss themes layer per phase; priority SFX = parry + death + ambient drips; Area 6 near-silence.

---

## 12. Narrative Systems

Environmental storytelling (corpse notes, murals, architecture); NPC fragments with 3–5 evolving dialogue states, no quest markers; in-engine pixel-art cutscenes (30–90s, skippable after first playthrough) at game start, each boss death, entering A7, each ending.

---

## 13. Technical Specifications (Godot 4)

See repo folder structure under `scenes/` (player, enemies, bosses, world, ui, systems), `assets/`, `addons/`.
**Export:** PC (Win/Mac/Linux), iOS (Xcode), Android (APK+AAB), Web (testing/demos).
**Save:** 3 slots; auto-save on checkpoint / area transition / boss death / ability unlock.
**Performance:** 60fps mid PC & iPhone 12+; pixel art at native res, scaled, no AA.

---

## 14. Milestone Plan

| # | Milestone | Deliverable |
|---|---|---|
| M1 | Foundation & repo | Godot project, repo, CI, player controller, test scene |
| M2 | Player controller | Full movement, AnimationTree |
| M3 | Combat v1 | Melee combo, parry, dagger throw, shadow bolt |
| M4 | Enemy AI v1 | Crawler, Fly, Brute state machines |
| M5 | Area 1 complete | Hollowed Gate, 2 bosses, HUD, checkpoints |
| M6 | Progression systems | Skill tree, roguelite loop, Sanctum, save |
| M7 | Areas 2–4 | 3 areas + bosses + ability unlocks |
| M8 | Areas 5–7 + final boss | Full game, endings |
| M9 | Polish & audio | SFX, music, particles, cutscenes, accessibility |
| M10 | Platform launch | iOS, Android, PC submission-ready |

---

## M1 status (this scaffold)

Done: repo + main/dev branches, full folder structure, CI workflow, `PlayerController.gd`
(run/jump/coyote/buffer/dash/crouch — all GDD specs), placeholder player, `TestLevel.tscn`,
system-singleton stubs. Animation is a state-machine seam in `PlayerAnimator.gd`; the real
visual AnimationTree gets wired in M2 once sprite sheets exist. Test floor uses `StaticBody2D`
platforms; proper TileMaps arrive with tile art.

*Document version 1.0 — update as the game evolves.*
