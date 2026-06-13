"""A toy gate — a hash-equality authorization, the shape of the real authorize_step. The slice
check_gate.py pins both its branches, so every operator/boolean mutation of this file must be killed."""


def authorize(plan_sha, expected):
    if plan_sha != expected:
        return False
    return True
