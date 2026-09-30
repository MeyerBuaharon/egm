# Run-cycle review history

## Current: full-body sprites, following user review

The user rejected the articulated legs as goofy in actual play. Replaced them
with generated intact full-body sequences using the Warden sheet as reference.
See `assets/characters/roster/RUN-V4.md` for exact prompts, anchors and order.
Four-frame playback is deliberately comparable to Warden; this is not an
eight-frame hand-authored production animation.

## Previous implementation: rebuilt articulated legs

September 30: replaced the rejected run-frame selection with separate painted
thigh, shin and foot components, rigid two-bone joints, fixed near/far ordering,
and half-cycle-offset tracks. Ground contacts match travel distance. Reviewed
eight phases, both directions and normal/slow motion at close and gameplay scale.
The original upper body remains an armed pose, without independent arm swing.

Implementation and exact art prompts: `assets/characters/roster/RUN-RIG.md`.
Preview: `previews/rebuilt-run.mp4`; checks: `tests/run_rig_behavior.gd`.
The failed approaches below are retained as history, not current behavior.

## Previous status: unresolved after user motion review

The run-v2 four-frame selection still reads as the same leading leg bending and extending. Knee-color changes do not establish anatomical leg swaps. The earlier acceptance below was incorrect. Frame-count tests only verify playback coverage, not correct anatomy.

Two additional built-in image-generation drafts (a six-pose Strider sheet and a single opposite-contact request) again repeated the original leg arrangement. Both were rejected; no new artwork or animation code was integrated. Strider and Wildborn still need authored opposite-leg contacts and passing poses, then visual review in motion. Existing gameplay and models are unchanged.

## Earlier review (superseded)

September 29 update: replaced the six-pose locomotion selection with four selected
alternating contact/passing poses from the new run-v2 atlases. See
assets/characters/roster/RUN-V2.md for accepted frames and prompts. The experiments
below were rejected; no mesh deformation is used in the current characters.

Strider and Wildborn currently repeat the same leading anatomical leg in their six run poses. Previous visual validation did not catch this. Playback-rate changes do not resolve it.

Correction attempts were reviewed and rejected: generated eight-frame cycles still repeated the lead leg; a connected-mesh leg deformation alternated the feet but visibly distorted boots and tunic. The mesh experiment was removed, and the original renderer was restored. Headless startup passes. No game process remains open.

No replacement PNG has been integrated. A finished correction requires an eight-pose cycle with distinct near-leg and far-leg contacts, narrow passing poses, stable foot/hip registration, and both-facing equipped motion review.

The following built-in image-generation prompts produced rejected review drafts, retained only in the generation output directory:

## strider

Use case: precise-object-edit. Create a replacement GAME RUN-CYCLE SPRITE SHEET using the attached character as exact visual identity reference. Transparent background. Exactly EIGHT intact full-body sprites in a 4 column by 2 row grid, facing RIGHT in every cell. Preserve character proportions, costume, painting style, face and equipment. This must be a genuine biomechanical TWO-STEP loop, not eight variations of the same leading leg. Near leg is visible over far leg at overlaps; far leg shaded darker. Frame order reading left to right: 1 near leg stretched FORWARD heel contact, far leg stretched BACK; 2 near foot plants under forward knee, far heel lifts behind; 3 near leg straight under hip supporting weight, far knee swings FORWARD past it; 4 near leg pushes BACK, far knee high FORWARD, airborne; 5 far leg stretched FORWARD landing, near leg stretched BACK visibly crossing in front; 6 far foot plants ahead, near heel lifts behind; 7 far leg supports below hip, near knee swings FORWARD past it; 8 far leg pushes BACK, near knee high FORWARD airborne. Frames 1 and 5 MUST swap which anatomical leg is forward. Crucially frames 3 and 7 are NARROW passing poses with knees close together, not wide split stances. Counter-swing arms. Fixed hip x at each cell center, identical scale and ground baseline; preserve natural small vertical bounce. Each whole figure fully contained in its cell, large transparent gutters. No labels or effects. Do not mirror entire body between frames. Strider: black spiky hair, red scarf trailing LEFT, teal sleeveless tunic, charcoal pants, leather gloves and brown boots, two short curved daggers held in hands. Preserve healthy athletic human anatomy.

## wildborn

