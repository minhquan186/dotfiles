#!/usr/bin/env bash
# Set up these dotfiles on a new machine, or refresh them after `git pull`.
# Safe to rerun: every step is skipped when it is already done.
#
#   ./install.sh            everything: packages, tools, links, post-steps, check
#   ./install.sh packages   apt packages from packages.txt only
#   ./install.sh tools      install missing tools apt cannot provide, using their
#                           official installers: wezterm starship neovim yazi font
#   ./install.sh tools vicinae   install the named tool(s) only; vicinae is opt-in
#   ./install.sh links      stow links + post-steps (use after git pull)
#   ./install.sh check      show installed tools and versions
#   -n   dry run: print what would be done      -y   do not ask before each tool
#
# sudo is used for apt, and by the WezTerm, Starship and Vicinae installers.
# Each tool installer shows what it will run and asks first. Files that are in
# the way of a link are moved to ~/.dotfiles-backup/<timestamp>/, never overwritten.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"

DRY=0
YES=0
CMD=all
NAMES=()
for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) DRY=1 ;;
    -y|--yes) YES=1 ;;
    all|packages|tools|links|check) CMD=$arg ;;
    -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $arg (try --help)" >&2; exit 2 ;;
    *) NAMES+=("$arg") ;;
  esac
done
if [ "${#NAMES[@]}" -gt 0 ] && [ "$CMD" != tools ]; then
  echo "unknown argument: ${NAMES[0]} (try --help)" >&2; exit 2
fi

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
NO_FOLD_DIRS=(.config/vicinae)
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
  local pkg dir
  # Apps that write their own files next to ours: keep these real directories,
  # so stow links the files inside instead of linking the whole directory into
  # the repo (Vicinae writes settings.json here)
  for dir in "${NO_FOLD_DIRS[@]}"; do
    if [ -L "$HOME/$dir" ]; then
      note "~/$dir is a link into the repo; replacing it with a real directory"
      run rm "$HOME/$dir"
    fi
    [ -d "$HOME/$dir" ] || run mkdir -p "$HOME/$dir"
  done
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
  vicinae_import
  note "Neovim installs its plugins on first start"
}

# Vicinae's settings.json is its own file (see vicinae/.config/vicinae/dotfiles.jsonc);
# make sure it imports the tracked dotfiles.jsonc. Vicinae reloads it on change.
vicinae_import() {
  local f="$HOME/.config/vicinae/settings.json"
  [ -f "$REPO/vicinae/.config/vicinae/dotfiles.jsonc" ] || return 0
  if [ ! -e "$f" ]; then
    note "vicinae: creating settings.json that imports dotfiles.jsonc"
    [ "$DRY" = 1 ] || printf '%s\n' '{ "imports": ["dotfiles.jsonc"] }' > "$f"
  elif grep -q 'dotfiles\.jsonc' "$f"; then
    ok "vicinae: settings.json imports dotfiles.jsonc"
  elif grep -q '"imports"' "$f"; then
    note "vicinae: add \"dotfiles.jsonc\" to the \"imports\" list in $f"
  elif grep -q '^{}$' "$f"; then
    note "vicinae: adding the dotfiles.jsonc import to settings.json"
    run sed -i 's/^{}$/{ "imports": ["dotfiles.jsonc"] }/' "$f"
  elif grep -q '^{$' "$f"; then
    note "vicinae: adding the dotfiles.jsonc import to settings.json"
    run sed -i '0,/^{$/s//{\n\t"imports": ["dotfiles.jsonc"],/' "$f"
  else
    note "vicinae: add \"imports\": [\"dotfiles.jsonc\"] to $f"
  fi
  if [ -f "$f" ] && grep -q '"theme"' "$f"; then
    note "vicinae: settings.json sets its own \"theme\", which overrides dotfiles.jsonc;"
    note "         remove that block from $f to use the repo's theme"
  fi
}

# ---------------------------------------------------------------------------
NVIM_MIN=0.12
YAZI_MIN=26.8.15
nvim_version() { nvim --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9.]*\).*/\1/p'; }
yazi_version() { yazi --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)+' | head -n1; }

TOOLS=(wezterm starship neovim yazi font)   # installed by `tools` when missing
OPTIONAL_TOOLS=(vicinae)                    # only when named: ./install.sh tools vicinae

