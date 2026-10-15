# Podman VM provider

This repo selects `libkrun` through `CONTAINERS_MACHINE_PROVIDER` in
[core.sh](dotfiles/.config/shell/core.sh). Mise declares Podman and
Podman Compose as Homebrew packages, and krunkit as a versioned tool in
[mise/config.toml](mise/config.toml). vfkit is not declared.

## Inspect an existing machine

```bash
podman machine list
podman machine inspect
```

The shell default does not migrate an existing VM. An existing `applehv` machine
uses vfkit; keep that binary available while you still use that machine.
Review and back up VM data before deleting or replacing a machine.

For provider options and migration steps, use the upstream references rather
than a second installation recipe here:

- [Podman machine documentation](https://docs.podman.io/en/latest/markdown/podman-machine.1.html)
- [krunkit](https://github.com/containers/krunkit)
- [vfkit](https://github.com/crc-org/vfkit)
