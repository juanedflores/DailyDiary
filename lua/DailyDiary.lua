local state = {
  floating = {
    buf = -1,
    win = -1,
  },
}

-- Shared by create_floating_window's default sizing and the VimResized
-- autocmd below, so both always agree on what "centered, near-fullscreen"
-- means.
local function compute_geometry(width, height)
  width = width or math.floor(vim.o.columns * 0.90)
  height = height or math.floor(vim.o.lines * 0.80)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  return width, height, col, row
end

local function create_floating_window(opts)
  opts = opts or {}
  local width, height, col, row = compute_geometry(opts.width, opts.height)

  -- Create a buffer
  local buf = nil
  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
  end

  -- Define window configuration
  local win_config = {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal', -- No borders or extra UI elements
    border = 'rounded',
  }

  -- Create the floating window
  local win = vim.api.nvim_open_win(buf, true, win_config)
  vim.cmd('execute(":VimwikiMakeDiaryNote")')
  vim.cmd('execute(":edit")')
  vim.cmd('execute(":set nowrap")')

  -- VimwikiMakeDiaryNote swaps the window onto the real, file-backed diary
  -- buffer rather than reusing our nofile scratch buffer (Vim only reuses
  -- the current buffer in place for a plain empty/unnamed buftype, not a
  -- scratch one) — so re-read whichever buffer the window actually ends up
  -- showing instead of assuming it's still the scratch `buf` we opened with.
  -- Without this, state.floating.buf pointed at an orphaned empty buffer.
  buf = vim.api.nvim_win_get_buf(win)

  return { buf = buf, win = win }
end

local toggle_terminal = function()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = create_floating_window({ buf = state.floating.buf })
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end

-- Global (not buffer-local) so <Esc> closes the diary float regardless of
-- which window/buffer currently has focus — e.g. if focus ends up somewhere
-- else entirely. Falls through to normal <Esc> behavior whenever the float
-- isn't open, so this changes nothing outside that one case.
vim.keymap.set('n', '<Esc>', function()
  if vim.api.nvim_win_is_valid(state.floating.win) then
    -- expr mappings run under textlock, which forbids window/buffer
    -- changes (E565) — defer the actual hide until after evaluation.
    local win = state.floating.win
    vim.schedule(function()
      vim.api.nvim_win_hide(win)
    end)
    return ''
  end
  return '<Esc>'
end, { expr = true, desc = 'Close DailyDiary float from anywhere' })

-- Example usage:
-- Create a floating window with default dimensions
vim.api.nvim_create_user_command('DailyDiaryToggle2', toggle_terminal, {})

-- Keep the diary float centered and sized to compute_geometry()'s ratio of
-- the editor when Neovim's window is resized, instead of staying pinned to
-- the old geometry.
vim.api.nvim_create_autocmd('VimResized', {
  callback = function()
    if vim.api.nvim_win_is_valid(state.floating.win) then
      local width, height, col, row = compute_geometry()
      vim.api.nvim_win_set_config(state.floating.win, {
        relative = 'editor',
        width = width,
        height = height,
        col = col,
        row = row,
      })
    end
  end,
})

-- Strips taskwiki's auto-injected syntax so the printed zine shows only what
-- was actually written, not Taskwarrior bookkeeping:
--   "## Goals for Today | status:pending due:(2026-09-13)" -> "## Goals for Today"
--   "* [ ] clean room (2026-09-13)  #534baf81"              -> "* [ ] clean room"
local function strip_taskwiki_syntax(text)
  local out_lines = {}
  for line in (text .. '\n'):gmatch('(.-)\n') do
    if line:match('^#+%s') then
      local heading_only = line:match('^(.-)%s*|')
      if heading_only then
        line = heading_only
      end
    end
    line = line:gsub('%s+#%x%x%x%x%x%x%x%x%s*$', '') -- trailing short-uuid tag
    line = line:gsub('%s+%(%d%d%d%d%-%d%d%-%d%d%)%s*$', '') -- trailing due-date
    table.insert(out_lines, line)
  end
  return table.concat(out_lines, '\n')
end

