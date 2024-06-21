local getgenv = getgenv or function() return _G end
local gethwid = gethwid or function() return '1' end

local shortenedScripts = {
	['library.lua'] = 'ui/library.lua',
	['bind-viewer.lua'] = 'ui/keyBindVisualizer.lua',
	['notifs.lua'] = 'ui/toastNotifs.lua',

	['utils.lua'] = 'utils/utilities.lua',
	['maid.lua'] = 'utils/maid.lua',
	['signal.lua'] = 'utils/signal.lua'
}

local constants = {
	timeout = 15,
	githubPath = 'https://raw.githubusercontent.com/Iratethisname10/UnboundedYieldV2/main/',
	filepath = 'Unbounded Yield V2/',
	errors = {'404: Not Found', '400: Invalid Request'},
	debugIDs = {'f83c9d5e172bdb30576027119148d3bc62027d21c72cefc3c74c9180f59cb7e8'}
}

local hash = function(data)
	return crypt.hash(string.format('$s/s\t %s\a﷽📙\n+2陷a%sa$%s􀏿','꧅',data,'?'), 'sha256')
end

getgenv().requireScript = function(scriptName, subTo)
	subTo = subTo or '-'
	local formattedPath = string.gsub(scriptName, ' ', subTo)

	if shortenedScripts[scriptName] then formattedPath = shortenedScripts[scriptName] end
	local isNotLua = string.reverse(string.reverse(formattedPath):sub(1, 4)) ~= '.lua'
	local file = constants.filepath.. formattedPath
	
	if isfile(file) and table.find(constants.debugIDs, hash(gethwid())) and not getgenv().dontUseFile then
		print(string.format('[requires] [requireScript] getting %s from client', formattedPath))

		local result = readfile(file)

		return isNotLua and result or loadstring(result)()
	end

	local success, result
	task.delay(constants.timeout, function()
		if result then return end
		warn('[requires] [requireScript] this is taking longer than expected: '.. constants.timeout)
	end)

	success, result = pcall(function() return game:HttpGet(constants.githubPath.. formattedPath) end)

	if not success or table.find(constants.errors, result) then
		return warn('[requires] unknowed path / path not available (yet) : '.. formattedPath.. ' : '.. result)
	end

	print(string.format('[requires] [requireScript] getting %s from server', formattedPath))

	return isNotLua and result or loadstring(result)()
end

getgenv().requireCustom = function(url)
	local formattedPath = string.gsub(scriptName, ' ', '%20')

	local success, result
	task.delay(constants.timeout, function()
		if result then return end
		warn('[requires] [requireCustom] this is taking longer than expected: '.. constants.timeout)
	end)

	success, result = pcall(function() return game:HttpGet(url) end)

	if not success or table.find(constants.errors, result) then
		return warn('[requires] [requireCustom] unknowed path / path not available (yet) : '.. formattedPath.. ' : '.. result)
	end

	return loadstring(result)()
end

getgenv().crash = function()
	task.spawn(function() table.clear(getreg()) end)
	task.spawn(function() repeat game:GetObjects('f342qhy65') until false end)
end

getgenv().hash = hash
