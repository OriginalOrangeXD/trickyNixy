local function config()
    vim.g.tex_flavor='latex'
    vim.g.vimtex_view_method='zathura'
    vim.g.vimtex_quickfix_mode=0
    vim.g.tex_conceal='abdmg'
    vim.cmd("set conceallevel=1")
end

local function init()
	config()
end

return {
	init = init,
}
