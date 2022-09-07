#!/usr/bin/env python2
 
from __future__ import print_function

import os
import sys
from cx_Freeze import setup, Executable

sys.path.insert(0, os.path.abspath(os.path.join(__file__, "..", "bin")))
sys.path.insert(0, os.path.abspath(os.path.join(__file__, "..", "bin", "ext")))
sys.path.insert(0, os.path.abspath(os.path.join(__file__, "..", "bin", "ext", "pygresql")))
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

setup(
    name="gpmgmt",
    version="0.1",
    executables=[Executable(name, targetName="__frozen__" + name) for name in py_program_names],
)