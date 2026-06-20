---
skill: nemo-retriever
name: NeMo Retriever
perks: [query, fast-path]
---

# nemo-retriever — NeMo Retriever

Search, quote, filter, and aggregate across a document corpus (PDFs, images, Office, HTML/TXT, audio, video) indexed by the NVIDIA NeMo Retriever library — read-only. This cartridge governs the corpus keyword/regex search over the already-built LanceDB index.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `query` | `grep_corpus` | read-only / safe (case-insensitive regex scan over the LanceDB table; no PDF re-extraction, no index mutation) |
| `fast-path` | `filename_fast_path` | read-only / safe (when the query names a PDF, extract+rank its pages by query-token frequency via bundled pdfium; no index mutation) |

The `query` perk runs `grep_corpus.py` against the LanceDB table that `retriever ingest` already built, emitting `<pdf>:p<page>:<type>:  ...snippet...` per hit. It never re-reads source documents and never mutates the index.

The `fast-path` perk runs `filename_fast_path.py`: when the query string literally contains a PDF basename in the corpus folder, it extracts that PDF's pages via the retriever's bundled pdfium stage, ranks pages by summed query-token frequency, and emits a top-10 ranking (`{doc_id, page_number, rank}`) plus the top page's raw text. It emits `NO_MATCH` when no basename is named and never mutates the PDFs or any index.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `nemo-retriever` (Apache-2.0).
