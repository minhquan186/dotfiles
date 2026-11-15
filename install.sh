#!/usr/bin/env bash
# Set up these dotfiles on a new machine, or refresh them after `git pull`.
# Safe to rerun: every step is skipped when it is already done.
#
#   ./install.sh            everything: packages, links, post-steps, check
#   ./install.sh packages   apt packages from packages.txt only
#   ./install.sh links      stow links + post-steps (use after git pull)
#   ./install.sh check      show installed tools and what to install by hand
#   add -n to any of them   dry run: print what would be done
#
# Uses sudo only for apt. Files that are in the way of a link are moved to
# ~/.dotfiles-backup/<timestamp>/, never overwritten.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"

DRY=0
CMD=all
for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) DRY=1 ;;
    all|packages|links|check) CMD=$arg ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $arg (try --help)" >&2; exit 2 ;;
  esac
done

if [ -t 1 ]; then
  B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; D=$'\033[2m'; Z=$'\033[0m'
else
  B=; G=; Y=; R=; D=; Z=
fi
step() { printf '\n%s== %s%s\n' "$B" "$*" "$Z"; }
ok()   { printf '  %sok%s    %s\n' "$G" "$Z" "$*"; }
note() { printf '  %s--%s    %s\n' "$Y" "$Z" "$*"; }
bad()  { printf '  %sMISSING%s %s\n' "$R" "$Z" "$*"; }
# run CMD...: execute, or only print it in a dry run
run() {
  if [ "$DRY" = 1 ]; then printf '  %swould run:%s %s\n' "$D" "$Z" "$*"; else "$@"; fi
}
have() { command -v "$1" >/dev/null 2>&1; }
# version_ge A B: true when version A >= B
version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]; }

# Top-level directories are the stow packages
packages=()
for d in */; do packages+=("${d%/}"); done

# ---------------------------------------------------------------------------
install_packages() {
  step "apt packages (packages.txt)"
  if ! have apt-get; then
    note "apt-get not found; install the tools in packages.txt with your package manager"
    return
  fi
  local want=() missing=() unavailable=() p
  while IFS= read -r p; do
    p="${p%%#*}"; p="${p//[[:space:]]/}"
    [ -n "$p" ] && want+=("$p")
  done < packages.txt

  for p in "${want[@]}"; do
    if dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "install ok installed"; then
      continue
    elif apt-cache show "$p" >/dev/null 2>&1; then
      missing+=("$p")
    else
      unavailable+=("$p")
    fi
  done

  if [ "${#missing[@]}" -eq 0 ]; then
    ok "all available packages are installed"
  else
    local sudo=sudo
    [ "$(id -u)" -eq 0 ] && sudo=
    note "installing: ${missing[*]}"
    run $sudo apt-get install -y "${missing[@]}"
  fi
  if [ "${#unavailable[@]}" -gt 0 ]; then
    note "not in your apt sources (see the check list below): ${unavailable[*]}"
  fi
}

# ---------------------------------------------------------------------------
# Ubuntu installs fd as fdfind and bat as batcat; yazi and others look for the
# upstream names.
link_ubuntu_names() {
  step "Ubuntu command names (~/.local/bin)"
  local pair src dst
  for pair in fdfind:fd batcat:bat; do
    src=${pair%%:*}; dst=${pair##*:}
    if have "$dst" || [ -e "$HOME/.local/bin/$dst" ]; then
      ok "$dst"
    elif have "$src"; then
      note "linking $dst -> $src"
      run mkdir -p "$HOME/.local/bin"
      run ln -s "$(command -v "$src")" "$HOME/.local/bin/$dst"
    else
      note "$src not installed, skipping $dst"
    fi
  done
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) note "$HOME/.local/bin is not in PATH yet (Ubuntu adds it at next login)" ;;
  esac
}

