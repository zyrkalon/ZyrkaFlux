

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "ZyrkaFlux V1.0",
    LoadingTitle = "ZyrkaFlux",
    LoadingSubtitle = "ZyrkaFlux V1.0",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "PlayerESPTool",
        FileName = "ESPConfig",
    },
})

local Tab = Window:CreateTab("ESP (Highlight)", 4483362458)
local AimTab = Window:CreateTab("Aim Assist", 4483362458)

local espEnabled = false
local showBoxes = true
local showNames = true
local showDistance = true
local showHealth = true
local showTracers = false
local showSkeleton = false
local teamCheck = false
local textSize = 14

local aimAssistOn = false
local aimStrength = 0.08
local aimFOV = 150
local aimBone = "Head"

local aimWallCheck = true
local showFOVCircle = true
local fovColor = Color3.fromRGB(255, 255, 255)


AimTab:CreateSection("Toggle")

AimTab:CreateToggle({
    Name = "Enable Aim Assist",
    CurrentValue = false,
    Flag = "AimOn",
    Callback = function(v)
        aimAssistOn = v
    end,
})

AimTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,
    Flag = "ShowFOV",
    Callback = function(v)
        showFOVCircle = v
    end,
})

AimTab:CreateSection("Strength")

AimTab:CreateSlider({
    Name = "Aim Strength",
    Range = {1, 30},
    Increment = 1,
    CurrentValue = 8,
    Flag = "AimStr",
    Callback = function(v)
        aimStrength = v / 100
    end,
})

AimTab:CreateSection("Field of View")

AimTab:CreateSlider({
    Name = "FOV Radius (pixels)",
    Range = {30, 400},
    Increment = 10,
    CurrentValue = 150,
    Flag = "AimFOV",
    Callback = function(v)
        aimFOV = v
    end,
})

AimTab:CreateSection("Target Bone")

AimTab:CreateDropdown({
    Name = "Aim At",
    Options = {"Head", "UpperTorso", "HumanoidRootPart"},
    CurrentOption = "Head",
    Flag = "AimBone",
    Callback = function(v)
        aimBone = v
    end,
})

AimTab:CreateSection("Safety")

AimTab:CreateToggle({
    Name = "Never Aim at Teammates",
    CurrentValue = false,
    Flag = "AimTeamChk",
    Callback = function(v)
        teamCheck = v
    end,
})

AimTab:CreateToggle({
    Name = "Wall Check (skip behind walls)",
    CurrentValue = true,
    Flag = "AimWallChk",
    Callback = function(v)
        aimWallCheck = v
    end,
})

AimTab:CreateSection("FOV Circle Color")

local fovColorMap = {
    White  = Color3.fromRGB(255, 255, 255),
    Red    = Color3.fromRGB(255, 60, 60),
    Green  = Color3.fromRGB(60, 255, 100),
    Blue   = Color3.fromRGB(60, 150, 255),
    Yellow = Color3.fromRGB(255, 220, 50),
}

AimTab:CreateDropdown({
    Name = "FOV Circle Color",
    Flag = "FOVCol",
    Options = {"White", "Red", "Green", "Blue", "Yellow"},
    CurrentOption = "White",
    Callback = function(v)
        fovColor = fovColorMap[v] or fovColor
    end,
})

local flyEnabled = false
local flySpeed = 10
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyConnection = nil
local UserInputService = game:GetService("UserInputService")

local fillColor = Color3.fromRGB(255, 0, 0)
local outlineColor = Color3.fromRGB(255, 255, 255)
local skeletonColor = Color3.fromRGB(255, 255, 0)

local activeHighlights = {}
local activeESP = {}
local activeTracers = {}
local activeSkeletons = {}

local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "ESPGui"
ESPGui.ResetOnSpawn = false
ESPGui.IgnoreGuiInset = true
ESPGui.DisplayOrder = 0
ESPGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local function isSameTeam(player)
    if not teamCheck then return false end
    if not LocalPlayer.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function clearHighlight(player)
    local h = activeHighlights[player]
    if h then
        h:Destroy()
        activeHighlights[player] = nil
    end
end

