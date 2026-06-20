---
skill: hsb-flash
name: HSB FPGA Flash
perks: [flash, local-manifest]
---

# hsb-flash — HSB FPGA Flash

Flash (upgrade or downgrade) the FPGA firmware on an HSB board connected to a remote NVIDIA devkit. Supports HSB Lattice boards (FPGA 2407/2412/2507/2510) and Leopard Imaging VB1940 "all-in-one" cameras (FPGA 2507/2510), using release-specific YAML manifests and board-type-specific program commands.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `flash` | `make_manifest` | destructive (permanently rewrites FPGA firmware; can brick the device) |
| `local-manifest` | `local_manifest` | read-only (builds a manifest YAML from local bit files; no NGC fetch, no flash) |

The `flash` perk prepares the version-matching manifest YAML (via `make_manifest`, which fetches the bitstream metadata from NGC) and then drives the per-board flash procedure on the remote devkit. Lattice and VB1940 commands must NEVER be mixed (`program_lattice_cpnx100` vs `program_leopard_cpnx100`) — the wrong tool can permanently brick the device. Because it rewrites firmware over SSH and power-cycles hardware, the perk is declared `destructive: true` and the executor gates it accordingly.

The `local-manifest` perk (via `local_manifest`) is the offline counterpart to `make_manifest`: instead of fetching bitstream metadata from NGC, it builds the manifest YAML from **local** bit files (CPNX, CLNX, and/or Stratix-10 `.rpd`), measuring each file's size and MD5 and recording the strategy. It is read-only — it never downloads or flashes anything — and the caller is trusted to ensure each bit file is correct for the target device.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars (VERSION, optional MANIFEST, SSH_TARGET, REMOTE_ROOT, BOARD_TYPE) + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `hsb-flash` (Apache-2.0).
