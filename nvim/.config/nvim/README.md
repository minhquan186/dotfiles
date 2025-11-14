# My Personal Neovim Configuration

A modern, efficient Neovim configuration built for productivity with LSP support, fuzzy finding, and beautiful UI.

## Requirements

- Neovim >= 0.12
- Git
- Node.js (for some LSP servers)
- Ripgrep (for Telescope live grep)
- A Nerd Font (for icons)

## Installation

```bash
git clone --branch=nvim_0_12 https://github.com/minhquan186/nvim ~/.config/nvim && nvim
```

## Plugins

| Plugin | Description | Repository |
|--------|-------------|-----------|
| which-key.nvim | Displays available keybindings in popup | [folke/which-key.nvim](https://github.com/folke/which-key.nvim) |
| nvim-web-devicons | Adds file type icons to Neovim plugins | [nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) |
| gitsigns.nvim | Git integration for buffers | [lewis6991/gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) |
| mini.pairs | Auto-close and auto-delete matching pairs | [nvim-mini/mini.pairs](https://github.com/nvim-mini/mini.pairs) |
| mini.indentscope | Visualize and operate on indent scope | [nvim-mini/mini.indentscope](https://github.com/nvim-mini/mini.indentscope) |
| mini.files | File explorer with column view | [nvim-mini/mini.files](https://github.com/nvim-mini/mini.files) |
| mini.animate | Animate common Neovim actions | [nvim-mini/mini.animate](https://github.com/nvim-mini/mini.animate) |
| plenary.nvim | Lua utility functions for Neovim plugins | [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim) |
| telescope.nvim | Fuzzy finder over lists | [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) |
| mason.nvim | Portable package manager for LSP servers, DAP servers, linters, and formatters | [mason-org/mason.nvim](https://github.com/mason-org/mason.nvim) |
| blink.cmp | Fast completion plugin with LSP, snippet, and buffer support | [saghen/blink.cmp](https://github.com/saghen/blink.cmp) |
| lualine.nvim | Fast and customizable statusline | [nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) |
| alpha-nvim | Fast and customizable start screen | [goolord/alpha-nvim](https://github.com/goolord/alpha-nvim) |
| catppuccin | Soothing pastel theme | [catppuccin/nvim](https://github.com/catppuccin/nvim) |

## LSP Support

| Language | LSP Server |
|----------|-----------|
| Bash/Shell | bash-language-server |
| BitBake | bitbake-language-server |
| C/C++ | clangd |
| CMake | cmake-language-server |
| Python | jedi-language-server |
| Lua | lua-language-server |

## Keymappings

**Leader Key:** `<Space>`

### General

| Keymap | Description |
|--------|-------------|
| `<leader>pu` | Update vim.pack() |
| `<leader>yf` | Copy relative filepath |
| `<A-z>` | Toggle line wrapping |
| `<Esc>` | Clear search highlights |

### Navigation

| Keymap | Description |
|--------|-------------|
| `<C-h>` | Move to left window |
| `<C-j>` | Move to window below |
| `<C-k>` | Move to window above |
| `<C-l>` | Move to right window |
| `<C-d>` | Scroll down and center |
| `<C-u>` | Scroll up and center |

### Window Management

| Keymap | Description |
|--------|-------------|
| `<C-Up>` | Decrease window height |
| `<C-Down>` | Increase window height |
| `<C-Left>` | Decrease window width |
| `<C-Right>` | Increase window width |
| `<leader>sv` | Split window vertically |
| `<leader>sh` | Split window horizontally |
| `<leader>sx` | Close current split |

### Tab Management

| Keymap | Description |
|--------|-------------|
| `<leader>to` | Open new tab |
| `<leader>tx` | Close current tab |
| `<leader>tn` | Go to next tab |
| `<leader>tp` | Go to previous tab |
| `<leader>tf` | Open current buffer in new tab |

### Buffer Management

| Keymap | Description |
|--------|-------------|
| `<S-h>` | Previous buffer |
| `<S-l>` | Next buffer |
| `<leader>x` | Close buffer |

### Line Numbers

| Keymap | Description |
|--------|-------------|
| `<leader>n` | Toggle line numbers |
| `<leader>rn` | Toggle relative line numbers |

### File Explorer

| Keymap | Description |
|--------|-------------|
| `<leader>e` | Toggle MiniFiles explorer |

### Telescope (Fuzzy Finder)

| Keymap | Description |
|--------|-------------|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep (search in files) |
| `<leader>fb` | Find buffers |
| `<leader>fh` | Search help tags |
| `<C-k>` (in Telescope) | Move to previous result |
| `<C-j>` (in Telescope) | Move to next result |
| `<C-q>` (in Telescope) | Send to quickfix list |

### Visual Mode

| Keymap | Description |
|--------|-------------|
| `<` | Decrease indent and reselect |
| `>` | Increase indent and reselect |

### Completion (blink.cmp)

| Keymap | Description |
|--------|-------------|
| `<C-space>` | Show completion menu / documentation |
| `<C-e>` | Hide completion menu |
| `<CR>` | Accept completion |
| `<Tab>` | Snippet forward |
| `<S-Tab>` | Snippet backward |
| `<C-p>` | Select previous item |
| `<C-n>` | Select next item |
| `<C-b>` | Scroll documentation up |
| `<C-f>` | Scroll documentation down |
| `<C-k>` | Show/hide signature help |

