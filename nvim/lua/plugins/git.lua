return {
  {
    'tpope/vim-fugitive',
    cmd = { 'Git', 'G', 'Gdiffsplit', 'Gblame' },
  },
  {
    'lewis6991/gitsigns.nvim', -- gitgutter replacement
    event = 'BufWinEnter',
    opts = {},
  },
}
