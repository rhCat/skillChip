# cyberware quickstart

Install the client, then make your first governed claim.

## Install
    export GOVD=http://127.0.0.1:5773
    ./govd-client --url $GOVD --discover

## Your first claim
Copy this task-ledger and run it:

```json
{ "skill": "fs", "perk": "find_large", "record_store": "/tmp/out", "vars": { "SEARCH_DIR": "/data", "MIN_SIZE": "200M" } }
```

Then read the verdict.
