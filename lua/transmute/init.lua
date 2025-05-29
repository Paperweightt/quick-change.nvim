require("transmute.converters.colors")

local registry = require("transmute.registry")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values

local M = {}

local function remove_duplicates(list)
  local seen = {}
  local result = {}

  for _, value in ipairs(list) do
    if not seen[value] then
      table.insert(result, value)
      seen[value] = true
    end
  end

  return result
end

local function replace_visual_selection(lines)
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local start_line = start_pos[2] - 1
  local end_line = end_pos[2]

  vim.api.nvim_buf_set_lines(0, start_line, end_line, false, lines)
end

M.get_data_formats = function(str)
  local formats = {}

  for type, modules in pairs(registry.formats) do
    if modules.find(str) then
      table.insert(formats, type)
    end
  end

  return formats
end

local get_highlighted_lines = function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.fn.getline(start_pos[2], end_pos[2])
  return lines
end

M.get_lines_data_formats = function(lines)
  if type(lines) == "string" then
    return remove_duplicates(M.get_data_formats(lines))
  end

  local types = {}

  for _, line in ipairs(lines) do
    for _, type in ipairs(M.get_data_formats(line)) do
      table.insert(types, type)
    end
  end

  return remove_duplicates(types)
end

M.get_data_types = function(str)
  local types = {}

  for _, modules in pairs(registry.formats) do
    if modules.find(str) then
      table.insert(types, modules.type)
    end
  end

  return types
end

M.get_lines_data_types = function(lines)
  if type(lines) == "string" then
    return remove_duplicates(M.get_data_types(lines))
  end

  local types = {}

  for _, line in ipairs(lines) do
    for _, type in ipairs(M.get_data_types(line)) do
      table.insert(types, type)
    end
  end

  return remove_duplicates(types)
end

M.getPicker = function(opts, results, preview, action)
  return pickers.new(opts, {
    prompt_title = "Available conversions",
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry[1],
          ordinal = entry[1],
        }
      end,
    }),
    layout_strategy = "horizontal",
    layout_config = {
      horizontal = {
        width = 0.5,
        height = 0.7,
        preview_width = 0.7,
      },
    },
    sorter = conf.generic_sorter(opts),
    previewer = previewers.new_buffer_previewer({
      define_preview = function(self, entry)
        preview(self, entry)
      end,
    }),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        action()
      end)
      return true
    end,
  })
end

M.transmute_from_to = function(opts)
  local input_lines = get_highlighted_lines()
  local results = {}
  local data_formats = M.get_lines_data_formats(input_lines)

  opts = opts or conf.options.picker

  if #data_formats == 0 then
    if conf.options.notify then
      vim.notify("No transmutations available", vim.log.levels.ERROR)
    end
    return
  end

  for _, start_format in ipairs(data_formats) do
    for end_format, modules in pairs(registry.formats) do
      if modules.type == registry.formats[start_format].type and start_format ~= end_format then
        local conversion = start_format .. " to " .. end_format
        local converter = registry.types[modules.type].convert_lines(start_format, end_format, input_lines)
        table.insert(results, { conversion, converter })
      end
    end
  end

  local preview = function(self, entry)
    local convert_data = entry.value[2]
    local lines = convert_data.lines
    local highlight_data = convert_data.highlights
    local ns_id = vim.api.nvim_create_namespace("transmute_highlight")
    local bufnr = self.state.bufnr

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    for _, highlight in ipairs(highlight_data) do
      local line = highlight.line - vim.fn.getpos("'<")[2] - 1
      local col_start = highlight.col_start - 1
      local col_end = highlight.col_end

      vim.api.nvim_buf_add_highlight(bufnr, ns_id, "Search", line, col_start, col_end)
    end
  end

  local action = function()
    local selection = action_state.get_selected_entry()
    local convert_data = selection.value[2].lines

    replace_visual_selection(convert_data.lines)
  end

  M.getPicker(opts, results, preview, action):find()
end

M.transmute_to = function(opts)
  local input_lines = get_highlighted_lines()
  local results = {}
  local data_types = M.get_lines_data_types(input_lines)

  opts = opts or conf.options.picker

  if #data_types == 0 then
    if conf.options.notify then
      vim.notify("No transmutations available", vim.log.levels.ERROR)
    end
    return
  end

  for _, data_type in ipairs(data_types) do
    for format_type, modules in pairs(registry.formats) do
      if modules.type == data_type then
        local conversion_name = data_type .. " to " .. format_type
        local converter = registry.types[data_type].convert_lines("any", format_type, input_lines)

        table.insert(results, { conversion_name, converter })
      end
    end
  end

  local preview = function(self, entry)
    local line_data = entry.value[2]
    local ns_id = vim.api.nvim_create_namespace("transmute_highlight")
    local bufnr = self.state.bufnr

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, line_data.lines)

    for _, highlight in ipairs(line_data.highlights) do
      local line = highlight.line - vim.fn.getpos("'<")[2] - 1
      local col_start = highlight.col_start - 1
      local col_end = highlight.col_end

      vim.api.nvim_buf_add_highlight(bufnr, ns_id, "Search", line, col_start, col_end)
    end
  end

  local action = function()
    local selection = action_state.get_selected_entry()
    local line_data = selection.value[2]

    replace_visual_selection(line_data.new_lines)
  end

  M.getPicker(opts, results, preview, action):find()
end

M.setup = function() end

return M
