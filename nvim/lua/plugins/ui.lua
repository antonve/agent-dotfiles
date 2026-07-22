return {
  {
    'nvim-lualine/lualine.nvim',
    event = 'BufWinEnter',
    opts = {
      options = { theme = 'auto', icons_enabled = false, section_separators = '', component_separators = '|' },
    },
  },
  {
    'folke/which-key.nvim',
    lazy = false,
    config = true, -- popup showing what leader keys do
  },
}
