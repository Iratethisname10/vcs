local combat = library:AddTab('Combat')
local visual = library:AddTab('Visual')
local teleport = library:AddTab('Teleports')
local misc = library:AddTab('Miscellaneous')

local combat1, combat2 = combat:AddColumn(), combat:AddColumn()
local visual1, visual2 = visual:AddColumn(), visual:AddColumn()
local teleport1, teleport2 = teleport:AddColumn(), teleport:AddColumn()
local misc1, misc2 = misc:AddColumn(), misc:AddColumn()

local cloneref = cloneref or function(instance) return instance end

local playersService = cloneref(game:GetService('Players'))
local runService = cloneref(game:GetService('RunService'))
local userInputService = cloneref(game:GetService('UserInputService'))
local teleportService = cloneref(game:GetService('TeleportService'))
local proximityPromptService = cloneref(game:GetService('ProximityPromptService'))
local replicatedStorageService = cloneref(game:GetService('ReplicatedStorage'))
local lightingService = cloneref(game:GetService('Lighting'))

local vector2New = Vector2.new
local vector3New = Vector3.new
local vector3Zero = Vector3.zero
local vector3One = Vector3.one

local udim2New = UDim2.new
local udimNew = UDim.new

local cframeNew = CFrame.new
local cframeAngles = CFrame.Angles
local cframeLookAt = CFrame.lookAt

local mathFloor = math.floor
local mathRandomSpeed = math.randomseed
local mathRandom = math.random
local infinite = math.huge
local mathRadian = math.rad
local fourQuadrantInverseTangent = math.atan2
local mathCosine = math.cos

local randomNew = Random.new
local drawingNew = Drawing.new
local instanceNew = Instance.new

local insert = table.insert
local find = table.find
local remove = table.remove
local clear = table.clear
local sort = table.sort

getgenv().USE_INSECURE_PARENT = true

if not playersService.LocalPlayer then playersService:GetPropertyChangedSignal('LocalPlayer'):Wait() end
local lplr = playersService.LocalPlayer

local gameCam = workspace.CurrentCamera
library.unloadMaid:GiveTask(workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
	gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
end))

local mouse = lplr:GetMouse()

local maid = requireScript('maid.lua').new()
local util = requireScript('utils.lua')
local notif = requireScript('notifs.lua')

local espLibrary = requireScript('utils/helpers/esp.lua')

local debug = library.flags.debugMode
library.OnFlagChanged:Connect(function(data)
	local option = library.options[data.flag]

	if option.flag ~= 'debugMode' then return end 
	debug = library.flags[option.flag]
end)

local function bind(flag) return library.options[flag]:SetState(not library.flags[flag]) end

local function copyTable(t) -- lua.org
    local k = typeof(t)
    local c = {}

    if k == 'table' then
        for i, v in t do
            c[copyTable(i)] = copyTable(v)
        end

        setmetatable(c, copyTable(getmetatable(t)))
    else
        c = t
    end

    return c
end

local funcs = {}

local circle
local circleOutline

local safeZones = workspace:WaitForChild('SafeZones', 100)
local jobSystem = workspace:WaitForChild('Job System', 100)

local gameRemotes = replicatedStorageService:WaitForChild('Remotes', 100)
local gameEvents = replicatedStorageService:WaitForChild('Events', 100)
local gameModules = replicatedStorageService:WaitForChild('Modules', 100)

local events = {
	killed = gameEvents.Killed,
	changeTeam = replicatedStorageService.TeamChangeRequestEvent,
	ragdollVariableServer = lplr.PlayerGui.ragdoll.events.variableserver,
	codeRedeem = replicatedStorageService.codeEvent
}

local modules = {
	blurModule = require(gameModules.CreateBlur),
	cameraShakeModule = require(gameModules.CameraShaker),
	carModule = require(gameModules.Cars),
	smokeTrailModule = require(gameModules.SmokeTrail)
}