local function applyHighlight(player)
    if not player.Character then return end
    if isSameTeam(player) then return end
    clearHighlight(player)

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.FillColor = fillColor
    highlight.OutlineColor = outlineColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Adornee = player.Character
    highlight.Parent = player.Character

    activeHighlights[player] = highlight

    player.CharacterRemoving:Once(function()
        clearHighlight(player)
    end)
end

local function clearESP(player)
    local data = activeESP[player]
    if data then
        if data.frame then data.frame:Destroy() end
        activeESP[player] = nil
    end
end

local function createESP(player)
    if activeESP[player] then return end
    if isSameTeam(player) then return end
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local frame = Instance.new("Frame")
    frame.Name = "ESPBox"
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = 2
    frame.Parent = ESPGui

    local border = Instance.new("UIStroke")
    border.Name = "BoxBorder"
    border.Thickness = 2
    border.Color = outlineColor
    border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    border.Parent = frame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0, textSize + 4)
    nameLabel.Position = UDim2.new(0, 0, 0, -(textSize + 6))
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = textSize
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Text = player.Name
    nameLabel.ZIndex = 3
    nameLabel.Parent = frame

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Size = UDim2.new(1, 0, 0, textSize + 4)
    distanceLabel.Position = UDim2.new(0, 0, 1, 2)
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.TextSize = textSize
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distanceLabel.Text = "-- m"
    distanceLabel.ZIndex = 3
    distanceLabel.Parent = frame

    local barBG = Instance.new("Frame")
    barBG.Name = "HealthBarBG"
    barBG.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    barBG.BorderSizePixel = 0
    barBG.Size = UDim2.new(0, 4, 1, 0)
    barBG.Position = UDim2.new(0, -8, 0, 0)
    barBG.ZIndex = 3
    barBG.Parent = frame

    local barFill = Instance.new("Frame")
    barFill.Name = "HealthBarFill"
    barFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    barFill.BorderSizePixel = 0
    barFill.AnchorPoint = Vector2.new(0, 1)
    barFill.Position = UDim2.new(0, 0, 1, 0)
    barFill.Size = UDim2.new(1, 0, 1, 0)
    barFill.ZIndex = 4
    barFill.Parent = barBG

    activeESP[player] = {
        frame = frame,
        nameLabel = nameLabel,
        distanceLabel = distanceLabel,
        barBG = barBG,
        barFill = barFill,
        rootPart = rootPart,
        character = character,
    }

    player.CharacterRemoving:Once(function()
        clearESP(player)
    end)
end

local function clearTracer(player)
    local t = activeTracers[player]
    if t then
        t:Destroy()
        activeTracers[player] = nil
    end
end

local function createTracer(player)
    if activeTracers[player] then return end
    if isSameTeam(player) then return end

    local frame = Instance.new("Frame")
    frame.Name = "Tracer"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = outlineColor
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(0, 1, 0, 0)
    frame.ZIndex = 1
    frame.Visible = false
    frame.Parent = ESPGui

    activeTracers[player] = frame
end

local function updateTracer(player, feetPosition)
    local frame = activeTracers[player]
    if not frame then return end

    local viewportSize = Camera.ViewportSize
    local originPoint = Vector2.new(viewportSize.X / 2, viewportSize.Y)

    local screenPoint, onScreen = Camera:WorldToViewportPoint(feetPosition)
    if not onScreen or screenPoint.Z <= 0 then
        frame.Visible = false
        return
    end

    local targetPoint = Vector2.new(screenPoint.X, screenPoint.Y)
    local distance = (targetPoint - originPoint).Magnitude
    local midpoint = (originPoint + targetPoint) / 2
    local angle = math.atan2(targetPoint.Y - originPoint.Y, targetPoint.X - originPoint.X)

    frame.Visible = true
    frame.Size = UDim2.new(0, 1, 0, distance)
    frame.Position = UDim2.new(0, midpoint.X, 0, midpoint.Y)
    frame.Rotation = math.deg(angle) + 90
    frame.BackgroundColor3 = outlineColor
end