# ---------------------------------------------------------------------------
# Move anything that would block stow out of the way. A target is fine when it
# already resolves to the file in this repo (linked directly or through a
# linked parent directory).
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
backed_up=0
backup_conflicts() {
  local pkg=$1 f rel target
  while IFS= read -r -d '' f; do
    rel=${f#"$pkg"/}
    target="$HOME/$rel"
    [ -e "$target" ] || [ -L "$target" ] || continue
    [ "$(realpath -m "$target")" = "$(realpath "$REPO/$f")" ] && continue
    note "in the way: ~/$rel -> $BACKUP/$rel"
    run mkdir -p "$(dirname "$BACKUP/$rel")"
    run mv "$target" "$BACKUP/$rel"
    backed_up=1
  done < <(find "$pkg" \( -type f -o -type l \) -print0)
}

link_packages() {
  step "stow links into $HOME"
  if ! have stow; then
    bad "stow is not installed (run: ./install.sh packages)"
    return 1
  fi
  local pkg
  for pkg in "${packages[@]}"; do
    backup_conflicts "$pkg"
  done
  # --restow also removes links left behind by files deleted from the repo
  if [ "$DRY" = 1 ]; then
    if [ "$backed_up" = 1 ]; then
      note "would restow after the moves above: ${packages[*]}"
    else
      stow -n --restow -t "$HOME" "${packages[@]}" && ok "no conflicts: ${packages[*]}"
    fi
  else
    stow --restow -t "$HOME" "${packages[@]}"
    ok "${packages[*]}"
  fi
  [ "$backed_up" = 1 ] && note "originals kept in $BACKUP"
  return 0
}

# ---------------------------------------------------------------------------
post_steps() {
  step "post-steps"
  local rc="$HOME/.bashrc" line

  # ~/.bashrc is not tracked; make sure it loads starship and ~/.bashrc.d
  line='eval "$(starship init bash)"'
  if grep -qs 'starship init bash' "$rc"; then
    ok "~/.bashrc: starship init"
  else
    note "~/.bashrc: adding starship init"
    [ "$DRY" = 1 ] || printf '\n%s\n' "command -v starship >/dev/null && $line" >> "$rc"
  fi
  line='for f in ~/.bashrc.d/*.bash; do [ -r "$f" ] && . "$f"; done'
  if grep -qs '\.bashrc\.d' "$rc"; then
    ok "~/.bashrc: sources ~/.bashrc.d"
  else
    note "~/.bashrc: adding ~/.bashrc.d loop"
    [ "$DRY" = 1 ] || printf '%s\n' "$line" >> "$rc"
  fi

  if have batcat || have bat; then
    local bat=batcat; have batcat || bat=bat
    note "rebuilding bat theme cache"
    run "$bat" cache --build >/dev/null
  fi

  if have ya && have yazi && version_ge "$(yazi_version)" "$YAZI_MIN"; then
    note "installing yazi plugins and flavor from package.toml"
    run ya pkg install
  else
    note "yazi >= $YAZI_MIN not found; run 'ya pkg install' after installing it"
  fi
  note "Neovim installs its plugins on first start"
}

# ---------------------------------------------------------------------------
NVIM_MIN=0.12
YAZI_MIN=26.8.15
nvim_version() { nvim --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9.]*\).*/\1/p'; }
yazi_version() { yazi --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)+' | head -n1; }

# check_tool NAME COMMAND MIN_VERSION VERSION_FUNCTION HOW
check_tool() {
  local name=$1 cmd=$2 min=$3 vfn=$4 how=$5 v
  if ! have "$cmd"; then
    bad "$name"; printf '          %s\n' "$how"; manual=1; return
  fi
  if [ -n "$min" ]; then
    v=$($vfn)
    if ! version_ge "${v:-0}" "$min"; then
      printf '  %sTOO OLD%s %s %s, need >= %s\n' "$R" "$Z" "$name" "${v:-?}" "$min"; printf '          %s\n' "$how"; manual=1; return
    fi
    ok "$name $v"
  else
    ok "$name"
  fi
}

check_tools() {
  step "tools to install by hand (not handled by this script)"
  manual=0
  check_tool "WezTerm" wezterm "" "" \
    "apt repo: https://wezterm.org/install/linux.html"
  check_tool "Starship" starship "" "" \
    "curl -sS https://starship.rs/install.sh | sh    (https://starship.rs/guide/)"
  check_tool "Neovim" nvim "$NVIM_MIN" nvim_version \
    "release tarball: https://github.com/neovim/neovim/releases"
  check_tool "yazi" yazi "$YAZI_MIN" yazi_version \
    "cargo install --force yazi-build    (https://yazi-rs.github.io/docs/installation)"
  check_tool "vivid (optional, LS_COLORS)" vivid "" "" \
    ".deb: https://github.com/sharkdp/vivid/releases"
  check_tool "zoxide (optional)" zoxide "" "" \
    "https://github.com/ajeetdsouza/zoxide#installation"
  check_tool "fzf (optional)" fzf "" "" \
    "https://github.com/junegunn/fzf#installation"
  check_tool "eza" eza "" "" \
    "https://github.com/eza-community/eza/blob/main/INSTALL.md"
  check_tool "delta" delta "" "" \
    "https://github.com/dandavison/delta/releases"

  if have fc-list && fc-list | grep -iE "JetBrains ?Mono.*(Nerd|NF)" >/dev/null; then
    ok "JetBrainsMono Nerd Font"
  else
    bad "JetBrainsMono Nerd Font (optional: WezTerm bundles JetBrains Mono + Nerd symbols)"
    printf '          %s\n' "unzip into ~/.local/share/fonts, then fc-cache -f: https://www.nerdfonts.com/font-downloads"
    manual=1
  fi

  if [ "$manual" = 1 ]; then
    printf '\n  Install or update the ones flagged above, then rerun: ./install.sh links\n'
  else
    printf '\n  Nothing left to install by hand.\n'
  fi
}

# ---------------------------------------------------------------------------
[ "$DRY" = 1 ] && printf '%sdry run: nothing will be changed%s\n' "$Y" "$Z"
case "$CMD" in
  all)      install_packages; link_ubuntu_names; link_packages; post_steps; check_tools ;;
  packages) install_packages ;;
  links)    link_ubuntu_names; link_packages; post_steps ;;
  check)    check_tools ;;
esac