-- Renders the current buffer through the pandoc/eisvogel pipeline documented
-- in Workflows/DailyDiary.md (6 pagebreak-separated pages), rotates pages 2
-- and 5 with unipdf, then imposes all 6 onto one sheet with pdfjam in
-- fold-order (6,1,5,2,4,3) for a 2x3 zine booklet. Ends by opening the
-- finished booklet PDF; printing is left to the user (Cmd+P in Preview).
local function print_zine()
  local src = vim.api.nvim_buf_get_name(0)
  if src == '' then
    vim.notify('DailyDiaryZine: current buffer has no file', vim.log.levels.ERROR)
    return
  end
  vim.cmd('write')

  -- All vim.fn.expand() calls happen here, up front on the main loop —
  -- vim.system's on_exit callbacks run in a fast-event context where
  -- Vimscript calls like vim.fn.expand are not allowed (E5560).
  local downloads = vim.fn.expand('~/Downloads')
  local pdf = downloads .. '/dailyjournal.pdf'
  local rotated = downloads .. '/out_unipdf.pdf'
  local booklet = downloads .. '/journal-booklet.pdf'
  local eisvogel_template = vim.fn.expand('~/.pandoc/templates/eisvogel.tex')
  local disable_float_header = vim.fn.expand('~/.pandoc/headers/disable_float.tex')
  local columns_filter = vim.fn.expand('~/.pandoc/filters/columns.lua')
  local latex_environment_filter = vim.fn.expand('~/Library/Python/3.9/bin/pandoc-latex-environment')
  local unipdf_bin = vim.fn.expand('~/Tools/unipdf-cli/bin/unipdf')

  -- Pandoc reads a cleaned temp copy, not the real diary note — taskwiki
  -- still needs its raw filter/uuid syntax in the actual file to keep
  -- syncing tasks, so it's only stripped for what gets rendered.
  local cleaned = strip_taskwiki_syntax(table.concat(vim.fn.readfile(src), '\n'))
  local tmp_src = downloads .. '/.dailydiary-zine-source.md'
  vim.fn.writefile(vim.split(cleaned, '\n', { plain = true }), tmp_src)

  local pandoc_cmd = {
    'pandoc',
    tmp_src,
    '-f', 'markdown+implicit_figures',
    '-M', 'book=true',
    '-o', pdf,
    '-V', 'colorlinks=true',
    '-V', 'linkcolor=blue',
    '-V', 'urlcolor=red',
    '--template=' .. eisvogel_template,
    '--pdf-engine=/Library/TeX/texbin/lualatex',
    '--highlight-style=kate',
    '--include-in-header=' .. disable_float_header,
    '--lua-filter=' .. columns_filter,
    '--filter=' .. latex_environment_filter,
    '--listings',
    '-V', 'mainfont:AlgolRevived',
    '-V', 'monofont:AnonymiceProNerdFontMono-Regular',
    '-V', 'geometry:margin=1in',
    '-V', 'fontsize=13pt',
  }

  local function fail(step, res)
    vim.schedule(function()
      vim.notify('DailyDiaryZine: ' .. step .. ' failed (exit ' .. res.code .. ')\n' .. (res.stderr or ''), vim.log.levels.ERROR)
    end)
  end

  vim.notify('DailyDiaryZine: rendering PDF with pandoc...', vim.log.levels.INFO)
  vim.system(pandoc_cmd, { text = true }, function(pandoc_res)
    if pandoc_res.code ~= 0 then
      return fail('pandoc', pandoc_res)
    end

    local unipdf_cmd = {
      unipdf_bin, 'rotate',
      '-o', rotated, '-P', '2,5', pdf, '180',
    }
    vim.system(unipdf_cmd, { text = true }, function(unipdf_res)
      if unipdf_res.code ~= 0 then
        return fail('unipdf rotate', unipdf_res)
      end

      local pdfjam_cmd = {
        '/Library/TeX/texbin/pdfjam', rotated, '6,1,5,2,4,3',
        '--outfile', booklet, '--nup=2x3',
      }
      vim.system(pdfjam_cmd, { text = true }, function(pdfjam_res)
        if pdfjam_res.code ~= 0 then
          return fail('pdfjam', pdfjam_res)
        end
        vim.schedule(function()
          vim.fn.delete(tmp_src)
          vim.notify('DailyDiaryZine: booklet ready -> ' .. booklet, vim.log.levels.INFO)
          vim.system({ 'open', booklet })
        end)
      end)
    end)
  end)
end

vim.api.nvim_create_user_command('DailyDiaryZine', print_zine, {
  desc = 'Render current diary note as a 6-page zine booklet PDF and open it',
})
