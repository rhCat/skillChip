# skillChip

The **feed-stock cartridge** for [cyberware](https://github.com/rhCat/cyberware) — a registry of governed
skills. cyberware is the engine; this is the cartridge it reads. Each skill is a self-contained, verifiable
package (blueprint · perks · contracts · per-file `index.json` · in-skill `test/`). The chip is
self-describing: `index.json` at the root is the manifest (every skill + its `skill_sha` + a roll-up
`chip_sha`) that cyberware retrieves to discover and verify the whole chip.

Vendored into cyberware as the `skillChip/` git submodule; the engine locates it by `$CYBERWARE_SKILLCHIP`
or the bundled default. Swap the chip, same engine governs a different feed-stock.

Generated/maintained with cyberware's `infra.tool` (`skill_index`, `scaffold`, `visualize`, `skilltest`).

## The cartridge model — the manifest is the load set

`index.json` is **authoritative**: what loads is what the manifest *declares* (its `skills[]` roster +
`chip_sha`), not whatever directory happens to sit on disk. A skill is loadable only if it is **permitted**
(in the manifest) **and present** (on disk) — so a stray dir scaffolded into the tree never loads, never
enters the manifest, and never pollutes discovery. The manifest carries `"version"` and `"cartridge"`
(`false` for this full dev feed-stock; `true` for a compiled cut).

Roster membership is changed **explicitly**, never auto-absorbed:

```sh
python3 -m infra.tool.skill_index --chip                 # re-pin the permitted roster (refresh shas)
python3 -m infra.tool.skill_index --chip --add <skill>   # permit a new skill (must be present)
python3 -m infra.tool.skill_index --chip --remove <skill>
python3 -m infra.tool.skill_index --chip --scan          # seed a fresh chip's roster from disk (bootstrap)
python3 -m infra.tool.skill_index --check                # files match indexes + manifest
```

**Compile a cartridge** — cut a standalone chip of exactly the skills you declare (one = a single-skill
cartridge), with a fresh root manifest; govd then needs only that skill + the root `chip_sha`:

```sh
python3 -m infra.tool.cartridge --compile cws-release --out /path/to/cartridge   # one skill (or several)
python3 -m infra.tool.cartridge --verify /path/to/cartridge                      # present + permitted + sha
```

An undeclared dir in a compiled cartridge cannot ride along — it is not in the cartridge's manifest.
