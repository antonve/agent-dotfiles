local map = vim.keymap.set

-- no arrow keys; wrapped-line-aware j/k
map('n', '<Up>', '<Nop>')
map('n', '<Down>', '<Nop>')
map('n', '<Left>', '<Nop>')
map('n', '<Right>', '<Nop>')
map({ 'n', 'v' }, 'j', 'gj')
map({ 'n', 'v' }, 'k', 'gk')

-- delete/change without clobbering the yank register
map('n', 'x', '"_x')
map('n', 'X', '"_X')
map({ 'n', 'v' }, 'c', '"_c')
map('n', 'C', '"_C')
map('v', 'x', '"_x')

-- yank to end of line; join without moving the cursor
map('n', 'Y', 'y$')
map('n', 'J', 'mZJ`ZmZ')

-- split line at cursor (inverse of J)
map('n', 'K', 'ylpr<CR>', { silent = true })
map('v', 'K', '<Nop>')

-- keep selection while indenting
map('v', '<', '<gv')
map('v', '>', '>gv')

-- undo-friendly <C-u>/<C-w> in insert mode
map('i', '<C-u>', '<C-g>u<C-u>')
map('i', '<C-w>', '<C-g>u<C-w>')

-- space motions
map({ 'n', 'v' }, '<Space>h', 'g^', { desc = 'Start of line' })
map({ 'n', 'v' }, '<Space>l', 'g$', { desc = 'End of line' })
map({ 'n', 'v' }, '<Space>m', '%', { desc = 'Matching pair' })
map('n', '<Space>o', 'mZo<Esc>`ZmZ', { desc = 'Blank line below' })
map('n', '<Space>O', 'mZO<Esc>`ZmZ', { desc = 'Blank line above' })
map({ 'n', 'v' }, '<Space>a', 'ggVG', { desc = 'Select all' })

-- select what was just pasted
map('n', 'gp', function()
  return '`[' .. vim.fn.strpart(vim.fn.getregtype(), 0, 1) .. '`]'
end, { expr = true, desc = 'Select pasted text' })

-- search: clear highlight, search/replace selection, replace word under cursor
map('n', '<C-l>', ':nohlsearch<CR><C-l>', { silent = true })
map('v', '<Space>/', [["xy/<C-r>=escape(@x, '\\/.*$^~')<CR>]])
map('v', '<Space>r', [["xy:%s/<C-r>=escape(@x, '\\/.*$^~')<CR>/]])
map('n', '<Space>*', [["xyiw:%s/\<<C-r>=escape(@x, '\\/.*$^~')<CR>\>/]])

-- tabs and windows
map('n', 'tn', ':tabnew<CR>', { silent = true })
map('n', 'tk', ':tabnext<CR>', { silent = true })
map('n', 'tj', ':tabprev<CR>', { silent = true })
map('n', '<C-w>t', ':tabnew<CR>', { silent = true })
map('n', '<C-w><C-t>', '<C-w>t', { remap = true })
map('n', '<C-w>v', ':vnew<CR>', { silent = true })
map('n', '<C-w><C-v>', '<C-w>v', { remap = true })
map('n', '<C-w>s', ':split +enew<CR>', { silent = true })
map('n', '<C-w><C-s>', '<C-w>s', { remap = true })
map('n', '<C-w>d', ':quit<CR>', { silent = true })
map('n', '<C-w><C-d>', '<C-w>d', { remap = true })
map('n', '<C-w>c', '<Nop>')
map('n', '<C-w><C-n>', 'gt')
map('n', '<C-w><C-b>', 'gT')

-- no accidental quit-without-saving; sudo write
map('n', 'ZQ', '<Nop>')
map('n', '<leader>W', ':w !sudo tee % > /dev/null<CR>')

-- sort lines inside the current block
map('n', '<leader>sor', [[?{<CR>jV/\v^\s*\}?$<CR>k:sort<CR>:noh<CR>]], { silent = true })
