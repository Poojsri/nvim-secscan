local M = {}

-- Generate comprehensive security report
function M.generate_report(config)
  local cwd = vim.fn.getcwd()
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  
  vim.notify("Generating security report...", vim.log.levels.INFO)
  
  -- Scan all relevant files
  local all_results = M.scan_project(cwd, config)
  
  -- Generate reports
  local md_report = M.generate_markdown_report(all_results, timestamp, cwd)
  local json_report = M.generate_json_report(all_results, timestamp, cwd)
  
  -- Write reports
  local md_file = cwd .. "/secscan-report.md"
  local json_file = cwd .. "/secscan-report.json"
  
  M.write_file(md_file, md_report)
  M.write_file(json_file, json_report)
  
  vim.notify(string.format("Reports generated: %s, %s", 
    vim.fn.fnamemodify(md_file, ":t"),
    vim.fn.fnamemodify(json_file, ":t")
  ), vim.log.levels.INFO)
  
  return all_results
end

-- Scan entire project
function M.scan_project(root_dir, config)
  local results = {}
  local file_patterns = {
    "*.py", "*.js", "*.ts", "requirements.txt", "package.json", "go.mod", "Dockerfile"
  }
  
  for _, pattern in ipairs(file_patterns) do
    local files = vim.fn.globpath(root_dir, "**/" .. pattern, false, true)
    
    for _, filepath in ipairs(files) do
      -- Skip common ignore patterns
      if not M.should_ignore_file(filepath) then
        local file_results = M.scan_single_file(filepath, config)
        if file_results and #file_results > 0 then
          results[filepath] = file_results
        end
      end
    end
  end
  
  return results
end

-- Scan single file
function M.scan_single_file(filepath, config)
  local results = {}
  local filetype = M.get_filetype(filepath)
  
  -- Use configured scanner
  if config.scanner == "trivy" then
    local trivy = require("nvim-secscan.trivy")
    local trivy_results = trivy.scan_file(filepath)
    if trivy_results then
      vim.list_extend(results, trivy_results)
    end
  else
    -- Fallback to OSV scanning logic
    local main = require("nvim-secscan")
    if filetype == "python" then
      local deps_results = main.scan_python_dependencies(filepath)
      if deps_results then vim.list_extend(results, deps_results) end
    elseif filetype == "javascript" then
      local deps_results = main.scan_javascript_dependencies(filepath)
      if deps_results then vim.list_extend(results, deps_results) end
    end
  end
  
  -- Add code pattern scanning
  if filetype == "python" then
    local main = require("nvim-secscan")
    local bandit_results = main.run_bandit(filepath)
    if bandit_results then
      vim.list_extend(results, bandit_results)
    end
  end
  
  return results
end

-- Generate Markdown report
function M.generate_markdown_report(results, timestamp, project_dir)
  local lines = {
    "# Security Scan Report",
    "",
    string.format("**Generated:** %s", timestamp),
    string.format("**Project:** %s", project_dir),
    "",
    "## Summary",
    ""
  }
  
  local summary = M.calculate_summary(results)
  table.insert(lines, string.format("- **Total Files Scanned:** %d", summary.files))
  table.insert(lines, string.format("- **Total Issues:** %d", summary.total))
  table.insert(lines, string.format("- **Critical:** %d", summary.critical))
  table.insert(lines, string.format("- **High:** %d", summary.high))
  table.insert(lines, string.format("- **Medium:** %d", summary.medium))
  table.insert(lines, string.format("- **Low:** %d", summary.low))
  table.insert(lines, "")
  table.insert(lines, "## Detailed Findings")
  table.insert(lines, "")
  
  for filepath, file_results in pairs(results) do
    local rel_path = vim.fn.fnamemodify(filepath, ":.")
    table.insert(lines, string.format("### %s", rel_path))
    table.insert(lines, "")
    
    for i, result in ipairs(file_results) do
      local severity = M.severity_to_string(result.severity)
      table.insert(lines, string.format("%d. **[%s]** Line %d: %s", 
        i, severity, result.line, result.message))
      if result.source then
        table.insert(lines, string.format("   - Source: %s", result.source))
      end
      table.insert(lines, "")
    end
  end
  
  return table.concat(lines, "\n")
end

-- Generate JSON report
function M.generate_json_report(results, timestamp, project_dir)
  local report = {
    metadata = {
      generated_at = timestamp,
      project_directory = project_dir,
      scanner_version = "nvim-secscan-1.0"
    },
    summary = M.calculate_summary(results),
    findings = {}
  }
  
  for filepath, file_results in pairs(results) do
    local rel_path = vim.fn.fnamemodify(filepath, ":.")
    report.findings[rel_path] = {}
    
    for _, result in ipairs(file_results) do
      table.insert(report.findings[rel_path], {
        line = result.line,
        column = result.col,
        severity = M.severity_to_string(result.severity),
        message = result.message,
        source = result.source,
        cve_id = result.cve_id,
        package = result.package
      })
    end
  end
  
  return vim.json.encode(report)
end

-- Calculate summary statistics
function M.calculate_summary(results)
  local summary = {files = 0, total = 0, critical = 0, high = 0, medium = 0, low = 0}
  
  for _, file_results in pairs(results) do
    summary.files = summary.files + 1
    for _, result in ipairs(file_results) do
      summary.total = summary.total + 1
      if result.severity == vim.diagnostic.severity.ERROR then
        if result.severity_raw == "CRITICAL" then
          summary.critical = summary.critical + 1
        else
          summary.high = summary.high + 1
        end
      elseif result.severity == vim.diagnostic.severity.WARN then
        summary.medium = summary.medium + 1
      else
        summary.low = summary.low + 1
      end
    end
  end
  
  return summary
end

-- Helper functions
function M.should_ignore_file(filepath)
  local ignore_patterns = {
    "node_modules", ".git", "__pycache__", ".pytest_cache", 
    "venv", ".venv", "build", "dist"
  }
  
  for _, pattern in ipairs(ignore_patterns) do
    if filepath:find(pattern, 1, true) then
      return true
    end
  end
  return false
end

function M.get_filetype(filepath)
  local ext = vim.fn.fnamemodify(filepath, ":e")
  local name = vim.fn.fnamemodify(filepath, ":t")
  
  if ext == "py" then return "python"
  elseif ext == "js" or ext == "ts" then return "javascript"
  elseif name == "requirements.txt" then return "python"
  elseif name == "package.json" then return "javascript"
  elseif name == "go.mod" then return "go"
  elseif name == "Dockerfile" then return "docker"
  end
  
  return "unknown"
end

function M.severity_to_string(severity)
  local map = {
    [vim.diagnostic.severity.ERROR] = "HIGH",
    [vim.diagnostic.severity.WARN] = "MEDIUM",
    [vim.diagnostic.severity.INFO] = "LOW",
    [vim.diagnostic.severity.HINT] = "INFO"
  }
  return map[severity] or "UNKNOWN"
end

function M.write_file(filepath, content)
  local file = io.open(filepath, "w")
  if file then
    file:write(content)
    file:close()
  end
end

return M