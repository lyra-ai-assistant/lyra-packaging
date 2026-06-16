#!/usr/bin/env python3
"""
Build a .deb package from a staged directory tree without dpkg-deb.
A .deb is an `ar` archive containing:
  - debian-binary   (text file: "2.0\n")
  - control.tar.gz  (DEBIAN/ contents)
  - data.tar.gz     (the rest of the tree)
"""
import io
import os
import stat
import struct
import sys
import tarfile
import time
from pathlib import Path


def _ar_header(name: str, size: int) -> bytes:
    """Build a 60-byte ar file header."""
    mtime = str(int(time.time())).encode()
    return struct.pack(
        "16s12s6s6s8s10s2s",
        name.encode().ljust(16),
        mtime.ljust(12),
        b"0".ljust(6),    # uid
        b"0".ljust(6),    # gid
        b"100644".ljust(8),
        str(size).encode().ljust(10),
        b"\x60\x0a",     # magic
    )


def _make_tar_gz(root: Path, members: list[Path]) -> bytes:
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz") as tar:
        for path in sorted(members):
            rel = path.relative_to(root)
            info = tar.gettarinfo(str(path), arcname="./" + str(rel))
            # Normalise ownership
            info.uid = 0
            info.gid = 0
            info.uname = "root"
            info.gname = "root"
            if path.is_file() and not path.is_symlink():
                with open(path, "rb") as f:
                    tar.addfile(info, f)
            else:
                tar.addfile(info)
    return buf.getvalue()


def build_deb(pkg_dir: str, output: str) -> None:
    root = Path(pkg_dir).resolve()

    debian_dir = root / "DEBIAN"
    if not debian_dir.is_dir():
        sys.exit(f"ERROR: {debian_dir} not found")

    # --- control.tar.gz (DEBIAN/ contents) ---
    control_members = [
        p for p in debian_dir.rglob("*")
        if p.is_file() or p.is_symlink()
    ]
    control_tar = _make_tar_gz(root, [debian_dir] + control_members)

    # --- data.tar.gz (everything except DEBIAN/) ---
    data_members = []
    for p in root.rglob("*"):
        if debian_dir in p.parents or p == debian_dir:
            continue
        data_members.append(p)
    data_tar = _make_tar_gz(root, data_members)

    # --- debian-binary ---
    debian_binary = b"2.0\n"

    # --- assemble ar archive ---
    out = Path(output)
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, "wb") as f:
        f.write(b"!<arch>\n")

        f.write(_ar_header("debian-binary", len(debian_binary)))
        f.write(debian_binary)
        if len(debian_binary) % 2:
            f.write(b"\n")

        f.write(_ar_header("control.tar.gz", len(control_tar)))
        f.write(control_tar)
        if len(control_tar) % 2:
            f.write(b"\n")

        f.write(_ar_header("data.tar.gz", len(data_tar)))
        f.write(data_tar)
        if len(data_tar) % 2:
            f.write(b"\n")

    print(f"Built: {out} ({out.stat().st_size // 1024 // 1024} MB)")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("Usage: deb_builder.py <pkg_dir> <output.deb>")
    build_deb(sys.argv[1], sys.argv[2])
