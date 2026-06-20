#!/usr/bin/env bash
# match_skills — rank each cluster against the sibling SKILL.md descriptions in SKILLS_DIR using
# the vendored match_skills.py (load_skill_descriptions + top_k_matches, cosine over embeddings).
# Prefers local sentence-transformers (the production embedder, no data egress); if that heavy lib
# is absent it falls back to a deterministic stdlib hashing embedder so ranking still runs offline.
# Reads CLUSTERS (clusters.json from the cluster perk) + SKILLS_DIR; TOP_K optional (default 5).
# Writes matches.json under RECORD_STORE. Structured-JSON audit line on stdout.
set -uo pipefail
: "${CLUSTERS:?CLUSTERS (path to clusters.json) is required}"
: "${SKILLS_DIR:?SKILLS_DIR (path to skills/ directory) is required}"
: "${RECORD_STORE:?RECORD_STORE is required}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/matches.json"
: > "$OUT"

TOP_K="${TOP_K:-5}"

PYTHONPATH="$HERE" python3 - \
  "$CLUSTERS" "$SKILLS_DIR" "$OUT" "$TOP_K" <<'PY' || true
import hashlib, json, sys
from pathlib import Path
from match_skills import load_skill_descriptions, top_k_matches

clusters_path, skills_dir, dst, top_k = sys.argv[1:5]
top_k = int(top_k)


def _embedder():
    """Production path: local sentence-transformers. Fallback: deterministic hashing
    bag-of-words vector (stdlib only) so cosine ranking still runs offline."""
    try:
        from sentence_transformers import SentenceTransformer
        model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")
        return lambda text: list(map(float, model.encode(text)))
    except Exception:
        DIM = 256

        def hashed(text):
            vec = [0.0] * DIM
            for tok in (text or "").lower().split():
                h = int(hashlib.md5(tok.encode()).hexdigest(), 16)
                vec[h % DIM] += 1.0
            return vec

        return hashed


def _cluster_query(c):
    parts = ["apps: " + ", ".join(c.get("apps", []))]
    if c.get("example_titles"):
        parts.append("titles: " + "; ".join(c["example_titles"]))
    return " | ".join(parts)


try:
    payload = json.load(open(clusters_path))
except Exception:
    payload = {}
clusters = payload.get("clusters", payload if isinstance(payload, list) else [])

skills = load_skill_descriptions(Path(skills_dir))
embedder = _embedder()

results = []
for c in clusters:
    query = _cluster_query(c)
    try:
        top_k_list = top_k_matches(query, skills, embedder=embedder, k=top_k)
    except Exception:
        top_k_list = []
    results.append({"apps": c.get("apps", []), "top_k": top_k_list})

with open(dst, "w") as fh:
    json.dump({"skill_count": len(skills), "matches": results}, fh, indent=2)
PY

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"match_skills","status":"ok","matches":"%s"}\n' "$OUT"
