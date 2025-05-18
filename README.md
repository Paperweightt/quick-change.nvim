# transmute.nvim

## What Is Transmute

`transmute.nvim` changes existing data to other forms.
Highlight a section of text and select the transformation.

### Installation

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
    require("transmute").setup()
  end,
}
```
