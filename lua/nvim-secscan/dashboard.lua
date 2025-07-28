local M = {}

-- Show security scan summary dashboard
function M.show_summary(results, config)
  local summary = M.calculate_summary(results)
  
  -- Filter by configured thresholds
  if config.hide_low and summary.low > 0 then
    summary.low = 0
    summary.total = summary.critical + summary.high + summary.medium
  end
  
  M.show_dashboard_window(summary)
end

-- Calculate summary from scan results
function M.calculate_summary(results)
  local summary = {
    critical = 0,
    high = 0,
    medium = 0,
    low = 0,
    total = 0,
    cves = 0,
    bandit_issues = 0,
    files_scanned = 0
  }
  
  if type(results) == "table" then
    -- Handle both single file results and project-wide results
    if results[1] and results[1].message then
      -- Single file results array
      summary.files_scanned = 1
      for _, result in ipairs(results) do
        M.categorize_result(result, summary)
      end
    else
      -- Project-wide results (filepath -> results mapping)
      for filepath, file_results in pairs(results) do
        summary.files_scanned = summary.files_scanned + 1
        for _, result in ipairs(file_results) do
          M.categorize_result(result, summary)
        end
      end
    end
  end
  
  summary.total = summary.critical + summary.high + summary.medium + summary.low
  
  return summary
end

-- Categorize individual result
function M.categorize_result(result, summary)
  -- Count by source
  if result.source == "osv" or result.source == "trivy" then
    summary.cves = summary.cves + 1
  elseif result.source == "bandit" then
    summary.bandit_issues = summary.bandit_issues + 1
  end
  
  -- Count by severity
  if result.severity_raw == "CRITICAL" then
    summary.critical = summary.critical + 1
  elseif result.severity == vim.diagnostic.severity.ERROR then
    summary.high = summary.high + 1
  elseif result.severity == vim.diagnostic.severity.WARN then
    summary.medium = summary.medium + 1
  else
    summary.low = summary.low + 1
  end
end

-- Show dashboard floating window
function M.show_dashboard_window(summary)
  local lines = {
    "🛡️  Security Scan Summary",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    ""
  }
  
  -- Severity breakdown
  if summary.critical > 0 then
    table.insert(lines, string.format("🔴 CRITICAL: %d", summary.critical))
  end
  if summary.high > 0 then
    table.insert(lines, string.format("🟠 HIGH:     %d", summary.high))
  end
  if summary.medium > 0 then
    table.insert(lines, string.format("🟡 MEDIUM:   %d", summary.medium))
  end
  if summary.low > 0 then
    table.insert(lines, string.format("🟢 LOW:      %d", summary.low))
  end
  
  table.insert(lines, "")
  table.insert(lines, string.format("📊 Total Issues: %d", summary.total))
  
  -- Source breakdown
  if summary.cves > 0 or summary.bandit_issues > 0 then
    table.insert(lines, "")
    table.insert(lines, "📋 Issue Sources:")
    if summary.cves > 0 then
      table.insert(lines, string.format("   CVEs: %d", summary.cves))
    end
    if summary.bandit_issues > 0 then
      table.insert(lines, string.format("   Code Issues: %d", summary.bandit_issues))
    end
  end
  
  if summary.files_scanned > 0 then
    table.insert(lines, "")
    table.insert(lines, string.format("📁 Files Scanned: %d", summary.files_scanned))
  end
  
  -- Status message
  table.insert(lines, "")
  if summary.total == 0 then
    table.insert(lines, "✅ No security issues found!")
  else
    local status = summary.critical > 0 and "🚨 Critical issues found!" or
                   summary.high > 0 and "⚠️  High severity issues found!" or
                   "ℹ️  Security issues detected"
    table.insert(lines, status)
  end
  
  M.create_dashboard_window(lines, summary)
end

-- Create and display dashboard window
function M.create_dashboard_window(lines, summary)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "secscan-dashboard")
  
  local width = math.max(40, math.min(60, vim.o.columns - 4))
  local height = math.min(#lines + 2, vim.o.lines - 4)
  
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " Security Dashboard ",
    title_pos = "center"
  }
  
  local win = vim.api.nvim_open_win(buf, true, opts)
  
  -- Add syntax highlighting
  M.setup_dashboard_highlights(buf)
  
  -- Keybindings
  local keymaps = {
    {"n", "q", "<cmd>close<cr>"},
    {"n", "<Esc>", "<cmd>close<cr>"},
    {"n", "r", function() 
      vim.api.nvim_win_close(win, true)
      vim.cmd("SecScan")
    end}
  }
  
  for _, keymap in ipairs(keymaps) do
    vim.api.nvim_buf_set_keymap(buf, keymap[1], keymap[2], 
      type(keymap[3]) == "string" and keymap[3] or "", 
      { noremap = true, silent = true, callback = type(keymap[3]) == "function" and keymap[3] or nil })
  end
  
  -- Show help text
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
    "",
    "Press 'q' to close, 'r' to rescan"
  })
end

-- Setup syntax highlighting for dashboard
function M.setup_dashboard_highlights(buf)
  vim.api.nvim_buf_call(buf, function()
    vim.cmd([[
      syntax match SecScanTitle /🛡️.*Summary/
      syntax match SecScanCritical /🔴.*CRITICAL.*/
      syntax match SecScanHigh /🟠.*HIGH.*/
      syntax match SecScanMedium /🟡.*MEDIUM.*/
      syntax match SecScanLow /🟢.*LOW.*/
      syntax match SecScanSuccess /✅.*/
      syntax match SecScanWarning /⚠️.*/
      syntax match SecScanError /🚨.*/
      
      highlight SecScanTitle guifg=#61AFEF gui=bold
      highlight SecScanCritical guifg=#E06C75 gui=bold
      highlight SecScanHigh guifg=#D19A66 gui=bold
      highlight SecScanMedium guifg=#E5C07B
      highlight SecScanLow guifg=#98C379
      highlight SecScanSuccess guifg=#98C379 gui=bold
      highlight SecScanWarning guifg=#D19A66 gui=bold
      highlight SecScanError guifg=#E06C75 gui=bold
    ]])
  end)
end

-- Quick summary for status line
function M.get_status_line_summary(results)
  local summary = M.calculate_summary(results)
  if summary.total == 0 then
    return "🛡️ Clean"
  end
  
  local parts = {}
  if summary.critical > 0 then table.insert(parts, string.format("C:%d", summary.critical)) end
  if summary.high > 0 then table.insert(parts, string.format("H:%d", summary.high)) end
  if summary.medium > 0 then table.insert(parts, string.format("M:%d", summary.medium)) end
  if summary.low > 0 then table.insert(parts, string.format("L:%d", summary.low)) end
  
  return string.format("🛡️ %s", table.concat(parts, " "))
end

return M