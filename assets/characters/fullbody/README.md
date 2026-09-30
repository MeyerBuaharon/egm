# Full-body mage — current direction

September 29: the playable Mage permanently wears the purple-and-gold outfit,
hood, gloves and boots. `update_equipment()` now configures that fixed outfit,
independent of inventory. Rings, amulets and body gems change gameplay only.
The appearance picker is now a name editor. Notes below describe the source
art and the superseded wardrobe experiment.

The mage uses complete painted human figures in a simple blue tunic, charcoal
trousers and brown boots. Each frame is one intact full-body drawing. No body
part is rotated, stretched, or assembled at runtime. The entire sprite may bob,
mirror, or lean slightly while hovering. Element selection changes magic only.

`mage-hover.png` contains four full-body idle/glide/air/guard poses. Four
`mage-{fire,ice,wind,earth}.png` sheets each contain three attacks, with three
full-body frames per attack: anticipation, release and recovery. Art was
generated from the approved-style full-body mage reference, requesting a
healthy adult male with long silver hair, normal proportions, the same basic
clothes throughout, connected anatomy, no armor/hood/cape, and transparency.

The previous modular mage body renderer is disabled. Equipment now follows the
complete painted frames: the hood is a registered clothing overlay with a
transparent face opening; robes add navy-and-gold fabric treatment; gloves and
boots recolor their existing painted surfaces while retaining fingers, folds
and silhouettes. Only clothing changes—no body parts are assembled or rotated.
Per-frame head/hand anchors live in `scripts/mage_visual.gd`. Equipment responds
to the same inventory state used by the four visible clothing slots. Removing gear restores the
basic painted outfit. Warden uses his original authored armored renderer again; see `WARDEN-ASSETS.md`.

Validation: `tests/mage_equipment_visual.gd` runs with a real renderer on Xvfb.
It checks that each of the four slots changes character pixels, confirms exact
restoration after removal, and captures equipped casting frames in both facing
directions. `tests/character_equipment.gd` checks pickup/equip/state persistence.

## Forward glide and appearance options

`mage-forward-glide.png` is a separate intact full-body pose: torso leans in the
travel direction, one leg extends and the other bends back. It is mirrored for
leftward travel; idle retains the existing upright pose. Raised-boot and
head/hand anchors keep equipment aligned to this pose.

C opens appearance selection for the currently selected class. Four
hair/skin color presets—Silver, Chestnut, Auburn, Onyx—share the same anatomy,
face and hairstyle. These are palette options, not four newly drawn models.
Name and appearance apply only on confirmation; gameplay pauses during editing.
They persist across map changes/reset in the current session, not across exits.

I opens the inventory. Seven equipment slots are available to each class:
helmet, robes, gloves, boots, two rings and one amulet. F picks up and equips
nearby class gear. Click worn gear to put it in the bag, then click the bag
item to wear it again. Jewelry currently provides equipment state and icons;
it does not add combat stats or painted body overlays. The bag contains only
unequipped owned gear (one starter item per slot).

`tests/mage_customization_visual.gd` captures both flight facings, equipped
flight, the appearance picker and seven-slot inventory with a real renderer.
