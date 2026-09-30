# Forest-to-mansion content loop

User authorized ongoing development on September 29, 2026. Finish and visually review running first; then implement map items, a passive tree, a boss, and connected content. Do not open a desktop game window at completion. Render tests use isolated Xvfb windows.

## Acceptance

- Rebuilt Strider/Wildborn run: actual alternating feet, stable joins and ground contacts, both facings and gameplay-scale motion review.
- Three connected maps from forest edge to the mansion gate, with readable objectives and useful loot.
- Passive tree with prerequisites, earned points and real combat/movement effects.
- Distinct boss with visible attack warnings, dodgeable attacks, an escalation phase, death and a reward.
- Loot/tree/boss checks plus existing combat/resource regression coverage.

Run implementation and art prompts: assets/characters/roster/RUN-RIG.md.

## Completed September 30

- Rebuilt Strider/Wildborn locomotion with actual near/far leg swaps, stable rigid
  joints, distance-matched contacts and separate recovery arcs. Reviewed both
  facings at gameplay and close-up scales; eight-phase contact sheets and videos.
- Three connected maps, minimap loot markers, objectives, chests, memory shards,
  embers, tonics and healing wayshrines. F prompts select the nearest collectible.
- Nine purchasable passives across three prerequisite branches; P opens the tree.
  Level-ups and memories grant points; embers are the second purchase currency.
- Hollow Regent boss: root warnings, ground slam, capped adds, faster half-health
  phase, checkpoint reset and a persistent collectible seal reward.
- Versioned JSON saves retain progression, claimed loot, class names and loadouts.
  Atomic writes and previous-file backup; invalid files do not silently overwrite
  player progress. Resume returns to the saved map entrance with full resources.

## Validation

`run_rig_behavior`, `forest_campaign`, `boss_combat`, `forest_portals`,
`character_equipment`, `gem_equipment`, `roster_systems`, `mage_elements`,
`warden_restore`, `forest_resources` and `forest_platforms` checks passed.
Boss combat coverage exercises all four classes and all four styles each.
`boss_playthrough` won using normal movement/attack inputs in 87.3 simulated
seconds with zero deaths. `campaign_save_roundtrip` saved in one process and
restored in another. Visual fixtures captured the tree, maps, warnings, eruption
and victory using an isolated virtual display, without opening a desktop game.

Controls: F loot/shrine, P passive tree, I jewelry/gems, Q style, J attack,
1 Nova / 2 Renewal when equipped, Up/E portal. Other controls are in README.md.

## Practical limits

The articulated-leg run was subsequently rejected by the user and replaced
with four full-body sprite poses; see assets/characters/roster/RUN-V4.md.
The boss uses one painted sprite with procedural motion/effects, not a bespoke
multi-frame attack atlas. This campaign ends at the mansion gate; the interior
is not implemented. Keys 3–4 remain future ability slots.

Art provenance and exact prompts: assets/levels/forest-kit/CAMPAIGN-ASSETS.md.
