#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit
from subprocess import call

def post_run(results):
    if VU.get_simulator_name() == "ghdl":
        results.merge_coverage(file_name="coverage_data")
        if results._simulator_if._backend == "gcc":
            call(["gcovr", "--html-details", "coverage.html", "coverage_data"])
        else:
            call(["gcovr", "-a", "coverage_data/gcovr.json"])

VU = VUnit.from_argv()
VU.add_vhdl_builtins()
VU.add_osvvm()
VU.add_verification_components()

HARDWARE_PATH = Path(__file__).parent / ".." / "hardware"
SRC_PATH = HARDWARE_PATH / "design"
TESTS_PATH = HARDWARE_PATH / "tests"

LIB = VU.add_library("design_lib")
LIB.add_source_files(SRC_PATH / "*.vhd")
LIB.add_source_files(TESTS_PATH / "*.vhd")

if VU.get_simulator_name() == "ghdl":
    LIB.set_sim_option("enable_coverage", True)
    LIB.set_compile_option("enable_coverage", True)

VU.main(post_run=post_run)
