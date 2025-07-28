-- nvim-secscan plugin entry point
if vim.g.loaded_nvim_secscan then
  return
end
vim.g.loaded_nvim_secscan = 1

-- Auto-setup with default config if not already configured
if not vim.g.nvim_secscan_setup_done then
  require('nvim-secscan').setup()
  vim.g.nvim_secscan_setup_done = true
end