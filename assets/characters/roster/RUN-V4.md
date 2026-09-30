# Full-body run sprites — September 30

User rejected the articulated-leg version in play. This revision uses the Warden approach: intact painted full-body sprite frames, measured roots, four-frame playback and velocity-scaled cadence. Both facings are rendered by flipping whole sprites; no limb deformation is used. Character collision and movement parameters are unchanged.

Assets: `strider-run-v4.png/json`, `wildborn-run-v4.png/json`. Generated with the built-in image tool; PNG pixels/alpha copied unchanged. JSON stores UV clip polygons and manually reviewed registration anchors. Strider playback order is 0,1,3,2; Wildborn is 0,1,2,3. Strider's final frame is airborne, deliberately registered above the floor. Daggers are sheathed during Strider running; combat art retains held weapons.

Sources under `/home/makalu/.codex/generated_images/01a0d330-f594-7e10-b619-876f266ede9f/`:
- Strider: `exec-41bd3210-626a-4f5c-86e0-70b2fabc64cc.png`
- Wildborn: `exec-30ceda18-05fb-4e77-ba63-765a92267fa5.png`

First drafts repeated the original lead; follow-up edits changed bottom-row arm/body counter-swing. Alpha inspection confirmed Wildborn background pixels are transparent despite colored RGB values in those pixels.

## Exact prompts

### striderPrompt

Use case: stylized-concept. Create a production draft full-body RUN sprite atlas for Strider. Image 1 is the Warden animation style/layout reference; image 2 supplies Strider identity only. Exactly FOUR full-body frames in a 2x2 square atlas, transparent background. Match the Warden's intact painted pixel-art sprites and natural heavy forward running motion, but render Strider: athletic healthy black-haired man, red scarf, teal tunic, charcoal trousers, brown boots/gloves, sheathed daggers at belt so arms can pump freely. Same character scale, head proportion and outfit in every cell, facing RIGHT. Reading order: (1) near thigh forward and shin extended toward right contact, far leg behind; (2) near foot underneath hip, far knee passing forward, narrow stance; (3) far leg forward contacting ground, NEAR leg stretches BACK LEFT visibly over far thigh at hip, near arm swings FORWARD; (4) far leg supports below hip, near knee comes forward passing, near arm moves back. Frames 1 and 3 must be opposite anatomical leg leads, not merely bent vs straight. Full body animation includes opposing arm swing, torso rotation and scarf follow-through. Stable pelvis registration and shared ground baseline within each equal cell. Generous transparent gutters, no detached parts, no labels, no shadows, no ground, no weapons in hands. All bodies fully contained.

### striderCorrection

Edit this Strider atlas. Keep TOP ROW exactly as reference. REDRAW BOTH BOTTOM figures with the opposite side of the body swinging forward. The arm CLOSEST TO CAMERA (currently stretched toward the left/back) must instead have elbow at front of chest and clenched fist reaching FORWARD RIGHT past the chin. The OTHER arm must reach BACK LEFT. In BOTTOM LEFT sprite the nearest leg must run BACK LEFT from pelvis, covering the far thigh where legs cross, near boot at far left of body; far leg extends forward RIGHT but is occluded by near thigh at pelvis. In BOTTOM RIGHT, same near arm forward, near thigh bent backward with heel high BEHIND buttock, far leg planted under torso. Whole torso rotates with counter-swing, face still faces RIGHT. This is two opposite-stride full-body poses, not the same arms held back. Maintain face, scarf, outfit, scale, two by two layout, transparent background. Make the changed foreground arm position unmistakable.

### wildbornPrompt

Use case: stylized-concept. Full-body RUN animation atlas for Wildborn, using image 1 Warden for painted pixel sprite finish and 2x2 layout, image 2 for Wildborn identity. Exactly FOUR intact full-body sprites, facing RIGHT, transparent background. Wildborn has bird skull mask, swept green leaf mane, dark green muscular body, bone shoulder/knee ornaments, brown belt, yellow claws and clawed feet. Match existing proportions and colors, no redesign. Animate whole body with vigorous natural biped running and opposing arms, mane follow through. Top left: near leg contacts far forward RIGHT, distant foot kicks back LEFT. Top right: near foot supports under hip while FAR knee swings ahead. Bottom left: FAR leg contacts forward RIGHT, NEAR thigh crosses over it from hip toward BACK LEFT with near heel raised behind, near claw arm swings FORWARD. Bottom right: FAR foot supports below hip while NEAR knee swings ahead and near arm moves back. Opposite anatomical legs lead in frames 1 and 3, clear overlap order proves the swap. Frame 2 and 4 are narrow passing poses. Consistent body size/pelvis x/ground baseline in equal cells, generous transparent gutters. No labels, no ground, no shadow, no detached limbs, no effects, no other characters.

### wildbornCorrection

Correct this Wildborn run atlas into transparent game sprites. Remove ALL background completely to real alpha, no colored haze. Preserve top row poses. Completely REDRAW BOTTOM ROW body counter-swing: nearest arm on viewer side now swings FORWARD RIGHT, huge near claw reaching past chest below beak, elbow in front of body. Other arm swings BACK LEFT, partly hidden. BOTTOM LEFT near thigh extends BACK LEFT across front of hip and far thigh, near heel lifted behind left, far leg reaches RIGHT ground contact. BOTTOM RIGHT near leg heel lifts high BEHIND hip, far leg is planted straight beneath body. Keep skull face looking RIGHT, green mane, bone decorations, same scale. Need unmistakably opposite arm and leg leads compared to top row. Four full-body intact figures with generous gutters, 2x2, no detached pieces, no ground, no text.

### wildbornAlpha

Use case: background-extraction. Remove the black, green and brown blurred background from this four-pose sprite sheet. Keep ONLY the four Wildborn figures with their original crisp outlines. Everything surrounding and between the characters, and all gaps between legs/arms, must be fully TRANSPARENT alpha=0. Preserve every figure, colors, anatomy, poses, locations and size exactly. Do not add floor shadows, glow, haze, gradients or new background. Output an actual RGBA transparent sprite atlas.

