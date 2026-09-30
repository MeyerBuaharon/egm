# Underfoot

## Separate class sandbox

`./play.sh res://class_sandbox.tscn` opens the new starting-item prototype.
Female Warden/Wildborn, male Strider/Hexbinder, sixteen starting items, locked
run loadouts and nonvisual jewelry/gems. See [CLASS-SANDBOX.md](CLASS-SANDBOX.md).
Campaign models and save data remain separate.

## Current playable forest build

Run `./play.sh res://forest_slice.tscn`.

| Key | Class | Q cycles |
| --- | --- | --- |
| F1 | Warden | Sword, Axe, Hammer, Spear |
| F2 | Hexbinder (Mage) | Fire, Ice, Wind, Earth |
| F3 | Strider | Bloodletter, Venom, Shadow, Flurry |
| F4 | Wildborn | Claws, Thorns, Roots, Feral |

A/D or arrows move; J attacks and queues combos; Shift dashes; Space jumps.
Hold S/Down on the ground to dig; release or attack to emerge (Warden retains
his original weapon-specific attacks). Down + Space drops through a platform.
Up/E uses the nearby portal. F collects class equipment, I opens the inventory,
C edits the character name. F8 toggles scene-layer diagnostics.

Each class now has one fixed model. Equipment never changes its appearance; Mage
starts in his permanent purple-and-gold hood, robes, gloves and boots. Armor
pickups and armor finish controls have been removed. C edits the character name.

Equipment: two rings, one amulet and four body gem sockets. F collects/equips;
I opens the inventory; click an equipped item to store it, then a bag item to equip.

| Item / body socket | Effect |
| --- | --- |
| Iron signet | Reduce incoming damage by 2 |
| Sapphire ring | +3 MP regeneration / second |
| Vitality amulet | +4 stamina regeneration / second |
| Aegis / heart | Reduce incoming damage by 3 |
| Gale / lungs | +15% movement speed |
| Nova / hand | Key 1: 20 area damage, 15 MP, 8-second cooldown |
| Renewal / core | Key 2: restore 25 HP, 20 MP, 12-second cooldown |

Active gems are separate from Q's class combat styles. Keys 3–4 remain future
leveling slots. P opens the passive tree and pauses play; F collects nearby loot
or uses a wayshrine. The minimap marks loot, enemies and portals.

The campaign connects Forest Edge → Deep Grove → Mansion Gate, with return
portals, chests, memory shards, dropped embers/tonics and healing wayshrines.
Nine passives across Might, Resolve and Wayfarer spend level/shard points and
embers. The Hollow Regent guards the final gate with warned root eruptions,
ground slams, summoned rootlings and a faster second phase. Defeating it awards
a seal: collect it for three points, 30 embers and permanent +10% damage.

Progress, names, jewelry/gems, claimed loot, passives and boss completion save
between sessions to `user://forest-progress-v1.json`, with an atomic write and
backup. Resume starts at the saved map entrance with replenished resources.
`./play.sh -- --fresh` runs a temporary session without loading or saving.

Strider and Wildborn now use generated full-body run frames, like the Warden.
The previous articulated-leg version was rejected in play and is superseded.
Four intact poses animate the body, arms and scarf/mane; Strider sheathes his
daggers while running. Cadence follows velocity. Other actions retain their
existing artwork. See [art prompts and registration](assets/characters/roster/RUN-V4.md)
and [full-body run preview](previews/fullbody-run.mp4).

Campaign implementation, validation and limits: [CONTENT-WORK.md](CONTENT-WORK.md).
Preview: [passive tree](previews/passive-tree.png),
[boss encounter](previews/campaign-boss-warning.png).

## Earlier movement lab and development notes

Open `project.godot` in Godot 4.7 and press F6 with `main.tscn` open (or F5).
If the bundled engine is available, run `./play.sh`.

A/D or arrows: move. Space/W/Up: jump, then air jump. Hold jump for height.
Shift: invulnerable horizontal dash, on the ground or in the air. Push into walls to slow your
fall, then jump away. Land on amber targets to bounce and restore your air jump.
Hold S/Down on the bottom floor to burrow; release to launch with an extra jump.
R: reset. M: reduced camera motion. The dot above your head indicates an air jump.

Movement uses 120 Hz physics, acceleration, jump buffering, coyote time, variable
jump height, air steering, wall jumps, ground/air dashes and automatic enemy bounces.
Controller parameters are exported at the top of `scripts/player.gd` for tuning.