local SKELETON_BONES = {
    { "Head",               "UpperTorso"         },
    { "UpperTorso",         "LowerTorso"         },
    { "LowerTorso",         "HumanoidRootPart"   },
    { "UpperTorso",         "LeftUpperArm"       },
    { "LeftUpperArm",       "LeftLowerArm"       },
    { "LeftLowerArm",       "LeftHand"           },
    { "UpperTorso",         "RightUpperArm"      },
    { "RightUpperArm",      "RightLowerArm"      },
    { "RightLowerArm",      "RightHand"          },
    { "LowerTorso",         "LeftUpperLeg"       },
    { "LeftUpperLeg",       "LeftLowerLeg"       },
    { "LeftLowerLeg",       "LeftFoot"           },
    { "LowerTorso",         "RightUpperLeg"      },
    { "RightUpperLeg",      "RightLowerLeg"      },
    { "RightLowerLeg",      "RightFoot"          },
}

local function drawBoneLine(gui)
    local line = Instance.new("Frame")
    line.Name = "BoneLine"
    line.AnchorPoint = Vector2.new(0.5, 0)
    line.BackgroundColor3 = skeletonColor
    line.BorderSizePixel = 0
    line.ZIndex = 5
    line.Visible = false
    line.Parent = gui
    return line
end

local function updateBoneLine(line, p1, p2)
    if not line then return end
    local dx = p2.X - p1.X
    local dy = p2.Y - p1.Y
    local length = math.sqrt(dx * dx + dy * dy)
    local angle = math.deg(math.atan2(dy, dx))

    line.Position = UDim2.new(0, p1.X, 0, p1.Y)
    line.Size = UDim2.new(0, length, 0, 1)
    line.Rotation = angle
    line.BackgroundColor3 = skeletonColor
    line.Visible = true
end

local function clearSkeleton(player)
    local lines = activeSkeletons[player]
    if lines then
        for _, line in ipairs(lines) do
            line:Destroy()
        end
        activeSkeletons[player] = nil
    end
end

local function createSkeleton(player)
    if activeSkeletons[player] then return end
    if isSameTeam(player) then return end

    local lines = {}
    for _ = 1, #SKELETON_BONES do
        local line = drawBoneLine(ESPGui)
        table.insert(lines, line)
    end
    activeSkeletons[player] = lines

    player.CharacterRemoving:Once(function()
        clearSkeleton(player)
    end)
end

local function updateSkeleton(player)
    local lines = activeSkeletons[player]
    if not lines then return end
    local character = player.Character
    if not character then
        for _, l in ipairs(lines) do l.Visible = false end
        return
    end

    for i, bone in ipairs(SKELETON_BONES) do
        local line = lines[i]
        if not line then continue end

        local partA = character:FindFirstChild(bone[1])
        local partB = character:FindFirstChild(bone[2])

        if partA and partB then
            local screenA, onA = Camera:WorldToViewportPoint(partA.Position)
            local screenB, onB = Camera:WorldToViewportPoint(partB.Position)

            if onA and onB and screenA.Z > 0 and screenB.Z > 0 then
                updateBoneLine(
                    line,
                    Vector2.new(screenA.X, screenA.Y),
                    Vector2.new(screenB.X, screenB.Y)
                )
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
end

local CORNER_MULTIPLIERS = {
    Vector3.new(1, 1, 1), Vector3.new(1, 1, -1), Vector3.new(1, -1, 1), Vector3.new(1, -1, -1),
    Vector3.new(-1, 1, 1), Vector3.new(-1, 1, -1), Vector3.new(-1, -1, 1), Vector3.new(-1, -1, -1),
}

local function getScreenBox(character)
    local ok, cf, size = pcall(function()
        return character:GetBoundingBox()
    end)
    if not ok then return nil end

    local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local anyOnScreen = false

    for _, mult in ipairs(CORNER_MULTIPLIERS) do
        local worldPoint = cf:PointToWorldSpace(Vector3.new(hx * mult.X, hy * mult.Y, hz * mult.Z))
        local screenPoint, onScreen = Camera:WorldToViewportPoint(worldPoint)
        if screenPoint.Z > 0 then
            anyOnScreen = true
            minX = math.min(minX, screenPoint.X)
            maxX = math.max(maxX, screenPoint.X)
            minY = math.min(minY, screenPoint.Y)
            maxY = math.max(maxY, screenPoint.Y)
        end
    end

    if not anyOnScreen then return nil end
    return minX, minY, maxX, maxY
