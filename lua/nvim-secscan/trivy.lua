local M = {}

-- Check if Trivy is available
function M.is_available()
  local handle = io.popen("trivy --version 2>/dev/null")
  if not handle then return false end
  local result = handle:read("*a")
  handle:close()
  return result ~= ""
end

-- Scan file with Trivy
function M.scan_file(filepath)
  if not M.is_available() then return nil end
  
  local cmd = string.format("trivy fs --format json --quiet %s 2>/dev/null", vim.fn.shellescape(filepath))
  local handle = io.popen(cmd)
  if not handle then return nil end
  
  local output = handle:read("*a")
  handle:close()
  
  if output == "" then return nil end
  
  local ok, data = pcall(vim.json.decode, output)
  if not ok or not data.Results then return nil end
  
  local results = {}
  for _, result in ipairs(data.Results) do
    if result.Vulnerabilities then
      for _, vuln in ipairs(result.Vulnerabilities) do
        table.insert(results, {
          line = 1,
          col = 1,
          severity = M.map_severity(vuln.Severity),
          message = string.format("[%s] %s - %s (Package: %s %s)",
            vuln.VulnerabilityID,
            vuln.Title or "Security vulnerability",
            (vuln.Description or ""):sub(1, 100),
            vuln.PkgName,
            vuln.InstalledVersion or ""
          ),
          source = "trivy",
          cve_id = vuln.VulnerabilityID,
          package = vuln.PkgName,
          severity_raw = vuln.Severity
        })
      end
    end
  end
  
  return results
end

-- Map Trivy severity to Neovim diagnostic severity
function M.map_severity(severity)
  local map = {
    CRITICAL = vim.diagnostic.severity.ERROR,
    HIGH = vim.diagnostic.severity.ERROR,
    MEDIUM = vim.diagnostic.severity.WARN,
    LOW = vim.diagnostic.severity.INFO,
    UNKNOWN = vim.diagnostic.severity.HINT
  }
  return map[severity] or vim.diagnostic.severity.WARN
end

return M