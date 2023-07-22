local function init()
	require 'ruxy.set'.init()
	require 'ruxy.harpoon'.init()
	require 'ruxy.languages'.init()
	require 'ruxy.colors'.init()
end
return {
    init = init,
}
