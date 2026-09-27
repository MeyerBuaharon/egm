# Forest tileset spec

Two authored biome endpoints — **Forest** (bright) and **Blackroot** (dark).
Stages 2 and 3 are palette interpolations of those two in `levels/biomes.json`,
so only two sets of art exist. If the interpolation reads as muddy once the art
is in, author a third midpoint set rather than four full sets.

## What the renderer needs

`room.gd` draws each `Rect2` as a filled body with a 2 px lit line along its top.
That top line is how a player reads "this is standable" at a glance — every tile
below preserves it. Rects are arbitrary sizes, so tiles must repeat cleanly, not
be fixed-size room pieces.

| Tile | Size | Repeats | Used for |
|---|---|---|---|
| `ground_top` | 32×32 | horizontally | the lit surface row of any platform or floor |
| `ground_fill` | 32×32 | both axes | everything below the surface row |
| `ground_side` | 16×32 | vertically | left/right caps on columns and shaft walls |
| `platform_thin` | 32×18 | horizontally | the 17–20 px floating platforms; a branch or plank, not a slab |
| `floor_band` | 32×49 | horizontally | the bottom strip at y=703 that the Warden burrows through |

All five tile to a single 160×49 strip is wrong — pack them as one atlas,
**160×64, 5 columns × 1 row, each cell 32×64**, tile art top-aligned in its cell,
transparent elsewhere. Register cell rects in code the way `warden_visual.gd`
does; do not trust the generator's packing.

Shafts are ≥60 px wide because the Warden wall-jumps in them, so `ground_side`
must read as a vertical surface, not a rounded edge.

## Backgrounds

Not tiles — three full-width layers per biome, `1280×800`, drawn behind geometry.

| Layer | Parallax | Content |
|---|---|---|
| `bg_far` | 0.15 | sky through canopy; a flat vertical gradient with light shafts. No trunks. |
| `bg_mid` | 0.40 | tree-trunk silhouette band, flat single colour, trunks clearing the middle 400 px of height so platforms stay readable |
| `bg_near` | 1.20 | foreground trunks and ferns at the extreme left and right edges only, transparent centre |

`bg_near` must leave the central 900 px fully transparent or it will hide the
player. This is the layer that most often ruins a generated set — check it first.

## Palette anchors

Take these from `levels/biomes.json`; the art must land on them or the
interpolated middle stages will not match the endpoints.

- Forest — surface `8fbf5c`, body `2f3a28`, floor `3a3122`, sky `121e18`
- Blackroot — surface `7a8fc4`, body `1a1a22`, floor `1d1a1e`, sky `07090f`

The story across the four stages is **warm sunlit green edge → cold moonlit blue
edge**. Keep the two sets structurally identical — same silhouettes, same trunk
spacing — so the change reads as the same forest turning, not a different place.
