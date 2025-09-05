local M = {}

-- Benchmark configuration
M.config = {
  warmup_runs = 3,
  benchmark_runs = 10,
  timeout = 30, -- seconds
  show_progress = true
}

-- Run a command multiple times and measure performance
function M.benchmark_command(cmd, runs, warmup)
  runs = runs or M.config.benchmark_runs
  warmup = warmup or M.config.warmup_runs
  
  local times = {}
  local total_runs = warmup + runs
  
  -- Warmup runs
  for i = 1, warmup do
    if M.config.show_progress then
      vim.notify(string.format("Warmup %d/%d", i, warmup), vim.log.levels.INFO)
    end
    os.execute(cmd .. " > /dev/null 2>&1")
  end
  
  -- Actual benchmark runs
  for i = 1, runs do
    if M.config.show_progress then
      vim.notify(string.format("Benchmark %d/%d", i, runs), vim.log.levels.INFO)
    end
    
    local start_time = vim.loop.hrtime()
    local exit_code = os.execute(cmd .. " > /dev/null 2>&1")
    local end_time = vim.loop.hrtime()
    
    local duration = (end_time - start_time) / 1e9 -- Convert to seconds
    table.insert(times, {
      duration = duration,
      exit_code = exit_code
    })
  end
  
  return M.analyze_results(times)
end

-- Analyze benchmark results
function M.analyze_results(times)
  if #times == 0 then
    return nil
  end
  
  local durations = {}
  local successful_runs = 0
  
  for _, result in ipairs(times) do
    if result.exit_code == 0 then
      table.insert(durations, result.duration)
      successful_runs = successful_runs + 1
    end
  end
  
  if #durations == 0 then
    return {
      error = "All benchmark runs failed",
      total_runs = #times,
      successful_runs = 0
    }
  end
  
  table.sort(durations)
  
  local sum = 0
  for _, duration in ipairs(durations) do
    sum = sum + duration
  end
  
  local mean = sum / #durations
  local median = durations[math.ceil(#durations / 2)]
  local min_time = durations[1]
  local max_time = durations[#durations]
  
  -- Calculate standard deviation
  local variance = 0
  for _, duration in ipairs(durations) do
    variance = variance + (duration - mean) ^ 2
  end
  local std_dev = math.sqrt(variance / #durations)
  
  return {
    total_runs = #times,
    successful_runs = successful_runs,
    mean = mean,
    median = median,
    min = min_time,
    max = max_time,
    std_dev = std_dev,
    times = durations
  }
end

-- Benchmark security scanners
function M.benchmark_scanners(filepath)
  local scanners = {
    {
      name = "bandit",
      cmd = string.format("bandit -f json %s", vim.fn.shellescape(filepath)),
      available = vim.fn.executable("bandit") == 1
    },
    {
      name = "nvim-secscan",
      cmd = string.format("python scripts/secscan-cli.py %s", vim.fn.shellescape(filepath)),
      available = true
    },
    {
      name = "trivy",
      cmd = string.format("trivy fs --format json %s", vim.fn.shellescape(vim.fn.fnamemodify(filepath, ":h"))),
      available = vim.fn.executable("trivy") == 1
    }
  }
  
  local results = {}
  
  for _, scanner in ipairs(scanners) do
    if scanner.available then
      vim.notify(string.format("Benchmarking %s...", scanner.name), vim.log.levels.INFO)
      local result = M.benchmark_command(scanner.cmd, 5, 2)
      if result then
        result.scanner = scanner.name
        table.insert(results, result)
      end
    else
      vim.notify(string.format("Skipping %s (not available)", scanner.name), vim.log.levels.WARN)
    end
  end
  
  return results
end

-- Benchmark code execution
function M.benchmark_code_execution(filepath)
  local filetype = vim.bo.filetype
  local cmd = nil
  
  if filetype == "python" then
    cmd = string.format("python %s", vim.fn.shellescape(filepath))
  elseif filetype == "javascript" then
    cmd = string.format("node %s", vim.fn.shellescape(filepath))
  elseif filetype == "lua" then
    cmd = string.format("lua %s", vim.fn.shellescape(filepath))
  else
    return { error = "Unsupported file type for execution benchmarking: " .. filetype }
  end
  
  vim.notify("Benchmarking code execution...", vim.log.levels.INFO)
  return M.benchmark_command(cmd, 10, 3)
end

-- Format benchmark results for display
function M.format_results(results)
  if results.error then
    return string.format("Error: %s", results.error)
  end
  
  local output = {}
  table.insert(output, string.format("Benchmark Results (%d successful runs):", results.successful_runs))
  table.insert(output, string.format("  Mean:   %.3f ms", results.mean * 1000))
  table.insert(output, string.format("  Median: %.3f ms", results.median * 1000))
  table.insert(output, string.format("  Min:    %.3f ms", results.min * 1000))
  table.insert(output, string.format("  Max:    %.3f ms", results.max * 1000))
  table.insert(output, string.format("  StdDev: %.3f ms", results.std_dev * 1000))
  
  return table.concat(output, "\n")
end

-- Compare multiple benchmark results
function M.compare_results(results_list)
  if #results_list < 2 then
    return "Need at least 2 results to compare"
  end
  
  local output = {}
  table.insert(output, "Scanner Performance Comparison:")
  table.insert(output, string.rep("-", 50))
  
  -- Sort by mean time
  table.sort(results_list, function(a, b)
    return (a.mean or math.huge) < (b.mean or math.huge)
  end)
  
  local fastest = results_list[1]
  
  for i, result in ipairs(results_list) do
    if result.error then
      table.insert(output, string.format("%d. %s: ERROR - %s", i, result.scanner, result.error))
    else
      local relative_speed = result.mean / fastest.mean
      local status = i == 1 and "FASTEST" or string.format("%.2fx slower", relative_speed)
      
      table.insert(output, string.format(
        "%d. %s: %.3f ms ± %.3f ms (%s)",
        i,
        result.scanner,
        result.mean * 1000,
        result.std_dev * 1000,
        status
      ))
    end
  end
  
  return table.concat(output, "\n")
end

-- Show benchmark results in floating window
function M.show_benchmark_results(results, title)
  title = title or "Benchmark Results"
  
  local content
  if type(results) == "table" and results[1] and results[1].scanner then
    -- Multiple scanner results
    content = M.compare_results(results)
  else
    -- Single result
    content = M.format_results(results)
  end
  
  local lines = vim.split(content, "\n")
  
  -- Create floating window
  local width = 60
  local height = #lines + 2
  local buf = vim.api.nvim_create_buf(false, true)
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = 'minimal',
    border = 'rounded',
    title = title,
    title_pos = 'center'
  }
  
  vim.api.nvim_open_win(buf, true, opts)
end

return M