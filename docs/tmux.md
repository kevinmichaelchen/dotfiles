# tmux

A terminal multiplexer that lets you run multiple terminal sessions in one
window.

## Quick Reference

| Action               | Shortcut                    |
| -------------------- | --------------------------- |
| Prefix key           | `Ctrl+b`                    |
| Split horizontally   | `prefix %`                  |
| Split vertically     | `prefix "`                  |
| Switch pane          | `prefix arrow-key` or click |
| Close pane           | `prefix x`                  |
| New window           | `prefix c`                  |
| Next/prev window     | `prefix n` / `prefix p`     |
| List windows         | `prefix w`                  |
| Detach session       | `prefix d`                  |
| Enter copy mode      | `prefix [`                  |
| Paste buffer         | `prefix ]`                  |
| Reload config        | `prefix r`                  |
| Show all keybindings | `prefix ?`                  |

> **Note:** "Prefix" means press `Ctrl+b`, release, then press the next key.

## Sesh: Smart Session Manager

We use [Sesh][sesh] for intelligent session management. It integrates with
[zoxide][zoxide] to quickly jump to your most-used directories.

### Sesh Keybindings

| Action                 | Shortcut   |
| ---------------------- | ---------- |
| Open session picker    | `prefix T` |
| Switch to last session | `prefix L` |

### Session Picker Controls

When the sesh picker is open (`prefix T`):

| Key         | Action                        |
| ----------- | ----------------------------- |
| `Ctrl+a`    | Show all sources              |
| `Ctrl+t`    | Show tmux sessions only       |
| `Ctrl+g`    | Show configured sessions only |
| `Ctrl+x`    | Show zoxide directories       |
| `Ctrl+f`    | Find directories in ~         |
| `Ctrl+d`    | Kill highlighted session      |
| `Tab`       | Move down                     |
| `Shift+Tab` | Move up                       |

### Sesh Configuration

Create `~/.config/sesh/sesh.toml` for custom sessions:

```toml
[[session]]
name = "dotfiles"
path = "~/dotfiles"
startup_command = "nvim"

[[session]]
name = "projects"
path = "~/dev"
```

## Our Configuration

Located at `~/.config/tmux/tmux.conf` (managed via chezmoi).

### Base Settings

```bash
# Start windows and panes at 1, not 0 (easier to reach on keyboard)
set -g base-index 1
setw -g pane-base-index 1

# Enable mouse support
set -g mouse on

# Skip "kill-pane 1? (y/n)" prompt
bind-key x kill-pane

# Don't exit tmux when closing a session
set -g detach-on-destroy off
```

### Mouse Support

With `set -g mouse on`, you can:

- **Scroll** - Mouse wheel scrolls pane history (auto-enters copy mode)
- **Resize panes** - Click and drag pane borders
- **Select panes** - Click to focus
- **Select windows** - Click window name in status bar
- **Right-click menu** - Context menu for splitting, swapping, etc.

**Tip:** Hold `Shift` while selecting text to bypass tmux and copy directly to
system clipboard.

### Plugins (via TPM)

We use [TPM (Tmux Plugin Manager)][tpm] to manage plugins. It's installed
automatically via chezmoi's `.chezmoiexternal.toml`.

```bash
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'rose-pine/tmux'
```

**Plugin commands:**

| Action                    | Shortcut       |
| ------------------------- | -------------- |
| Install plugins           | `prefix I`     |
| Update plugins            | `prefix U`     |
| Uninstall removed plugins | `prefix Alt+u` |

### Theme: Rose Pine

We use [Rose Pine][rose-pine-tmux] to match our Ghostty terminal theme.

```bash
set -g @rose_pine_variant 'auto'  # Switches with system dark/light mode
```

Available variants: `main` (dark), `moon` (darker), `dawn` (light), `auto`.

## Copy Mode

Copy mode lets you scroll through history and copy text.

1. Enter copy mode: `prefix [`
2. Navigate with arrow keys or vim keys (`hjkl`)
3. Start selection: `Space`
4. Copy selection: `Enter`
5. Paste: `prefix ]`

### Copy to System Clipboard (macOS)

To copy to system clipboard instead of tmux buffer, add:

```bash
set -g set-clipboard on
```

Or use `pbcopy`:

```bash
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
```

## Sessions (without Sesh)

If you need to manage sessions manually:

```bash
# List sessions
tmux ls

# New named session
tmux new -s myproject

# Attach to session
tmux attach -t myproject

# Kill session
tmux kill-session -t myproject
```

## Useful Links

- [Sesh - Smart session manager][sesh]
- [tmux GitHub][tmux-github]
- [tmux Cheat Sheet][cheatsheet]
- [TPM - Tmux Plugin Manager][tpm]
- [Rose Pine tmux theme][rose-pine-tmux]
- [zoxide - Smarter cd][zoxide]
- [Awesome tmux - plugin list][awesome-tmux]

[sesh]: https://github.com/joshmedeski/sesh
[zoxide]: https://github.com/ajeetdsouza/zoxide
[tmux-github]: https://github.com/tmux/tmux
[cheatsheet]: https://tmuxcheatsheet.com/
[tpm]: https://github.com/tmux-plugins/tpm
[rose-pine-tmux]: https://github.com/rose-pine/tmux
[awesome-tmux]: https://github.com/rothgar/awesome-tmux
