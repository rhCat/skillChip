#!/usr/bin/env python3
"""
eda_format_reference — thin CLI over the vendored eda_analyzer core.

Looks up the format-reference section for a scientific file's extension in the
vendored references/*.md and returns it as text. Reuses the core's
detect_file_type() for category routing; the reference markdown is read from
the references/ folder sitting next to this script (vendored). Pure stdlib: no
scientific library or network is touched, so this runs hermetically.

Usage:
    python eda_format_reference.py <filepath> [output.md]

Emits the matched reference section (markdown). If no section matches, emits a
short note naming the detected category/extension.
"""

import os
import re
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


def lookup_section(category, extension):
    ref_name = CATEGORY_FILES.get(category)
    if not ref_name:
        return None
    ref_file = os.path.join(HERE, "references", ref_name)
    if not os.path.exists(ref_file):
        return None
    with open(ref_file, "r") as f:
        content = f.read()
    pattern = rf"### \.{extension}[^#]*?(?=###|\Z)"
    match = re.search(pattern, content, re.IGNORECASE | re.DOTALL)
    if match:
        return match.group(0), ref_name
    return None


def main():
    if len(sys.argv) < 2:
        print("Usage: python eda_format_reference.py <filepath> [output.md]",
              file=sys.stderr)
        sys.exit(1)

    filepath = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else None

    extension, category, description = eda_analyzer.detect_file_type(filepath)

    found = lookup_section(category, extension)
    if found:
        section, ref_name = found
        text = section.rstrip() + f"\n\n*Reference: {ref_name}*\n"
    else:
        text = (
            f"# Format Reference\n\n"
            f"No reference section found for extension `.{extension}` "
            f"(category: {category}, description: {description}).\n"
        )

    if output_path:
        with open(output_path, "w") as f:
            f.write(text)
    else:
        sys.stdout.write(text)


if __name__ == "__main__":
    main()
