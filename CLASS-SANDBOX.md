# Starting-item class sandbox

Run with `./play.sh res://class_sandbox.tscn`.
This separate scene does not read/write campaign saves, change the default scene,
or replace campaign combat/models. Its unlocks are session-only.

## Agreed roster

| Job | Identity | Starting items |
| --- | --- | --- |
| Warden | Female armored knight | Sword, axe, hammer, spear |
| Hexbinder | Male gliding caster | Fire, ice, wind, earth grimoires |
| Strider | Male agile fighter | Bloodletter dual daggers; Venom blowgun/needle; Shadow shuriken; Stone Lash weighted whip |
| Wildborn | Female feral guardian, runs on four limbs | Melee claws; forked Briar claws; Rootbind tendrils/grapples; matching Prowler hand/foot set |

Venom blowgun/poison darts and Roots tendrils/grapples were explicitly selected
by the user. Starting item locks combat style and appearance for the whole test
run. B ends the test run and returns to selection. Q does not swap styles here.

## Loadout behavior

- Warden retains her four existing weapon mechanics, now with a female sprite
  sheet and separately attached weapon artwork.
- Each grimoire has a casting gesture, projectile/ground attack pattern, third-hit
  elemental payoff and elemental digging eruption. Fire burns, ice freezes,
  wind launches and earth buries.
- Bloodletter applies bleed. Venom shoots poison darts and jabs a nearby enemy
  with a needle. Shadow uses single/double/triple shuriken throws. Stone Lash
  has longer reach and a stunning weighted-tip finisher.
- Wildborn's claws are melee. Briar claws fire thorn volleys and have visibly
  longer, red-barbed blades. Rootbind lashes, smoothly pulls, then pins enemies;
  its digging attack snares and pulls nearby enemies. Prowler uses pounce,
  rising kick and diving heel strike with matching hand/foot equipment.
- Rings, amulets and four body gem sockets reuse the existing equipment system.
  Sandbox supplies all seven items in the bag at run start; none change art.
  U additionally provides a capped damage upgrade for testing.

## Unlocks and controls

One starting item per class begins unlocked. Enemy kills grant one mastery;
additional items cost two. “Unlock all · sandbox only” allows quick review.
No mastery carries into the campaign or survives exiting this sandbox.

A/D: move. Space: jump. Down+Space: platform drop. Shift: dash. S/Down: dig.
J: attack/queue combo. B: new loadout. T: respawn targets. R: reset/refill player.
I: jewelry/gems (actors pause while open). 1: Nova, 2: Renewal when slotted.
U: +15% damage per test gem, up to five; resets on a new test run.

## Validation and review scope

`tests/class_sandbox.gd` exercises all 16 combos and digging attacks, unlock
costs, mid-run loadout locking, damage upgrades, Venom poison and root grapples.
`tests/class_sandbox_visual.gd` captures all 16 item attack silhouettes and all
four menus, checks character pixels remain identical after equipping every
jewelry/gem item, and captures Wildborn's four-legged run in both directions.
`tests/class_sandbox_motion.gd` records both-facing movement with ground travel.

This is a playable design sandbox, not final animation polish. Several attacks
share anticipation/recovery poses, Warden still needs unique authored full-body
weapon clips, and some jumps/dig transitions reuse available poses. Projectiles
and tendril effects are native prototype visuals. The campaign remains the prior
version until this direction is reviewed.

Artwork, exact prompts and source files:
[assets/characters/class-sandbox/GENERATION.md](assets/characters/class-sandbox/GENERATION.md).
