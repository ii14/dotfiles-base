local api = vim.api
local lsp = vim.lsp

local M = {}

M.map = function(type, key, value)
  vim.fn.nvim_buf_set_keymap(0, type, key, value, {noremap = true, silent = true});
end

M.has_lsp = function()
  for _ in pairs(lsp.buf_get_clients()) do
    return true
  end
  return false
end

M.on_attach = function(client, bufnr)
  api.nvim_command('setlocal signcolumn=yes')
  api.nvim_command('call VimrcLspOnAttach()')
  print(client.config.name .. ' LSP started.')
end

M.stop_clients = function()
  api.nvim_command('setlocal signcolumn=auto')
  lsp.stop_client(lsp.get_active_clients())
  print('LSP stopped.')
end

return M
