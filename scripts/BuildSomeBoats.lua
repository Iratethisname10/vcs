local buildABoat = library:AddTab('Build A Boat')

local column1, column2 = buildABoat:AddColumn(), buildABoat:AddColumn()

local cloneref = cloneref or function(instance) return instance end

local playersService = cloneref(game:GetService('Players'))
local lightingService = cloneref(game:GetService('Lighting'))

local vector3New = Vector3.new
local vector3Zero = Vector3.zero
local cframeNew = CFrame.new
local instanceNew = Instance.new

if not playersService.LocalPlayer then playersService:GetPropertyChangedSignal('LocalPlayer'):Wait() end
local lplr = playersService.LocalPlayer

local gameCam = workspace.CurrentCamera
library.unloadMaid:GiveTask(workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
	gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
end))

local maid = requireScript('maid.lua').new()
local util = requireScript('utils.lua')

local debug = library.flags.debugMode
library.OnFlagChanged:Connect(function(data)
	local option = library.options[data.flag]

	if option.flag ~= 'debugMode' then return end 
	debug = library.flags[option.flag]
end)

local function bind(flag) return library.options[flag]:SetState(not library.flags[flag]) end

local funcs = {}

local zones = {White = 'WhiteZone', Black = 'BlackZone', Red = 'Really redZone', Yellow = 'New YellerZone', Green = 'CamoZone', Blue = 'Really blueZone', Purple = 'MagentaZone'}
local remotes = {openChest = workspace.ItemBoughtFromShop}

local stages = workspace.BoatStages.NormalStages
local endPoint = stages.TheEnd.GoldenChest.Trigger

do -- funcs
	function funcs.autoFarm(t)
		if not t then return end
		
		repeat
			if not util:getPlayerData().alive then return end
			for i = 1, #stages:GetChildren() - 2 do
				if not library.flags.autoFarm then break end
				if not util:getPlayerData().alive then break end

				local stage = stages[string.format('CaveStage%s', i)]
				local trigger = stage:FindFirstChild('DarknessPart')

				lplr.Character.HumanoidRootPart.CFrame = trigger.CFrame

				local temp = instanceNew('Part', gameCam)
				temp.Anchored = true
				temp.CFrame = lplr.Character.HumanoidRootPart.CFrame * cframeNew(0, -6, 0)
				temp.Size = vector3New(30, 1, 30)
				temp.Transparency = debug and 0 or 1
				temp.CanCollide = true
				
				task.wait(library.flags.teleportDelay)

				temp:Destroy()
			end

			repeat task.wait() until util:getPlayerData().alive
			if not library.flags.autoFarm then lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead) break end
	
			repeat
				if not util:getPlayerData().alive then return end
				lplr.Character.HumanoidRootPart.CFrame = endPoint.CFrame
				task.wait(0.3)
			until lightingService.ClockTime ~= 14
	
			local respawned = false
			maid.respawned = lplr.CharacterAdded:Connect(function()
				respawned = true
				maid.respawned = nil
			end)
	
			repeat task.wait() until respawned
			task.wait(1)
		until not library.flags.autoFarm
	end

	function funcs.autoCrate(t)
		if not t then return end

		repeat
			remotes.openChest:InvokeServer(string.format('%s Chest', library.flags.chestType), library.flags.ammount)
			task.wait(3 * library.flags.ammount)
		until not library.flags.autoCrate
	end

	function funcs.tp(team)
		if not util:getPlayerData().alive then return end

		if workspace[zones[team]]:FindFirstChild('Lock') then
			workspace[zones[team]].Lock:Destroy()
		end

		lplr.Character.HumanoidRootPart.CFrame = workspace[zones[team]].CFrame * cframeNew(0, 8.35, 0)

		lplr.Character.HumanoidRootPart.AssemblyLinearVelocity = vector3Zero
		lplr.Character.HumanoidRootPart.AssemblyAngularVelocity = vector3Zero
	end
end

local autoFarm = column1:AddSection('Auto Farm')
local autoCrate = column1:AddSection('Auto Crate')

local extras = column2:AddSection('Extras')
local teleports = column2:AddSection('Teleports')

autoFarm:AddToggle({text = 'Enabled', flag = 'auto farm', callback = funcs.autoFarm})
autoFarm:AddDivider()
autoFarm:AddSlider({text = 'teleport delay', min = 1, max = 5, float = 0.1, value = 2})

autoCrate:AddToggle({text = 'Enabled', flag = 'auto crate', callback = funcs.autoCrate})
autoCrate:AddDivider()
autoCrate:AddList({flag = 'chest type', values = {'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'}})
autoCrate:AddSlider({text = 'Ammount', tip = 'the ammount of crates you want to buy', min = 1, max = 10})

for name in zones do
	teleports:AddButton({text = string.format('%s Zone', name), callback = function() funcs.tp(name) end})
end
