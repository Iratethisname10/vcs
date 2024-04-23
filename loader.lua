local cloneref = cloneref or function(instance) return instance end

local httpService = cloneref(game:GetService('HttpService'))

do -- getting required functions
	local key = '08ac2582954713609cd682f4ee0aaf5568d107a1d3658e0d252b73d2b1dba511'
	local gottenKey

	local doingRequest
	local requestData

	task.delay(15, function()
		if gottenKey then return end
		gottenKey = 'failed 1' 
	end)

	print('[loader] starting')

	repeat
		if typeof(game) ~= 'Instance' then gottenKey = 'failed 2' break end
		if gottenKey then break end
		if doingRequest then return end

		doingRequest = true
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/Iratethisname10/UnboundedYieldV2/main/requires.lua')
		end)

		if not suc or table.find({'404: Not Found', '400: Invalid Request'}, res) then gottenKey = 'failed 3' break end

		requestData = loadstring(res)()

		doingRequest = false

		task.wait()
	until requestData

	gottenKey = requestData.key
	print(string.format('needed key: %s', key))
	print(string.format('gotten key: %s', gottenKey))

	if gottenKey ~= key then return warn('[loader] script could not load: invalid key') end
	if string.find(gottenKey, 'failed') then return warn(string.format('[loader] script could not load: %s', gottenKey)) end
end

local library = requireScript('library.lua')

do -- game scan & setup
	local customGamesList = httpService:JSONDecode(requireScript('custom-games.json'))
	local hasCustom = false

	local scriptName = customGamesList[tostring(game.PlaceId)]
	if scriptName then
		library.gameName = scriptName
		hasCustom = true
		requireScript(string.format('scripts/%s.lua', scriptName))
	end

	if not hasCustom then
		requireScript('scripts/universal.lua')
	end
end

-- add queue on telpeort

library:Init()