# Install tests

Validates that the built `.deb` and `.pkg.tar.zst` packages install cleanly
on Lyra's two supported distributions (see root `README.md` → "Supported
distributions"): Ubuntu and Arch Linux. Each runs in a clean Docker
container — no host state involved.

## Running

```bash
# 1. Build the artifacts first (existing scripts, unchanged):
./scripts/build-deb.sh
./scripts/build-arch.sh

# 2. Run the install matrix:
./tests/run.sh            # both OS
./tests/run.sh ubuntu      # just Ubuntu
./tests/run.sh archlinux   # just Arch
```

Each run is a fresh container: install the package via the OS's own package
manager (`apt install ./lyra.deb` / `pacman -U`), then run the shared
assertions in `tests/cases/assertions.sh` — binaries on `PATH`, `lyra
--version`, `lyra serve --help`, desktop entry present, `lyra uninstall`
exits cleanly.

## What this does NOT cover

- `lyra-ui` is checked for presence only, not launched — it's an Electron
  GUI app and these containers are headless (no X server / display).
- `lyra-install-backend` (the model download step) is not run — it needs
  network access to fetch a ~1GB model and isn't something you want in a
  routine install-test loop. Presence on `PATH` is checked; actual behavior
  needs a separate, opt-in test.
- This tests **install correctness**, not runtime performance — for
  resource/response-time benchmarking see the separate
  [lyra-benchmarking](https://github.com/lyra-ai-assistant/lyra-benchmarking)
  repo.

## Adding a check

Add assertions to `tests/cases/assertions.sh` — it's shared across both OS
images, so anything added there runs on both automatically. Only add
OS-specific logic to the Dockerfiles themselves (package manager syntax) if
a check genuinely differs between apt and pacman.
