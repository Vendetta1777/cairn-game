# Cairn — Asset Credits

Cairn uses third-party art assets as placeholders/foundation. Credit where due, and
**verify each pack's license before any commercial release.**

| Asset (in repo) | Used for | Source pack | Author | License notes |
|---|---|---|---|---|
| `assets/sprites/player/hooded.png` | Player (the hooded assassin) — idle/run/jump/crouch/hurt | `AnimationSheet_Character.png` (itch.io download) | **TBD — confirm** | ⚠️ source/author not yet recorded; identify the pack + verify its license before release |
| `assets/environment/caverns/*` | The underground cave (parallax layers + terrain) | GothicVania "Caverns" | **Ansimuz** | CC0 / free for commercial use |
| `assets/sprites/enemies/bat/*` | Enemy (the "Fly") test dummy | DarkFantasyEnemies (FREE) | (itch.io free pack) | verify pack license |
| `assets/fx/slash.png`, `assets/fx/hit.png` | Attack slash + hit spark VFX | GothicVania "Explosions and Magic" | **Ansimuz** | CC0 / free for commercial use |
| `assets/fx/dagger.png` | Thrown-dagger projectile | GothicVania "Terrible Knight" projectiles | **Ansimuz** | CC0 / free for commercial use |
| `assets/sprites/enemies/crawler/*` | Crawler (ground imp) | imp_axe_demon | (itch.io) | verify pack license |
| `assets/sprites/enemies/brute/*` | Brute (ogre) | GothicVania Ogre | **Ansimuz** | CC0 / free for commercial use |
| `assets/sprites/npc/keeper.png` | The Keeper NPC (heart upgrades) | GothicVania "death" reaper | **Ansimuz** | CC0 / free for commercial use |
| `assets/sprites/npc/guard_idle.png` | Lore NPC (spectral civilian) | GothicVania "Dancing Girl" idle | **Ansimuz** | CC0 / free for commercial use |
| `assets/decor/torch.png` | Animated wall torch | Bitcrawl Free Roguelike | (itch.io) | verify pack license |
| `assets/decor/crystal*.png`, `rock*.png`, `web.png` | Cave crystals / rocks / cobwebs | Free Top-Down Pixel Art Cave Objects | (itch.io) | verify pack license |
| `assets/decor/torch.png`, dungeon enemy/prop sheets | Animated torch + props | Bitcrawl / craftpix dungeon packs | (itch.io) | verify pack license |
| `assets/fonts/silkscreen.ttf` | UI / dialogue pixel font | Silkscreen by Jason Kottke | **OFL** (open font license, free) |

## Notes
- Sources were downloaded by the project owner from itch.io.
- These are **foundation/placeholder** assets chosen to match Cairn's dark-fantasy
  underground theme. They may be replaced with commissioned/original art before release.
- Before shipping commercially, re-confirm every license (some "free" packs require
  attribution or forbid redistribution of the raw pack) and keep this file current.

## Audio
All sound effects and music in `assets/audio/` are **procedurally synthesized**
by `tools/gen_audio.gd` (noise bursts, tuned partials, slow pads) — no recorded
samples, no external licenses. Regenerate any time with:
`godot --headless --path . -s res://tools/gen_audio.gd`
