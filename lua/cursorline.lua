local M = {}

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local timer = vim.loop.new_timer()
local wo = vim.wo

local options = {
  auto_hide = true,
  disabled_filetypes = {},
  timeout = 1000,
}

local function create(opts)
  local group = augroup('cursorline', { clear = true })

  if opts.auto_hide then
    autocmd({ 'InsertLeave', 'WinEnter' }, {
      group = group,
      callback = function()
        wo.cursorline = true
      end,
    })

    autocmd({ 'InsertEnter', 'WinLeave' }, {
      group = group,
      callback = function()
        wo.cursorline = false
      end,
    })
  end

  return autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = group,
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
end

local function delete(id)
  vim.cmd [[ autocmd! cursorline ]]
  vim.api.nvim_set_var(id, nil)
  timer:start(
    0,
    0,
    vim.schedule_wrap(function()
      wo.cursorline = false
    end)
  )
end

function M.setup(opts)
  opts = vim.tbl_deep_extend('force', options, opts or {})
  local group = augroup('cursorline.nvim', { clear = true })
  local id = 'cursorline.nvim'
  local status = 'cl.status'
  vim.api.nvim_set_var(id, nil)

  autocmd('BufEnter', {
    group = group,
    callback = function()
      if pcall(vim.api.nvim_buf_get_var, 0, status) then
        if vim.api.nvim_get_var(id) then
          delete(id)
        end
        return
      end

      if not vim.api.nvim_get_var(id) then
        wo.cursorline = true
        vim.api.nvim_set_var(id, create(opts))
      end
    end,
  })

  autocmd('FileType', {
    pattern = opts.disabled_filetypes,
    group = group,
    callback = function()
      vim.api.nvim_buf_set_var(0, status, true)
      if vim.api.nvim_get_var(id) then
        delete(id)
      end
    end,
  })

  if not vim.api.nvim_get_var(id) then
    if not vim.tbl_contains(opts.disabled_filetypes, vim.o.filetype) then
      wo.cursorline = true
      vim.api.nvim_set_var(id, create(opts))
    end
  end
end

return M
