# skillChip

The **feed-stock cartridge** for [cyberware](https://github.com/rhCat/cyberware) — a registry of governed
skills. cyberware is the engine; this is the cartridge it reads. Each skill is a self-contained, verifiable
package (blueprint · perks · contracts · per-file `index.json` · in-skill `test/`). The chip is
self-describing: `index.json` at the root is the manifest (every skill + its `skill_sha` + a roll-up
`chip_sha`) that cyberware retrieves to discover and verify the whole chip.

Vendored into cyberware as the `skillChip/` git submodule; the engine locates it by `$CYBERWARE_SKILLCHIP`
or the bundled default. Swap the chip, same engine governs a different feed-stock.

Generated/maintained with cyberware's `infra.tool` (`skill_index`, `scaffold`, `visualize`, `skilltest`).
