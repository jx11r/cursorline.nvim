local M = {}

local create_autocmd = vim.api.nvim_create_autocmd
local create_augroup = vim.api.nvim_create_augroup
local timer = vim.loop.new_timer()
local wo = vim.wo
local next = next

local options = {
  auto_hide = true,
  disabled_filetypes = {},
  timeout = 1000,
}

local function auto_hide()
  create_autocmd({ 'InsertLeave', 'WinEnter' }, {
    callback = function()
      wo.cursorline = true
    end,
  })

  create_autocmd({ 'InsertEnter', 'WinLeave' }, {
    callback = function()
      wo.cursorline = false
    end,
  })
end

local function show(opts)
  wo.cursorline = true
  create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    callback = function()
      wo.cursorline = false
      timer:start(
        opts.timeout,
        0,
        vim.schedule_wrap(function()
          wo.cursorline = true
        end)
      )
    end,
  })

  if opts.auto_hide then
    auto_hide()
  end
end

function M.setup(opts)
  opts = vim.tbl_deep_extend('force', options, opts or {})

  if not next(opts.disabled_filetypes) then
    show(opts)
    return
  end

  create_autocmd({ 'BufRead', 'BufWinEnter', 'BufNewFile' }, {
    group = create_augroup('cursorline.nvim', { clear = true }),
    callback = function(e)
      local ft = vim.bo[e.buf].filetype
      if not vim.tbl_contains(opts.disabled_filetypes, ft) then
        show(opts)
      end
    end,
  })
end

return M
