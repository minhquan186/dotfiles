-----------------
-- Add Plugins --
-----------------

vim.pack.add({
  { src = "https://github.com/folke/which-key.nvim" }, -- Whichkey
  { src = "https://github.com/nvim-tree/nvim-web-devicons" }, -- Icons
  { src = "https://github.com/lewis6991/gitsigns.nvim" }, -- Gitsigns
  { src = "https://github.com/nvim-mini/mini.pairs" }, -- Auto bracket
  { src = "https://github.com/nvim-mini/mini.indentscope" }, -- Indentation highlight
  { src = "https://github.com/nvim-mini/mini.files" }, -- File Explorer
  { src = "https://github.com/nvim-mini/mini.animate" }, -- Animation
  { src = "https://github.com/nvim-lua/plenary.nvim" }, -- Plenary, nvim-telescope dependency
  { src = "https://github.com/nvim-telescope/telescope.nvim" }, -- Telescope
  { src = "https://github.com/mason-org/mason.nvim" }, -- Mason for LSP server
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("^1") }, -- Completion
  { src = "https://github.com/nvim-lualine/lualine.nvim" }, -- Lualine
  { src = "https://github.com/goolord/alpha-nvim" }, -- Dashboard
})

---------------------
-- Plugins' config --
---------------------

require("which-key").setup({})
require("nvim-web-devicons").setup({})
require("mini.pairs").setup({})
require("mini.indentscope").setup({})
require("mini.files").setup({})
require("mason").setup({})

-- Gitsigns
require("gitsigns").setup({
  signcolumn = true,
  current_line_blame = true,
})

-- Animation
local animate = require("mini.animate")
animate.setup({
  cursor = {
     -- Animate for 200 milliseconds with linear easing
      timing = animate.gen_timing.linear({ duration = 200, unit = 'total' }),

      -- Animate with shortest line for any cursor move
      path = animate.gen_path.line({}),
  }
})

-- Telescope
local telescope = require("telescope")
local actions = require("telescope.actions")
-- Action setup
telescope.setup({
  defaults = {
    path_display = { "smart" },
    mappings = {
      i = {
        ["<C-k>"] = actions.move_selection_previous, -- move to prev result
        ["<C-j>"] = actions.move_selection_next, -- move to next result
        ["<C-q>"] = actions.smart_send_to_qflist  + actions.open_qflist,
      },
    },
  },
})

-- Completion config
require('blink.cmp').setup({
    fuzzy = { implementation = 'prefer_rust_with_warning' },
    signature = { enabled = true },
    keymap = {
        preset = "default",
        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-e>'] = { 'hide', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },

        ['<Tab>'] = { 'snippet_forward', 'fallback' },
        ['<S-Tab>'] = { 'snippet_backward', 'fallback' },

        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
        ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
        ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },

        ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

        ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
    },

    appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "normal",
    },

    completion = {
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 200,
        },
        ghost_text = {
          enabled = false
        }
    },

    cmdline = {
        keymap = {
            preset = 'inherit',
            ['<CR>'] = { 'accept_and_enter', 'fallback' },
        },
    },

    sources = { default = { "lsp", "buffer", "snippets", "path" } }
})

