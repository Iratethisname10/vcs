local floor = math.floor
local arcTangent = math.atan
local squareRoot = math.sqrt

local vector3New = Vector3.new
local vector3Zero = Vector3.zero

local fromAxisAngle = CFrame.fromAxisAngle

local predictionUtils = {}

local gravityCast = RaycastParams.new()
gravityCast.RespectCanCollide = true

function predictionUtils:accountGravity(origin: Vector3, velocity: Vector3, magnitude: number, targetCharacter: Instance, worldGravity: number)
	gravityCast.FilterDescendantsInstances = {targetCharacter}

	local newVelocity = velocity.Y
	local rootSize = targetCharacter.Humanoid.HipHeight + (targetCharacter.RootPart.Size.Y / 2)

	for i = 1, floor(magnitude / 0.016) do
		newVelocity -= worldGravity * 0.016
		local floor = workspace:Raycast(origin, vector3New(0, (newVelocity * 0.016) - rootSize, 0), gravityCast)
		if floor then
			origin = vector3New(origin.X, floor.Position.Y + rootSize, origin.Z)
			break
		end
		origin += vector3New(0, newVelocity * 0.016, 0)
	end

	return origin, vector3New(velocity.X, 0, velocity.Z)
end

function predictionUtils:findLaunchAngle(speed: number, gravity: number, mag: number, hei: number, higherArc: boolean)
	local speedSquared = speed * speed
	local speedZenzizenzic = speedSquared * speedSquared
	local root = squareRoot(speedZenzizenzic - gravity * (gravity * mag * mag + 2 * hei * speedSquared))
	if not higherArc then root = -root end

	return arcTangent((speedSquared + root) / (gravity * mag))
end

function predictionUtils:findLaunchDirection(origin: Vector3, target: Vector3, speed: number, gravity: number, higherArc: boolean)
	local hor = vector3New(target.X - origin.X, 0, origin.Z - origin.Z)
	local hei = target.Y - origin.Y
	local mag = horizontal.Magnitude

	local arc = self:findLaunchAngle(speed, gravity, mag, hei, higherArc)
	if arc ~= arc then return nil end

	local vec = hor.Unit * speed
	local rotationAxis = vector3New(-hor.Z, 0, hor.X)

	return fromAxisAngle(rotationAxis, arc) * vec
end

function predictionUtils:findLeadShot(target: Vector3, targetVelocity: Vector3, speed: number, origin: Vector3, originVelocity: Vector3)
	local distance = (target - origin).Magnitude
	local p = target - origin
	local v = targetVelocity - originVelocity
	local a = Vector3.zero
	local timeTaken = distance / speed
	local goalX = target.X + v.X * timeTaken + 0.5 * a.X * timeTaken ^ 2
	local goalY = target.Y + v.Y * timeTaken + 0.5 * a.Y * timeTaken ^ 2
	local goalZ = target.Z + v.Z * timeTaken + 0.5 * a.Z * timeTaken ^ 2

	return vector3New(goalX, goalY, goalZ)
end

return predictionUtils