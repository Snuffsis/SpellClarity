"""Run release tests, standalone runtime and package verification; never publish."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def run(*args):
    subprocess.run([sys.executable, *args], cwd=ROOT, check=True)


if __name__ == '__main__':
    run('dev/update_manifest.py', '--check')
    run('-m', 'unittest', 'discover', '-s', 'dev', '-p', 'test_release.py', '-v')
    run('dev/run_checks.py')
    run('dev/release.py')
    run('dev/release.py', '--verify')
