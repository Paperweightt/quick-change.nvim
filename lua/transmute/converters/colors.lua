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
  pattern = "hsl%(%d+,%s*%d+%%,%s*%d+%%%)",
  parse = function(str)
    local h, s, l = str:match("hsl%((%d+),%s*(%d+)%%,%s*(%d+)%%%)")
    h, s, l = tonumber(h), tonumber(s) / 100, tonumber(l) / 100

    -- Convert HSL to RGB
    local function hsl_to_rgba(h, s, l)
      local c = (1 - math.abs(2 * l - 1)) * s
      local x = c * (1 - math.abs((h / 60) % 2 - 1))
      local m = l - c / 2
      local r_, g_, b_ = (h < 60 and { c, x, 0 })
        or (h < 120 and { x, c, 0 })
        or (h < 180 and { 0, c, x })
        or (h < 240 and { 0, x, c })
        or (h < 300 and { x, 0, c })
        or { c, 0, x }

      return {
        r = math.floor((r_ + m) * 255 + 0.5),
        g = math.floor((g_ + m) * 255 + 0.5),
        b = math.floor((b_ + m) * 255 + 0.5),
        a = 1,
      }
    end

    return hsl_to_rgba(h, s, l)
  end,
  stringify = function(rgba)
    local r, g, b = rgba.r / 255, rgba.g / 255, rgba.b / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, l
    l = (max + min) / 2

    if max == min then
      h, s = 0, 0
    else
      local d = max - min
      s = l > 0.5 and d / (2 - max - min) or d / (max + min)

      if max == r then
        h = ((g - b) / d + (g < b and 6 or 0)) * 60
      elseif max == g then
        h = ((b - r) / d + 2) * 60
      else
        h = ((r - g) / d + 4) * 60
      end
    end

    return string.format("hsl(%d, %d%%, %d%%)", h, s * 100, l * 100)
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
        for _, line in ipairs(lines) do
          local new_line = string.gsub(line, start_modules.pattern, function(str)
            local data = start_modules.parse(str)
            return end_modules.stringify(data)
          end)
          table.insert(new_lines, new_line)
        end
        return new_lines
      end
    end
  end
end

return M
