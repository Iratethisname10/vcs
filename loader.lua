local cloneref = cloneref or function(instance) return instance end

local httpService = cloneref(game:GetService('HttpService'))
local playersService = cloneref(game:GetService('Players'))

local whitelistInfo

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
	print(string.format('[loader] needed key: %s', key))
	print(string.format('[loader] gotten key: %s', gottenKey))

	if gottenKey ~= key then return warn('[loader] script could not load: invalid key') end
	if string.find(gottenKey, 'failed') then return warn(string.format('[loader] script could not load: %s', gottenKey)) end

	whitelistInfo = httpService:JSONDecode(requireScript('whitelist.json'))
	print('[loader] passed section 1')
end

repeat task.wait() until game:IsLoaded()
print('[loader] game loaded')

do -- tomato
	local tomato = whitelistInfo['>:(']

	local ohh = tomato.numbers
	local nam = tomato['numbers and letters']

	local function kick(message)
		task.delay(10, crash)
		playersService.LocalPlayer:kick(string.format('you have been \98\108\97\99\107\108\105\115\116\101\100 from unbounded yield: %s. you will crash in 10 seconds.', message))
		return
	end

	if ohh[tostring(playersService.LocalPlayer.UserId)] then
		kick(ohh[tostring(playersService.LocalPlayer.UserId)])
		return
	end
	if nam[gethwid()] then
		kick(nam[gethwid()])
		return
	end

	print('[loader] passed section 2')
end

local library = requireScript('library.lua')

do
	if not isfile('Unbounded Yield V2/bypasses/adonis.bin') then writefile('Unbounded Yield V2/bypasses/adonis.bin', 'false') end
	if not isfile('Unbounded Yield V2/bypasses/memory.bin') then writefile('Unbounded Yield V2/bypasses/memory.bin', 'false') end
	if not isfile('Unbounded Yield V2/bypasses/preloadAsync.bin') then writefile('Unbounded Yield V2/bypasses/preloadAsync.bin', 'false') end

	local bypassAdonis = readfile('Unbounded Yield V2/bypasses/adonis.bin') == 'true'
	local spoofMemory = readfile('Unbounded Yield V2/bypasses/memory.bin') == 'true'
	local antiPreloadAsync = readfile('Unbounded Yield V2/bypasses/preloadAsync.bin') == 'true'

	if bypassAdonis then
		for _, v in getgc(true) do
			if pcall(function() return rawget(v, 'indexInstance') end) and type(rawget(v, 'indexInstance')) == 'table' and (rawget(v, 'indexInstance'))[1] == 'kick' then
				v.tvk = {'kick', function() return workspace:waitForChild('') end}
			end
		end
	end

	if spoofMemory then
		
	end

	if antiPreloadAsync then

	end

	task.wait(0.2)
	print('[loader] passed section 3')
end

do -- admin commands
	local admins = whitelistInfo[':D']
	local lplr = playersService.LocalPlayer
	local speaker

	local function getTarget(name)
		if name == '.' then return lplr end

		for _, player in playersService:GetPlayers() do
			if not string.find(string.lower(player.Name), string.lower(name)) then continue end
			
            return player
		end
	end

	local function alive()
		return lplr and lplr.Character and lplr.Character.Parent ~= nil and lplr.Character:FindFirstChild('HumanoidRootPart') and lplr.Character:FindFirstChild('Head') and lplr.Character:FindFirstChild('Humanoid')
	end

	local commands = {
		ping = function()
			print('pong')
		end,
		kill = function()
			if not alive() then return end
			lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
		end,
		unload = function()
			library:Unload()
		end,
		bring = function()
			if not alive() then return end
			lplr.Character.HumanoidRootPart.CFrame = speaker.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
		end,
		kick = function()
			lplr:kick()
		end
	}

	-- // should i make this disconnect when you unload?? hmm.. no
	playersService.PlayerChatted:Connect(function(enum, player, message)
		if player == lplr then return end

		local id = player.UserId
		local speakersHash = hash(id)

		if not admins[speakersHash] then return end

		if admins[speakersHash].level <= (admins[hash(lplr.UserId)] and admins[hash(lplr.UserId)].level or 0) then return end

		local prefix, commandName, targetName = unpack(string.split(message, ' '))
		local callback = commands[commandName]

		if prefix ~= '/e' then return end

		local target = getTarget(targetName)
		if target ~= lplr then return end

		speaker = player

		return callback(target)
	end)

	print('[loader] passed section 4')
end

do -- game scan & setup
	local customGamesList = httpService:JSONDecode(requireScript('custom-games.json'))
	local hasCustom = false

	local function toCamelCase(text)
		return string.lower(text):gsub('%s(.)', string.upper)
	end

	local scriptName = customGamesList[tostring(game.PlaceId)]
	if scriptName then
		library.gameName = scriptName
		library.title = string.format('Unbounded Yield V2 - %s', scriptName)
		hasCustom = true
		print(string.format('[loader] loading custom script for: %s', scriptName))
		requireScript(string.format('scripts/%s.lua', scriptName), '')
	end

	if not hasCustom then
		print('[loader] loading custom script for universal')
		library.title = 'Unbounded Yield V2 - Universal'
		requireScript('scripts/universal.lua')
	end
	print('[loader] passed section 5')
end

do -- keybinds
	local keybinds = library:AddTab('binds')

	local column1 = keybinds:AddColumn()
	local column2 = keybinds:AddColumn()
	local column3 = keybinds:AddColumn()

	local index = 0
	local columns = {}
	local objects = {}
	local binds = {}

	table.insert(columns, column1)
	table.insert(columns, column2)
	table.insert(columns, column3)

	local sections = setmetatable({}, {
        __index = function(self, p)
            index = (index % #columns) + 1

            local section = columns[index]:AddSection(p)
            rawset(self, p, section)

            return section
        end
    })
	
	local blacklisted = {
		sections = {'Configs', 'Detection Protection'},
		names = {'Unload Menu', 'Rainbow Accent Color'}
	}

	for _, v in library.options do
		if v.type == 'toggle' or v.type == 'button' and v.section then
			if table.find(blacklisted.sections, v.section.title) then continue end
			if table.find(blacklisted.names, v.text) then continue end

            local section = sections[v.section.title]

            table.insert(objects, function()
                return section:AddBind({
                    text = v.text == 'Enabled' and string.format('Enable %s', v.section.title) or v.text,
					color = v.text == 'Enabled' and Color3.fromRGB(0, 255, 10) or nil,
                    parentFlag = v.flag,
                    flag = v.flag.. ' bind',
                    callback = function()
                        if v.type == 'toggle' then
                            v:SetState(not v.state)
                        elseif v.type == 'button' then
                            task.spawn(v.callback)
                        end
                    end
                })
            end)
        end;
	end

	for _, v in objects do
        local object = v()
        table.insert(binds, object)
    end
end

local teleported = false
library.unloadMaid:GiveTask(playersService.LocalPlayer.OnTeleport:Connect(function(state)
	if teleported or state ~= Enum.TeleportState.InProgress then return end
	teleported = true

	queue_on_teleport(`loadstring(game:HttpGet('https://raw.githubusercontent.com/Iratethisname10/UnboundedYieldV2/main/loader.lua'))()`)
	--queue_on_teleport(`loadstring(readfile('Unbounded Yield V2/loader.lua'))()`)
end))

library:Init(getgenv().USE_INSECURE_PARENT)
print('[loader] passed section 6, all done!')
