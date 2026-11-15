# dotfiles

My dotfile config, themed with Catppuccin Mocha throughout. Each top-level
directory is a [GNU Stow](https://www.gnu.org/software/stow/) package that
mirrors `$HOME`.

| Package | Links to | Notes |
|---|---|---|
| `bash` | `~/.bash_aliases`, `~/.inputrc`, `~/.bashrc.d/` | aliases, vi-mode readline, history/fzf/zoxide/vivid extras, CMake defaults (Ninja, compile_commands, ccache) |
| `bat` | `~/.config/bat/` | Catppuccin Mocha theme as default |
| `clangd` | `~/.config/clangd/config.yaml` | makes `.cu`/`.cuh` parse from nvcc compile commands |
| `eza` | `~/.config/eza/theme.yml` | Catppuccin Mocha, mauve accent |
| `git` | `~/.gitconfig`, `~/.config/delta/` | delta pager with Catppuccin Mocha |
| `nvim` | `~/.config/nvim/` | Neovim 0.12+ (`vim.pack`) |
| `starship` | `~/.config/starship.toml` | two-line prompt, CUDA/CMake modules |
| `vicinae` | `~/.config/vicinae/dotfiles.jsonc` | launcher theme; `settings.json` stays Vicinae's own file and imports this |
| `wezterm` | `~/.wezterm.lua` | |
| `backgrounds` | `~/.config/backgrounds/` | wallpapers |

## Install

```sh
git clone https://github.com/minhquan186/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh        # add -n first to see what it would do
```

`install.sh` is safe to rerun and does, in order:

1. installs the apt packages listed in `packages.txt`
2. links `fd`/`bat` to Ubuntu's `fdfind`/`batcat` in `~/.local/bin`
3. installs tools apt cannot provide (or has too old) from their official
   installers, asking before each one: WezTerm (apt repo), Starship (install
   script), Neovim >= 0.12 and yazi >= 26.8.15 (GitHub releases, into
   `~/.local`), JetBrainsMono Nerd Font
4. stows every package; files in the way are moved to `~/.dotfiles-backup/`
5. adds `starship init` and the `~/.bashrc.d` loop to `~/.bashrc` if missing,
   rebuilds the bat theme cache, runs `ya pkg install`
6. prints the state of every tool

| Command | Use |
|---|---|
| `./install.sh links` | after `git pull`: steps 2, 4, 5 |
| `./install.sh tools` | step 3 only; `-y` skips the questions |
| `./install.sh tools vicinae` | opt-in extras, by name |
| `./install.sh check` | step 6 only |
| `./install.sh -n` | dry run of any of the above |

Machine-specific git settings (e.g. a work email) go in an untracked
`~/.gitconfig.local`, which `.gitconfig` includes last.

The X11 setup (bspwm, sxhkd, picom, polybar, xbindkeys) was removed after
moving to GNOME on Wayland; it is still in the git history.

Vendored Catppuccin themes: see [THIRD-PARTY.md](THIRD-PARTY.md).