This is deliberately a movement prototype. The later game brief is a side-view
2D roguelike ARPG with four classes, three choices on level-up, drops and chests,
and a goal of reaching map three, with different enemies on each map. None of
those progression systems are implemented yet.

## Levels and themes

Levels are JSON in `levels/`, not scenes. TAB cycles Rootworks → Cistern →
Emberworks. Each file carries its geometry, bounce targets, training dummies,
annotations and a colour theme; `scripts/room.gd` reads it and rebuilds the
static bodies. Geometry stays flat themed rectangles for now — generated tileset
or parallax art layers on later without changing the format.

The shared floor and outer walls are fixed across every level: `player.gd`
hardcodes `FLOOR_Y` and burrowing depends on it. `.claude/agents/level-designer.md`
writes new levels; `tests/levels.gd` enforces the invariants. See
`levels/GENERATION.md`.

### Forest → Blackroot

Four forest stages darken across the biome: Forest Edge, Deep Grove, Thornwood,
Blackroot. Each level names a `biome` and a `corruption` value from 0 to 1;
`resolve_theme()` interpolates between the two authored endpoints in
`levels/biomes.json`, so stages 2 and 3 need no separate palette and no separate
art. Change the stage count by adding a file, not by re-authoring colours.

Tiles and backgrounds are specified in `assets/levels/TILES.md`, with generation
prompts in `assets/levels/FOREST-PROMPT.md`. No level art is generated yet —
geometry still draws as flat themed rectangles.

## Warden animation lab

Warden (1) now uses a separate full-body sprite sequence, with a sheathed sword,
a brief push-off, slower six-frame run, dash/wall/air poses, and gauntlet-led
burrow entry followed by an upward burst. The default acceleration is 900 px/s²
and top speed is 180 px/s (about 0.2 seconds from rest to full speed).

F2 opens live acceleration, speed and animation cadence sliders. These settings
last for this session; permanent defaults are exported in `scripts/player.gd`.
T toggles slow motion. Hold S on the bottom floor to crouch, strike, and dive;
release to launch upward with an air jump restored. Early release queues the exit
until the 0.27-second entry completes. The underground position marker remains.

The Warden sprite sequence is generated draft artwork, not a finished hand-drawn
animation set. His sword and costume are baked into these frames, so Q/E do not
change his appearance yet. Modular Warden equipment remains future work.
`previews/warden-run-burrow.mp4` previews the new sequence. Movement checks pass.

## Other classes: procedural rig, revision 4

1–4: Warden, Strider, Hexbinder, Wildborn. E: light/heavy visual equipment.
Q: sword, hammer, staff, daggers. J: visual weapon flourish (no damage).
T: toggle slow motion to inspect poses. Movement controls above still apply.

The rig now animates textured body parts from each class's consistent idle pose,
rather than cycling inconsistent generated run frames. Running follows distance
traveled. Jointed arms attach to weapon grips; heavy/long weapons have two-handed
support, and weapons move to back attachments when hands are needed for walls or
burrowing. Class-specific burrow entry/emergence and underground effects are
procedural. This is articulated cutout animation, not newly hand-drawn frames.

The underlying atlas remains unchanged. A material rejects faint alpha matte
pixels at rendering time. Base clothing is still baked into the artwork; the
armor overlay and separate weapons are a prototype of modular equipment.

Checks:
- `tools/godot --headless --path . --script tests/movement.gd`
- `tools/godot --headless --path . --script tests/animation.gd`
- `tests/animation_review.gd` renders run and burrow contact sheets with a display.

Art: built-in image generation, `assets/characters/classes.png`. A requested
background-only regeneration was rejected because it altered foreground pixels.

Revision 3 keeps the upper-body artwork continuous, straightens the resting stance,
refines weapon silhouettes, and adds a 1.5× smoothly following camera with fixed HUD.

Revision 4 adds an idle-to-run push-off, speed-driven blend, shorter ground contact,
heel recovery, opposite arm swing, and a decelerating settle back to idle.
`previews/run-start-stop.mp4` records the actual rig through the full transition.

### Warden leg swap and slash update

J plays a visual sword draw → slash → resheath sequence (no damage yet).
Movement, jump and burrow inputs are locked through the attack; dash can cancel it. Attacking
with movement carries a short forward slide, brakes to rest, and locks facing.
Slide speed and braking are exported on the player; idle attacks stay planted. The sword is part of these authored action
frames, not a modular weapon attachment. Running uses eight intact full-body frames, combining passing poses with a
separate opposite-leg sequence. The rejected articulated legs have been removed.
Tests: `tests/warden_actions.gd`; preview: `previews/warden-slash.mp4`.

