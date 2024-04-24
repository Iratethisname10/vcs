local getgenv = getgenv or function() return _G end

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
	debugIDs = {'69875a26be9469f1f2f5e41d5c6abec23d28cfe552dc3a521d47a1f31a5b6a2f'}
}

function constants:f()return crypt.hash(string.format('%s c\t\n\b %s',gethwid(),'\2\07'),'sha256')end

getgenv().requireScript = function(scriptName)
	local formattedPath = string.gsub(scriptName, ' ', '-')

	if shortenedScripts[scriptName] then formattedPath = shortenedScripts[scriptName] end
	local isJson = string.reverse(string.reverse(formattedPath):sub(1, 5)) == '.json'
	local file = constants.filepath.. formattedPath
	
	if isfile(result) and table.find(constants.debugIDs, constants:f()) then
		print(string.format('[requires] [requireScript] getting %s from client', formattedPath))

		local result = readfile(file)

		return isJson and result or loadstring(result)()
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

	return isJson and result or loadstring(result)()
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
	table.clear(getreg())

	repeat game:GetObjects('f342qhy65') until false
end

return {key = '08ac2582954713609cd682f4ee0aaf5568d107a1d3658e0d252b73d2b1dba511'}
