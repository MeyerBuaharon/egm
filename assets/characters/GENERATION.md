# Character sprite source

Generated using the built-in image generation tool from the modular four-class
concept sheet. This is an early art pass, with baked-in base clothing and separate
runtime equipment overlays; it is not yet a fully modular wardrobe.

Final edit prompt:
Convert this exact 32-character sprite atlas to a USABLE GAME ASSET. Remove the ENTIRE colored background and glows: actual transparent alpha outside characters, NOT a dark background, NOT a checkerboard painted into image. Preserve all character pixels, identities, clothing, and poses. Repack sprites into an EXACT 8 columns x 4 rows uniform grid at 1536x1024, cell 192x256. Fit each complete individual sprite within its own cell with 20 pixels clear margins on ALL sides; no feet cross cell rows, no scarf crosses columns. Standing and running sprites must be resized to at most 170 pixels tall, never 220, placed with soles on pixel y=224 of their own cell. Jump poses also bottom aligned y=224. Slide sprites only 85px tall at same y=224 baseline. Especially shrink first row to not cross y=256. Make every row separate with large transparent horizontal gutters. Same order and poses. Output only the transparent game sprite atlas, no text, no decoration, no shadows outside bodies.

Runtime uses alpha bounds and per-class scale to normalize the generated frames.
Atlas: `classes.png`, 8 columns × 4 rows. Columns: idle, run ×4, jump, fall, slide.
Rows: Warden, Strider, Hexbinder, Wildborn.


## Warden-only full-body animation draft

`warden.png` was generated with the imagegen reference-image workflow from the supplied Warden run and burrow boards. Direction: consistent steel armor, enclosed helmet, oversized gold gauntlet, orange-red cape and sheathed sword; side-view pixel art, transparent background, 4×4 atlas. Frames: idle, push-off, six heavy run poses, slide, wall contact, rise, fall, crouch, ground punch, dive, upward emergence. Source: `exec-221d3e2d-2572-4f30-ac33-5233978e9a63.png`.

Frames are registered in `scripts/warden_visual.gd`; this replaces articulated cutouts only for Warden. The costume and sheathed sword are baked into the image. Treat this generated sequence as a draft pending player feedback on gait and arm swing.
