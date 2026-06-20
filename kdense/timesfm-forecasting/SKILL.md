---
skill: timesfm-forecasting
name: TimesFM Forecasting
perks: [check-system, forecast-csv, detect-anomalies, demo-covariates]
---

# timesfm-forecasting — TimesFM Forecasting

Zero-shot univariate time-series forecasting with Google's TimesFM foundation model: a mandatory
preflight resource check, end-to-end CSV forecasting with quantile prediction intervals, two-phase
quantile-band anomaly detection, and a covariate (XReg) workflow demo.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.
`check-system` and `demo-covariates` run fully offline (stdlib / numpy / pandas / matplotlib only).
`forecast-csv` and `detect-anomalies` need `timesfm` + `torch` to produce real forecasts; absent those,
the porter degrades gracefully (empty `{}` report, exit 0) so the contract still holds.

## Perks
| perk | tool | nature |
|---|---|---|
| `check-system` | `check_system` | read-only / safe (RAM/GPU/disk/Python/package preflight → `system_check.json`) |
| `forecast-csv` | `forecast_csv` | local file-producing (`timesfm.forecast` → `forecasts.json`; needs timesfm+torch) |
| `detect-anomalies` | `detect_anomalies` | local file-producing (detrend Z-score + quantile PI → `anomaly_detection.json`; needs timesfm+torch) |
| `demo-covariates` | `demo_covariates` | local file-producing (synthetic XReg data → `sales_with_covariates.csv` + metadata) |

`check-system` never loads the model — it only inspects the host and writes a machine-readable verdict.
`forecast-csv` and `detect-anomalies` download TimesFM weights (~800 MB) from HuggingFace on first use;
run `check-system` first. `demo-covariates` only prints the `forecast_with_covariates()` API (no inference),
so it is hermetic. All four are read-only with respect to remote/live services and are declared
`destructive: false`.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `timesfm-forecasting` — MIT (see LICENSE.txt).
