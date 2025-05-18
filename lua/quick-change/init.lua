local M = {}
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

require("quick-change.converters.colors")

M.data_types = require("quick-change.registry").data_types

local print_array = function(array)
  for _, value in ipairs(array) do
    print(value)
  end
end

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
--1
--2
--3
--4
--5
--6
--7

M.get_highlighted_data_types = function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.fn.getline(start_pos[2], end_pos[2])

  if type(lines) == "string" then
    return M.get_data_types(lines)
  end

  local types = {}

  for _, line in ipairs(lines) do
    for _, type in ipairs(M.get_data_types(line)) do
      table.insert(types, type)
    end
  end

  return remove_duplicates(types)
end

-- rgb(60,60,60) rgba(60,60,60,0.1)
-- rgb(60,60,60)
-- rgba(60,60,60,0.1)

M.show_options = function(opts)
  opts = opts or {}
  local conversions = {}

  local data_types = M.get_highlighted_data_types()

  if #data_types == 0 then
    print("no conversions available")
    return
  end

  for _, start_data_type in ipairs(data_types) do
    for end_data_type, _ in pairs(M.data_types[start_data_type].converters) do
      local conversion = start_data_type .. " to " .. end_data_type
      table.insert(conversions, conversion)
    end
  end

  pickers
    .new(opts, {
      prompt_title = "Available conversions",
      finder = finders.new_table({
        results = conversions,
      }),
      sorter = conf.generic_sorter(opts),
    })
    :find()
end

M.setup = function() end

return M
