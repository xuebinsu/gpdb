#!/usr/bin/env python2
 
from __future__ import print_function

import os
import sys
from cx_Freeze import setup, Executable

sys.path.insert(0, os.path.abspath(os.path.join("..", "bin")))
sys.path.insert(0, os.path.abspath(os.path.join("..", "bin", "ext")))
sys.path.insert(0, os.path.abspath(os.path.join("..", "bin", "ext", "pygresql")))
print("sys.path =", sys.path)

programs_buf = []
makefile = open("Makefile")
for line in makefile:
    if line.startswith("PROGRAMS=") or len(programs_buf) > 0:
        programs_buf.append(line)
        if "\\" not in line:
            break

program_names = [name for line in programs_buf for name in line.replace("\\", "").split() if name != "PROGRAMS="]

def is_python_program(name):
    prog = open(name)
    line = prog.readline()
    prog.close()
    return "python" in line

py_program_names = [name for name in program_names if is_python_program(name)]
print("building standalone management utils...", py_program_names)

build_exe_options = {"include_files": [name for name in program_names if not is_python_program(name)]}

setup(
    name="gpmgmt",
    version="0.1",
    options={"build_exe": build_exe_options},
    executables=[Executable(name, targetName=name) for name in py_program_names],
)