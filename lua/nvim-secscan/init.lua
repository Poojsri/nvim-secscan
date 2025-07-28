local M = {}

-- Configuration
M.config = {
  osv_api_url = "https://api.osv.dev/v1/query",
  enable_diagnostics = true,
  enable_floating_window = true,
  enable_suggestions = true,
  scanner = "osv", -- "osv" or "trivy"
  hide_low = false,
  upload_report = false,
  python_tools = { "bandit", "osv" },
  javascript_tools = { "osv" }
}

-- Store last scan results for summary
M.last_scan_results = {}

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  
  -- Create user commands
  vim.api.nvim_create_user_command("SecScan", function()
    M.scan_current_file()
  end, { desc = "Scan current file for security vulnerabilities" })
  
  vim.api.nvim_create_user_command("SecScanClear", function()
    M.clear_diagnostics()
  end, { desc = "Clear security scan diagnostics" })
  
  vim.api.nvim_create_user_command("SecScanReport", function()
    M.generate_project_report()
  end, { desc = "Generate comprehensive security report" })
  
  vim.api.nvim_create_user_command("SecScanSummary", function()
    M.show_last_summary()
  end, { desc = "Show security scan summary dashboard" })
end

-- Clear diagnostics
function M.clear_diagnostics()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.diagnostic.reset(vim.api.nvim_create_namespace("nvim-secscan"), bufnr)
  
  -- Clear suggestions
  local suggestions = require("nvim-secscan.suggestions")
  suggestions.clear_virtual_text(bufnr)
end

-- Main scan function
function M.scan_current_file()
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local filetype = vim.bo.filetype
  
  if filepath == "" then
    vim.notify("No file open", vim.log.levels.WARN)
    return
  end
  
  vim.notify("Scanning " .. vim.fn.fnamemodify(filepath, ":t") .. "...", vim.log.levels.INFO)
  
  if filetype == "python" then
    M.scan_python_file(filepath, bufnr)
  elseif filetype == "javascript" or filetype == "typescript" then
    M.scan_javascript_file(filepath, bufnr)
  else
    vim.notify("Unsupported file type: " .. filetype, vim.log.levels.WARN)
  end
end

-- Python scanning
function M.scan_python_file(filepath, bufnr)
  local results = {}
  
  -- Use configured scanner for dependencies
  if M.config.scanner == "trivy" then
    local trivy = require("nvim-secscan.trivy")
    local trivy_results = trivy.scan_file(filepath)
    if trivy_results then
      vim.list_extend(results, trivy_results)
    end
  else
    -- Fallback to OSV
    local deps_results = M.scan_python_dependencies(filepath)
    if deps_results then
      vim.list_extend(results, deps_results)
    end
  end
  
  -- Scan with Bandit for code patterns
  local bandit_results = M.run_bandit(filepath)
  if bandit_results then
    vim.list_extend(results, bandit_results)
  end
  
  -- Show suggestions if enabled
  if M.config.enable_suggestions then
    M.show_code_suggestions(filepath, bufnr)
  end
  
  M.display_results(results, bufnr)
  
  -- Store results for summary
  M.last_scan_results = results
end

-- JavaScript scanning
function M.scan_javascript_file(filepath, bufnr)
  local results = {}
  
  -- Use configured scanner
  if M.config.scanner == "trivy" then
    local trivy = require("nvim-secscan.trivy")
    local trivy_results = trivy.scan_file(filepath)
    if trivy_results then
      vim.list_extend(results, trivy_results)
    end
  else
    local deps_results = M.scan_javascript_dependencies(filepath)
    if deps_results then
      vim.list_extend(results, deps_results)
    end
  end
  
  -- Show suggestions if enabled
  if M.config.enable_suggestions then
    M.show_code_suggestions(filepath, bufnr)
  end
  
  M.display_results(results, bufnr)
  
  -- Store results for summary
  M.last_scan_results = results
end

-- Show code suggestions
function M.show_code_suggestions(filepath, bufnr)
  local suggestions = require("nvim-secscan.suggestions")
  local filetype = vim.bo.filetype
  
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    local line_suggestions = suggestions.get_suggestions(line, filetype)
    if #line_suggestions > 0 then
      suggestions.show_virtual_text(bufnr, i, line_suggestions)
    end
  end
end

-- Generate project report
function M.generate_project_report()
  local report = require("nvim-secscan.report")
  local results = report.generate_report(M.config)
  
  -- Show summary after report generation
  local dashboard = require("nvim-secscan.dashboard")
  dashboard.show_summary(results, M.config)
end

-- Show last scan summary
function M.show_last_summary()
  local dashboard = require("nvim-secscan.dashboard")
  dashboard.show_summary(M.last_scan_results, M.config)
end

