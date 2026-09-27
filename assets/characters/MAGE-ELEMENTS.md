# Elemental mage

The mage now renders complete full-body figures in basic clothing; see
`fullbody/README.md`. The full-body atlases below remain as references for the
original animation work. Spell artwork and combat timings remain active.

`mage-elements.png` supplies the four hover-idle poses.
`mage-casting-v3.png` is a 1254 × 1254 transparent, 6 × 6 casting atlas:
36 full-body frames, three per attack, three attacks per element.
Read row-major, grouped Fire → Ice → Wind → Earth. Each attack has wind-up,
release, recovery. Damage and spell release occur at 42% of attack duration;
recovery begins at 72%. Measured frame regions, scale and foot anchors live in
`scripts/mage_visual.gd`. Costume and hands are baked into each full-body frame.
The first crowded 9-column attempt was rejected in favor of this layout.

`../effects/mage-spells.png` is a separate 1254 × 1254 transparent painted
VFX atlas: Fire/Ice/Wind/Earth rows, formation/release/impact/dissipation columns.
`scripts/mage_spell_visual.gd` draws moving releases and impacts at hit positions,
including a taller tornado for Wind's finisher. Effects last 0.56 seconds.

## Generation brief

Match the Warden's outlined, shaded fantasy sprite finish, proportions and
ornate gold details. Create an adult silver-haired hooded mage in dark navy
robes, gold bracers and trim, floating with trailing feet. No staff or weapon.
Keep the full character intact and consistent in every cell on transparency.
Fire: red accents, palm jab, sweeping hand, double-palm flame thrust.
Ice: cyan accents, finger flick, crossed-arm gesture, frost sigil finisher.
Wind: jade accents, air slice, low-to-high sweep, both arms raised to launch.
Earth: ochre accents, punch, gathering stones, downward pressing finisher.
No environment, text, labels, borders, or extra characters.

## Gameplay

F2 selects Mage; J attacks; Q cycles elements while idle.
Number keys 1–4 are independent leveling ability slots, currently empty.
Slots unlock at levels 5/10/15/20; specific learned abilities are not implemented.
Each combo costs 6, 8, then 12 MP and deals 6, 7, then 9 direct damage.
Only hit 3 applies the element: Fire burns for 4 s (2 damage each 0.5 s),
Ice freezes movement and attacks for 2 s, Wind launches upward, and Earth
half-buries for 2.5 s with the upper body visible. Airborne Earth targets
fall to a supporting platform before burial. Switching element resets combo.
The mage glides without a running leg cycle. Physics still respect platforms,
jumping, dropping, dashing and burrowing. Spell effects are drawn separately.

Validation: `tests/mage_elements.gd` and `tests/mage_glide.gd`.

## Revised generation brief and validation

Use the original mage as visual reference; keep navy robes, gold trim, silver
hair and elemental cape colors. Make a 6 × 6 transparent sheet containing
wind-up/release/recovery for all 12 attacks, full bodies facing right, generous
cell gutters, fixed root and toe baseline, no spell effects or weapons.
Fire uses palm thrust / sweeping arm / double palm blast; Ice finger flick /
opening crossed arms / double palm press; Wind slicing arm / upward scoop /
raised-arm launch; Earth punch / gathering hands / downward slam.
Generate spell art separately: flowing flame comet and flame crown, faceted ice
spears and frost burst, curling gust and tall tornado, stone eruption and dust.
Four stages per element with transparent gutters, no characters or scenery.

Reviewed a 72-pose rendered contact sheet (all attacks, three frames, both
facings) and in-scene spell captures using an isolated Xvfb display that exited
automatically. No desktop game window was launched. Headless tests cover
release timing, damage once, status effects, Q/ability separation, level unlock,
MP/stamina/XP and mage glide. Animation is intentionally three-frame and stepped.

## Mage eruption and aerial combo

Hold Down/S to phase into the ground with an elemental ground ring. Press J
underground, or release Down/S, to charge an 18 MP eruption. Fire bursts and
burns, Ice erupts and freezes, Wind launches nearby enemies, and Earth pulls
them inward and half-buries them. Each eruption deals 12 direct damage within
155 horizontal / 100 vertical pixels and checks line of sight. Exit clearance
is checked before charging MP. Without enough MP, releasing burrow still exits
normally. Existing stamina drain and burrow recharge remain in effect.

J during eruption buffers air hit 1. In air, J chains three casts for 6/8/12 MP;
the first two slow the mage's fall and juggle targets, then hit 3 applies the
elemental finisher. Aerial body lean uses the existing three-frame casting art.
The new moves reuse painted spell art; no new full-body atlas was generated.
Focused checks: `tests/mage_eruption.gd` plus mage element/glide/platform tests.
