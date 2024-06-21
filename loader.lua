local cloneref = cloneref or function(instance) return instance end
local gethwid = gethwid or function() return '1' end

local httpService = cloneref(game:GetService('HttpService'))
local playersService = cloneref(game:GetService('Players'))

local scriptName

local scriptLoadAt = tick()

local supportedExecutors = {}
local teleported = false

loadstring(game:HttpGet('https://raw.githubusercontent.com/Iratethisname10/UnboundedYieldV2/main/requires.lua'))()
local whitelistInfo = httpService:JSONDecode(requireScript('whitelist.json'))
print('[loader] passed section 1')

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

	end

	if spoofMemory and memorystats then
		local tags = {'Internal', 'HttpCache', 'Instances', 'Signals', 'LuaHeap', 'Script', 'Physics Collision', 'PhysicsParts', 'GraphicsSolidModels', 'GraphicsMeshparts', 'GraphicsParticles', 'GraphicsParts', 'GraphicsSpatialHash', 'GraphicsTerrain', 'GraphicsTexture', 'GraphicsTextureCharacter', 'Sounds', 'StreamingSounds', 'TerrainVoxels', 'Gui', 'Animation', 'Navigation', 'GemoetryCSG'}

		for _, tag in tags do memorystats.cache(tag) end
		task.delay(20, function() for _, tag in tags do memorystats.restore(tag) end end)
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

	local textChatService = cloneref(game:GetService('TextChatService'))
	local replicatedStorageService = cloneref(game:GetService('ReplicatedStorage'))

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
		end,
		reveal = function()
			if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
				textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync('i am using unbounded yield')
			else
				pcall(function() replicatedStorageService.DefaultChatSystemChatEvents.SayMessageRequest:FireServer('i am using unbounded yield', 'All') end)
			end
		end
	}
	getgenv().cmds = commands

	local con; con = playersService.PlayerChatted:Connect(function(enum, player, message)
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

	scriptName = customGamesList[tostring(game.PlaceId)]
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
		sections = {'Configs', 'Detection Protection', 'Discord', 'Extra'},
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
        end
	end

	for _, v in objects do
        local object = v()
        table.insert(binds, object)
    end
end

library.unloadMaid:GiveTask(playersService.LocalPlayer.OnTeleport:Connect(function(state)
	if teleported or state ~= Enum.TeleportState.InProgress then return end
	teleported = true

	queue_on_teleport(`loadstring(game:HttpGet('https://raw.githubusercontent.com/Iratethisname10/UnboundedYieldV2/main/loader.lua'))()`)
end))

if scriptName == 'Cali Shootout' then -- omg fix !!
	if getgenv().cali_fix_done then
		library:Init()
		print('[loader] passed section 6, all done!')
		return
	end
	task.delay(1.5, function() print('[loader] passed section 6, all done!'); library:Init(); getgenv().cali_fix_done = true end)
	library:Init()
else
	library:Init()
	print(string.format('[loader] passed section 6, all done! (%s)', tick() - scriptLoadAt))
end
