local M = {}

-- Secure code patterns database
M.patterns = {
  python = {
    ["eval("] = {
      suggestion = "Use ast.literal_eval() for safe evaluation of literals",
      replacement = "ast.literal_eval(",
      severity = "HIGH"
    },
    ["exec("] = {
      suggestion = "Avoid exec(). Consider safer alternatives like importlib",
      replacement = nil,
      severity = "HIGH"
    },
    ["pickle.loads("] = {
      suggestion = "Use json.loads() or safer serialization methods",
      replacement = "json.loads(",
      severity = "HIGH"
    },
    ["os.system("] = {
      suggestion = "Use subprocess.run() with shell=False for safer execution",
      replacement = "subprocess.run([",
      severity = "MEDIUM"
    },
    ["shell=True"] = {
      suggestion = "Set shell=False and pass command as list for security",
      replacement = "shell=False",
      severity = "MEDIUM"
    },
    ["random.random()"] = {
      suggestion = "Use secrets.SystemRandom() for cryptographic purposes",
      replacement = "secrets.SystemRandom().random()",
      severity = "LOW"
    }
  },
  javascript = {
    ["eval("] = {
      suggestion = "Use JSON.parse() for data or safer evaluation methods",
      replacement = "JSON.parse(",
      severity = "HIGH"
    },
    ["innerHTML"] = {
      suggestion = "Use textContent or sanitize HTML to prevent XSS",
      replacement = "textContent",
      severity = "MEDIUM"
    },
    ["document.write("] = {
      suggestion = "Use DOM manipulation methods instead of document.write",
      replacement = "element.appendChild(",
      severity = "MEDIUM"
    }
  }
}

-- Get suggestions for a line of code
function M.get_suggestions(line_content, filetype)
  local suggestions = {}
  local lang_patterns = M.patterns[filetype]
  
  if not lang_patterns then return suggestions end
  
  for pattern, info in pairs(lang_patterns) do
    if line_content:find(pattern, 1, true) then
      table.insert(suggestions, {
        pattern = pattern,
        suggestion = info.suggestion,
        replacement = info.replacement,
        severity = info.severity
      })
    end
  end
  
  return suggestions
end

-- Show suggestion as virtual text
function M.show_virtual_text(bufnr, line_num, suggestions)
  local ns = vim.api.nvim_create_namespace("nvim-secscan-suggestions")
  
  for _, suggestion in ipairs(suggestions) do
    local text = string.format("💡 %s", suggestion.suggestion)
    vim.api.nvim_buf_set_extmark(bufnr, ns, line_num - 1, 0, {
      virt_text = {{text, "Comment"}},
      virt_text_pos = "eol"
    })
  end
end

-- Clear virtual text suggestions
function M.clear_virtual_text(bufnr)
  local ns = vim.api.nvim_create_namespace("nvim-secscan-suggestions")
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

-- Show suggestions in floating window
function M.show_suggestions_window(suggestions, line_num)
  if #suggestions == 0 then return end
  
  local lines = {string.format("💡 Security Suggestions (Line %d):", line_num), ""}
  
  for i, suggestion in ipairs(suggestions) do
    table.insert(lines, string.format("%d. Pattern: %s", i, suggestion.pattern))
    table.insert(lines, string.format("   %s", suggestion.suggestion))
    if suggestion.replacement then
      table.insert(lines, string.format("   Try: %s", suggestion.replacement))
    end
    table.insert(lines, "")
  end
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  
  local width = math.min(60, vim.o.columns - 4)
  local height = math.min(#lines + 2, vim.o.lines - 4)
  
  local opts = {
    relative = "cursor",
    width = width,
    height = height,
    col = 0,
    row = 1,
    style = "minimal",
    border = "rounded",
    title = " Security Suggestions ",
    title_pos = "center"
  }
  
  local win = vim.api.nvim_open_win(buf, false, opts)
  
  -- Auto-close after 5 seconds
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, 5000)
end

return M