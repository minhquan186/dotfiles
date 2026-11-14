local autocmd = vim.api.nvim_create_autocmd

autocmd('VimLeave', {
  pattern = "*",
  command = "set guicursor=a:ver80-blinkon1"
})

autocmd('FileType', {
  pattern = "qf",
  command = "set nobuflisted"
})

-- Remove trailing whitespace on save, keeping the cursor/view and the last search.
-- Skipped where trailing spaces matter: markdown line breaks, diff/patch context lines.
local keep_trailing_ws = { markdown = true, diff = true }
autocmd('BufWritePre', {
  callback = function(args)
    local bo = vim.bo[args.buf]
    if keep_trailing_ws[bo.filetype] or bo.binary or not bo.modifiable then
      return
    end
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- Restore cursor position
autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    local line = vim.fn.line "'\""
    if
      line > 1
      and line <= vim.fn.line "$"
      and vim.bo.filetype ~= "commit"
      and vim.fn.index({ "xxd", "gitrebase" }, vim.bo.filetype) == -1
    then
      vim.cmd 'normal! g`"'
    end
  end,
})

-- Auto reload files on change
vim.o.autoread = true
autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
	command = "if mode() != 'c' | checktime | endif",
	pattern = { "*" },
})