end

local FOV_SEGMENTS = 40

local function drawCircle(cx, cy, radius, color)
    for i = 0, FOV_SEGMENTS - 1 do
        local a1 = (i     / FOV_SEGMENTS) * math.pi * 2
        local a2 = ((i+1) / FOV_SEGMENTS) * math.pi * 2
        local p1 = Vector2.new(cx + math.cos(a1) * radius, cy + math.sin(a1) * radius)
        local p2 = Vector2.new(cx + math.cos(a2) * radius, cy + math.sin(a2) * radius)
        local d   = p2 - p1
        local len = d.Magnitude
        if len >= 1 then
            local mid = (p1 + p2) / 2
            local ln = Instance.new("Frame")
            ln.AnchorPoint      = Vector2.new(0.5, 0.5)
            ln.BackgroundColor3 = color
            ln.BorderSizePixel  = 0
            ln.Size     = UDim2.fromOffset(len, 1)
            ln.Position = UDim2.fromOffset(mid.X, mid.Y)
            ln.Rotation = math.deg(math.atan2(d.Y, d.X))
            ln.ZIndex = 6
            ln.Parent = ESPGui
            task.delay(0, function() ln:Destroy() end)
        end
    end
end

local function getAimTarget()
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local bestDist = aimFOV
    local bestTarget = nil

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if isSameTeam(p) then continue end

        local char = p.Character
        if not char then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local bone = char:FindFirstChild(aimBone) or char:FindFirstChild("HumanoidRootPart")
        if not bone then continue end

        if aimWallCheck then
            local origin = Camera.CFrame.Position
            local direction = bone.Position - origin
            local ignore = {char, LocalPlayer.Character}
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = ignore
            params.FilterType = Enum.RaycastFilterType.Blacklist
            local rayResult = Workspace:Raycast(origin, direction, params)
            if rayResult then continue end
        end

        local sp, onScreen = Camera:WorldToViewportPoint(bone.Position)
        if not onScreen or sp.Z <= 0 then continue end

        local screenPos = Vector2.new(sp.X, sp.Y)
        local dist2D    = (screenPos - center).Magnitude

        if dist2D < bestDist then
            bestDist = dist2D
            bestTarget = bone
        end
    end

    return bestTarget
end

local function updateESP()
    if aimAssistOn then
        local target = getAimTarget()
        if target then
            local targetCF = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, aimStrength)
        end
    end

    if showFOVCircle and aimAssistOn then
        local vp = Camera.ViewportSize
        drawCircle(vp.X / 2, vp.Y / 2, aimFOV, fovColor)
    end

    if not espEnabled then return end

    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for player, data in pairs(activeESP) do
        local character = data.character
        if character and character.Parent and data.rootPart and data.rootPart.Parent then
            local minX, minY, maxX, maxY = getScreenBox(character)

            if minX then
                data.frame.Visible = true
                data.frame.Position = UDim2.new(0, minX, 0, minY)
                data.frame.Size = UDim2.new(0, maxX - minX, 0, maxY - minY)

                local border = data.frame:FindFirstChild("BoxBorder")
                if border then
                    border.Enabled = showBoxes
                    border.Color = outlineColor
                end

                data.nameLabel.Visible = showNames
                data.nameLabel.TextSize = textSize
                data.nameLabel.Text = player.Name
                data.nameLabel.Size = UDim2.new(1, 0, 0, textSize + 4)
                data.nameLabel.Position = UDim2.new(0, 0, 0, -(textSize + 6))

                data.distanceLabel.Visible = showDistance
                data.distanceLabel.TextSize = textSize
                data.distanceLabel.Size = UDim2.new(1, 0, 0, textSize + 4)
                if localRoot then
                    local dist = (data.rootPart.Position - localRoot.Position).Magnitude
                    data.distanceLabel.Text = string.format("%.0f m", dist)
                else
                    data.distanceLabel.Text = "-- m"
                end

                data.barBG.Visible = showHealth
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local healthPct = 1
                if humanoid then
                    healthPct = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                end
                data.barFill.Size = UDim2.new(1, 0, healthPct, 0)
                if healthPct > 0.6 then
                    data.barFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
                elseif healthPct > 0.3 then
                    data.barFill.BackgroundColor3 = Color3.fromRGB(255, 255, 100)
                else
                    data.barFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                end
            else
                data.frame.Visible = false
            end

            if showTracers then
                if not activeTracers[player] then createTracer(player) end
                local feetPosition = data.rootPart.Position - Vector3.new(0, 3, 0)
                updateTracer(player, feetPosition)
            else
                clearTracer(player)
            end

            if showSkeleton then
                if not activeSkeletons[player] then createSkeleton(player) end
                updateSkeleton(player)
            else
                if activeSkeletons[player] then
                    for _, l in ipairs(activeSkeletons[player]) do l.Visible = false end
                end
            end
        else
            clearESP(player)
            clearTracer(player)
            clearSkeleton(player)
        end
    end
