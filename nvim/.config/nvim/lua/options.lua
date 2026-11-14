local o = vim.opt

-----------
-- Misc  --
-----------
o.clipboard = 'unnamedplus'   -- use system clipboard
o.mouse = 'a'                 -- allow the mouse to be used in Nvim
o.swapfile = false            -- disable swap files creation
o.completeopt = {'menu', 'menuone', 'noselect'}

---------
-- Tab --
---------
o.autoindent = true           -- enable auto indentation
o.tabstop = 2                 -- number of visual spaces per TAB
o.softtabstop = 2             -- number of spaces in tab when editing
o.shiftwidth = 2              -- insert 2 spaces on a tab
o.expandtab = true            -- tabs are spaces, mainly because of python

---------------
-- UI config --
---------------
-- Editor
o.signcolumn = 'yes:1'         -- show sign column
o.number = true               -- show absolute number
o.relativenumber = false      -- add numbers to each line on the left side
o.numberwidth = 2             -- set number column width
o.cursorline = true           -- highlight cursor line underneath the cursor horizontally
o.splitbelow = true           -- open new horizontal splits below
o.splitright = true           -- open new vertical splits right
o.termguicolors = true        -- enable 24-bit RGB color in the TUI
o.showmode = false
o.winborder = 'rounded'
o.hlsearch = true

-- Fold
vim.wo.foldlevel = 99

-- Undo (undodir left at Neovim's default, ~/.local/state/nvim/undo, which it creates itself)
o.undofile = true             -- enable undo history

---------------
-- Searching --
---------------
o.incsearch = true            -- search as characters are entered
o.hlsearch = true             -- highlight matches
o.ignorecase = true           -- ignore case in searches by default
o.smartcase = true            -- but make it case sensitive if an uppercase is entered

------------------
-- Shell config --
------------------
-- vim.fn.has() returns 0 or 1, and 0 is truthy in Lua, so compare with 1
local is_windows = vim.fn.has("win32") == 1   -- also true on 64-bit Windows
if is_windows then
  local hasWSL = vim.fn.has("wsl") == 1
  if not hasWSL then
    o.shell = 'pwsh'
    local powershell_options = {
      shell = vim.fn.executable "pwsh" == 1 and "pwsh" or "powershell",
      shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;",
      shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait",
      shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode",
      shellquote = "",
      shellxquote = "",
    }

    for option, value in pairs(powershell_options) do
      vim.opt[option] = value
    end
  end
else
  o.shell = "bash"
end
