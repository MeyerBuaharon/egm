# Forest biome generation prompts

Four prompts. Run each in a session with image generation, save to the filename
given. Reject and regenerate rather than accepting a near-miss — the character
pipeline lost a day to a "background-only" edit that altered foreground pixels.

---

## 1. `forest-tiles.png` — bright forest tile atlas

Side-view 2D pixel art game tileset, single image 160x64 pixels, exactly 5
columns by 1 row, each cell exactly 32x64 pixels, fully transparent background
(real alpha, not a painted checkerboard, not a dark fill).

Cell 1: a 32x32 grass-and-moss ground surface tile, top-aligned in the cell,
bright sunlit green #8fbf5c along its top two rows fading into dark earth
#2f3a28 below. Must tile seamlessly left-to-right — left and right edges match.
Cell 2: a 32x32 packed-earth-and-root fill tile in #2f3a28, top-aligned, tiling
seamlessly on all four edges, no lit edge, no grass.
Cell 3: a 16x32 vertical bark side-wall tile in #2f3a28 with a flat vertical
face, top-aligned at the left of its cell, tiling seamlessly top-to-bottom.
Cell 4: a 32x18 mossy fallen-branch platform, top-aligned, lit #8fbf5c along its
top edge, tiling seamlessly left-to-right.
Cell 5: a 32x49 forest-loam ground band in #3a3122 with fern and root detail in
#6d8a45, top-aligned, tiling seamlessly left-to-right.

Flat limited palette, hard pixel edges, no anti-aliasing, no gradients, no
outlines around cells, no text, no labels, no grid lines, no drop shadows.

---

## 2. `forest-bg.png` — bright forest background layers

Three separate images, each exactly 1280x800 pixels, side-view 2D pixel art:

`forest-bg-far.png`: a flat vertical gradient from dark green-black #121e18 at
the bottom to a slightly lighter hazy green at the top, with two or three soft
pale sunlight shafts angling down. No trees, no trunks, no ground, no creatures.
Opaque, fills the whole frame.

`forest-bg-mid.png`: a silhouette band of tall straight tree trunks in a single
flat colour slightly lighter than #121e18, trunks running from the bottom edge
upward. Transparent everywhere else. Trunks must NOT cross the horizontal band
between y=200 and y=600 — keep that band clear so platforms stay readable.

`forest-bg-near.png`: dark foreground tree trunks and fern fronds in near-black,
occupying only the leftmost 190 pixels and the rightmost 190 pixels of the
frame. The central 900 pixels must be FULLY TRANSPARENT — no haze, no vignette,
no faint pixels. Transparent background, real alpha.

---

## 3. `blackroot-tiles.png` — dark forest tile atlas

Identical to prompt 1 in layout, size, cell structure and silhouette — the same
forest after it has gone dark. Same 160x64, same 5 cells, same tiling rules.

Change only the palette and the light: surface lit edge becomes cold moonlit
blue #7a8fc4 instead of green, ground body becomes near-black #1a1a22, the loam
band becomes #1d1a1e with pale fungus detail #5a6b8a instead of ferns. Grass on
cell 1 becomes dead brittle stalks. The branch in cell 4 becomes bare and
leafless. Keep the shapes recognisably the same tiles.

---

## 4. `blackroot-bg.png` — dark forest background layers

Same three layers, same sizes and transparency rules as prompt 2.

`blackroot-bg-far.png`: flat vertical gradient from #07090f at the bottom to a
dim cold blue at the top, with one narrow pale moonbeam instead of sun shafts.
`blackroot-bg-mid.png`: the same trunk silhouette arrangement as the forest mid
layer, in near-black, same clear band between y=200 and y=600.
`blackroot-bg-near.png`: the same left and right foreground framing, bare and
leafless, central 900 pixels fully transparent.

---

## Acceptance

- Open each tile atlas and confirm real alpha outside the art, not a dark fill.
- Confirm each `_near` layer's centre is transparent before wiring it in.
- Confirm the forest and blackroot tiles have matching silhouettes — if they do
  not, the four-stage transition will read as four different forests.