end

RunService.RenderStepped:Connect(updateESP)

local function enableAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            createESP(player)
            applyHighlight(player)
            if showSkeleton then createSkeleton(player) end
        end
    end
end

local function disableAll()
    for player, _ in pairs(activeESP) do clearESP(player) end
    for player, _ in pairs(activeHighlights) do clearHighlight(player) end
    for player, _ in pairs(activeTracers) do clearTracer(player) end
    for player, _ in pairs(activeSkeletons) do clearSkeleton(player) end
end

local function reapplyTeamFilter()
    if not espEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if isSameTeam(player) then
                clearESP(player)
                clearHighlight(player)
                clearTracer(player)
                clearSkeleton(player)
            else
                if player.Character then
                    createESP(player)
                    applyHighlight(player)
                    if showSkeleton then createSkeleton(player) end
                end
            end
        end
    end
end

local function stopFlying()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
    if flyBodyGyro then
        flyBodyGyro:Destroy()
        flyBodyGyro = nil
    end
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
end

local function startFlying()
    local character = LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end

    stopFlying()

    humanoid.PlatformStand = true

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.Parent = rootPart

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyGyro.P = 10000
    flyBodyGyro.CFrame = rootPart.CFrame
    flyBodyGyro.Parent = rootPart

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled then return end
        local char = LocalPlayer.Character
        if not char then stopFlying() return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root or not flyBodyVelocity then stopFlying() return end

        local camCFrame = Camera.CFrame
        local moveVector = Vector3.new(0, 0, 0)

        local forward = camCFrame.LookVector
        local right = camCFrame.RightVector
        local up = Vector3.new(0, 1, 0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVector = moveVector + forward
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVector = moveVector - forward
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVector = moveVector - right
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVector = moveVector + right
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVector = moveVector + up
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveVector = moveVector - up
        end

        if moveVector.Magnitude > 0 then
            moveVector = moveVector.Unit * flySpeed
        end

        flyBodyVelocity.Velocity = moveVector
        flyBodyGyro.CFrame = camCFrame
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    if flyEnabled then
        task.wait(1)
        startFlying()
    end
end)

Tab:CreateToggle({
    Name = "Toggle ESP",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(Value)
        espEnabled = Value
        if espEnabled then
            enableAll()
            Rayfield:Notify({ Title = "ESP Enabled", Content = "Highlighting all players.", Duration = 3 })
        else
            disableAll()
            Rayfield:Notify({ Title = "ESP Disabled", Content = "All highlights, boxes, and tracers removed.", Duration = 3 })
        end
    end,
})

Tab:CreateColorPicker({
    Name = "Fill Color",
    Color = fillColor,
    Flag = "FillColorPicker",
    Callback = function(Value)
        fillColor = Value
        for _, h in pairs(activeHighlights) do
            h.FillColor = fillColor
        end
    end,
})

Tab:CreateColorPicker({
    Name = "Outline / Box Color",
    Color = outlineColor,
    Flag = "OutlineColorPicker",
    Callback = function(Value)
        outlineColor = Value
        for _, h in pairs(activeHighlights) do
            h.OutlineColor = outlineColor
        end
        for _, data in pairs(activeESP) do
            local border = data.frame:FindFirstChild("BoxBorder")
            if border then border.Color = outlineColor end
        end
    end,
})

Tab:CreateColorPicker({
    Name = "Skeleton Color",
    Color = skeletonColor,
    Flag = "SkeletonColorPicker",
    Callback = function(Value)
        skeletonColor = Value
    end,
})

