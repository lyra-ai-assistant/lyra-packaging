# Lyra

Your Cosmic Companion — an open source AI assistant for GNU/Linux.

Lyra runs fully offline using a lightweight language model on your own machine.
No telemetry, no cloud dependency. It knows your system: your distro, package
manager, and installed ecosystems, so it gives you accurate commands instead of
generic answers.

## Supported distributions

| Distribution | Package manager | Status |
|--------------|----------------|--------|
| Arch Linux and derivatives | pacman | Supported |
| Debian, Ubuntu and derivatives | apt | Supported |

## System requirements

> These requirements have not been formally verified yet. They are estimates
> based on the components included in Lyra.

| | Minimum | Recommended |
|-|---------|-------------|
| RAM | 4 GB | 8 GB |
| Disk | 3 GB free | 5 GB free |
| CPU | x86_64, 2 cores | x86_64, 4 cores |
| GPU | Not required | NVIDIA, AMD, or Intel Arc |
| OS | GNU/Linux | GNU/Linux |

## Installation

### Arch Linux

Download the latest `.pkg.tar.zst` from the [releases page](https://github.com/lyra-ai-assistant/lyra-packaging/releases):

```bash
sudo pacman -U lyra-1.1.0-1-x86_64.pkg.tar.zst
```

### Debian / Ubuntu

Download the latest `.deb` from the [releases page](https://github.com/lyra-ai-assistant/lyra-packaging/releases):

```bash
sudo apt install ./lyra_1.1.0-1_amd64.deb
```

## First run

After installation, download the AI model once:

```bash
lyra-install-backend
```

This detects your GPU (NVIDIA, AMD ROCm, Intel Arc, or CPU-only) and downloads
the model automatically. Requires an internet connection and approximately 1 GB
of free disk space.

## Usage

Start the assistant:

```bash
lyra serve --daemon
lyra-ui
```

Or use it directly from the terminal:

```bash
lyra -q "how do I install neovim"
```

## Uninstall

```bash
lyra uninstall
```

This removes all Lyra data, the AI model, and configuration files.
To also remove the package:

```bash
# Arch
sudo pacman -R lyra

# Debian / Ubuntu
sudo apt remove lyra
```

## Authors

- AndresMpa — [ing.andres.m.prieto@gmail.com](mailto:ing.andres.m.prieto@gmail.com)
- xcerock — [xcerock@gmail.com](mailto:xcerock@gmail.com)

## License

- `lyra-server`: AGPL-3.0
- `lyra-ui`: MIT
```

---

This README is now the primary, end‑user facing documentation for the `lyra-packaging` repository. All build‑pipeline details (scripts, CI/CD, versioning) have been moved out of the main README — they can be documented separately (e.g., in a `CONTRIBUTING.md` or `DEVELOPER.md`) to keep the user experience clean and focused.

If you want to keep some developer information in the README (e.g., a brief "Building from source" section), I can add that back, but the checkpoint explicitly states it's "user‑facing, installation focused". I recommend keeping it as is. Let me know if you need any adjustments.
