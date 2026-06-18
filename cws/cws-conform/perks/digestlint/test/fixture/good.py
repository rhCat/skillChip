import hashlib, json

from infra.cwp import canonical


def plan_sha(x):
    return canonical.digest(x)                       # JSON-object hash via the canonical form — OK


def file_hash(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()   # raw-byte file hash — OK, not json.dumps


def dump(x):
    return json.dumps(x, sort_keys=True)             # serialization, never hashed — OK
