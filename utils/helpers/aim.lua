local cloneref = cloneref or function(instance) return instance end

local playersService = cloneref(game:GetService('Players'))
local userInputService = cloneref(game:GetService('UserInputService'))

if not playersService.LocalPlayer then playersService:GetPropertyChangedSignal('LocalPlayer'):Wait() end
local lplr = playersService.LocalPlayer

local gameCam = workspace.CurrentCamera
library.unloadMaid:GiveTask(workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
	gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
end))

local vector2New = Vector2.new

local aimUtils = {}

function aimUtils:getClosestToMouse(distance, options)
	options = options or {}
	
	local maxHealth = options.maxHealth or 100
	local data = {}

	if options.stickyAim and isLocked then return end

	for _, player in playersService:GetPlayers() do
		if player == lplr then continue end
		if not player.Character then continue end
		if not player.Character:FindFirstChild('Humanoid') then continue end
		if not player.Character:FindFirstChild(options.aimPart) then continue end

		if options.wallCheck and #gameCam:GetPartsObscuringTarget({player.Character[options.aimPart].CFrame.Position}, player.Character:GetDescendants()) > 0 then continue end
		if options.teamCheck and player.TeamColor == lplr.TeamColor then continue end
		if options.sheildCheck and player.Character:FindFirstChild('ForceField') then continue end
		if options.aliveCheck and player.Character.Humanoid.Health <= 0 then continue end

		if player.Character.Humanoid.Health > maxHealth then continue end
		
		local vector, inViewport = gameCam:WorldToViewportPoint(player.Character[options.aimPart].CFrame.Position)
		local magnitude = (userInputService:GetMouseLocation() - vector2New(vector.X, vector.Y)).Magnitude

		if magnitude <= distance and inViewport then
			distance = magnitude
			data = {player = player, character = player.Character}
		end
	end

	return data
end

function aimUtils:getClosestToCharacter(distance, options)
	options = options or {}

	local maxHealth = options.maxHealth or 100
	local data = {}

	for _, player in playersService:GetPlayers() do
		if player == lplr then continue end
		if not player.Character then continue end
		if not player.Character:FindFirstChild('Humanoid') then continue end
		if not player.Character:FindFirstChild(options.aimPart) then continue end

		if options.wallCheck and #gameCam:GetPartsObscuringTarget({player.Character[options.aimPart].CFrame.Position}, player.Character:GetDescendants()) > 0 then continue end
		if options.teamCheck and player.TeamColor == lplr.TeamColor then continue end
		if options.sheildCheck and player.Character:FindFirstChild('ForceField') then continue end
		if options.aliveCheck and player.Character.Humanoid.Health <= 0 then continue end

		if player.Character.Humanoid.Health > maxHealth then continue end

		local magnitude = (lplr.Character.HumanoidRootPart.CFrame.Position - player.Character.HumanoidRootPart.CFrame.Position).Magnitude

		if magnitude <= distance then
			distance = magnitude
			data = {player = player, character = player.Character}
		end
	end

	return data
end

return aimUtils
