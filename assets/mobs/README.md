# Rootling

`rootling-walk.png`: 1536 × 1024 RGBA, generated with the built-in image tool.
Original alpha preserved. Four poses in a 2 × 2 sheet. Source regions and foot
registration live in `scripts/forest_mob.gd`; Godot AtlasTexture margins align
the poses without rewriting or slicing the source image.

Generation prompt:

Production enemy animation sprite sheet for a side-view fantasy platformer.
Exactly four frames in a strict 2 × 2 equal-cell grid on genuine transparent
alpha. Same moss-backed rootling in every cell facing right: squat woodland
imp of twisted brown bark, two short articulated root legs, two twig arms,
compact woody head, amber eyes, olive shoulder leaves. Chunky silhouette,
dark outlines, crisp illustrated pixel-art-inspired shading, upper-left
lighting matching the knight. Walk phases: right contact, passing crouch,
left contact, passing rise. Counter-swing arms, consistent anatomy, scale,
baseline and cell placement, generous transparent margins. No weapons,
ground, scenery, shadows, dust, labels, numbers, grid lines or text.

The current sheets are draft generated animation. Defeated mobs collapse into
bark and leaves, then fade out; R restores them.

## Combat

`rootling-combat.png`: 1536 × 1024 RGBA, generated with the built-in image tool
using the walking sheet as an identity reference. Six poses: wind-up, extended
claw swipe, follow-through, impact recoil, stagger, and recovery. Each pose is
registered independently in AtlasTexture margins, preserving feet alignment.

Generation brief: same bark rootling, amber eyes, moss and leaves; six poses in
a 3 × 2 layout on real transparency. Right-facing attack sequence across the
top row and getting-hit sequence across the bottom. Strong silhouette changes,
consistent anatomy/scale, no scenery, ground, weapons, dust, labels, or grid.

Attacks start within 65 px horizontally and 28 px vertically with clear line of
sight. Wind-up lasts 0.32 s, followed by one 10-damage swipe and recovery, then
a 0.7 s cooldown. Facing locks at wind-up. Hits interrupt attacks and play a
0.34 s recoil sequence. Dash immunity and burrowing prevent incoming damage.
Contact alone no longer deals damage. Player HP and hurt flash are visible.

Check: `./play.sh --headless --script tests/forest_mob_combat.gd`.

## Death

`rootling-death.png`: 1536 × 1024 RGBA, generated with the built-in image tool
using the walk sheet as the identity reference. Four individually registered
poses: buckling, knees/hands collapse, fallen body, settled bark-and-leaf pile.
The sequence lasts 1.5 s, including a final 0.5 s fade. Attack and hit detection
stop immediately on defeat. Airborne bodies fall to supporting terrain.

Generation brief: identical right-facing bark rootling, four death poses in a
2 × 2 layout, same scale and foot baseline. Amber eyes fade to dark; body
crumbles into roots, bark, and olive leaves. Real transparency; no scenery,
ground, blood, text, grid, or additional characters.

Check: `./play.sh --headless --script tests/forest_mob_death.gd`.

## Elemental reactions

Mage third hits can burn (4 s), freeze (2 s), launch, or half-bury (2.5 s).
Earth keeps the upper body visible using `shaders/mob_cutout.gdshader`;
airborne targets fall before burial. Frozen mobs cannot move or attack.
Burn damage does not repeatedly trigger recoil. Reset/death clears statuses.
