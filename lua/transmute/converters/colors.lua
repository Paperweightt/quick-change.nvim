local M = {
  data_type = {},
}

local registry = require("transmute.registry")

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

M.data_type["rgba"] = {
  pattern = "rgba%(%d+,%s*%d+,%s*%d+,%s*[%.%d]+%)",
  parse = function(str)
    local r, g, b, a = str:match("rgba%((%d+),%s*(%d+),%s*(%d+),%s*([%d%.]+)%)")

    return {
      r = tonumber(r),
      g = tonumber(g),
      b = tonumber(b),
      a = tonumber(a),
    }
  end,
  stringify = function(rgba)
    local r = rgba.r
    local g = rgba.g
    local b = rgba.b
    local a = rgba.a
    return string.format("rgba(%d, %d, %d, %.2f)", r, g, b, a)
  end,
}

M.data_type["hsl"] = {
  pattern = "hsl%(%s*%d+%s*,%s*%d+%%%s*,%s*%d+%%%s*%)",

  parse = function(str)
    local h, s, l = str:match("hsl%(%s*(%d+)%s*,%s*(%d+)%%%s*,%s*(%d+)%%%s*%)")
    h = tonumber(h) % 360
    s = tonumber(s) / 100
    l = tonumber(l) / 100

    local c = (1 - math.abs(2 * l - 1)) * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = l - c / 2

    local r, g, b
    if h < 60 then
      r, g, b = c, x, 0
    elseif h < 120 then
      r, g, b = x, c, 0
    elseif h < 180 then
      r, g, b = 0, c, x
    elseif h < 240 then
      r, g, b = 0, x, c
    elseif h < 300 then
      r, g, b = x, 0, c
    else
      r, g, b = c, 0, x
    end

    return {
      r = math.floor((r + m) * 255 + 0.5),
      g = math.floor((g + m) * 255 + 0.5),
      b = math.floor((b + m) * 255 + 0.5),
      a = 1,
    }
  end,

  stringify = function(rgba)
    local r, g, b = rgba.r / 255, rgba.g / 255, rgba.b / 255
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local delta = max - min

    local h
    if delta == 0 then
      h = 0
    elseif max == r then
      h = 60 * (((g - b) / delta) % 6)
    elseif max == g then
      h = 60 * (((b - r) / delta) + 2)
    else
      h = 60 * (((r - g) / delta) + 4)
    end

    if h < 0 then
      h = h + 360
    end

    local l = (max + min) / 2
    local s = delta == 0 and 0 or delta / (1 - math.abs(2 * l - 1))

    return string.format(
      "hsl(%d, %d%%, %d%%)",
      math.floor(h + 0.5),
      math.floor(s * 100 + 0.5),
      math.floor(l * 100 + 0.5)
    )
  end,
}

M.data_type["hsla"] = vim.tbl_deep_extend("force", vim.deepcopy(M.data_type["hsl"]), {
  pattern = "hsla%(%d+,%s*%d+%%,%s*%d+%%,%s*[%d%.]+%)",
  parse = function(str)
    local h, s, l, a = str:match("hsla%((%d+),%s*(%d+)%%,%s*(%d+)%%,%s*([%d%.]+)%)")
    local rgba = M.data_type["hsl"].parse(string.format("hsl(%d, %d%%, %d%%)", h, s, l))
    rgba.a = tonumber(a)
    return rgba
  end,
  stringify = function(rgba)
    local hsl = M.data_type["hsl"].stringify(rgba)
    return hsl:gsub("^hsl", "hsla"):gsub("%)$", string.format(", %.2f)", rgba.a))
  end,
})

M.data_type["hex"] = {
  pattern = "#%x%x%x%x%x%x",
  parse = function(str)
    local r, g, b = str:match("#(%x%x)(%x%x)(%x%x)")
    return {
      r = tonumber(r, 16),
      g = tonumber(g, 16),
      b = tonumber(b, 16),
      a = 1,
    }
  end,
  stringify = function(rgba)
    return string.format("#%02x%02x%02x", rgba.r, rgba.g, rgba.b)
  end,
}

M.data_type["hexa"] = {
  pattern = "#%x%x%x%x%x%x%x%x",
  parse = function(str)
    local r, g, b, a = str:match("#(%x%x)(%x%x)(%x%x)(%x%x)")
    return {
      r = tonumber(r, 16),
      g = tonumber(g, 16),
      b = tonumber(b, 16),
      a = tonumber(a, 16) / 255,
    }
  end,
  stringify = function(rgba)
    local alpha = math.floor((rgba.a or 1) * 255 + 0.5)
    return string.format("#%02x%02x%02x%02x", rgba.r, rgba.g, rgba.b, alpha)
  end,
}

M.data_type["hwb"] = {
  pattern = "hwb%(%d+,%s*%d+%%,%s*%d+%%%)",
  parse = function(str)
    local h, w, b = str:match("hwb%((%d+),%s*(%d+)%%,%s*(%d+)%%%)")
    h = tonumber(h)
    w = tonumber(w) / 100
    b = tonumber(b) / 100

    -- Convert HWB to RGB
    local function hwb_to_rgb(h, w, b)
      local ratio = w + b
      if ratio > 1 then
        w = w / ratio
        b = b / ratio
      end

      local i = (h / 60) % 6
      local f = (h / 60) - math.floor(h / 60)
      local p = 1 - b
      local q = p * (1 - f)
      local t = p * f

      local r, g, bl
      if i < 1 then
        r, g, bl = p, t, b
      elseif i < 2 then
        r, g, bl = q, p, b
      elseif i < 3 then
        r, g, bl = b, p, t
      elseif i < 4 then
        r, g, bl = b, q, p
      elseif i < 5 then
        r, g, bl = t, b, p
      else
        r, g, bl = p, b, q
      end

      return {
        r = math.floor(r * 255 + 0.5),
        g = math.floor(g * 255 + 0.5),
        b = math.floor(bl * 255 + 0.5),
        a = 1,
      }
    end

    return hwb_to_rgb(h, w, b)
  end,
  stringify = function(rgba)
    -- This is a simplified HWB conversion (not always exact)
    local r, g, b = rgba.r / 255, rgba.g / 255, rgba.b / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local whiteness = min
    local blackness = 1 - max

    -- Convert RGB to hue
    local hue
    if max == min then
      hue = 0
    elseif max == r then
      hue = (g - b) / (max - min) % 6
    elseif max == g then
      hue = (b - r) / (max - min) + 2
    else
      hue = (r - g) / (max - min) + 4
    end
    hue = math.floor(hue * 60 + 0.5)

    return string.format(
      "hwb(%d, %d%%, %d%%)",
      hue,
      math.floor(whiteness * 100 + 0.5),
      math.floor(blackness * 100 + 0.5)
    )
  end,
}

for start_data_type, start_modules in pairs(M.data_type) do
  registry.data_types[start_data_type] = {
    find = function(str)
      local match = str:match(start_modules.pattern)
      if match then
        return true
      end
      return false
    end,
    converters = {},
  }

  for end_data_type, end_modules in pairs(M.data_type) do
    if start_data_type ~= end_data_type then
      registry.data_types[start_data_type].converters[end_data_type] = function(lines)
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
