local registry = require("transmute.registry")
local M = {}

require("transmute.converters.colors")

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

M.get_data_formats = function(str)
  local formats = {}

  for type, modules in pairs(registry.data_formats) do
    if modules.find(str) then
      table.insert(formats, type)
    end
  end

  return formats
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

  for _, modules in pairs(registry.data_formats) do
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

M.transmute_lines = function(from, to, lines)
  local new_lines = {}
  for _, lines in ipairs(lines) do
  end
  return new_lines
end

return M
