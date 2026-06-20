#!/usr/bin/env python3
"""Thin harness: generate the executor launch script (scheduler headers + nextflow run
command) by calling the UNCHANGED vendored run_pacsomatic.py:build_nextflow_command and
write_launch_script. Reads inputs from env, writes the launch script to --out. No execution,
no nextflow/conda required (the script is generated, not run)."""

import argparse
import os
import sys
from types import SimpleNamespace

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run_pacsomatic as core  # noqa: E402


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--samplesheet", required=True)
    p.add_argument("--outdir", required=True)
    p.add_argument("--out", required=True, help="launch script output path")
    p.add_argument("--fasta", default="")
    p.add_argument("--genome", default="")
    p.add_argument("--profile", default="singularity")
    p.add_argument("--executor", default="local",
                   choices=["local", "none", "lsf", "slurm", "pbs", "sge"])
    p.add_argument("--nextflow-bin", default="nextflow")
    p.add_argument("--pipeline", default="nf-core/pacsomatic")
    p.add_argument("--pipeline-version", default="")
    p.add_argument("--job-name", default="pacsomatic")
    p.add_argument("--project", default="")
    p.add_argument("--queue", default="")
    p.add_argument("--cpus", type=int, default=16)
    p.add_argument("--memory-gb", type=float, default=64.0)
    p.add_argument("--walltime", default="48:00")
    p.add_argument("--workdir", default="")
    p.add_argument("--logdir", default="")
    p.add_argument("--stdout-file", default="out%J.out")
    p.add_argument("--stderr-file", default="err%J.err")
    p.add_argument("--nxf-opts", default="")
    p.add_argument("--singularity-cache", default="")
    p.add_argument("--module-load", default="")
    a = p.parse_args()

    if not a.fasta and not a.genome:
        raise SystemExit("[ERROR] one of --fasta or --genome is required")

    # Assemble the full namespace the vendored builders expect, with safe defaults
    # for the knobs this perk does not surface.
    args = SimpleNamespace(
        nextflow_bin=a.nextflow_bin,
        pipeline=a.pipeline,
        profile=a.profile,
        outdir=a.outdir,
        fasta=a.fasta,
        genome=a.genome,
        pipeline_version=a.pipeline_version,
        params_file="",
        use_generated_params_file=False,
        generated_params_file="",
        resume=False,
        with_report="",
        with_dag="",
        extra_args="",
        workdir=a.workdir or os.path.join(a.outdir, "work"),
        logdir=a.logdir,
        stdout_file=a.stdout_file,
        stderr_file=a.stderr_file,
        executor=a.executor,
        job_name=a.job_name,
        project=a.project,
        queue=a.queue,
        cpus=a.cpus,
        memory_gb=a.memory_gb,
        walltime=a.walltime,
        nxf_opts=a.nxf_opts,
        singularity_cache=a.singularity_cache,
        runtime_prefix=None,
        module_load=a.module_load,
    )

    nextflow_cmd = core.build_nextflow_command(args, a.samplesheet)
    os.makedirs(os.path.dirname(a.out) or ".", exist_ok=True)
    core.write_launch_script(args, a.out, nextflow_cmd)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
