#!/usr/bin/env python3
"""
eda_analyze — thin CLI over the vendored eda_analyzer core.

Runs the full EDA pipeline (detect type -> load format reference -> format-
specific data analysis -> markdown report) and writes the report. This is the
main operation; data analysis depends on the file type and may need numpy /
pandas / biopython / pillow / h5py. The core degrades gracefully: when a
required library is missing it records the error in the report rather than
crashing, so a governed run still produces the markdown output.

Usage:
    python eda_analyze.py <filepath> [output.md]

The references/*.md folder vendored next to this script is wired into the core
loader so the report's Format Reference section resolves offline.
"""

import os
import sys

import eda_analyzer  # vendored UNCHANGED next to this file

HERE = os.path.dirname(os.path.abspath(__file__))

CATEGORY_FILES = {
    "chemistry_molecular": "chemistry_molecular_formats.md",
    "bioinformatics_genomics": "bioinformatics_genomics_formats.md",
    "microscopy_imaging": "microscopy_imaging_formats.md",
    "spectroscopy_analytical": "spectroscopy_analytical_formats.md",
    "proteomics_metabolomics": "proteomics_metabolomics_formats.md",
    "general_scientific": "general_scientific_formats.md",
}


def _load_reference_info(category, extension):
    """Replacement loader pointing at the vendored references/ next to us."""
    import re

    ref_name = CATEGORY_FILES.get(category)
    if not ref_name:
        return None
    ref_file = os.path.join(HERE, "references", ref_name)
    if not os.path.exists(ref_file):
        return None
    try:
        with open(ref_file, "r") as f:
            content = f.read()
        pattern = rf"### \.{extension}[^#]*?(?=###|\Z)"
        match = re.search(pattern, content, re.IGNORECASE | re.DOTALL)
        if match:
            return {"raw_section": match.group(0), "reference_file": ref_name}
    except Exception as e:  # pragma: no cover - defensive
        print(f"Error loading reference: {e}", file=sys.stderr)
    return None


# Wire the vendored references into the unchanged core loader.
eda_analyzer.load_reference_info = _load_reference_info


def main():
    if len(sys.argv) < 2:
        print("Usage: python eda_analyze.py <filepath> [output.md]",
              file=sys.stderr)
        sys.exit(1)

    filepath = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else None

    if not os.path.exists(filepath):
        print(f"Error: File not found: {filepath}", file=sys.stderr)
        sys.exit(1)

    analysis = eda_analyzer.analyze_file(filepath)
    eda_analyzer.generate_markdown_report(analysis, output_path)


if __name__ == "__main__":
    main()
