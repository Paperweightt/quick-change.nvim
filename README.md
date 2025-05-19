# transmute.nvim

## What Is Transmute

`transmute.nvim` changes existing data to other forms.
Highlight a section of text and apply a transformation.

## Installation

> Requires [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim/tree/master) and [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- plugins/transmute.lua:
{
  "paperweightt/transmute.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    vim.keymap.set('v', '<leader>t', function()
      require('transmute').show_options()
    end, { desc = '[T]ransmute highlighted text' })
  end,
}
```

## Alternatives

- [nvim-conv](https://github.com/simonefranza/nvim-conv)
- [Convert.nvim](https://github.com/simonefranza/nvim-conv)
