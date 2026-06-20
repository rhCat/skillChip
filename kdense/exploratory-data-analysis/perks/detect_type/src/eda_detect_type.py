#!/usr/bin/env python3
"""
eda_detect_type — thin CLI over the vendored eda_analyzer core.

Detects a scientific file's type (extension -> category -> human description)
and gathers basic filesystem metadata. Pure stdlib: no scientific library or
network is touched, so this runs hermetically anywhere python3 is present.

Usage:
    python eda_detect_type.py <filepath> [output.json]

Emits a JSON object: {"basic_info": {...}, "file_type": {...}}.
"""

import json
import sys

import eda_analyzer  # vendored UNCHANGED next to this file


def main():
    if len(sys.argv) < 2:
        print("Usage: python eda_detect_type.py <filepath> [output.json]",
              file=sys.stderr)
        sys.exit(1)

    filepath = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else None

    result = {
        "basic_info": eda_analyzer.get_file_basic_info(filepath),
    }
    extension, category, description = eda_analyzer.detect_file_type(filepath)
    result["file_type"] = {
        "extension": extension,
        "category": category,
        "description": description,
    }

    text = json.dumps(result, indent=2, default=str)
    if output_path:
        with open(output_path, "w") as f:
            f.write(text)
    else:
        print(text)


if __name__ == "__main__":
    main()
