local M = {}

local default_opts = {
  palette = "twilight",
  -- TODO add time-based color schemes
}

function M.setup(opts)
  -- Set your colorscheme's highlights
  opts = vim.tbl_deep_extend("force", default_opts, opts)

  local palette = require("salmon.palettes." .. opts.palette)
  if not palette then
    vim.notify("Palette not found, using twilight", vim.log.levels.WARN)
    palette = require("salmon.palettes.twilight")
  end

  --- @type Salmon
  local core = require("salmon.core")

  core.build_from_palette(palette)

  core.apply_highlights()
  core.apply_signs()

  vim.g.colors_name = "Salmon_" .. palette.name .. "_" .. palette.view
end

return M
