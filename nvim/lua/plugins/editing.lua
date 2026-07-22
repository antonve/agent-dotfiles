return {
  {
    'numToStr/Comment.nvim',
    keys = {
      { 'gc', mode = { 'n', 'v' } },
      { 'gcc' },
      -- nerdcommenter muscle memory
      { '<leader>c<Space>', '<Plug>(comment_toggle_linewise_current)', desc = 'Toggle comment' },
      { '<leader>c<Space>', '<Plug>(comment_toggle_linewise_visual)', mode = 'v', desc = 'Toggle comment' },
    },
    opts = { padding = true },
  },
  {
    'kylechui/nvim-surround', -- ys / cs / ds, same keys as surround.vim
    event = 'BufWinEnter',
    config = true,
  },
  {
    'folke/flash.nvim', -- easymotion replacement: s{char} jumps anywhere
    keys = {
      { 's', mode = { 'n', 'x', 'o' }, function() require('flash').jump() end, desc = 'Flash jump' },
    },
    opts = {
      modes = { char = { enabled = false } }, -- keep native f/t
    },
  },
}