local locations = {
	['gun shop'] = vector3New(-1633, 7, -92),
	['bank'] = vector3New(-2369, 4, 115),
	['night club'] = vector3New(-1195, 3, -75),
	['car dealership'] = vector3New(-1415, 3, -128),
	['armour'] = vector3New(-1616, 3, -546),
	['casino'] = vector3New(-2417, 3, -660),
	['cash register'] = vector3New(-1793, 4, -71),
	['cali apartments'] = vector3New(-2442, 6, -292),
	['mc donald\'s'] = vector3New(-1919, 4, -654),
	['swipe'] = vector3New(-1539, 3, -322),
	['weed area'] = vector3New(-2000, 3, 187),
	['janitor job'] = vector3New(-1675, 4, 49),
	['crate job'] = vector3New(-1947, 3, -39),
	['bank dealer'] = vector3New(-1923, 3, 89)
}
local locationName = {}
for name in locations do locationName[#locationName + 1] = name end

local buys = {
	['Uzi'] = {position = vector3New(-1642, 4, -84), text = 'Buy Uzi for $2000', cost = 2000},
	['Draco'] = {position = vector3New(-1638, 4, -87), text = 'Buy Draco for $2500', cost = 2500},
	['AR Pistol'] = {position = vector3New(-1630, 4, -79), text = 'Buy AR Pistol for $4000', cost = 4000},
	['M4A1'] = {position = vector3New(-1633, 4, -76), text = 'Buy M4A1 for $3000', cost = 3000},
	['Micro AR Pistol'] = {position = vector3New(-1637, 4, -74), text = 'Buy Micro AR Pistol for $4000', cost = 4000},
	['Glock 17'] = {position = vector3New(-1641, 4, -93), text = 'Buy Glock 17 for $1000', cost = 1000},
	['Ruger'] = {position = vector3New(-1637, 4, -96), text = 'Buy Ruger for $900', cost = 900}
}
local buyNames = {}
for name in buys do buyNames[#buyNames + 1] = name end
sort(buyNames, function(a, b) return buys[a].cost < buys[b].cost end)

local unnecessaryTools = {'Phone', 'Mop', 'Laptop'}

local gunsList = {}
local animList = {}

do -- combat funcs
	function funcs.aimbot(t)
		if not t then
			maid.aimBot = nil
			if circle then circle.Visible = false end
			if circleOutline then circleOutline.Visible = false end
			return
		end

		maid.aimBot = runService.RenderStepped:Connect(function()
			if not util:getPlayerData().alive then return end

			target = util:getClosestToMouse(library.flags.aimBotFOV, {
				aimPart = library.flags.aimBotPart,
				wallCheck = false,
				teamCheck = false,
				sheildCheck = false,
				aliveCheck = false,
				maxHealth = library.flags.aimBotIgnore and 200 or infinite
			})

			if circle and circleOutline then 
				circle.Color = library.flags.aimBotCircleColor
				circle.Filled = false
				circle.NumSides = 100
				circle.Transparency = 1
				circle.Radius = library.flags.aimBotFOV
				circle.Thickness = 1
				circle.Visible = library.flags.aimBot
				circle.ZIndex = 2
				circle.Position = userInputService:GetMouseLocation()

				circleOutline.Color = Color3.fromRGB(0, 0, 0)
				circleOutline.Filled = false
				circleOutline.NumSides = circle.NumSides
				circleOutline.Transparency = circle.Transparency
				circleOutline.Radius = circle.Radius
				circleOutline.Thickness = circle.Thickness + 1.5
				circleOutline.Visible = circle.Visible
				circleOutline.ZIndex = circle.ZIndex - 1
				circleOutline.Position = circle.Position
			end

			target = target and target.character
			if not target then return end

			if library.flags.aimBotMouseCheck then
				if not userInputService:IsMouseButtonPressed(library.flags.aimBotMouse == 'Left' and 0 or 1) then return end
			end

			gameCam.CFrame = gameCam.CFrame:lerp(cframeNew(gameCam.CFrame.Position, target[library.flags.aimBotPart].CFrame.Position), 1 / library.flags.aimBotSmoothing)
		end)
	end

	local function toYRotation(cframe)
		local _, y, Z = cframe:ToOrientation()
		return cframeNew(cframe.Position) * cframeAngles(0, y, 0)
	end
	local rotationAngle
	local antiAimFunctions = {
		Shift = function()
			rotationAngle = -fourQuadrantInverseTangent(gameCam.CFrame.LookVector.Z, gameCam.CFrame.LookVector.X) + mathRadian(library.flags.antiAimAngle)
		end,
		Random = function()
			rotationAngle = -fourQuadrantInverseTangent(gameCam.CFrame.LookVector.Z, gameCam.CFrame.LookVector.X) + mathRandom(0, 360)
		end
	}

	function funcs.antiAim(t)
		if not t then
			maid.antiAim = nil
			maid.antiAimAnimStop = nil

			if not util:getPlayerData().alive then return end
			lplr.Character.Humanoid.AutoRotate = true
			return
		end

		maid.antiAim = runService.RenderStepped:Connect(function()
			if not util:getPlayerData().alive then return end

			lplr.Character.Humanoid.AutoRotate = false

			antiAimFunctions[library.flags.antiAimMode]()

			if library.flags.antiAimMode == 'Shift' then
				lplr.Character.HumanoidRootPart.CFrame = cframeNew(lplr.Character.HumanoidRootPart.CFrame.Position) * cframeAngles(0, math.rad(library.flags.antiAimAngle) + math.rad((math.random(1, 2) == 1 and library.flags.antiAimSpeed or -library.flags.antiAimSpeed)), 0)
			else
				local newAngle = cframeNew(lplr.Character.HumanoidRootPart.CFrame.Position) * cframeAngles(0, rotationAngle + library.flags.antiAimAngle, 0)
				lplr.Character.HumanoidRootPart.CFrame = toYRotation(newAngle)
			end
		end)
	end

	local animation
	local animations = {
		['sleep'] = 4689362868,
		['Tilt'] = 3360692915,
		['Salute'] = 3360689775,
		['Applaud'] = 5915779043,
		['Hero Landing'] = 5104377791,
		['HIPMOTION - Amaarae'] = 16572756230,
		['Mae Stephens - Piano Hands'] = 16553249658,
		['Mini Kong'] = 17000058939,
		['ericdoa - dance'] = 15698510244,
		['Bored'] = 5230661597,
		['V Pose - Tommy Hilfiger'] = 10214418283,
		['Uprise - Tommy Hilfiger'] = 10275057230,
		['Elton John - Piano Jump'] = 11453096488,
		['Dolphin Dance'] = 5938365243,
		['Quiet Waves'] = 7466046574,
		['Frosty Flair - Tommy Hilfiger'] = 10214406616
	}
	for name in animations do animList[#animList + 1] = name end

	local function addAnimation()
		repeat task.wait(); until lplr.Character and lplr.Character:FindFirstChild('Humanoid') or not library.flags.animationPlayer
		if animation then
			animation:Stop()
			animation.Animtion:Destroy()
			animation = nil
		end
		local anim = Instance.new('Animation')
		local suc, id = pcall(function() return string.match(game:GetObjects('rbxassetid://'.. (library.flags.customAnimation and library.flags.customAnimationId or animations[library.flags.animation]))[1].AnimationId, '%?id=(%d+)') end)
		if not suc then id = library.flags.customAnimation and library.flags.customAnimationId or animations[library.flags.animation] end
		anim.AnimationId = 'rbxassetid://'.. id
		local suc, res = pcall(function() animation = lplr.Character.Humanoid.Animator:LoadAnimation(anim) end)
		if suc then
			animation.Priority = Enum.AnimationPriority.Action4
			animation.Looped = true
			animation:AdjustSpeed(library.flags.animationSpeed)
			animation:Play()
			maid.antiAimAnimStop = animation.Stopped:Connect(function()
				if library.flags.animationPlayer then
					library.options.animationPlayer:SetState(not library.flags.animationPlayer)
					library.options.animationPlayer:SetState(not library.flags.animationPlayer)
				end
			end)
		end
	end


	function funcs.animPlayer(t)
		if not t then
			maid.antiAimAnimStop = nil
			maid.antiAimAnimChar = nil
			if animation then animation:Stop(); animation = nil end
			return
		end

		addAnimation()
		maid.antiAimAnimChar = lplr.CharacterAdded:Connect(addAnimation)
	end
end

do -- visuals
	function funcs.betterHurtScreen(t) lplr.PlayerGui["Damage GUI"].IgnoreGuiInset = t end

	function funcs.noHurtScreen(t)
		if not t then
			maid.noHurtCam = nil
			return
		end

		maid.noHurtCam = runService.RenderStepped:Connect(function()
			for i, v in next, lplr.PlayerGui["Damage GUI"]:GetChildren() do
				if v:IsA('ImageLabel') then
					v.Visible = false
				end
			end
		end)
	end

	local oldBlurFunction, oldSmokEmmitFunction = modules.blurModule.Create, modules.smokeTrailModule.EmitSmokeTrail
	function funcs.noGunBlur(t) modules.blurModule.Create = t and function() end or oroldBlurFunction end
	function funcs.noSmokeTrail(t) modules.smokeTrailModule.EmitSmokeTrail = t and function() end or oldSmokEmmitFunction end

	function funcs.changeTime(t)
		if not t then
			maid.customTime = nil
			if not oldTime then return end
			lightingService.ClockTime = oldTime
			return
		end

		oldTime = lightingService.ClockTime

		maid.customTime = lightingService:GetPropertyChangedSignal('ClockTime'):Connect(function()
			lightingService.ClockTime = library.flags.timeOfDay
		end)
		lightingService.ClockTime = library.flags.timeOfDay
	end

	local oldData, processing = {}, false
	local function changeCharacterMaterial()
		repeat task.wait() until not processing
		repeat task.wait() until lplr.Character or not library.flags.materialChams
		for i, v in next, lplr.Character:GetDescendants() do
			processing = true
			if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' then
				processing = true
				oldData[v] = {material = v.Material, color = v.Color, trans = v.Transparency}
				v.Material = library.flags.materialChamsMaterial
				v.Color = library.flags.materialChamsColor
				v.Transparency = library.flags.materialChamsTrans
			end
			processing = false
		end
	end
	function funcs.materialChams(t)
		if not t then
			maid.materialChamsChar = nil
			if not lplr.Character then return end
			processing = true
			for i, v in next, lplr.Character:GetDescendants() do
				if oldData[v] then v.Transparency = oldData[v].trans end
				if oldData[v] then v.Color = oldData[v].color end
				if oldData[v] then v.Material = oldData[v].material end
			end
			processing = false
			return
		end
		
		changeCharacterMaterial()
		maid.materialChamsChar = lplr.CharacterAdded:Connect(function()
			task.wait(0.2)
			changeCharacterMaterial()
		end)
	end

	local chatFrame = lplr.PlayerGui.Chat.Frame
	function funcs.showChat(t)
		chatFrame.ChatChannelParentFrame.Visible = t
		if not t then
			chatFrame.ChatBarParentFrame.Position = udim2New()
			return
		end

		chatFrame.ChatChannelParentFrame.Visible = true
		chatFrame.ChatBarParentFrame.Position = chatFrame.ChatChannelParentFrame.Position + udim2New(udimNew(), chatFrame.ChatChannelParentFrame.Size.Y)
	end
end

do -- teleports
	local teleporting = false
	function funcs.teleport(position)
		if not util:getPlayerData().alive then return end

		local rayParams = RaycastParams.new()
		rayParams.RespectCanCollide = true
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = {gameCam, lplr.Character}

		if typeof(position) == 'Vector3' then position = cframeNew(position) end

		teleporting = true

		task.delay(library.flags.safeLoad and 20 or library.flags.timeout, function()
			teleporting = false
			lplr.Character.HumanoidRootPart.Anchored = false
		end)

		if lplr.Character.Humanoid.SeatPart then
			if library.flags.holdWhenSitting then teleporting = false return end
			lplr.Character.Humanoid.Sit = false
			task.wait()
		end

		lplr.Character.HumanoidRootPart.Anchored = library.flags.safeLoad

		lplr.Character.HumanoidRootPart.CFrame = position
		lplr.Character.HumanoidRootPart.AssemblyLinearVelocity = vector3Zero
		lplr.Character.HumanoidRootPart.AssemblyAngularVelocity = vector3Zero

		if library.flags.safeLoad then
			repeat
				local ray = workspace:Raycast(lplr.Character.HumanoidRootPart.CFrame.Position, Vector3.new(0, -150, 0), rayParams)
				task.wait()
			until ray and ray.Instance

			lplr.Character.HumanoidRootPart.Anchored = false
		end
		
		teleporting = false
	end

	function funcs.clickTP(t)
		if not t then
			maid.clickTP = nil
			return
		end

		if not mouse then return end
		maid.clickTP = mouse.Button1Down:Connect(function()
			local hitPoint = mouse.Hit.Position + vector3New(0, 4, 0)
			funcs.teleport(hitPoint)
		end)
	end

	function funcs.toPlayer()
		pcall(function()
			local player = playersService:FindFirstChild(library.flags.playerList.Name).Character
			if not player or not player:FindFirstChild('HumanoidRootPart') then return end
			if not util:getPlayerData().alive then return end

			funcs.teleport(player.HumanoidRootPart.CFrame)
		end)
	end

	function funcs.viewPlayer(t)
		if not t then
			if not isSpectating then return end
			gameCam.CameraSubject = lplr.Character
			return
		end

		pcall(function()
			local player = playersService[library.flags.playerList.Name].Character
			if not player then return end

			gameCam.CameraSubject = player
			isSpectating = true
		end)
	end

	function funcs.toLocation()
		funcs.teleport(locations[library.flags.tpLocations])
	end

	function funcs.refilAmmo()
		local prev = lplr.Character.HumanoidRootPart.CFrame
		funcs.teleport(vector3New(-1626, 4, -98))
		task.wait(0.2)
		for i, v in next, workspace:GetDescendants() do
			if v:IsA('ProximityPrompt') and v.Parent.Parent.Name == 'AmmoBox (Unlimited Use)' then
				fireproximityprompt(v)
			end
		end
		task.wait(0.1)
		funcs.teleport(prev)
	end

	function funcs.getArmor()
		local prev = lplr.Character.HumanoidRootPart.CFrame
		funcs.teleport(vector3New(-1615, 3, -548))
		task.wait(0.2)
		for i, v in next, workspace:GetDescendants() do
			if v:IsA('ProximityPrompt') and v.Parent.CFrame.Position == vector3New(-1614.6724853515625, 4.4449944496154785, -549.386962890625) then
				fireproximityprompt(v)
			end
		end
		task.wait(0.1)
		funcs.teleport(prev)
	end

	function funcs.buyWeapon(name, actionText, cost)
		if lplr.stats.Money.Value < cost then
			local moreDollars = tonumber(cost - lplr.stats.Money.Value)
			return notif.new({text = string.format('you need %s more to buy the %s', moreDollars, name), duration = 10})
		end

		local prev = lplr.Character.HumanoidRootPart.CFrame.Position
		funcs.teleport(buys[name].position)
		task.wait(0.1)
		for i, v in next, workspace:GetDescendants() do
			if v:IsA('ProximityPrompt') and v.ActionText == actionText then
				fireproximityprompt(v)
			end
		end
		task.wait(0.1)
		funcs.teleport(prev)
	end
end

do -- character and extras
	function funcs.speed(t)
		if not t then
			maid.speed = nil
			
			if not util:getPlayerData().alive then return end
			lplr.Character.HumanoidRootPart.AssemblyLinearVelocity = vector3Zero
			return
		end
	
		maid.speed = runService.Heartbeat:Connect(function(delta)
			if not util:getPlayerData().alive then return end
	
			lplr.Character.HumanoidRootPart.AssemblyLinearVelocity *= vector3New(0, 1, 0)
	
			local vector = lplr.Character.Humanoid.MoveDirection
			lplr.Character.HumanoidRootPart.CFrame += vector3New(vector.X * library.flags.speedValue * delta, 0, vector.Z * library.flags.speedValue * delta)
		end)
	end

	local flyVertical = 0
	function funcs.fly(t)
		if not t then
			maid.fly = nil
			if flyBV then flyBV:Destroy(); flyBV = nil end
			return
		end

		maid.fly = runService.Heartbeat:Connect(function(delta)
			if not util:getPlayerData().alive then return end

			if userInputService:IsKeyDown(Enum.KeyCode.Space) then
				flyVertical = library.flags.verticalValue
			elseif userInputService:IsKeyDown(Enum.KeyCode.LeftShift) or userInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				flyVertical = -library.flags.verticalValue
			else
				flyVertical = 0
			end

			if lplr.Character.Humanoid.SeatPart then lplr.Character.Humanoid.Sit = false end
			lplr.Character.HumanoidRootPart.AssemblyLinearVelocity = vector3Zero
			local vector = lplr.Character.Humanoid.MoveDirection

			flyBV = flyBV or Instance.new('BodyVelocity', lplr.Character.HumanoidRootPart)
			flyBV.MaxForce = vector3One * math.huge
			flyBV.Velocity = vector3New(vector.X * library.flags.horizontalValue * delta, flyVertical * delta, vector.Z * library.flags.horizontalValue * delta)
			
			lplr.Character.HumanoidRootPart.CFrame += vector3New(vector.X * library.flags.horizontalValue * delta, flyVertical * delta, vector.Z * library.flags.horizontalValue * delta)
		end)
	end

	function funcs.highJump(t)
		if not t then
			maid.highJump = nil

			if not util:getPlayerData().alive then return end
			lplr.Character.Humanoid.JumpPower = 50.145
			lplr.Character.Humanoid.UseJumpPower = false
			return
		end

		maid.highJump = runService.Heartbeat:Connect(function()
			if not util:getPlayerData().alive then return end
			
			lplr.Character.Humanoid.UseJumpPower = true
			lplr.Character.Humanoid.JumpPower = library.flags.jumpPower
		end)
	end

	function funcs.infJump(t)
		if not t then
			maid.infJump = nil
			return
		end

		maid.infJump = runService.Heartbeat:Connect(function()
			if not util:getPlayerData().alive then return end

			if userInputService:IsKeyDown(Enum.KeyCode.Space) then
				local velocity = lplr.Character.HumanoidRootPart.AssemblyLinearVelocity
				lplr.Character.HumanoidRootPart.AssemblyLinearVelocity = vector3New(velocity.X, lplr.Character.Humanoid.JumpPower, velocity.Z)
			end
		end)
	end

	function funcs.noClip(t)
		if not t then
			maid.noClip = nil

			if not util:getPlayerData().alive then return end
			if lplr.Character.Humanoid.SeatPart then return end

			lplr.Character.Humanoid:ChangeState('Physics')
			task.wait()
			lplr.Character.Humanoid:ChangeState('RunningNoPhysics')
			return
		end

		maid.noClip = runService.Stepped:Connect(function()
			if not util:getPlayerData().alive then return end

			local parts = util:getPlayerData().parts
			if not parts then return end

			for _, part in parts do
				part.CanCollide = false
			end
		end)
	end

	function funcs.autoSprint(t)
		if not t then
			maid.autoSprintSpeedChanged = nil
			maid.autoSprint = nil
			lplr.Character.Humanoid.WalkSpeed = 10
			return
		end

		maid.autoSprint = runService.Heartbeat:Connect(function()
			if not util:getPlayerData().alive then return end

			maid.autoSprintSpeedChanged = lplr.Character.Humanoid:GetPropertyChangedSignal('WalkSpeed'):Connect(function()
				lplr.Character.Humanoid.WalkSpeed = 20
			end)
			lplr.Character.Humanoid.WalkSpeed = 20
		end)
	end

	local oldCframe, oldSize, part
	function funcs.godMode(t)
		if not t then
			maid.godMode = nil
			if part and oldCframe and oldSize then
				part.CFrame = oldCframe
				part.Size = oldSize
			end
			return
		end

		repeat
			for _, obj in safeZones:GetChildren() do
				if obj.Name ~= 'safeZoneArea' or not obj:IsA('BasePart') then continue end

				part = obj
				break
			end
			task.wait()
		until part

		oldCframe = part.CFrame
		oldSize = part.Size

		maid.godmodeLoop = runService.RenderStepped:Connect(function()
			if not util:getPlayerData().alive then return end
			if not part then return end

			part.Size = vector3One * 2040
			part.CFrame = lplr.Character.HumanoidRootPart.CFrame
		end)
	end

	function funcs.antiRagdoll()
		repeat
			events.ragdollVariableServer:FireServer('ragdoll', false)
			task.wait()
		until not library.flags.antiRagdoll
	end

	function funcs.equipAllTools(t)
		if not util:getPlayerData().alive then return end
		if not t then
			lplr.Character.Humanoid:UnequipTools()
			return
		end

		lplr.Character.Humanoid:UnequipTools()
		task.wait()
		for i, v in next, lplr.Backpack:GetChildren() do
			if not v:IsA('Tool') then continue end
			if not table.find(gunsList, v.Name) then continue end

			task.spawn(function()
				v.Parent = lplr.Character
			end)
		end
	end

	function funcs.instantPP(t)
		if not t then
			maid.instantInteract = nil
			return
		end

		maid.instantInteract = proximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
			fireproximityprompt(prompt)
		end)
	end

	local function destroyTools()
		if not lplr.Character then return end

		for i, v in next, lplr.Backpack:GetChildren() do
			if not v:IsA('Tool') then continue end
			if not table.find(unnecessaryTools, v.Name) then continue end
			
			v:Destroy()
		end
		for i, v in next, lplr.Character:GetChildren() do
			if not v:IsA('Tool') then continue end
			if not table.find(unnecessaryTools, v.Name) then continue end

			v.Parent = workspace
		end
	end
	function funcs.dropBadTools(t)
		if not t then return end

		repeat
			destroyTools()
			task.wait(2)
		until not library.flags.dropUnnecessaryTools
	end

	local chatRemote = replicatedStorageService:WaitForChild('DefaultChatSystemChatEvents', 10).SayMessageRequest
	local killSayList = {
		'<player> just died the same way as those requisition users',
		'<player>, maybe buy vcs?? /sRz4eEs9Qk',
		'<player> would not have died if he used vcs: /sRz4eEs9Qk',
		'<player> might be tempted to get scripts to spin back at me, but the truth is, he cannot',
		'vcs on top | sRz4eEs9Qk',
		'BUY VCS NOW: /sRz4eEs9Qk',
		'<player> should buy vcs now: /sRz4eEs9Qk'
	}
	function funcs.killSay(t)
		if not t then
			maid.killSay = nil
			return
		end

		maid.killSay = events.killed.OnClientEvent:Connect(function(playerName)
			local message = killSayList[math.random(1, #killSayList)]
			if message then message = message:gsub('<player>', playerName) end
			chatRemote:FireServer(message, 'All')
		end)
	end

	local otherFolder = workspace:WaitForChild('Buildings', 10).Other
	function funcs.noFenceCollisions(t)
		for i, v in next, otherFolder:GetChildren() do
			if not v:IsA('MeshPart') then continue end
			if not v.Name == 'TallFence' then continue end

			v.CanCollide = not t
		end
	end

	function funcs.redeemAllCodes()
		for i, v in next, lplr.CodesFolder:GetChildren() do
			if not v:IsA('BoolValue') then continue end
			if v.Value then continue end

			events.codeRedeem:FireServer(v.Name)
			notif.new({text = 'redeemed: '.. v.Name, duration = 5})
			task.wait()
		end
	end

	function funcs.setTeam(teamName)
		events.changeTeam:FireServer(teamName)
	end

	local sentAt = 0
	function funcs.fuckProxiHub(t)
		if not t then
			maid.safeChange = nil
			maid.detectProxiHub = nil
			return
		end

		maid.detectProxiHub = playersService.PlayerChatted:Connect(function(enum, player, message)
			if message ~= 'auto arrest by . g g / p r o x i h u b' then return end
			if player == lplr then return end

			if tick() - sentAt < 30.2 then return end
			sentAt = tick()
			notif.new({text = string.format('%s is using proxi hub (detected chat message)', player.Name), duration = 30})
			
			if not library.flags.safeChangeTeams then return end
			if lplr.Team == 'Police' then return end

			local prev = lplr.Character.HumanoidRootPart.CFrame
			maid.safeChange = lplr.CharacterAdded:Connect(function()
				task.wait(0.3)
				funcs.teleport(prev)
				maid.safeChange = nil
				prev = nil
			end)
			funcs.setTeam('Police')
		end)
	end
end

do -- auto farm (re do this)
	local function isJobLoaded(jobName)
		for i, v in next, jobSystem:GetChildren() do
			if v.Name == jobName then
				local t = {}
				for i2, v2 in next, v:GetChildren() do
					table.insert(t, v2)
				end
				return #t > 1
			end
		end
	end

	local function loadJob(position, floorMaterial, weed)
		if not util:getPlayerData().alive then return end

		local rayParams = RaycastParams.new()
		rayParams.RespectCanCollide = true
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = {gameCam, lplr.Character}
	
		lplr.Character.HumanoidRootPart.Anchored = true
		lplr.Character.HumanoidRootPart.CFrame = cframeNew(position)
	
		repeat
			local ray = workspace:Raycast(lplr.Character.HumanoidRootPart.CFrame.Position, Vector3.new(0, -10, 0), rayParams)
			task.wait()
		until not weed and (ray and ray.Instance.Material == floorMaterial and ray.Instance:IsA('BasePart')) or (ray and ray.Instance.Material == Enum.Material.SmoothPlastic and ray.Instance:FindFirstChildOfClass('Texture'))

		task.wait(0.5)
		lplr.Character.HumanoidRootPart.Anchored = false
	end

	do
		local foundWeedPot = {}
		local constants = {
			['load point'] = vector3New(-1986, 7, 177),
			['nigger'] = vector3New(-2005, 3, 195),
			['nigger closer'] = vector3New(-2004, 3, 197),
		}
		
		local function getData()
			for i, v in next, workspace:GetDescendants() do
				if not v:IsA('ProximityPrompt') then continue end
				if v.Parent.Name ~= 'Grass' or not v.Parent:IsA('MeshPart') then continue end
					
				if v.Parent.Transparency == 0 then
					foundWeedPot.ProximityPrompt = v
					foundWeedPot.ParentPart = v.Parent
				end
			end
		end

		local function equipRequiredTool(delay)
			if lplr.Backpack:FindFirstChild('Grass') then
				if not lplr.Backpack.Grass:IsA('Tool') then return end

				if not lplr.Character:FindFirstChild('Grass') then lplr.Character.Humanoid:UnequipTools() end
				if delay then task.wait(delay) end
				lplr.Backpack.Grass.Parent = lplr.Character
			end
		end

		local function check()
			if lplr.Backpack:FindFirstChild('Grass') and lplr.Backpack:FindFirstChild('Grass'):IsA('Tool') then
				if not lplr.Character:FindFirstChild('Grass') then lplr.Character.Humanoid:UnequipTools() end
				lplr.Backpack.Grass.Parent = lplr.Character
			end
		end

		function funcs.weedFarm(t)
			if not t then return end

			loadJob(constants['load point'], Enum.Material.SmoothPlastic, true)

			repeat
				if not library.flags.weedFarm then break end
				if not util:getPlayerData().alive then return end

				lplr.Character.HumanoidRootPart.CFrame = cframeNew(constants['load point'] - Vector3.new(0, 4, 0))

				repeat
					if not library.flags.weedFarm then break end
					getData()
					task.wait()
				until foundWeedPot.ProximityPrompt and foundWeedPot.ParentPart

				lplr.Character.HumanoidRootPart.CFrame = foundWeedPot.ParentPart.CFrame

				fireproximityprompt(foundWeedPot.ProximityPrompt)
				equipRequiredTool(0.5)
				task.wait(0.2)
				repeat
					if not library.flags.weedFarm then break end
					equipRequiredTool()
					lplr.Character.HumanoidRootPart.CFrame = cframeNew(constants['load point'] - Vector3.new(0, 4, 0))
					task.wait(0.2)
					lplr.Character.HumanoidRootPart.CFrame = cframeNew(constants['nigger closer'])
					task.wait()
				until not lplr.Character:FindFirstChild('Grass')
				foundWeedPot = {}
			until not library.flags.weedFarm
			foundWeedPot = {}
		end
	end

	do
		local constants = {
			['load point'] = vector3New(-1399, 3, 24),
			['garbage'] = vector3New(-1386, 3, 27),
			['garbage safe'] = vector3New(-1391, 3, 25),
			['truck'] = vector3New(-1409, 3, 28),
			['truck closer'] = vector3New(-1409, 3, 31),
			['prompt text'] = '🗑️Deliver the trash to the truck'
		}

		local ProximityPrompt
		local function getProximityPrompt()
			for i, v in next, jobSystem:GetDescendants() do
				if v:IsA('ProximityPrompt') and v.ObjectText == constants['prompt text'] then
					ProximityPrompt = v
				end
			end
		end

		local function equipRequiredTool(delay)
			if lplr.Backpack:FindFirstChild('Garbage') then
				if not lplr.Backpack.Garbage:IsA('Tool') then return end

				if not lplr.Character:FindFirstChild('Garbage') then lplr.Character.Humanoid:UnequipTools() end
				if delay then task.wait(delay) end
				lplr.Backpack.Garbage.Parent = lplr.Character
			end
		end
		
		function funcs.indianFarm(t)
			if not t then return end

			if not isJobLoaded('GarbageJob') then loadJob(constants['load point'], Enum.Material.Concrete) end

			repeat
				if not library.flags.garbageFarm then break end
				if not util:getPlayerData().alive then return end

				lplr.Character.HumanoidRootPart.CFrame = cframeNew(constants['garbage safe'])
				task.wait(1)
				lplr.Character.HumanoidRootPart.CFrame = cframeNew(constants['garbage'])

				if not ProximityPrompt then getProximityPrompt() end
				fireproximityprompt(ProximityPrompt)
				equipRequiredTool(0.5)
				task.wait(0.3)
				repeat
					if not library.flags.garbageFarm then break end
					equipRequiredTool()
					lplr.Character.HumanoidRootPart.CFrame = cframeNew(constants['truck'])
					task.wait(0.3)
					equipRequiredTool()
					lplr.Character.HumanoidRootPart.CFrame = cframeNew(constants['truck closer'])
					task.wait(0.2)
				until not lplr.Character:FindFirstChild('Garbage')
				lplr.Character.HumanoidRootPart.CFrame = cframeNew(constants['load point'])
				task.wait(3.4)
			until not library.flags.garbageFarm
		end
	end

	do
		local constants = {
			['load point'] = vector3New(-1936, 10, -37),
			['crates'] = vector3New(-1941, 3, -47),
			['crates safe'] = vector3New(-1937, 3, -43),
			['truck'] = vector3New(-1925, 3, -22),
			['truck closer'] = vector3New(-1922, 3, -22),
			['prompt text'] = '📦Deliver the crate to the truck'
		}

		local ProximityPrompt
		local function getProximityPrompt()
			for i, v in next, jobSystem:GetDescendants() do
				if v:IsA('ProximityPrompt') and v.ObjectText == constants['prompt text'] then
					ProximityPrompt = v
				end
			end
		end

		local function equipRequiredTool(delay)
			if lplr.Backpack:FindFirstChild('BOX') then
				if not lplr.Backpack.BOX:IsA('Tool') then return end

				if not lplr.Character:FindFirstChild('BOX') then lplr.Character.Humanoid:UnequipTools() end
				if delay then task.wait(delay) end
				lplr.Backpack.BOX.Parent = lplr.Character
			end
		end

		function funcs.boxFarm(t)
			if not t then return end

			if not isJobLoaded('BoxPickingJob') then loadJob(constants['load point'], Enum.Material.Concrete) end

			repeat
				if not library.flags.boxFarm then break end
				if not util:getPlayerData().alive then return end

				lplr.Character.HumanoidRootPart.CFrame = cframeNew(constants['crates safe'])
				task.wait(1)
				lplr.Character.HumanoidRootPart.CFrame = cframeNew(constants['crates'])

				if not ProximityPrompt then getProximityPrompt() end
				fireproximityprompt(ProximityPrompt)
				equipRequiredTool(0.5)
				task.wait(0.3)
				repeat
					if not library.flags.boxFarm then break end
					equipRequiredTool()
					lplr.Character.HumanoidRootPart.CFrame = cframeNew(constants['truck'])
					task.wait(0.3)
					equipRequiredTool()
					lplr.Character.HumanoidRootPart.CFrame = cframeNew(constants['truck closer'])
					task.wait(0.2)
				until not lplr.Character:FindFirstChild('BOX')
				lplr.Character.HumanoidRootPart.CFrame = cframeNew(constants['load point'])
				task.wait(3.4)
			until not library.flags.boxFarm
		end
	end
end

do -- gun mod funcs
	local gunRestorationSave = {}
	local gunSettings = gameModules.WeaponSettings.Gun

	for i, v in next, gameModules.WeaponSettings.Gun:GetChildren() do
		if v:IsA('Folder') and #v:GetDescendants() == 2 then
			insert(gunsList, v.Name)
		end
	end

	local function clearRestorationSave(gunName)
		if not gunRestorationSave[gunName] then return end
		local temp = gunRestorationSave[gunName]
		clear(temp)
		temp = nil
	end

	local function restoreGun(gunName, property)
		if gunRestorationSave[gunName] then
			local savedData = gunRestorationSave[gunName]

			if property then
				require(gunSettings[gunName].Setting['1'])[property] = savedData[property]
			else
				local settings = require(gunSettings[gunName].Setting['1'])
				settings = savedData
			end
		end
	end

	local function modifyGun(gunName, property, value)
		if not gunSettings:FindFirstChild(gunName) then return end
		local localGunSettings = require(gunSettings[gunName].Setting['1'])
		clearRestorationSave(gunName)
		task.wait()
		gunRestorationSave[gunName] = copyTable(localGunSettings)
		task.wait()
		localGunSettings[property] = value
	end

	function funcs.modifyFunc(property, value, toggle)
		if toggle == false then
			for _, gun in gunsList do
				restoreGun(gun, property)
			end
			return
		end

		for _, gun in gunsList do
			modifyGun(gun, property, value)
		end
	end
end

do -- rage funcs
	local function checkTool() -- what the fuck
		if not util:getPlayerData().alive then return end
		if not lplr.Character:FindFirstChildOfClass('Tool') then
			for i, v in next, lplr.Backpack:GetChildren() do
				if v:IsA('Tool') and table.find(gunsList, v.Name) then
					v.Parent = lplr.Character
					return true
				else
					return false
				end
			end
		end
		return true
	end

	function funcs.killAll(t)
		if not t then
			maid.killAll = nil
			lplr.CameraMaxZoomDistance = 30
			return
		end

		if not library.flags.antiRagdoll then library.options.antiRagdoll:SetState(true) end
		maid.killAll = runService.Heartbeat:Connect(function()
			if not util:getPlayerData().alive then return end

			local target = util:getClosestToCharacter(infinite, {maxHealth = 200, aimPart = 'HumanoidRootPart'})
			target = target and target.character
			if not target then lplr.CameraMaxZoomDistance = 30 return end

			local hit = target:FindFirstChild('HumanoidRootPart')
			local hitPos = hit and hit.CFrame.Position

			local camera = workspace.CurrentCamera
			if not camera then return end
			if not checkTool() then lplr.CameraMaxZoomDistance = 30 return end

			camera.CFrame = camera.CFrame:lerp(cframeNew(camera.CFrame.Position, hitPos), 1 / 1)

			lplr.Character.HumanoidRootPart.AssemblyLinearVelocity = vector3Zero
			lplr.Character.HumanoidRootPart.AssemblyAngularVelocity = vector3Zero

			lplr.CameraMaxZoomDistance = 0
			lplr.Character.HumanoidRootPart.CFrame = cframeNew(hitPos) * cframeNew(0, library.flags.snapHeight, library.flags.snapSpace)
			mouse1click()
		end)
	end

	--function funcs.autoArrest(t)
	--	if not t then
	--		maid.autoArrest = nil
	--		return
	--	end

	--	maid.autoArrest = runService.Heartbeat:Connect(function()
	--		if not util:getPlayerData().alive then return end

	--		local target = util:getClosestToCharacter(infinite, {maxHealth = 200, aimPart = 'HumanoidRootPart'})
	--		target = target and target.character

	--		
	--	end)
	--end
end

local aimbot = combat1:AddSection('Aim Bot')
local antiAim = combat2:AddSection('Anti Aim')
local animationPlayer = combat2:AddSection('Animation Player')

local playerESP = visual1:AddSection('Player ESP')
local effects = visual2:AddSection('Effects')
local materialChams = visual2:AddSection('Material Chams')
local extraVisuals = visual2:AddSection('Extras')

local tpMain = teleport1:AddSection('Main')
local tpPlayers = teleport1:AddSection('Players')
local tpLocations = teleport1:AddSection('Locations')
local tpSecttings = teleport2:AddSection('Settings')
local tpUtilities = teleport2:AddSection('Utilities')

local character = misc1:AddSection('Character')
local extras = misc1:AddSection('Extras')
local autoFarms = misc2:AddSection('Auto Farms')
local gunMods = misc2:AddSection('Gun Modifications')
local rage = misc2:AddSection('Rage')

aimbot:AddToggle({text = 'Enabled', flag = 'aim bot', callback = funcs.aimbot})
aimbot:AddDivider()
aimbot:AddList({text = 'Aim Part', flag = 'aim bot part', values = {'Head', 'HumanoidRootPart'}})
aimbot:AddSlider({text = 'Field Of View', flag = 'aim bot f o v', min = 10, max = 1000, value = 100, callback = function() end})
aimbot:AddSlider({text = 'Smoothing', flag = 'aim bot smoothing', min = 1, max = 10})
aimbot:AddToggle({
	text = 'Fov Circle',
	flag = 'aim bot fov circle',
	callback = function(t)
		if t then
			circle = circle or drawingNew('Circle')
			circle.Color = library.flags.aimBotCircleColor
			circle.Filled = false
			circle.NumSides = 100
			circle.Transparency = 1
			circle.Radius = library.flags.aimBotFOV
			circle.Thickness = 2
			circle.Visible = library.flags.aimBot
			circle.ZIndex = 2
			circle.Position = userInputService:GetMouseLocation()

			circleOutline = circleOutline or drawingNew('Circle')
			circleOutline = circleOutline or drawingNew('Circle')
			circleOutline.Color = Color3.fromRGB(0, 0, 0)
			circleOutline.Filled = false
			circleOutline.NumSides = circle.NumSides
			circleOutline.Transparency = circle.Transparency
			circleOutline.Radius = circle.Radius
			circleOutline.Thickness = circle.Thickness + 1.5
			circleOutline.Visible = circle.Visible
			circleOutline.ZIndex = circle.ZIndex - 1
			circleOutline.Position = circle.Position
		else
			if circle then circle:Destroy(); circle = nil end
			if circleOutline then circleOutline:Destroy(); circleOutline = nil end
		end
	end
}):AddColor({flag = 'aim bot circle color'})
aimbot:AddToggle({text = 'Require Mouse Down', flag = 'aim bot mouse check'})
aimbot:AddList({flag = 'aim bot mouse', values = {'Right', 'Left'}})
aimbot:AddToggle({text = 'Ignore Un Attackable', flag = 'aim bot ignore'})

antiAim:AddToggle({text = 'Enabled', flag = 'anti aim', callback = funcs.antiAim})
antiAim:AddDivider()
antiAim:AddList({text = 'Mode', flag = 'anti aim mode', values = {'Shift', 'Random'}})
antiAim:AddSlider({text = 'Speed', flag = 'anti aim speed', min = 1, max = 1000, value = 130})
antiAim:AddSlider({text = 'Angle', flag = 'anti aim angle', min = 0, max = 360})

animationPlayer:AddToggle({text = 'Enabled', flag = 'animation player', tip = 'use with anti aim', callback = funcs.animPlayer})
animationPlayer:AddDivider()
animationPlayer:AddList({text = 'Animation', values = animList, value = 'Sleep', callback = function()
	if library.flags.animationPlayer then
		library.options.animationPlayer:SetState(not library.flags.animationPlayer)
		library.options.animationPlayer:SetState(not library.flags.animationPlayer)
	end
end})
animationPlayer:AddToggle({text = 'Custom Animation'})
animationPlayer:AddBox({text = 'Animation Id'})
animationPlayer:AddSlider({text = 'Animation Speed', min = 1, max = 100, value = 5})

do -- esp
	local espPlayers = {}

	local function onPlayerAdded(player)
		if player == lplr then return end
		local espDonePlayer = espLibrary.new(player)
	
		library.unloadMaid[player] = function()
			remove(espPlayers, find(espPlayers, espDonePlayer))
			espDonePlayer:Destroy()
		end
	
		insert(espPlayers, espDonePlayer)
	end

	local function onPlayerRemoving(player)
		library.unloadMaid[player] = nil
	end

	library.OnLoad:Connect(function()
		playersService.PlayerAdded:Connect(onPlayerAdded)
		playersService.PlayerRemoving:Connect(onPlayerRemoving)
	
		for _, player in playersService:GetPlayers() do
			task.spawn(onPlayerAdded, player)
		end
	end)
	
	local function toggleRainbowEsp(flag)
		return function(toggle)
			if(not toggle) then
				maid['rainbow'.. flag] = nil
				return
			end
	
			maid['rainbow'.. flag] = runService.RenderStepped:Connect(function()
				library.options[flag]:SetColor(library.chromaColor, false, true)
			end)
		end
	end

	playerESP:AddToggle({
		text = 'Enabled',
		flag = 'toggle esp',
		callback = function(t)
			if t then
				local lastUpdateAt = 0
				local ESP_UPDATE_RATE = 10/1000
			
				maid.updateEsp = runService.RenderStepped:Connect(function()
					if tick() - lastUpdateAt < ESP_UPDATE_RATE then return end
					lastUpdateAt = tick()
			
					for _, player in espPlayers do
						player:Update()
					end
				end)
			else
				maid.updateEsp = nil
				for _, player in espPlayers do
					player:Hide()
				end
			end
		end
	})
	playerESP:AddDivider()
	playerESP:AddSlider({
		text = 'Max Esp Distance',
		value = 10000,
		min = 50,
		max = 10000,
		textpos = 2,
		callback = function(val)
			if val == 10000 then
				val = infinite
			end
	
			library.flags.maxEspDistance = val
		end
	})
	playerESP:AddToggle({text = 'Render Tracers'})
	playerESP:AddToggle({text = 'Render Boxes'})
	playerESP:AddToggle({
		text = 'Render Health Bar'
	}):AddColor({
		flag = 'health bar low',
		tip = 'health bar color when low health',
		color = Color3.fromRGB(255, 0, 0)
	}):AddColor({
		flag = 'health bar high',
		tip = 'health bar color when full health',
		color = Color3.fromRGB(0, 255, 0)
	})

	playerESP:AddDivider('Customisation')
	playerESP:AddList({
		text = 'Esp Font',
		values = {'UI', 'System', 'Plex', 'Monospace'},
		callback = function(val)
			val = Drawing.Fonts[val]
			for _, v in espPlayers do
				v:SetFont(val)
			end
		end,
	})
	playerESP:AddSlider({
		text = 'Text Size',
		textpos = 2,
		max = 100,
		min = 16,
		callback = function(val)
			for _, v in espPlayers do
				v:SetTextSize(val)
			end
		end
	})

	playerESP:AddDivider()
	playerESP:AddToggle({text = 'Display Name', state = true})
	playerESP:AddToggle({text = 'Display Distance'})
	playerESP:AddToggle({text = 'Display Health'})
	playerESP:AddToggle({text = 'Use Float Health', tip = 'shows the players health as a percentage'})
	
	playerESP:AddDivider()
	playerESP:AddToggle({text = 'Render Team Members', state = true})
	playerESP:AddToggle({text = 'Only Render Niggers'})
	playerESP:AddToggle({text = 'Unlock Tracers'})

	playerESP:AddDivider()
	playerESP:AddToggle({text = 'Rainbow Enemy Color', callback = toggleRainbowEsp('enemyColor')})
	playerESP:AddToggle({text = 'Rainbow Ally Color', callback = toggleRainbowEsp('allyColor')})
	playerESP:AddColor({text = 'Ally Color', color = Color3.fromRGB(0, 255, 0)})
	playerESP:AddColor({text = 'Enemy Color', color = Color3.fromRGB(255, 0, 0)})
	playerESP:AddToggle({text = 'Use Team Color', state = true})
end

effects:AddToggle({text = 'Better Hurt Cam', tip = 'makes the death screen look better', callback = funcs.betterHurtScreen})
effects:AddToggle({text = 'No Hurt Cam', tip = 'removes the death screen', callback = funcs.noHurtScreen})
effects:AddDivider()
effects:AddToggle({text = 'No Gun Blur', callback = funcs.noGunBlur})
effects:AddToggle({text = 'No Smoke Trail', callback = funcs.noSmokeTrail})
effects:AddDivider()
effects:AddToggle({text = 'Clock Time', callback = funcs.changeTime})
effects:AddSlider({flag = 'time of day', value = 14, min = 0, max = 23, textpos = 2, float = 0.01, callback = function(val) if not library.flags.clockTime then return end; lightingService.ClockTime = val; end})

local materials = {}
for _, material in Enum.Material:GetEnumItems() do insert(materials, material.Name) end

materialChams:AddToggle({text = 'Enabled', flag = 'material chams', callback = funcs.materialChams})
materialChams:AddDivider()
materialChams:AddColor({text = 'Color', flag = 'material chams color'})
materialChams:AddList({text = 'Material', flag = 'material chams material', values = materials, value = 'ForceField'})
materialChams:AddSlider({text = 'Transparency', flag = 'material chams trans', min = 0, max = 1, float = 0.01})

extraVisuals:AddToggle({text = 'Show Chat', callback = funcs.showChat})

tpMain:AddToggle({text = 'Click Teleport', callback = funcs.clickTP})

tpPlayers:AddList({flag = 'player list', playerOnly = true, skipflag = true})
tpPlayers:AddButton({text = 'Teleport To Player', callback = funcs.toPlayer})
tpPlayers:AddToggle({text = 'Spectate Player', skipflag = true, callback = funcs.viewPlayer})

tpLocations:AddList({flag = 'tp locations', values = locationName})
tpLocations:AddButton({text = 'Teleport To Location', callback = funcs.toLocation})

tpSecttings:AddSlider({text = 'Timeout', min = 5, max = 10, tip = 'how long defore the teleport gets cancelled'})
tpSecttings:AddToggle({text = 'Safe Load', tip = 'waits for the floor to load before letting you walk'})
tpSecttings:AddToggle({text = 'Hold When Sitting', tip = 'does not teleport you when you are sitting'})

tpUtilities:AddButton({text = 'Refill Ammo', callback = funcs.refilAmmo})
tpUtilities:AddButton({text = 'Get Armour', callback = funcs.getArmor})
tpUtilities:AddLabel('\nWeapons')

for _, name in buyNames do
	tpUtilities:AddButton({text = string.format('Buy %s - %s', name, buys[name].cost), callback = function() funcs.buyWeapon(name, buys[name].text, buys[name].cost) end})
end

character:AddToggle({text = 'Speed', callback = funcs.speed})
character:AddSlider({text = 'Speed Value', textpos = 2, min = 10, max = 500, value = 100})

character:AddDivider()
character:AddToggle({text = 'Fly', callback = funcs.fly})
character:AddSlider({text = 'Horizontal Value', textpos = 2, min = 1, max = 500, value = 100})
character:AddSlider({text = 'Vertical Value', textpos = 2, min = 1, max = 500, value = 200})

character:AddDivider()
character:AddToggle({text = 'High Jump', callback = funcs.highJump})
character:AddSlider({text = 'Jump Power', textpos = 2, min = 50, max = 500, value = 100})

character:AddDivider()
character:AddToggle({text = 'Inf Jump', callback = funcs.infJump})
character:AddToggle({text = 'No Clip', callback = funcs.noClip})
character:AddToggle({text = 'Auto Sprint', callback = funcs.autoSprint})
character:AddToggle({text = 'God Mode', callback = funcs.godMode})
--character:AddToggle({text = 'Invis', callback = funcs.invis})
character:AddToggle({text = 'Anti Ragdoll', callback = funcs.antiRagdoll})

extras:AddToggle({text = 'Equip All Tools', callback = funcs.equipAllTools})
extras:AddToggle({text = 'Instant Interact', callback = funcs.instantPP})
extras:AddToggle({text = 'Drop Unnecessary Tools', callback = funcs.dropBadTools})
extras:AddToggle({text = 'Kill Say', callback = funcs.killSay})
extras:AddToggle({text = 'No Fence Collisions', callback = funcs.noFenceCollisions})
extras:AddToggle({text = 'Proxi Hub Detector', tip = 'detects people that use that retarded script', callback = funcs.fuckProxiHub})
extras:AddToggle({text = 'Safe Change Teams', tip = 'proxi hub detector must be enabled, switches to police team when proxi hub is detected'})

extras:AddButton({text = 'Redeem All Codes', callback = funcs.redeemAllCodes})

extras:AddDivider('teams')
extras:AddButton({text = 'Civilian', callback = function() funcs.setTeam('Civilian') end})
extras:AddButton({text = 'Police', callback = function() funcs.setTeam('Police') end})
extras:AddButton({text = 'Prisoner', callback = function() funcs.setTeam('Prisoner') end})

autoFarms:AddLabel('please dont turn on more\nthan 1 farm at a time\n')
autoFarms:AddToggle({text = 'weed farm', callback = funcs.weedFarm})
autoFarms:AddToggle({text = 'garbage farm', callback = funcs.indianFarm})
autoFarms:AddToggle({text = 'box farm', callback = funcs.boxFarm})

gunMods:AddToggle({text = 'Instant Kill', callback = function(t) funcs.modifyFunc('BaseDamage', 9e9, t) end})
gunMods:AddToggle({text = 'Bullet Visualizer', callback = function(t) funcs.modifyFunc('LaserTrailEnabled', t, t) end})
gunMods:AddToggle({text = 'Sniper Scope', callback = function(t) funcs.modifyFunc('SniperEnabled', t, t) end})

gunMods:AddDivider()
gunMods:AddToggle({text = 'Instant Reload', callback = function(t) if t then funcs.modifyFunc('ReloadTime', 0, t) end end})
gunMods:AddToggle({text = 'Infinite Ammo', callback = function(t) if t then funcs.modifyFunc('AmmoCost', 0, t) end end})
gunMods:AddToggle({text = 'No Spread', callback = function(t) if t then funcs.modifyFunc('Spread', 0, t) end end})
gunMods:AddToggle({text = 'High Fire Rate', callback = function(t) if t then funcs.modifyFunc('FireRate', 0.001, t) end end})
gunMods:AddToggle({text = 'No Camera Recoil', callback = function(t) if t then funcs.modifyFunc('CameraRecoilingEnabled', t, t) end end})
gunMods:AddToggle({text = 'No Gun Recoil', callback = function(t) if t then funcs.modifyFunc('Recoil', 0, t) end end})
gunMods:AddToggle({text = 'Shotgun Bullets', callback = function(t) if t then funcs.modifyFunc('ShotgunEnabled', t, t) end end})
gunMods:AddToggle({text = 'Explosive Bullets', callback = function(t) if t then funcs.modifyFunc('ExplosiveEnabled', t, t) end end})
gunMods:AddToggle({text = 'No Bullet Shells', callback = function(t) if t then funcs.modifyFunc('BulletShellEnabled', not t, t) end end})
gunMods:AddToggle({text = 'Always Automatic', callback = function(t) if t then funcs.modifyFunc('Auto', t, t) end end})
gunMods:AddToggle({text = 'Infinite Bullet Range', callback = function(t) if t then funcs.modifyFunc('Range', 9e9, t); funcs.modifyFunc('ZeroDamageDistance', 9e9, t); funcs.modifyFunc('FullDamageDistance', 9e9, t) end end})

rage:AddToggle({text = 'Auto Kill', tip = 'hold out a gun for this to work', callback = funcs.killAll})
rage:AddSlider({text = 'Snap Height', min = 0, max = 10, float = 0.1})
rage:AddSlider({text = 'Snap Space', min = -10, max = 10, float = 0.1})

--rage:AddDivider()
--rage:AddToggle({text = 'Auto Arrest', callback = funcs.autoArrest})
--rage:AddSlider({text = 'Snap Height', flag = 'ar height', min = 0, max = 10, float = 0.1})
--rage:AddSlider({text = 'Snap Space', flag = 'ar space', min = -10, max = 10, float = 0.1})
--rage:AddToggle({text = 'Auto Switch Team'})

library.OnLoad:Connect(function()
	for i, v in workspace:GetChildren() do
		if not v:IsA('BasePart') then continue end
		if v.Name ~= 'Particles' then continue end

		v:Destroy()
	end
end)
