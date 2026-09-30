# Four-class completion work

September 29 scope update: fixed class looks replace wearable armor visuals.
Mage starts permanently clothed/armored. Two rings, an amulet and four body gem
sockets provide passive/active effects. Armor pickups and appearance options are
removed. Strider/Wildborn now use full-body generated run sprites after the
user rejected the articulated-leg version in play.
See README.md and assets/characters/roster/RUN-V4.md for current behavior.
Both facings and gameplay/close-up motion were reviewed. The checklist below
records the earlier armor-based version and is historical.

Authorized scope: four playable classes, four combat styles each, distinct digging
techniques, customizable wearable armor with coherent animation. Preserve original
Warden combat/cape artwork; do not replace it with the rejected generic body.

Roster: Warden (sword/axe/hammer/spear), Hexbinder / Mage (fire/ice/wind/earth), Strider
(bleed/venom/shadow/flurry), Wildborn (claws/thorns/roots/feral).
Class keys retain F1 Warden / F2 Mage; add F3 Strider / F4 Wildborn; move layer debug
toggle to F8. Q cycles current class combat style. J attack, Shift dash,
Down/S dig, Space jump/drop, F collect, I equipment, C appearance.

Implementation checkpoints:
- [x] Class/style registry and four-class selection, HUD/tooltips.
- [x] Strider and Wildborn authored full-body movement/attack artwork.
- [x] Strider and Wildborn gameplay, status effects, projectiles, burrow/air actions.
- [x] Seven-slot inventory for all classes, wearable armor visuals and customization.
- [x] Original Warden per-slot armor customization without replacing animations.
- [x] Appearance picker and session state for all classes.
- [x] Focused gameplay regression and four-class combat coverage.
- [x] Rendered movement/combat/loadout review in both directions; fix found issues.
- [x] Launch final reviewed build and report exact controls and remaining limitations.

Quality gates: intact human silhouettes, consistent pose registration, weapons in
hands, no atlas-neighbor bleed, clothing follows authored animation, no misleading
inventory/appearance options, damage/status/projectile collision checks, resource
costs and cooldowns, map/class-switch persistence, no runtime shader/script errors.

User steering: assets/characters/classes.png is the canonical roster appearance.
Use Warden, Strider (green tunic/red scarf), Hexbinder (purple/silver hair),
Wildborn (green foliage, bone skull mask, gold claws). Discard the Ranger plan.

Delivered armor scope: independent wearable slots with fitted material finishes;
the painted base silhouette remains. No separate full armor shape sets, jewelry
bonuses, or cross-session saving. Mage retains the previously approved full-body
gliding model. Preview recordings document the motion review; final mask fixes
remove glove spill onto belts/scarves and are checked in the final still renders.

Validation: roster combat/systems, all-class equipment/profile persistence,
original Warden six-phase attacks for four weapons, Mage four elements/eruptions/
glide, one-way platforms, portals/minimap, 20 rendered equipment comparisons and
16 finish comparisons pass. Movement/attack contact sheets cover both facings;
720 recorded frames cover idle, forward/reverse movement and mixed-finish combos.
Default project startup now opens the playable forest rather than the old lab.
