# Level artwork

## Modular forest screen

- Run: `./play.sh res://forest_slice.tscn`.
- Mage movement preview: `./play.sh res://forest_slice.tscn -- --mage`.
  F1 selects Warden, F2 selects Mage (outside combat/burrow). Both classes use
  modular body/gear art; Mage robes stay navy/gold across all elements.
  Mage casting has three hand-pose phases per attack. It hovers 12 visual pixels above
  grounded collision; glide speed 220, acceleration 650, braking 850.
  J casts a three-hit combo. Q cycles Fire/Ice/Wind/Earth.
  Third hits burn, freeze, launch, or half-bury enemies respectively.
  See `../characters/MAGE-ELEMENTS.md` for asset and combat details.
  Checks: `tests/mage_glide.gd`, `tests/mage_elements.gd`.
- Equipment: F picks up and wears nearby gear; I opens Helmet/Robes/Gloves/Boots.
  Four items per class appear near spawn on Forest Edge. Class loadouts persist
  for the session; see `../characters/modular/README.md`.
- Raised platforms are one-way: jump through from below and land on top.
  Down + Space (or S + W) drops through the current platform only; lower
  platforms and the main ground remain solid. Release and press Down again
  to burrow after landing. Drop-through costs no stamina.
- Platform checks: `./play.sh --headless --script tests/forest_platforms.gd`.
- Bottom-center HUD: HP, MP, stamina, level/XP, J attack with combo-step badge,
  Space jump/air-jump count, Shift dash, S/Down burrow, and four independent leveling ability
  slots on 1–4 (unlock at levels 5/10/15/20, currently unassigned). Clockwise recovery rings and time labels follow live
  action state. NEXT marks a buffered combo input. Hover slots for costs/controls.
- Forest resource rules: 100 stamina, 12 per started Warden swing (including misses
  and each air-combo stage), 20 per dash, 10 burrow entry + 14/sec underground.
  Regen is 18/sec after 0.9 sec idle; exhaustion forces emergence. Burrow
  recharges for 2 sec after exiting. Legacy movement labs leave resources off.
- MP is 100 with 8/sec regeneration. Mage combo hits cost 6/8/12 MP;
  dash and burrow retain their stamina costs.
- Rootling defeats award 25 XP once per life. Level 2 requires 100 XP;
  subsequent thresholds increase by 50. Progress persists between maps for
  the session; there is no save file or level-up stat bonus yet. R is a debug
  reset that refills resources and respawns mobs.
- Resource/HUD checks: `./play.sh --headless --script tests/forest_resources.gd`.
- Separate source assets in `forest-kit/`: background, transparent oak, and
  transparent moss/soil terrain. Built with the built-in image generator.
- Terrain uses end caps and a repeating center at consistent 0.4 texture scale;
  collision aligns to source-image y=250. Ground and two raised platforms are
  independent nodes. Background and trees are independent of collision.
- Camera stays at 1×; distant layer moves at 0.8% of player travel.
- Forest Edge's right-side portal enters Deep Grove; Up/E activates only when
  standing nearby, outside combat and burrowing. Deep Grove has a cooler palette,
  a different layout, five mobs, and a left-side return portal. Transitions fade,
  preserve player health, and rebuild map terrain/mobs. Re-entering resets mobs.
- Live upper-right minimap projects current platforms, living mobs, player and
  portal from world coordinates. Yellow is the player, coral is mobs, blue is
  the portal. It updates automatically after map changes.
- Portal checks: `./play.sh --headless --script tests/forest_portals.gd`.
- A/D movement, Space double jump, Shift dash, J attack, S/Down burrow on the
  main floor (release to emerge), R reset. F3 hides scenery to inspect terrain.
- Live footsteps/landing dust. Four independent animated rootling mobs patrol
  the main ground and both platforms; no characters are baked into scenery.
- Rootlings use `assets/mobs/rootling-walk.png`, turn at patrol boundaries,
  wind up and swipe when close, recoil from Warden attacks, and reset with R. Their walk
  cycle uses four registered atlas poses through AnimatedSprite2D. Defeat
  plays a four-pose collapse into bark and leaves followed by a fade-out.
- Mob checks: `./play.sh --headless --script tests/forest_mobs.gd`.
- Check: `./play.sh --headless --script tests/forest_slice.gd` tests surface
  contact, walking dust, burrow entry/travel/exit, and both platform jumps.
- Generation briefs: `forest-kit/PROMPTS.md`.

## Playable concept preview

- Run: `./play.sh res://concept_preview.tscn`.
- Uses `forest-mansion-clean-preview.png` as a temporary full-scene mockup with
  authored collision surfaces and the existing player controller.
- A/D move, Space double jump, Shift dash, J attack, R reset, Tab overview.
- Footstep and landing dust are live effects. Painted warriors and creatures
  have been removed. Water and vegetation remain static; this does not replace
  the modular asset plan.
- The built-in image generator returned 2172 × 724 despite a 3840 × 1280
  request. The preview camera displays it at native pixel scale; it is not 4K.
- Burrowing is unbound because the lab controller assumes a fixed floor.
- Check: `./play.sh --headless --script tests/concept_preview.gd`.

## Forest estate distant background

- File: `forest-estate-bg-far.png` (2048 × 683, user-supplied artwork).
- Integrated as a separate background layer in `levels/f1-forest-edge.json`.
- Preview: `./play.sh -- --forest-preview`.
- Preserves image proportions with a 2× close crop anchored to the lower
  canopy, keeping the distant skyline out of view. Scrolls at 4% of camera
  travel (about 26 screen pixels across the current room).
- This is a background integration preview using existing side-view movement
  and placeholder terrain, not the final isometric map. Nearby tree layers
  are still needed for a true forest-interior view. The full warm-to-dark
  transition is reserved for the longer map.
- Buildings in this image are distant scenery. Playable terrain, trees,
  mansion, and enemies still need separate assets.
