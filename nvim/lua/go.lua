-- vim-go parity: run/test/build bindings and :A to switch to the test file
local aug = vim.api.nvim_create_augroup('go_bindings', {})

local function alternate(cmd)
  local file = vim.fn.expand('%')
  local target
  if file:match('_test%.go$') then
    target = file:gsub('_test%.go$', '.go')
  elseif file:match('%.go$') then
    target = file:gsub('%.go$', '_test.go')
  else
    return
  end
  vim.cmd(cmd .. ' ' .. vim.fn.fnameescape(target))
end

vim.api.nvim_create_autocmd('FileType', {
  group = aug,
  pattern = 'go',
  callback = function(ev)
    local function nmap(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = desc })
    end
    nmap('<leader>r', '<cmd>split | terminal go run %<cr>', 'go run')
    nmap('<leader>t', '<cmd>split | terminal go test ./%:h/...<cr>', 'go test')
    nmap('<leader>b', function()
      local file = vim.fn.expand('%')
      if file:match('_test%.go$') then
        vim.cmd('split | terminal go test -run xxx ./%:h/...') -- compile tests only
      else
        vim.cmd('split | terminal go build ./%:h/...')
      end
    end, 'go build')

    vim.api.nvim_buf_create_user_command(ev.buf, 'A', function() alternate('edit') end, {})
    vim.api.nvim_buf_create_user_command(ev.buf, 'AV', function() alternate('vsplit') end, {})
    vim.api.nvim_buf_create_user_command(ev.buf, 'AS', function() alternate('split') end, {})
    vim.api.nvim_buf_create_user_command(ev.buf, 'AT', function() alternate('tabedit') end, {})
  end,
})
