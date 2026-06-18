"""The test slice for gate.py — pins BOTH branches so a mutated gate is always caught.
Exits nonzero on any disagreement, which is how cws_mutate counts a mutant as killed."""
import sys

from gate import authorize

ok = authorize("abc", "abc") is True and authorize("abc", "xyz") is False
sys.exit(0 if ok else 1)
