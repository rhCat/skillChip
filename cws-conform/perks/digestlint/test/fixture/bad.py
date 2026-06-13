import hashlib, json


def plan_sha(x):                                      # shape 1: json.dumps nested in the hash call
    return hashlib.sha256(json.dumps(x, sort_keys=True).encode()).hexdigest()


def chip_sha(x):                                      # shape 2: json.dumps flows through a variable
    canon = json.dumps(x, sort_keys=True)
    return hashlib.sha256(canon.encode()).hexdigest()


def _canon(o):                                        # shape 3: json.dumps hidden behind a helper
    return json.dumps(o, sort_keys=True).encode()


def ledger_hash(x):
    return hashlib.sha256(_canon(x)).hexdigest()