-- Lualine
require('lualine').setup({
  options = {
    icons_enabled = true,
    theme = 'auto',
    component_separators = '',
    section_separators = { left = '', right = ''},
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    always_show_tabline = true,
    globalstatus = true,
    refresh = {
      statusline = 100,
      tabline = 100,
      winbar = 100,
    }
  },
  sections = {
    lualine_a = {
        {
            'mode',
            seperator =
            {
                left = ''
            },
            right_padding = 2
        }
    },
    lualine_b = {'branch', 'diff'},
    lualine_c = {
      {
        'windows',
        show_filename_only = true,   -- Shows shortened relative path when set to false.
        show_modified_status = true, -- Shows indicator when the window is modified.

        mode = 2, -- 0: Shows window name
                  -- 1: Shows window index
                  -- 2: Shows window name + window index

        max_length = vim.o.columns * 2 / 3, -- Maximum width of windows component,
                                            -- it can also be a function that returns
                                            -- the value of `max_length` dynamically.
        filetype_names = {
          TelescopePrompt = 'Telescope',
          fzf = 'FZF',
          alpha = 'Alpha'
        }, -- Shows specific window name for that filetype ( { `filetype` = `window_name`, ... } )
      }
    },
    lualine_x = {'diagnostics', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {
        {
            'location',
            seperator =
            {
                right = ''
            },
            left_padding = 2
        }
    }
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {
    "mason",
    "nvim-dap-ui",
  }
})

-- Alpha-nvim
local dashboard = require("alpha.themes.dashboard")

-- Set menu
dashboard.section.buttons.val = {
  dashboard.button("e", "  > New File", "<cmd>ene<CR>"),
  dashboard.button("SPC e", "  > Toggle file explorer", "<cmd>lua MiniFiles.open()<CR>"),
  dashboard.button("SPC ff", "󰱼  > Find File", "<cmd>Telescope find_files<CR>"),
  dashboard.button("SPC fg", "  > Find Word", "<cmd>Telescope live_grep<CR>"),
  -- dashboard.button("SPC wr", "󰁯  > Restore Session For Current Directory", "<cmd>SessionRestore<CR>"),
  dashboard.button("q", "  > Quit NVIM", "<cmd>qa<CR>"),
}

-- helper function for utf8 chars
local function getCharLen(s, pos)
  local byte = string.byte(s, pos)
  if not byte then
    return nil
  end
  return (byte < 0x80 and 1) or (byte < 0xE0 and 2) or (byte < 0xF0 and 3) or (byte < 0xF8 and 4) or 1
end

local function applyColors(logo, colors, logoColors)
  dashboard.section.header.val = logo

  for key, color in pairs(colors) do
    local name = "Alpha" .. key
    vim.api.nvim_set_hl(0, name, color)
    colors[key] = name
  end

  dashboard.section.header.opts.hl = {}
  for i, line in ipairs(logoColors) do
    local highlights = {}
    local pos = 0

    for j = 1, #line do
      local opos = pos
      pos = pos + getCharLen(logo[i], opos + 1)

      local color_name = colors[line:sub(j, j)]
      if color_name then
        table.insert(highlights, { color_name, opos, pos })
      end
    end

    table.insert(dashboard.section.header.opts.hl, highlights)
  end
  return dashboard.opts
end

require("alpha").setup(applyColors({
  [[  ███       ███  ]],
  [[  ████      ████ ]],
  [[  ████     █████ ]],
  [[ █ ████    █████ ]],
  [[ ██ ████   █████ ]],
  [[ ███ ████  █████ ]],
  [[ ████ ████ ████ ]],
  [[ █████  ████████ ]],
  [[ █████   ███████ ]],
  [[ █████    ██████ ]],
  [[ █████     █████ ]],
  [[ ████      ████ ]],
  [[  ███       ███  ]],
  [[                    ]],
  [[  N  E  O  V  I  M  ]],
}, {
  ["b"] = { fg = "#3399ff", ctermfg = 33 },
  ["a"] = { fg = "#53C670", ctermfg = 35 },
  ["g"] = { fg = "#39ac56", ctermfg = 29 },
  ["h"] = { fg = "#33994d", ctermfg = 23},
  ["i"] = { fg = "#33994d", bg = "#39ac56", ctermfg = 23, ctermbg = 29},
  ["j"] = { fg = "#53C670", bg = "#33994d", ctermfg = 35, ctermbg = 23 },
  ["k"] = { fg = "#30A572", ctermfg = 36},
}, {
  [[  kkkka       gggg  ]],
  [[  kkkkaa      ggggg ]],
  [[ b kkkaaa     ggggg ]],
  [[ bb kkaaaa    ggggg ]],
  [[ bbb kaaaaa   ggggg ]],
  [[ bbbb aaaaaa  ggggg ]],
  [[ bbbbb aaaaaa igggg ]],
  [[ bbbbb  aaaaaahiggg ]],
  [[ bbbbb   aaaaajhigg ]],
  [[ bbbbb    aaaaajhig ]],
  [[ bbbbb     aaaaajhi ]],
  [[ bbbbb      aaaaajh ]],
  [[  bbbb       aaaaa  ]],
  [[                    ]],
  [[  a  a  a  b  b  b  ]],
}))
