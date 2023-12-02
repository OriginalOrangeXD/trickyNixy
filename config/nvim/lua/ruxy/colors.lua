local catppuccin = require 'catppuccin'
local onedark = require 'onedarkpro'
local colorizer = require 'colorizer'
local gitsigns = require 'gitsigns'
local lualine = require 'lualine'
local noice = require 'noice'

local function init()
    onedark.setup({
        -- integrations = {
        --     --indent_blankline = { enabled = true },
        --     native_lsp = {
        --         enabled = true,
        --     },
        --     telescope = true,
        --     treesitter = true,
        -- },
        options = {
            transparency = true
        },
    })


    lualine.setup {
        options = {
            component_separators = { left = '', right = '' },
            icons_enabled = false,
            section_separators = { left = '', right = '' },
            theme = "onedark"
        }
    }

    vim.cmd.colorscheme "onedark"
end

function ColorMyPencils(color)
	color = color or "onedark"
	vim.cmd.colorscheme(color)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

end

return {
    ColorMyPencils = ColorMyPencils,
    init = init,
}
