#!/usr/bin/env python3

import os
import sys
from cx_Freeze import setup, Executable

gpmgmt_dir = os.path.join(*os.path.split(os.path.abspath(__file__))[:-1])
sys.path = [
    os.path.join(gpmgmt_dir, "bin", "ext", "pygresql"),
    os.path.join(gpmgmt_dir, "bin", "ext"),
    os.path.join(gpmgmt_dir, "bin"),
] + sys.path
print("sys.path =", sys.path)
# exit()

programs_buf = []
makefile = open("Makefile")
for line in makefile:
    if line.startswith("PROGRAMS=") or len(programs_buf) > 0:
        programs_buf.append(line)
        if "\\" not in line:
            break

program_names = [
    name
    for line in programs_buf
    for name in line.replace("\\", "").split()
    if name != "PROGRAMS="
]


def is_python_program(name):
    prog = open(name)
    line = prog.readline()
    prog.close()
    return "python" in line


py_program_names = [name for name in program_names if is_python_program(name)]
print("building standalone management utils...", py_program_names)

setup(
    name="gpmgmt",
    version="0.1",
    executables=[
        Executable(name, target_name="__frozen__" + name) for name in py_program_names
    ],
)
