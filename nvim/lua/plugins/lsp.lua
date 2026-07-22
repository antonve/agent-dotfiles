-- Language servers come from nixpkgs (see home.nix): gopls,
-- typescript-language-server, terraform-ls, lua-language-server, nil.
return {
  {
    'neovim/nvim-lspconfig',
    event = 'BufWinEnter',
    config = function()
      vim.lsp.enable({ 'gopls', 'ts_ls', 'terraformls', 'lua_ls', 'nil_ls' })

      -- coc-era keybindings
      local aug = vim.api.nvim_create_augroup('lsp_keys', {})
      vim.api.nvim_create_autocmd('LspAttach', {
        group = aug,
        callback = function(ev)
          local function nmap(lhs, rhs, desc)
            vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = desc })
          end
          nmap('gd', vim.lsp.buf.definition, 'Definition')
          nmap('gh', vim.lsp.buf.hover, 'Hover')
          nmap('gt', vim.lsp.buf.type_definition, 'Type definition')
          nmap('gi', vim.lsp.buf.implementation, 'Implementation')
          nmap('gR', function() require('fzf-lua').lsp_references() end, 'References')
          nmap('gr', vim.lsp.buf.rename, 'Rename')
          nmap('gq', vim.lsp.buf.code_action, 'Code action')
        end,
      })

      vim.api.nvim_create_user_command('Format', function()
        vim.lsp.buf.format()
      end, {})

      -- goimports on save (vim-go parity). Must run synchronously: the async
      -- code_action variant races the write and the format below.
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = aug,
        pattern = '*.go',
        callback = function(ev)
          local params = vim.lsp.util.make_range_params(0, 'utf-8')
          params.context = { only = { 'source.organizeImports' }, diagnostics = {} }
          local results = vim.lsp.buf_request_sync(ev.buf, 'textDocument/codeAction', params, 1000)
          for _, res in pairs(results or {}) do
            for _, action in pairs(res.result or {}) do
              if action.edit then
                vim.lsp.util.apply_workspace_edit(action.edit, 'utf-8')
              end
            end
          end
          vim.lsp.buf.format({ bufnr = ev.buf, timeout_ms = 1000 })
        end,
      })
    end,
  },
  {
    'saghen/blink.cmp',
    version = '1.*', -- prebuilt fuzzy-matcher binary
    event = 'InsertEnter',
    opts = {
      keymap = {
        preset = 'super-tab',            -- Tab confirms, like the coc setup
        ['<CR>'] = { 'accept', 'fallback' },
      },
      completion = { documentation = { auto_show = true } },
    },
  },
}
