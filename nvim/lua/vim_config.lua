local o = vim.opt
vim.g.mapleader = ','          -- comma is the leader key

-- appearance
o.number = true
o.relativenumber = true
o.cursorline = true
o.colorcolumn = '90'
o.list = true
o.listchars = { tab = '▸ ', nbsp = '∘', extends = '❯', precedes = '❮' }
o.breakindent = true
o.showbreak = '   ›'
o.title = true
o.showmatch = true
o.signcolumn = 'yes'           -- sign column always visible

-- editing
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 0
o.smartindent = true
o.shiftround = true
o.textwidth = 0
o.formatoptions:append('lmoq') -- multibyte-friendly line breaking
o.undofile = true              -- persistent undo instead of backup/swap files
o.backup = false
o.swapfile = false
o.autoread = true
o.updatetime = 200

-- search
o.ignorecase = true
o.smartcase = true
o.gdefault = true              -- :s replaces all matches on a line by default
o.inccommand = 'nosplit'       -- live preview for search/replace
o.matchpairs:append('<:>')

-- windows
o.splitright = true
o.splitbelow = true
o.scrolloff = 5

-- integration
o.clipboard = 'unnamedplus'    -- share the system clipboard
vim.g.clipboard = 'osc52'      -- headless box: yank through the terminal, no X needed
o.mouse = ''                   -- no mouse; lets herdr keep host mouse capture off

-- filetype overrides
local aug = vim.api.nvim_create_augroup('vimrc', {})
vim.api.nvim_create_autocmd('FileType', {
  group = aug, pattern = { 'go', 'gomod' },
  callback = function() vim.opt_local.expandtab = false end,
})

-- highlight trailing whitespace and full-width spaces
vim.api.nvim_set_hl(0, 'TrailingSpace', { link = 'Error' })
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
  group = aug,
  callback = function()
    if vim.bo.buftype == '' and not vim.w.trailing_space_matches then
      vim.w.trailing_space_matches = true -- matches are per-window; add once
      vim.fn.matchadd('TrailingSpace', [[\s\+$]])
      vim.fn.matchadd('TrailingSpace', '　')
    end
  end,
})
