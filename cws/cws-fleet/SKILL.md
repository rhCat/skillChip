---
skill: cws-fleet
name: Cyberware Fleet
perks: [status, deploy, down]
---

# cws-fleet — govern the fleet, scope the subagents

Fleet management as a governed skill: see the fleet at a glance, and **deploy a scoped governance domain
for a subagent** so it cannot go rogue *through the governed channel*.

## What deploy gives a subagent (and what it does not)

`cws-fleet:deploy` spins the subagent its **own govd**, governing its claims against a least-privilege
chip + a per-actor ACL: in-scope claims get a blessed value-free plan, out-of-scope claims are denied
(`acl_skill_denied`). That bounds the subagent's **governed surface** — what it can be blessed to do — so
it can't go rogue through that channel. This is the per-subagent governance domain made concrete.

It is **not, by itself, an OS sandbox**: a *cooperative* body governs decisions while the subagent still
executes steps client-side. For hard **execution confinement** (the subagent runs nothing itself, only
delegates to `exod`), pass `CONFINE=1` to require a *delegated + exod* body. The body's
`exec_mode`/`exod_attached` are always recorded in `deploy.json`, so the confinement status is explicit,
never assumed.

## The containment gates (fail-closed, before any `docker run`)

1. **Strict descent** — the child must sit *strictly lower* on the fleet hierarchy than the deploying node
   (mothership → edge → subagent → … — a node scopes only *below* itself, never sideways or up).
2. **Content-identical subset** — *every* child skill must equal a parent skill **by `skill_sha`** (not by
   leaf name), and the ACL ⊆ child ⊆ parent. A **trojaned or foreign same-name skill cannot ride along** —
   this is what makes `MODE=mount` safe.

Because the check lives in a porter **blessed by hash** (`skill_sha`, folded into `chip_sha`), weakening it
is tamper-evident: `verify_chip` rejects it before govd will serve the skill. govd governs the *decision*;
the operating agent's cooperative-mode porter runs docker; `exod` (delegated mode) never gets docker.

## Perks

| perk | what it does |
|------|--------------|
| `status` | read-only fleet overview — the roster + each body's container state + `/health` (value-free) |
| `deploy` | compose a least-privilege subset chip (cartridge), mint a scoped principal, spin the subagent its own strictly-lower-tier govd (cooperative by default; `CONFINE=1` for delegated+exod), register it |
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
