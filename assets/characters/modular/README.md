# Modular characters and equipment

**Mage override:** the user rejected the cutout body. Mage now uses complete
painted figures in `../fullbody/`; its old visible equipment layers are disabled.
The equipment state is retained. Warden still uses this modular renderer.

The forest game uses separately painted body/gear parts for Warden and Mage.
`mage-parts.png` and `warden-parts.png` are 1254 × 1254 RGBA atlases generated
from the existing class art. Source images remain intact; measured regions are
in `scripts/modular_character.gd`. The body wears neutral underwear, with no
helmet, robes, gloves or boots baked into it. Mage gear is consistently navy
and gold; Warden gear is charcoal steel, burgundy and gold. Element changes
only affect magic, never the equipment palette.

Atlas order (4 × 4): head, torso, underwear/pelvis, upper arm; forearm, hand,
thigh, shin; bare foot, helmet/hood, robe chest, robe skirt; upper sleeve,
glove, boot, lower sleeve. The Warden sleeve regions exclude painted hands so
removing Gloves really exposes the bare hand. Head and helmet share an anchor.
Sleeves share shoulder/elbow/wrist transforms with the base arms; boots share
ankle transforms. Robes include chest, skirt and sleeves as one equipment slot.

The renderer is a textured cutout rig. Locomotion follows the existing joints;
Mage attack hand targets have wind-up/release/recovery phases for each element,
and Warden weapon grips follow the attack motion. It is not the old baked
full-body atlas. Existing combat logic and spell effects remain in use.
Legacy movement labs retain their original renderer via `modular_equipment`.

## Play

Four items appear near spawn on Forest Edge for the selected class. F picks up
and wears the nearest eligible item. I opens the four-slot equipment panel;
click a slot to remove or re-equip owned gear. F1/F2 change class. Each class has
its own items and loadout. Ownership survives reset, death and map transitions
within the current session; collected items do not respawn on revisiting the
map. There is no disk save or gear stat bonus in this implementation.

## Generation brief

Match the original class's detailed outlined fantasy painting. Produce exactly
16 isolated assembly pieces on a transparent 4 × 4 atlas, generous gutters,
right-facing side/three-quarter perspective, straight vertical limbs with
proximal joint at top and rounded overlap at endpoints. No scenery, labels,
grid, spell effects or baked-in equipment on base body parts. Adult male base:
silver-haired Mage, short dark-haired Warden, warm skin, neutral charcoal
underwear. Separate helmet, sleeveless robe torso, skirt, upper/lower sleeves,
gloves and boots using each class's fixed palette.

## Validation

`tests/character_equipment.gd` exercises both classes, pickup distance, duplicate
rejection, button-driven removal/re-equip, class switching, map persistence,
and invalid requests. Mage glide/eruption/element checks and Warden action checks
pass. Rendered base/partial/full outfits plus 72 locomotion/attack samples across
both facings were inspected on an isolated virtual display. Preview artifacts:
`previews/equipment-models.png` and `previews/modular-motion.png`.

## Upright base-model proportions

The modular body now uses higher hips, longer relaxed legs, a longer upright
torso and a smaller head/helmet ratio. Mage hover and glide keep the spine
nearly vertical and arms relaxed; running lean is reduced for Warden. These
are visual rig changes only; collision and movement values remain unchanged.
The older deeply bent neutral pose is no longer used for modular characters.
