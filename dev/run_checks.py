"""Run the actual independent TOC in an isolated Lua 5.1 environment."""
from pathlib import Path
import os
import shutil
import subprocess
from package_addons import validate_sources

ROOT = Path(__file__).resolve().parents[1]


def main():
    os.chdir(ROOT)
    validate_sources()
    executable = shutil.which('lua5.1') or shutil.which('luajit')
    if executable:
        subprocess.run([executable, 'dev/test.lua'], check=True)
    else:
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            raise SystemExit('Install Lua 5.1 or: python -m pip install -r dev/requirements.txt')
        LuaRuntime().execute('dofile("dev/test.lua")')


if __name__ == '__main__':
    main()
