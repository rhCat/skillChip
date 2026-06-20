# build fixture

A tiny non-git directory. `git log` against it fails, so the porter degrades
gracefully (pre-created `summary.json` falls back to `{}`) and still exits 0.
