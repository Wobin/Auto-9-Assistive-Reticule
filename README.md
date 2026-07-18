# Auto-9 Assistive Reticule

A RoboCop-style targeting HUD for Darktide. The reticule "boots up" on your target: a lock-on box zooms in
from the screen edges onto the enemy, a full-screen crosshair sweeps in from your previous target's location,
and once it settles the box and crosshair hand off to a clean outline on the locked enemy. A lower-left
scanner readout names the subject as it locks on.

It works two ways, and you can run either or both:

- **Skitarii, Advanced Combat Doctrines (ACD):** while ACD is active the reticule tracks the ability's
  auto-aim target, exactly as before.
- **Any class, by tagging:** tag (ping) an enemy and the reticule acquires that enemy. No auto-aim is
  involved, so this opens the whole mod up to every class. A live tag takes priority over ACD.

## Compatibility

> **Not compatible with "Clarity of Aim". Run one or the other, not both.**
>
> Both mods draw their own enemy outline on the target. Running them together makes the two outlines fight
> over the same enemy (colours and priority will not agree). Auto-9 Assistive Reticule is the full targeting
> overlay; Clarity of Aim is the lighter outline-only option. Pick whichever you prefer and disable the other.

## What it does

- **Box** zooms in from the screen borders onto the target as it is acquired.
- **Crosshair** (full-screen horizontal and vertical lines) sweeps in from your previous target's physical
  location. If that target was off-screen or behind you, the crosshair sweeps in from the screen edge on the
  correct side. The sweep is time-based, so panning the camera fast cannot outrun it: it reaches the target in
  a fixed time no matter how the enemy or your view moves.
- **Outline** takes over as the persistent lock indicator once the reticule settles on the target.
- **Scanner readout** in the lower-left reads `SCANNING...` while searching and swaps to
  `SUBJECT: <name> / WANTED` on lock, with the name decrypting into place. Names are drawn from the game's
  credits (a randomised first and last, never a real credited person's actual full name) and stay locked to
  each enemy, so the same target keeps its name if you re-acquire it.

### Tagging mode

- Tag an enemy and the reticule acquires it, for any class.
- A live tag overrides the ACD auto-aim target while it lasts.
- The reticule holds the tagged enemy until the tag clears (it expires, is re-tagged, or the enemy dies).
- The crosshair bars sweep in once per tag, then hand off to the outline and stay hidden until the next tag,
  so a moving tagged enemy does not make the bars flicker back.

## Requirements

- Darktide Mod Framework (DMF).
- For the ACD auto-aim mode: the Skitarii class with **Advanced Combat Doctrines** equipped (the auto-aim
  reticule only tracks while ACD is active).
- For tagging mode: any class. Enabled by default.

## Settings

- **Target Box:** enable, thickness, colour, opacity, zoom duration.
- **Lines (crosshair):** enable, thickness, colour, opacity, match the box colour.
- **Outline:** match the crosshair colour, custom colour, draw priority (lower wins; 0 shows over everything).
- **Scanner Readout:** enable, on-screen position (horizontal and vertical), text scale, colour.
- **Tag Trigger:** enable triggering the reticule on tagged enemies, and whether to react only to your own
  tags or to any teammate's enemy tag.

## Credits

By Wobin.
