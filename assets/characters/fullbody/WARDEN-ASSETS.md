# Warden full-body experiment — disabled by default

The user rejected this replacement because it reduced the original Warden's
combat and clothing animation quality. The forest now uses the original
`warden_visual.gd` again. `player.warden_fullbody_enabled` is false by default.
The new sheets below are retained only for explicit art review. Inventory state
works; the original Warden now supports per-slot material finishes through
`roster_equipment.gdshader`, preserving the baked armor silhouette and animations.
Shape-changing armor requires matching per-pose layers or full outfit sheets;
a single static armor image cannot preserve the authored animation.


Generated with the built-in image-generation tool, September 28, 2026.
Project assets: `warden-movement.png` and `warden-combos.png` (1254 × 1254,
transparent PNGs). The mage sheet was the style reference for movement;
the resulting Warden movement sheet was the character reference for combat.

The rejected experiment used intact painted poses through
`scripts/warden_fullbody.gd`. This renderer is disabled in the forest; the original
armored renderer now serves both the forest and the movement lab. The following
notes describe the archived experiment, not the current playable Warden.
No collision sizes, movement speeds, damage, stamina, hit timing, or status
behavior changed. Six running poses follow travel speed; idle, jump, fall,
wall grip, slide, dig, and emergence have separate poses. Three combo attacks
have anticipation/strike/recovery poses. Special attacks currently reuse
these attack poses; they are not newly authored per-weapon special clips.
All four existing native weapon silhouettes attach to measured fist anchors.
The shared combat poses are one-handed, including axe/hammer variants.

Equipment uses the same approach as Mage: a registered helmet overlay;
painted tunic/hand/boot recoloring preserves the full human silhouette.
Robes become crimson/gold, gloves and boots steel/gold. This is an equipment
color treatment, not replacement plate-armor geometry. Rings and amulet keep
the existing state/icon behavior without combat bonuses or body overlays.

C edits the current class with four hair/skin palette presets. Name and preset
are separate per class and persist through switching/reset/map changes in the
current session only. They are not four different faces or hairstyles.

Validation: equipment/profile tests, Warden actions, six-frame locomotion and
three-phase combo state checks, real-renderer equipment pixel changes/removal,
64 movement/loadout/facing samples and 72 weapon/attack/facing samples.
Preview files live in `previews/warden-fullbody-*.png` and `warden-creation.png`.

## Movement generation prompt

Create a PRODUCTION GAME SPRITE ATLAS, transparent background, square 4 by 4 equal grid, SIXTEEN complete full-body poses of ONE identical male WARDEN warrior. Use attached mage only as painted fantasy art style and human anatomy quality reference; Warden is different: healthy handsome adult, strong athletic build, upright normal proportions, short SILVER hair, clean shaven, simple BLUE short-sleeved belted tunic ending upper thigh, charcoal fitted trousers, brown leather boots, bare hands, NO armor NO helmet NO cape. Every cell contains intact connected full human head to feet, never dismembered. All face RIGHT, side / slight three quarter view. No weapons, hands loosely closed for attaching a separate weapon later. EXACT 4x4 equal cells, each figure fully inside cell with generous transparent gutters, consistent anatomy and scale, no ground/shadows/text/effects/grid lines. At least 2048px square if possible. Row1 left to right: 1 upright relaxed idle with near hand at waist poised to hold sword, 2 run right front leg forward rear extended (contact A), 3 run recoil crouch with front knee bent, 4 run passing pose rear leg passing under hips. Row2: 5 run opposite leg contact B, 6 opposite recoil, 7 opposite passing pose, 8 jump takeoff knees flexed one raised. Row3: 9 falling ready to land, 10 wall grab facing right both hands stretched forward/up, 11 low ground slide leg extended right other folded, 12 crouched digging punch down into ground with near fist. Row4: 13 overhead sword windup empty near fist high, 14 sword swing near empty fist forward chest height torso turns, 15 recovery empty fist down in front, 16 upward emergence strong leap fist raised. Same exact character, hair, costume and proportions in every cell. Grounded poses feet at same baseline within each cell. Detailed professional painted 2D action RPG sprite art, crisp silhouettes, full human no cutout body parts.

## Combat generation prompt

Generate a matching COMBAT sprite sheet for this EXACT Warden human character, same short silver hair, healthy strong adult face, blue short-sleeved short belted tunic, charcoal trousers, brown boots, bare hands. Transparent background, crisp painted RPG style. Nine full intact human figures in EXACT 3 by 3 square equal cells, all face RIGHT, identical scale and costume. Generous gutters EVERY figure strictly inside own cell no overlap adjacent rows. No weapons/effects/text/shadow/background; hands CLOSED fists for attaching separate weapon. ONE-HANDED attacks, near hand does weapon move, other hand balances. Every row has three phases windup, strike, recover. Row1 horizontal sword cut: near fist behind shoulder; near fist thrust forward at chest level; near fist down forward after swing. Row2 rising backhand: near fist low behind hip; near fist reaches diagonally up forward; near fist back near waist after swing. Row3 overhead cleave: near fist above head with bent elbow; near fist drives diagonally forward down; near fist low forward torso recovering upright. Right-facing body throughout, head looking right even when torso turns, normal upright warrior stance legs braced not bent-over ill. Preserve intact hands, wrists, shoulders; complete head-to-toe poses with feet on same baseline for all cells. Same anatomical proportions as attached reference; full human illustration, never separated body parts.
