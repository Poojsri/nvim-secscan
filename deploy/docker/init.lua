-- Neovim configuration for nvim-secscan Docker container
require("nvim-secscan").setup({
  s3_bucket = os.getenv("S3_BUCKET"),
  lambda_function = os.getenv("LAMBDA_FUNCTION"),
  use_github_advisory = true,
  github_token = "env:GITHUB_TOKEN",
  scanner = "osv", -- Default to OSV for container
  enable_diagnostics = true,
  enable_floating_window = true,
  enable_suggestions = true
})