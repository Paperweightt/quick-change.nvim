local M = {}
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values

require("transmute.converters.colors")

M.data_types = require("transmute.registry").data_types

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

M.get_data_types = function(str)
  local types = {}

  for type, modules in pairs(M.data_types) do
    if modules.find(str) then
      table.insert(types, type)
    end
  end

  return types
end

local get_highlighted_lines = function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.fn.getline(start_pos[2], end_pos[2])
  return lines
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

M.show_options = function(opts)
  local lines = get_highlighted_lines()
  opts = opts or {}
  local conversions = {}

  local data_types = M.get_lines_data_types(lines)

  if #data_types == 0 then
    print("no conversions available")
    return
  end

  for _, start_data_type in ipairs(data_types) do
    for end_data_type, converter in pairs(M.data_types[start_data_type].converters) do
      local conversion = start_data_type .. " to " .. end_data_type
      table.insert(conversions, { conversion, converter })
    end
  end

  pickers
    .new(opts, {
      prompt_title = "Available conversions",
      finder = finders.new_table({
        results = conversions,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry[1],
            ordinal = entry[1],
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      previewer = previewers.new_buffer_previewer({
        define_preview = function(self, entry)
          -- Get current visual selection

          -- Apply the conversion function
          local new_lines = entry.value[2](lines)

          -- Show result in the preview buffer
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, new_lines)
        end,
      }),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          local new_lines = selection.value[2](lines)
          local start_pos = vim.fn.getpos("'<")
          local end_pos = vim.fn.getpos("'>")

          local start_line = start_pos[2] - 1
          local end_line = end_pos[2]

          vim.api.nvim_buf_set_lines(0, start_line, end_line, false, new_lines)
        end)
        return true
      end,
    })
    :find()
end

M.setup = function() end

return M
