---
skill: vss-manage-alerts
name: VSS Alert Management
perks: [notify, render-notification, subscribe-create, subscribe-list, subscribe-stop]
---

# vss-manage-alerts — VSS Alert Management

Operate the VSS alert pipeline: run the multi-backend incident-notification webhook relay that
fans VSS incidents out to Slack (and/or the OpenClaw Dashboard), with companion references for
Alert-Bridge subscription CRUD and incident queries.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `notify` | `server` | destructive (starts a long-lived webhook server that posts live incidents to remote Slack / Dashboard) |
| `render-notification` | `render_notification` | read-only (offline — renders an incident into Slack blocks + Dashboard markdown, sends nothing) |
| `subscribe-create` | `subscribe_create` | create a realtime alert rule on Alert Bridge (`POST /api/v1/realtime`) — Workflow D |
| `subscribe-list` | `subscribe_list` | read-only (lists active realtime alert rules — `GET /api/v1/realtime`) — Workflow D |
| `subscribe-stop` | `subscribe_stop` | destructive (deletes/stops a realtime alert rule by ID — `DELETE /api/v1/realtime/<id>`) — Workflow D |

The `notify` perk launches `server.py`, the FastAPI relay that receives VSS incident webhooks on
`POST /webhook/alert-notify` and pushes formatted notifications to every configured backend. It is
`destructive: true` because it runs a network service and forwards live incident data to remote
services; the executor gates it accordingly.

`render-notification` exercises the relay's *pure* formatters (`build_slack_blocks`,
`build_dashboard_message`) offline: given an incident JSON it produces the exact Slack Block Kit
payload and Dashboard markdown the live relay would post — useful for previewing/validating a
notification without a token or running server.

The three `subscribe-*` perks are the Alert-Bridge realtime subscription CRUD (Workflow D, VLM
real-time mode only): `subscribe-create` POSTs the canonical rule payload, `subscribe-list` GETs the
rule inventory (an empty list is a valid success), and `subscribe-stop` DELETEs a rule by UUID. The
skill's user-facing yes/no stop confirmation must be satisfied before invoking `subscribe-stop`
(it ALWAYS applies, including under autonomous execution). All call Alert Bridge directly at
`http://<HOST_IP>:9080` — never via the VSS Agent `/generate` endpoint — and degrade gracefully when
the endpoint is unreachable.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars (`SLACK_BOT_TOKEN`, `SLACK_CHANNEL_ID`,
`VST_ENDPOINT`) + `record_store`, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `vss-manage-alerts` (Apache-2.0).
