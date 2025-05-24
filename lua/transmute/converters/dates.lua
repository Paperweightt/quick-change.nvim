local registry = require("transmute.registry")
local M = {}

M.data_type = {}

M.data_type["rgb"] = {
  pattern = "rgb%(%d+,%s*%d+,%s*%d+%)",
  parse = function(str)
    local r, g, b = str:match("rgb%((%d+),%s*(%d+),%s*(%d+)%)")

    return {
      r = tonumber(r),
      g = tonumber(g),
      b = tonumber(b),
      a = 1,
    }
  end,
  stringify = function(rgba)
    local r = rgba.r
    local g = rgba.g
    local b = rgba.b
    return string.format("rgb(%d, %d, %d)", r, g, b)
  end,
}

for start_format, start_modules in pairs(M.data_type) do
  registry.formats[start_format] = {
    find = function(str)
      local match = str:match(start_modules.pattern)
      if match then
        return true
      end
      return false
    end,
    type = "date",
    converters = {},
  }

  for end_format, end_modules in pairs(M.data_type) do
    if start_format ~= end_format then
      registry.formats[start_format].converters[end_format] = function(lines)
        local new_lines = {}
        local highlight_data = {}

        for line_number, line in ipairs(lines) do
          local new_line = ""
          local i = 0

          while true do
            local j, k = string.find(line, start_modules.pattern, i + 1) -- find 'next' newline

            -- test for both to make warnings go away
            if j == nil or k == nil then
              new_line = new_line .. string.sub(line, i + 1, string.len(line))
              table.insert(new_lines, new_line)
              break
            end

            local start_string = string.sub(line, j, k)
            local adjusted_string = end_modules.stringify(start_modules.parse(start_string))

            -- add in non adjusted word
            new_line = new_line .. string.sub(line, i, j - 1)

            -- add highlight
            table.insert(highlight_data, {
              line = line_number,
              col_start = string.len(new_line) + 1,
              col_end = string.len(new_line) + string.len(adjusted_string),
            })
            -- add in adjusted word
            new_line = new_line .. adjusted_string

            i = k
          end
        end

        return { new_lines = new_lines, highlight_data = highlight_data }
      end
    end
  end
end

return M
