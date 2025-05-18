local M = {
  data_type = {},
}

local registry = require("quick-change.registry")

M.data_type["rgb"] = {
  find = function(str)
    local match = str:match("rgb%(%d+,%s*%d+,%s*%d+%)")
    if match then
      return true
    end
    return false
  end,
  parse = function(str)
    local r = tonumber(str:sub(2, 3), 16)
    local g = tonumber(str:sub(4, 5), 16)
    local b = tonumber(str:sub(6, 7), 16)
    return { r = r, g = g, b = b, a = 1 }
  end,
  stringify = function(rgba)
    local r = rgba.r
    local g = rgba.g
    local b = rgba.b
    return string.format("rgba(%d, %d, %d)", r, g, b)
  end,
}

M.data_type["rgba"] = {
  find = function(str)
    local match = str:match("rgba%(%d+,%s*%d+,%s*%d+,%s*[%.%d]+%)")
    if match then
      return true
    end
    return false
  end,
  parse = function(str)
    local r = tonumber(str:sub(2, 3), 16)
    local g = tonumber(str:sub(4, 5), 16)
    local b = tonumber(str:sub(6, 7), 16)
    local a = tonumber(str:sub(6, 9))
    return { r = r, g = g, b = b, a = a }
  end,
  stringify = function(rgba)
    local r = rgba.r
    local g = rgba.g
    local b = rgba.b
    local a = rgba.a
    return string.format("rgba(%d, %d, %d, %.2f)", r, g, b, a)
  end,
}

for start_data_type, start_modules in pairs(M.data_type) do
  registry.data_types[start_data_type] = {
    find = start_modules.find,
    converters = {},
  }

  for end_data_type, end_modules in pairs(M.data_type) do
    if start_data_type ~= end_data_type then
      registry.data_types[start_data_type].converters[end_data_type] = function(str)
        local data = start_modules.parse(str)
        data = end_modules.parse(data)
        return data
      end
    end
  end
end

return M