# tool_state NAME: prints "ok [version]", "missing" or "old VERSION"
tool_state() {
  local v
  case "$1" in
    wezterm)  have wezterm  && echo ok || echo missing ;;
    starship) have starship && echo ok || echo missing ;;
    vicinae)  have vicinae  && echo ok || echo missing ;;
    neovim)
      have nvim || { echo missing; return; }
      v=$(nvim_version)
      if version_ge "${v:-0}" "$NVIM_MIN"; then echo "ok $v"; else echo "old ${v:-?}"; fi ;;
    yazi)
      have yazi || { echo missing; return; }
      v=$(yazi_version)
      if version_ge "${v:-0}" "$YAZI_MIN"; then echo "ok $v"; else echo "old ${v:-?}"; fi ;;
    font)
      # no grep -q: it would close the pipe early and fail under pipefail
      if have fc-list && fc-list | grep -iE "JetBrains ?Mono.*(Nerd|NF)" >/dev/null; then
        echo ok
      else
        echo missing
      fi ;;
    *) echo "unknown tool: $1" >&2; return 2 ;;
  esac
}

tool_title() {
  case "$1" in
    wezterm)  echo "WezTerm" ;;
    starship) echo "Starship" ;;
    neovim)   echo "Neovim (>= $NVIM_MIN)" ;;
    yazi)     echo "yazi (>= $YAZI_MIN)" ;;
    font)     echo "JetBrainsMono Nerd Font" ;;
    vicinae)  echo "Vicinae launcher (optional)" ;;
  esac
}

tool_docs() {
  case "$1" in
    wezterm)  echo "https://wezterm.org/install/linux.html" ;;
    starship) echo "https://starship.rs/guide/" ;;
    neovim)   echo "https://github.com/neovim/neovim/releases" ;;
    yazi)     echo "https://yazi-rs.github.io/docs/installation" ;;
    font)     echo "https://www.nerdfonts.com/font-downloads" ;;
    vicinae)  echo "https://docs.vicinae.com/install/linux" ;;
  esac
}

# What the installer does, shown before asking
tool_plan() {
  case "$1" in
    wezterm)  echo "add WezTerm's apt repo (apt.fury.io/wez) and apt install wezterm [sudo]" ;;
    starship) echo "curl -sS https://starship.rs/install.sh | sh -s -- -y   (/usr/local/bin) [sudo]" ;;
    neovim)   echo "latest release tarball from github.com/neovim -> ~/.local/opt, link ~/.local/bin/nvim" ;;
    yazi)
      if yazi_from_cargo; then
        echo "cargo install --force yazi-build   (updates your cargo install; compiles, takes a while)"
      else
        echo "latest release zip from github.com/sxyazi/yazi -> ~/.local/bin/{yazi,ya}"
      fi ;;
    font)     echo "JetBrainsMono.zip from github.com/ryanoasis/nerd-fonts -> ~/.local/share/fonts" ;;
    vicinae)  echo "curl -fsSL https://vicinae.com/install | bash   (/usr/local) [sudo]" ;;
  esac
}

yazi_from_cargo() {
  have cargo && [ "$(command -v yazi 2>/dev/null)" = "$HOME/.cargo/bin/yazi" ]
}

as_root() { if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi; }

linux_arch() {
  case "$(uname -m)" in
    x86_64)        echo "$1" ;;
    aarch64|arm64) echo "$2" ;;
    *) echo "unsupported CPU: $(uname -m)" >&2; return 1 ;;
  esac
}

do_install() {
  local tmp arch
  tmp=$(mktemp -d)
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp'" RETURN
  case "$1" in
    wezterm)
      curl -fsSL https://apt.fury.io/wez/gpg.key -o "$tmp/wez.key"
      as_root gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg "$tmp/wez.key"
      echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
        | as_root tee /etc/apt/sources.list.d/wezterm.list >/dev/null
      as_root chmod 644 /usr/share/keyrings/wezterm-fury.gpg
      as_root apt-get update
      as_root apt-get install -y wezterm
      ;;
    starship)
      curl -fsSL https://starship.rs/install.sh -o "$tmp/install.sh"
      sh "$tmp/install.sh" -y
      ;;
    neovim)
      arch=$(linux_arch x86_64 arm64)
      curl -fL --progress-bar -o "$tmp/nvim.tar.gz" \
        "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$arch.tar.gz"
      mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
      rm -rf "$HOME/.local/opt/nvim-linux-$arch"
      tar -xzf "$tmp/nvim.tar.gz" -C "$HOME/.local/opt"
      ln -sfn "$HOME/.local/opt/nvim-linux-$arch/bin/nvim" "$HOME/.local/bin/nvim"
      ;;
    yazi)
      if yazi_from_cargo; then
        cargo install --force yazi-build
      else
        arch=$(linux_arch x86_64 aarch64)
        curl -fL --progress-bar -o "$tmp/yazi.zip" \
          "https://github.com/sxyazi/yazi/releases/latest/download/yazi-$arch-unknown-linux-gnu.zip"
        unzip -q "$tmp/yazi.zip" -d "$tmp"
        mkdir -p "$HOME/.local/bin"
        install -m 755 "$tmp/yazi-$arch-unknown-linux-gnu/yazi" "$tmp/yazi-$arch-unknown-linux-gnu/ya" \
          "$HOME/.local/bin/"
      fi
      ;;
    font)
      curl -fL --progress-bar -o "$tmp/font.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
      mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
      unzip -qo "$tmp/font.zip" '*.ttf' -d "$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
      fc-cache -f
      ;;
    vicinae)
      curl -fsSL https://vicinae.com/install -o "$tmp/install.sh"
      bash "$tmp/install.sh"
      ;;
  esac
}

