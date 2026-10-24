#!/usr/bin/env python3
"""Hash repository files, excluding Git metadata and ignored local output.

Run after editing files and before committing. --check verifies without writing.
Includes new, not-yet-staged files so the manifest can be staged with the change.
"""
import argparse
import hashlib
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "MANIFEST.sha256"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    listing = subprocess.check_output(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"], cwd=ROOT
    )
    names = sorted(set(listing.decode("utf-8").split("\0")) - {"", MANIFEST.name})
    lines = []
    for name in names:
        path = ROOT / name
        if path.is_file():
            lines.append(f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {name}\n")
    content = "".join(lines).encode("utf-8")
    if args.check:
        if not MANIFEST.exists() or MANIFEST.read_bytes() != content:
            raise SystemExit("Manifest differs. Run python dev/update_manifest.py before committing.")
        print(f"Verified SHA-256 manifest for {len(lines)} files.")
    else:
        MANIFEST.write_bytes(content)
        print(f"Updated SHA-256 manifest for {len(lines)} files.")


if __name__ == "__main__":
    main()