## Weapon combat prototype

Warden Q cycles Sword / Axe / Hammer / Spear. J attacks, including while holding
S underground. R resets the player and training targets; T slows time.

- Sword: forward thrust; moving or burrowed attacks dash about 78 px. Hits stun
  targets for 1.2 seconds. Sword and longsword share this mechanic; the prototype
  currently has one sword selection.
- Axe / spear: rising attack with knock-up. Burrow attacks launch vertically and
  restore the air jump.
- Hammer: whole-sprite somersault into a downward slam. Hit enemies fall through
  elevated platforms to the main floor, become half-buried for 2 seconds, then
  recover. Ground targets are buried on impact.

Movement and facing remain locked through attack recovery. Walls block dashes
and blocked burrow exits. One hit per enemy per attack. Combat timing runs on
physics ticks, independently of animation playback. Settings are exported in
`scripts/warden_combat.gd`. Ground/platform training enemies show status timers.
These are reusable training targets, without health/death or full enemy AI.

Weapon action frames are generated full-body draft artwork; running and burrow
frames stay intact. Equipment remains baked into frames. Somersault rotates the
whole character, never individual legs. Preview: `previews/weapon-combat.mp4`.
Regression checks: `tests/weapon_combat.gd`, `tests/attack_movement.gd`,
`tests/warden_actions.gd`, `tests/movement.gd`.

## Attack mode rules

- Running attack: actual horizontal speed at or above 120 px/s when J is pressed.
  Applies the weapon's status effect. F2 exposes the threshold. Holding a direction
  alone does not count as running.
- Burrow attack: takes priority underground, with the same status effect and
  its distinct emergence movement. Only burrow hammer performs the somersault;
  running hammer uses a short forward hop/slam.
- Regular attack: below threshold, or a combo follow-up. Press J again after
  the initial windup to buffer the next hit, or within 0.35 seconds of recovery.
  Three hits maximum, no stun/knock-up/burial. A special can chain into regular
  hit one; follow-ups override speed. Existing enemy statuses aren't erased.
- Air attacks: J starts a weapon-specific chain; press J again to buffer each follow-up.
  Early swings briefly suspend the player even on a miss; hits also suspend enemies.

Regular combos reuse full-body weapon poses with per-hit ordering and timing.
No individual limb deformation. `tests/combo_modes.gd` covers classification,
all four weapon chains, status exclusion, grace timeout and airborne classification.

## Expanded regular combo animations

Each hit now has six timed phases: anticipation, windup, acceleration, contact,
follow-through, recovery. Hit detection starts at contact, not during windup.

- Sword: forehand cut → rising backhand → overhead cleave.
- Axe: broad chop → low reverse sweep → overhead cleave.
- Hammer: cross-body blow → shoulder smash → overhead crush.
- Spear: extended thrust → diagonal sweep → butt-end strike.

These use intact full-body sprites with weapon-specific timing and reach.
Hammer is slower; spear thrust is faster. The hammer finisher shares some
windup/recovery poses and approved slam frames because its generated final rows
overlapped and the image-generation retry hit the usage limit. Other sheets have
18 poses each. The artwork remains a generated draft with some pose variation.
Running/burrow status rules remain unchanged. Regular combos still have no
status effects. Preview: `previews/regular-combos.mp4` (both directions).

## Dash and air combat

Shift replaces slide: a 0.16-second invulnerable horizontal dash with a 0.4-second
recharge, available on the ground and in the air. It cancels attacks and releases
held enemies. Tune `dash_speed`, `dash_duration`, and `dash_recharge` on Player.

Jump, then press J (Q changes weapon):
- Sword: two hits, then a thrown sword and collision-safe teleport. Smear lines
  mark the path; damage and stun resolve after the Warden reappears and sheathes.
- Axe/spear: forward hit, angled downward knockback, then a diagonal weapon-first
  dive with an impact hit on landing.
- Hammer: immediate straight downward slam, without the burrow somersault.

Each early air swing grants a short float, including misses. Attack buffering
requires separate presses. Dash cancels any chain. Air combat tuning lives in
`scripts/warden_air_combat.gd`. The visuals reuse intact body poses with procedural
weapons/effects for the dive and teleport, rather than newly drawn frame sequences.
An airborne training target spawns near the player. Training targets track health
but remain available at zero health; R resets them and player health. Ground
contact deals damage so dash immunity can be tested.

`tests/air_dash.gd` covers immunity, air chains, hit suspension, cancellation,
delayed path damage and collision/line-of-sight restrictions.
