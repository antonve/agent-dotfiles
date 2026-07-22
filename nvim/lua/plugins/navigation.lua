-- fzf.vim replacement with the same <leader>f prefix bindings
local function files()
  -- git-aware file list, plain files outside a repo
  local fzf = require('fzf-lua')
  if vim.fn.executable('git') == 1
      and vim.fn.systemlist('git rev-parse --is-inside-work-tree')[1] == 'true' then
    fzf.git_files()
  else
    fzf.files()
  end
end

return {
  {
    'ibhagwan/fzf-lua',
    cmd = 'FzfLua',
    opts = {
      fzf_colors = true, -- inherit the colorscheme, like g:fzf_colors did
      winopts = { split = 'belowright new', height = 0.4 }, -- fzf_layout down ~40%
    },
    keys = {
      { '<leader>ff', files, desc = 'Files (git-aware)' },
      { '<leader>fi', '<cmd>FzfLua files<cr>', desc = 'Files' },
      { '<leader>fh', '<cmd>FzfLua oldfiles<cr>', desc = 'History' },
      { '<leader>fb', '<cmd>FzfLua buffers<cr>', desc = 'Buffers' },
      { '<leader>fl', '<cmd>FzfLua blines<cr>', desc = 'Buffer lines' },
      { '<leader>fr', '<cmd>FzfLua live_grep<cr>', desc = 'Rg' },
      { '<leader>fg', '<cmd>FzfLua grep_project<cr>', desc = 'Grep project' },
    },
  },
  {
    'stevearc/oil.nvim', -- edit the filesystem like a buffer
    opts = { view_options = { show_hidden = true } },
    keys = { { '<leader>e', '<cmd>Oil<cr>', desc = 'File browser' } },
  },
}
