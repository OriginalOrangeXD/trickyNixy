local catppuccin = require 'catppuccin'
local colorizer = require 'colorizer'
local gitsigns = require 'gitsigns'
local lualine = require 'lualine'
local noice = require 'noice'

local function init()
    catppuccin.setup({
        flavour = "macchiato",
        integrations = {
            --indent_blankline = { enabled = true },
            native_lsp = {
                enabled = true,
            },
            telescope = true,
            treesitter = true,
        },
        term_colors = true,
        transparent_background = true,
    })


    lualine.setup {
        options = {
            component_separators = { left = '', right = '' },
            icons_enabled = false,
            section_separators = { left = '', right = '' },
            theme = "catppuccin"
        }
    }

    vim.cmd.colorscheme "catppuccin"
end

function ColorMyPencils(color)
	color = color or "nord"
	vim.cmd.colorscheme(color)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

end

return {
    ColorMyPencils = ColorMyPencils,
    init = init,
}
