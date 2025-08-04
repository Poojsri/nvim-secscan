local M = {}

-- Upload report to S3 and trigger Lambda
function M.upload_report(config)
  local cwd = vim.fn.getcwd()
  local report_file = cwd .. "/secscan-report.json"
  
  if vim.fn.filereadable(report_file) == 0 then
    vim.notify("No report found. Run :SecScanReport first", vim.log.levels.ERROR)
    return false
  end
  
  -- Read and parse report
  local content = table.concat(vim.fn.readfile(report_file), "\n")
  local ok, report_data = pcall(vim.json.decode, content)
  if not ok then
    vim.notify("Failed to parse report JSON", vim.log.levels.ERROR)
    return false
  end
  
  -- Check for HIGH severity issues
  local has_high_severity = M.check_high_severity(report_data)
  
  -- Upload to S3
  local s3_success = M.upload_to_s3(report_file, config)
  if not s3_success then
    return false
  end
  
  -- Trigger Lambda if HIGH severity found
  if has_high_severity then
    M.trigger_lambda(report_data, config)
  end
  
  return true
end

-- Check if report contains HIGH severity issues
function M.check_high_severity(report_data)
  if not report_data.summary then return false end
  
  local high_count = (report_data.summary.critical or 0) + (report_data.summary.high or 0)
  return high_count > 0
end

-- Upload report to S3
function M.upload_to_s3(report_file, config)
  local bucket = config.s3_bucket
  local key = string.format("security-reports/%s/secscan-report-%s.json", 
    vim.fn.fnamemodify(vim.fn.getcwd(), ":t"),
    os.date("%Y%m%d-%H%M%S")
  )
  
  local cmd = string.format("aws s3 cp %s s3://%s/%s", 
    vim.fn.shellescape(report_file), bucket, key)
  
  vim.notify("Uploading report to S3...", vim.log.levels.INFO)
  
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    vim.notify("Failed to execute AWS CLI", vim.log.levels.ERROR)
    return false
  end
  
  local output = handle:read("*a")
  local success = handle:close()
  
  if success then
    vim.notify(string.format("Report uploaded to s3://%s/%s", bucket, key), vim.log.levels.INFO)
    return true
  else
    vim.notify("S3 upload failed: " .. output, vim.log.levels.ERROR)
    return false
  end
end

-- Trigger Lambda function
function M.trigger_lambda(report_data, config)
  local lambda_function = config.lambda_function
  
  local payload = {
    severity = "HIGH",
    project = vim.fn.fnamemodify(vim.fn.getcwd(), ":t"),
    timestamp = os.date("%Y-%m-%dT%H:%M:%SZ"),
    summary = report_data.summary,
    total_issues = (report_data.summary.critical or 0) + (report_data.summary.high or 0)
  }
  
  local payload_json = vim.json.encode(payload)
  local temp_file = "/tmp/lambda-payload.json"
  
  -- Write payload to temp file
  local file = io.open(temp_file, "w")
  if file then
    file:write(payload_json)
    file:close()
  else
    vim.notify("Failed to create Lambda payload", vim.log.levels.ERROR)
    return false
  end
  
  local cmd = string.format("aws lambda invoke --function-name %s --payload file://%s /tmp/lambda-response.json",
    lambda_function, temp_file)
  
  vim.notify("Triggering Lambda function...", vim.log.levels.INFO)
  
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    vim.notify("Failed to invoke Lambda", vim.log.levels.ERROR)
    return false
  end
  
  local output = handle:read("*a")
  local success = handle:close()
  
  if success then
    vim.notify("Lambda function triggered successfully", vim.log.levels.INFO)
  else
    vim.notify("Lambda invocation failed: " .. output, vim.log.levels.ERROR)
  end
  
  -- Cleanup
  os.remove(temp_file)
  os.remove("/tmp/lambda-response.json")
  
  return success
end

return M