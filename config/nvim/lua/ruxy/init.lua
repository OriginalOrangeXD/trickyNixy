local function init()
	require 'ruxy.set'.init()
	require 'ruxy.languages'.init()
	require 'ruxy.colors'.init()
	require 'ruxy.remap'.init()
    require 'ruxy.latex'.init()
end
return {
    init = init,
}
