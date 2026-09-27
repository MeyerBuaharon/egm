# Underfoot design decisions

## Confirmed direction
- Side-view 2D roguelike ARPG with Dead Cells-inspired graphics and original assets.
- Four classes; class names and concept-sheet designs are proposals, not final choices.
- Level-ups immediately offer three kit choices. Later: drops, chests, and three maps with different enemies.
- Current priority is movement responsiveness and fluidity; keep the movement lab as the test bed.

## Modular appearance and equipment
- Character appearance must change with equipped outfits and items. Do not bake a class into one fixed costume or weapon.
- Separate underlying body/identity, wearable equipment, weapons, and animation/handling.
- Light and heavy gear should visibly affect stance and how items are carried.
- Different weapons require appropriate grips and carry positions (including one-handed and two-handed handling).
- Whether equipment weight changes movement speed, jumps, or other gameplay statistics is undecided. Preserve current controller feel until agreed.
- Concept sheets are visual references, not working sprite atlases or implemented equipment systems.

## Proposed production approach
- Reusable character rigs with modular equipment and weapon attachment points, rendered to pixel-style sprites.
- Validate layering, hand alignment, and weapon occlusion with one character and two contrasting loadouts before expanding all four.
- Avoid pre-rendering every possible equipment combination; evaluate separate synchronized sprite layers versus runtime rendering during the technical art prototype.