# confirm: true when the install should go ahead
confirm() {
  local reply
  [ "$YES" = 1 ] && return 0
  if [ ! -t 0 ]; then
    note "not a terminal, skipping (use -y to install without asking)"
    return 1
  fi
  read -r -p "          install now? [y/N] " reply
  case "$reply" in y|Y|yes) return 0 ;; *) return 1 ;; esac
}

install_tools() {
  step "tools from their official installers"
  local list=("${TOOLS[@]}") name state failed=0 rc
  [ "${#NAMES[@]}" -gt 0 ] && list=("${NAMES[@]}")
  if ! have curl; then
    bad "curl is not installed (run: ./install.sh packages)"; return 1
  fi
  for name in "${list[@]}"; do
    state=$(tool_state "$name") || exit 2
    case "$state" in
      ok*) ok "$(tool_title "$name")${state#ok}"; continue ;;
      old*) note "$(tool_title "$name"): found ${state#old }, too old" ;;
      *)    note "$(tool_title "$name"): not installed" ;;
    esac
    printf '          %s\n' "$(tool_plan "$name")"
    if [ "$DRY" = 1 ]; then continue; fi
    confirm || continue
    # set -e is ignored inside an `if` condition, so run the installer outside one
    set +e; (set -e; do_install "$name"); rc=$?; set -e
    if [ "$rc" -ne 0 ]; then
      bad "$(tool_title "$name"): installer failed, see $(tool_docs "$name")"
      failed=1; continue
    fi
    hash -r
    export PATH="$HOME/.local/bin:$PATH"
    state=$(tool_state "$name")
    case "$state" in
      ok*) ok "$(tool_title "$name")${state#ok} installed" ;;
      *)   bad "$(tool_title "$name"): installed, but the one found in PATH is still ${state}"
           note "open a new shell; if it persists, another copy comes first in PATH" ;;
    esac
    if [ "$name" = vicinae ]; then
      note "GNOME: install Vicinae's GNOME extension, start its server at login, and bind"
      note "a shortcut to 'vicinae toggle' (see the quickstart in $(tool_docs vicinae))"
    fi
  done
  return "$failed"
}

check_tools() {
  step "tools"
  local name state todo=0 cmd
  for name in "${TOOLS[@]}"; do
    state=$(tool_state "$name")
    case "$state" in
      ok*)  ok "$(tool_title "$name")${state#ok}" ;;
      old*) printf '  %sTOO OLD%s %s: found %s\n' "$R" "$Z" "$(tool_title "$name")" "${state#old }"; todo=1 ;;
      *)    bad "$(tool_title "$name")"; todo=1 ;;
    esac
  done
  # from packages.txt; shown here because older releases may not package them
  for cmd in eza delta fzf zoxide vivid ccache; do
    if have "$cmd"; then ok "$cmd"; else note "$cmd not installed (./install.sh packages; optional if apt lacks it)"; fi
  done
  for name in "${OPTIONAL_TOOLS[@]}"; do
    state=$(tool_state "$name")
    case "$state" in
      ok*) ok "$(tool_title "$name")" ;;
      *)   note "$(tool_title "$name"): not installed (./install.sh tools $name)" ;;
    esac
  done
  if [ "$todo" = 1 ]; then
    printf '\n  Install the flagged ones with: ./install.sh tools\n'
  fi
}

# ---------------------------------------------------------------------------
[ "$DRY" = 1 ] && printf '%sdry run: nothing will be changed%s\n' "$Y" "$Z"
case "$CMD" in
  all)      install_packages; link_ubuntu_names; install_tools || true; link_packages; post_steps; check_tools ;;
  packages) install_packages ;;
  tools)    install_tools ;;
  links)    link_ubuntu_names; link_packages; post_steps ;;
  check)    check_tools ;;
esac