Tab:CreateToggle({
    Name = "Show Boxes",
    CurrentValue = true,
    Flag = "ShowBoxesToggle",
    Callback = function(Value)
        showBoxes = Value
    end,
})

Tab:CreateToggle({
    Name = "Show Names",
    CurrentValue = true,
    Flag = "ShowNamesToggle",
    Callback = function(Value)
        showNames = Value
    end,
})

Tab:CreateToggle({
    Name = "Show Distance",
    CurrentValue = true,
    Flag = "ShowDistanceToggle",
    Callback = function(Value)
        showDistance = Value
    end,
})

Tab:CreateToggle({
    Name = "Show Health",
    CurrentValue = true,
    Flag = "ShowHealthToggle",
    Callback = function(Value)
        showHealth = Value
    end,
})

Tab:CreateSlider({
    Name = "Text Size",
    Range = { 8, 28 },
    Increment = 1,
    CurrentValue = 14,
    Flag = "TextSizeSlider",
    Callback = function(Value)
        textSize = Value
    end,
})

Tab:CreateToggle({
    Name = "Show Tracers",
    CurrentValue = false,
    Flag = "ShowTracersToggle",
    Callback = function(Value)
        showTracers = Value
        if not showTracers then
            for player, _ in pairs(activeTracers) do
                clearTracer(player)
            end
        end
    end,
})

Tab:CreateToggle({
    Name = "Show Skeleton",
    CurrentValue = false,
    Flag = "ShowSkeletonToggle",
    Callback = function(Value)
        showSkeleton = Value
        if not showSkeleton then
            for _, lines in pairs(activeSkeletons) do
                for _, l in ipairs(lines) do l.Visible = false end
            end
        else
            if espEnabled then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and not isSameTeam(player) then
                        createSkeleton(player)
                    end
                end
            end
        end
    end,
})

Tab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "TeamCheckToggle",
    Callback = function(Value)
        teamCheck = Value
        reapplyTeamFilter()
    end,
})

Tab:CreateButton({
    Name = "Clear All Highlights",
    Callback = function()
        disableAll()
        espEnabled = false
        Rayfield:Notify({ Title = "Cleared", Content = "All highlights, boxes, tracers, and skeletons removed.", Duration = 3 })
    end,
})

local FlyTab = Window:CreateTab("Movement", 4483362458)

FlyTab:CreateToggle({
    Name = "Toggle Fly",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(Value)
        flyEnabled = Value
        if flyEnabled then
            startFlying()
            Rayfield:Notify({ Title = "Fly Enabled", Content = "Use WASD + Space/Ctrl to move.", Duration = 3 })
        else
            stopFlying()
            Rayfield:Notify({ Title = "Fly Disabled", Content = "Flight mode turned off.", Duration = 3 })
        end
    end,
})

FlyTab:CreateSlider({
    Name = "Fly Speed",
    Range = { 0, 100 },
    Increment = 1,
    CurrentValue = 10,
    Flag = "FlySpeedSlider",
    Callback = function(Value)
        flySpeed = Value
    end,
})



local function handleTeamChange(player)
    if not espEnabled or player == LocalPlayer then return end
    if isSameTeam(player) then
        clearESP(player)
        clearHighlight(player)
        clearTracer(player)
        clearSkeleton(player)
    elseif player.Character then
        createESP(player)
        applyHighlight(player)
        if showSkeleton then createSkeleton(player) end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if espEnabled and player ~= LocalPlayer and not isSameTeam(player) then
            task.wait(0.5)
            createESP(player)
            applyHighlight(player)
            if showSkeleton then createSkeleton(player) end
        end
    end)
    player:GetPropertyChangedSignal("Team"):Connect(function()
        handleTeamChange(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    clearHighlight(player)
    clearESP(player)
    clearTracer(player)
    clearSkeleton(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            if espEnabled and not isSameTeam(player) then
                task.wait(0.5)
                createESP(player)
                applyHighlight(player)
                if showSkeleton then createSkeleton(player) end
            end
        end)
        player:GetPropertyChangedSignal("Team"):Connect(function()
            handleTeamChange(player)
        end)
    end
end
