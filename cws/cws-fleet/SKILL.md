---
skill: cws-fleet
name: Cyberware Fleet
perks: [status, deploy, down]
---

# cws-fleet — govern the fleet, contain the subagents

Fleet management as a governed skill: see the fleet at a glance, and **deploy a scoped, contained governed
body for a subagent** so it cannot go rogue.

## The anti-rogue property

A confined body (`exod`, delegated mode) has **no docker, no host socket, no `CAP_SYS_ADMIN`** — so a
subagent **cannot self-spawn** a body. The **only** path to a governed body is `cws-fleet:deploy`, and that
perk, fail-closed and **before any `docker run`**:

1. refuses any spawn that is not **strictly lower** on the fleet hierarchy than the deploying node
   (mothership → edge → subagent → … — a node contains only *below* itself, never sideways or up); and
2. refuses any child whose **chip or ACL is not a subset** of the parent's — least-privilege by
   construction: the body carries exactly the named skills and the principal may invoke only those.

Because the containment check lives in a porter that is **blessed by hash** (`skill_sha`, folded into
`chip_sha`), weakening it is tamper-evident: `verify_chip` rejects it before govd will serve the skill.
govd governs the *decision*; the operating agent's cooperative-mode porter runs docker; `exod` never gets
docker. Privilege stays out of cyberware; the hierarchy is a real boundary, not a label.

## Perks

| perk | what it does |
|------|--------------|
| `status` | read-only fleet overview — the roster + each body's container state + `/health` (value-free) |
| `deploy` | compose a least-privilege subset chip (cartridge), mint a scoped principal, spin a strictly-lower-tier govd+exod body, register it |
| `down` | stop + remove a body container and deregister it (the durable ledger mirror — its provenance — is preserved) |

## deploy — scoping a subagent body

Two ways to source the body's chip:

- **`MODE=compose`** (least-privilege): pass `SKILLS` (e.g. `"fs http"`); `deploy` compiles a subset
  cartridge from `PARENT_CHIP_DIR` containing exactly those skills, then mounts it.
- **`MODE=mount`**: pass a ready `SKILL_DIR`; `deploy` cartridge-verifies it and mounts it as-is.

The scoped principal is minted from `ACL_SKILLS` (the skills the body's actor may invoke) and a bearer token
supplied **only** as a `TOKEN_FILE` pointer — its sha256 is stored in the registry, the value never is. The
body is then governed exactly like any node: in-scope claims get a blessed value-free plan; out-of-scope
claims → `acl_skill_denied`. `down` later tears the container down; its runs persist in the durable mirror.

The refusal reasons (`fleet_tier_not_strictly_lower`, `acl_not_subset`, `chip_not_subset`, …) and the full
var list are in each perk's `metadata.json`. The tier-containment decision is the pure, unit-tested core
`check_containment` in `perks/deploy/src/fleet_deploy.py`.
