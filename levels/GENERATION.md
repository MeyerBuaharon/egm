# Level source

Levels are data, not scenes: one JSON file each, loaded by `load_level()` in
`scripts/room.gd`. TAB cycles them. `.claude/agents/level-designer.md` writes
them; `tests/levels.gd` checks the invariants.

Geometry is drawn as flat themed rectangles, deliberately — it is the Dead Cells
silhouette read, and it costs no art. Generated tileset or parallax artwork can
be layered on later by adding a key to `theme` and reading it in `_draw()`; the
level format does not need to change for that.

## Themes

- **Rootworks** — the original movement lab. Cold slate blue, packed earth floor.
- **Cistern** — flooded stonework, teal. Staggered platforms; the climb dominates.
- **Emberworks** — collapsed forge, black stone and molten orange. Vertical
  chimney shafts; wall-jumping dominates.

No level art has been generated yet. When it is, follow the character pipeline:
one prompt file per theme next to the image, transparent output, and register
frame rects in code rather than trusting the generator's packing.