Use case: precise-object-edit. Create a replacement GAME RUN-CYCLE SPRITE SHEET using the attached character as exact visual identity reference. Transparent background. Exactly EIGHT intact full-body sprites in a 4 column by 2 row grid, facing RIGHT in every cell. Preserve character proportions, costume, painting style, face and equipment. This must be a genuine biomechanical TWO-STEP loop, not eight variations of the same leading leg. Near leg is visible over far leg at overlaps; far leg shaded darker. Frame order reading left to right: 1 near leg stretched FORWARD heel contact, far leg stretched BACK; 2 near foot plants under forward knee, far heel lifts behind; 3 near leg straight under hip supporting weight, far knee swings FORWARD past it; 4 near leg pushes BACK, far knee high FORWARD, airborne; 5 far leg stretched FORWARD landing, near leg stretched BACK visibly crossing in front; 6 far foot plants ahead, near heel lifts behind; 7 far leg supports below hip, near knee swings FORWARD past it; 8 far leg pushes BACK, near knee high FORWARD airborne. Frames 1 and 5 MUST swap which anatomical leg is forward. Crucially frames 3 and 7 are NARROW passing poses with knees close together, not wide split stances. Counter-swing arms. Fixed hip x at each cell center, identical scale and ground baseline; preserve natural small vertical bounce. Each whole figure fully contained in its cell, large transparent gutters. No labels or effects. Do not mirror entire body between frames. Wildborn: green scaled biped with long green leaf/feather mantle trailing LEFT, ivory animal skull mask, ivory shoulder/knee bone plates, gold claws and clawed feet. Clearly alternating bipedal legs, not a hopping or galloping creature.

## run_opposite_prompt

Edit this sprite sheet. Keep the TOP ROW completely unchanged. Correct ONLY the four BOTTOM ROW sprites' legs to show the OPPOSITE HALF STRIDE. All characters still face RIGHT. In bottom-left pose: the leg attached to the LEFT side of the belt on screen (the near/camera-side hip) must extend diagonally across the body toward the RIGHT with its foot in front. The other leg goes BACK LEFT, behind the near thigh. The near knee must occlude the far thigh. This crossing is the exact opposite of the top-left pose, whose near thigh goes back-left. Bottom row second: near thigh points FORWARD-RIGHT with near foot planted ahead, far shin folds BACK-LEFT. Bottom row third: near leg straight under hip, far knee lifted forward, dark far knee behind near thigh. Bottom row fourth: near leg stretches BACK-LEFT and far knee is lifted forward-RIGHT. Preserve the upper bodies, weapons, costume, original style, transparent background, grid and scales. Do not redraw the same thigh direction as the top row. An actual alternating-leg run cycle.

## run_guide_prompt

Create a transparent 4-column 2-row eight-frame game run sprite sheet. Image 1 is the EXACT LEG POSE and OCCLUSION guide: recreate each of its eight skeleton poses faithfully as the fully painted character in image 2. Image 2 is only appearance/costume reference, do NOT copy its leg poses. Anatomical orange guide leg is near the camera and must be painted IN FRONT wherever legs overlap; blue guide leg is behind. Use original natural costume colors, NOT orange/blue diagram colors. Keep narrow passing poses 2,3,6,7 and opposite leading legs on frames1 versus5. Near leg goes FORWARD on frame1, BACK on frame5. True side view facing RIGHT throughout, fixed torso/hip location, fixed scale. Preserve Strider black hair, red scarf, green tunic, brown boots, curved daggers and detailed pixel-painted style. Full connected body, no dismembered pieces. Generous transparent cell padding. No labels, floor lines, diagram marks or text.

## near_leg_prompt

Draw ONE full-body Strider sprite on transparent background, using reference for identity only. Black hair, red scarf, teal sleeveless tunic, brown gloves/boots, two daggers. Facing RIGHT in exactly side profile. Sprint pose with CAMERA-SIDE LEG thrust strongly FORWARD-RIGHT: its thigh visibly crosses IN FRONT of the lower tunic, and its knee is raised in front of belly at waist height; shin bends straight DOWN from that forward knee. The OTHER, distant leg stretches BACK-LEFT and is darker and partially occluded behind the foreground thigh. Near/foreground thigh must lie OVER the front of tunic, not disappear behind it. This is the OPPOSITE leg lead from the reference running poses. Entire body healthy athletic and intact, same proportions and pixel-painted style. No grid, no other figures, no text. Keep feet pointing right.

## leg_mirror_prompt

Edit ONLY the lower body below the belt. HORIZONTALLY MIRROR THE LEGS around the pelvis center: the large raised knee currently on the RIGHT must move to the LEFT, the long trailing leg currently on the LEFT must move to the RIGHT. The torso, arms, hair, face, scarf and daggers MUST remain exactly unchanged and facing right. Then turn just the boots' toes back toward the RIGHT, without undoing the leg swap. This intentionally produces a changed stride with the right-side leg extending forward and low, while the left-side knee bends back. Preserve pixel art, natural clothing, connected pelvis and transparency. One full-body sprite.
