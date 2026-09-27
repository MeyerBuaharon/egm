# Full-body mage — current direction

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

The previous modular mage renderer is disabled. Inventory ownership is retained,
but its old equipment artwork does not fit this new body: independent visible
mage equipment needs matching full-body clothing variants. Warden still uses
its existing equipment renderer. The rejected crowded 36-frame draft is not used.
