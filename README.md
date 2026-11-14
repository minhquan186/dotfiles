# dotfiles

My dotfile config, themed with Catppuccin Mocha throughout. Each top-level
directory is a [GNU Stow](https://www.gnu.org/software/stow/) package that
mirrors `$HOME`.

| Package | Links to | Notes |
|---|---|---|
| `bash` | `~/.bash_aliases`, `~/.inputrc`, `~/.bashrc.d/` | aliases, vi-mode readline, history/fzf/zoxide/vivid extras |
| `bat` | `~/.config/bat/` | Catppuccin Mocha theme as default |
| `clangd` | `~/.config/clangd/config.yaml` | makes `.cu`/`.cuh` parse from nvcc compile commands |
| `eza` | `~/.config/eza/theme.yml` | Catppuccin Mocha, mauve accent |
| `git` | `~/.gitconfig`, `~/.config/delta/` | delta pager with Catppuccin Mocha |
| `nvim` | `~/.config/nvim/` | Neovim 0.12+ (`vim.pack`) |
| `starship` | `~/.config/starship.toml` | two-line prompt, CUDA/CMake modules |
| `wezterm` | `~/.wezterm.lua` | |
| `backgrounds` | `~/.config/backgrounds/` | wallpapers |

## Install

```sh
git clone https://github.com/minhquan186/dotfiles ~/dotfiles
cd ~/dotfiles
stow bash bat clangd eza git nvim starship wezterm backgrounds
batcat cache --build   # register the bat theme (also used by delta)
```

Then add this line at the end of `~/.bashrc` (after `starship init`):

```sh
for f in ~/.bashrc.d/*.bash; do [ -r "$f" ] && . "$f"; done
```

Machine-specific git settings (e.g. a work email) go in an untracked
`~/.gitconfig.local`, which `.gitconfig` includes last.

Needs: WezTerm, Starship, JetBrainsMono Nerd Font, eza, bat, git-delta, Neovim,
clangd. Optional (skipped if missing): fzf, fd-find, zoxide, vivid.

The X11 setup (bspwm, sxhkd, picom, polybar, xbindkeys) was removed after
moving to GNOME on Wayland; it is still in the git history.

Vendored Catppuccin themes: see [THIRD-PARTY.md](THIRD-PARTY.md).