-- Run Bandit scan
function M.run_bandit(filepath)
  local cmd = string.format("bandit -f json %s 2>/dev/null", vim.fn.shellescape(filepath))
  local handle = io.popen(cmd)
  if not handle then return nil end
  
  local output = handle:read("*a")
  handle:close()
  
  if output == "" then return nil end
  
  local ok, data = pcall(vim.json.decode, output)
  if not ok or not data.results then return nil end
  
  local results = {}
  for _, result in ipairs(data.results) do
    table.insert(results, {
      line = result.line_number,
      col = 1,
      severity = result.issue_severity == "HIGH" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
      message = string.format("[%s] %s", result.test_id, result.issue_text),
      source = "bandit",
      severity_raw = result.issue_severity
    })
  end
  
  return results
end

-- Scan Python dependencies
function M.scan_python_dependencies(filepath)
  local dir = vim.fn.fnamemodify(filepath, ":h")
  local req_file = dir .. "/requirements.txt"
  
  if vim.fn.filereadable(req_file) == 0 then
    return nil
  end
  
  local packages = {}
  for line in io.lines(req_file) do
    line = line:gsub("%s+", "")
    if line ~= "" and not line:match("^#") then
      local pkg, version = line:match("([^=<>!]+)[=<>!]*([%d%.]*)")
      if pkg then
        table.insert(packages, { package = pkg:lower(), version = version or "" })
      end
    end
  end
  
  return M.query_osv_vulnerabilities(packages)
end

-- Scan JavaScript dependencies
function M.scan_javascript_dependencies(filepath)
  local dir = vim.fn.fnamemodify(filepath, ":h")
  local pkg_file = dir .. "/package.json"
  
  if vim.fn.filereadable(pkg_file) == 0 then
    return nil
  end
  
  local content = table.concat(vim.fn.readfile(pkg_file), "\n")
  local ok, data = pcall(vim.json.decode, content)
  if not ok then return nil end
  
  local packages = {}
  if data.dependencies then
    for pkg, version in pairs(data.dependencies) do
      version = version:gsub("^[^%d]*", "") -- Remove ^ ~ etc
      table.insert(packages, { package = pkg, version = version })
    end
  end
  
  return M.query_osv_vulnerabilities(packages, "npm")
end

-- Query OSV.dev API
function M.query_osv_vulnerabilities(packages, ecosystem)
  if #packages == 0 then return nil end
  
  local results = {}
  ecosystem = ecosystem or "PyPI"
  
  for _, pkg in ipairs(packages) do
    local query = {
      package = {
        name = pkg.package,
        ecosystem = ecosystem
      }
    }
    
    if pkg.version ~= "" then
      query.version = pkg.version
    end
    
    local json_data = vim.json.encode(query)
    local cmd = string.format(
      'curl -s -X POST -H "Content-Type: application/json" -d %s %s',
      vim.fn.shellescape(json_data),
      M.config.osv_api_url
    )
    
    local handle = io.popen(cmd)
    if handle then
      local output = handle:read("*a")
      handle:close()
      
      local ok, data = pcall(vim.json.decode, output)
      if ok and data.vulns then
        for _, vuln in ipairs(data.vulns) do
          table.insert(results, {
            line = 1,
            col = 1,
            severity = vim.diagnostic.severity.ERROR,
            message = string.format(
              "[%s] %s - %s (Package: %s)",
              vuln.id,
              vuln.summary or "Security vulnerability",
              vuln.details and vuln.details:sub(1, 100) or "No details available",
              pkg.package
            ),
            source = "osv",
            cve_id = vuln.id,
            package = pkg.package,
            severity_raw = "HIGH"
          })
        end
      end
    end
  end
  
  return results
end

-- Display results
function M.display_results(results, bufnr)
  if M.config.enable_diagnostics then
    local ns = vim.api.nvim_create_namespace("nvim-secscan")
    vim.diagnostic.reset(ns, bufnr)
    
    if #results > 0 then
      vim.diagnostic.set(ns, bufnr, results)
    end
  end
  
  if M.config.enable_floating_window and #results > 0 then
    M.show_floating_window(results)
  end
  
  -- Show dashboard summary
  local dashboard = require("nvim-secscan.dashboard")
  dashboard.show_summary(results, M.config)
  
  local count = #results
  if count == 0 then
    vim.notify("No security issues found!", vim.log.levels.INFO)
  else
    vim.notify(string.format("Found %d security issue%s", count, count == 1 and "" or "s"), vim.log.levels.WARN)
  end
end

-- Show floating window with results
function M.show_floating_window(results)
  local lines = { "Security Scan Results:", "" }
  
  for i, result in ipairs(results) do
    table.insert(lines, string.format("%d. %s", i, result.message))
    table.insert(lines, string.format("   Source: %s", result.source))
    table.insert(lines, "")
  end
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "secscan")
  
  local width = math.min(80, vim.o.columns - 4)
  local height = math.min(#lines + 2, vim.o.lines - 4)
  
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " Security Scan Results ",
    title_pos = "center"
  }
  
  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_win_set_option(win, "wrap", true)
  
  -- Close on escape or q
  vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<cr>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>close<cr>", { noremap = true, silent = true })
end

return M