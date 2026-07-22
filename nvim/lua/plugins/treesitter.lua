return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master', -- the rewritten main branch drops the configs API used here
    build = ':TSUpdate',
    event = 'BufWinEnter',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = {
        'go', 'gomod', 'gosum',
        'typescript', 'tsx', 'javascript',
        'terraform', 'hcl',
        'proto', 'lua', 'nix', 'bash',
        'json', 'yaml', 'toml', 'markdown', 'markdown_inline',
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
}
