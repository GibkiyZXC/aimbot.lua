local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Clear old Rayfield
if Rayfield then
    pcall(function() Rayfield:Destroy() end)
end

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Window
local Window = Rayfield:CreateWindow({
    Name = "SWILL Auto Trigger",
    LoadingTitle = "Full Features + FOV Fixed",
    LoadingSubtitle = "by Swill Way | 26.09.2025",
    ConfigurationSaving = {Enabled = true, FolderName = "SWILL_AutoTrigger", FileName = "Config"}
})

-- Tabs
local MainTab = Window:CreateTab("Aimbot", 4483362458)
local VHTab = Window:CreateTab("Wallhack", 4483362458)
local TriggerTab = Window:CreateTab("Auto Trigger", 4483362458)
local VisualTab = Window:CreateTab("Visuals", 4483362458)
local HitboxTab = Window:CreateTab("Hitbox", 4483362458)
local SpeedTab = Window:CreateTab("Speed", 4483362458)
local ExtraTab = Window:CreateTab("Extra", 4483362458)

-- Settings
local Settings = {
    Aimbot = {
        Enabled = true,
        TeamCheck = true,
        TeamCheckMode = "TeamColor",
        VisibleCheck = true,
        AimPart = "Head",
        AimSpeed = 10,
        UseCamera = false
    },
    ESP = {
        Enabled = true,
        Box = true,
        Tracer = true,
        Skeleton = true,
        FootTracer = true,
        HealthBar = true,
        Distance = true,
        EnemyColor = Color3.fromRGB(255,0,0),
        TeamColor = Color3.fromRGB(0,255,0),
        SkeletonColor = Color3.fromRGB(255,165,0),
        BoxColorEnemy = Color3.fromRGB(255,0,0),
        BoxColorTeam = Color3.fromRGB(0,255,0),
        DistanceColor = Color3.fromRGB(255,255,255)
    },
    Trigger = {Enabled = true, Delay = 0.05},
    FOV = {Radius = 200, Show = true, Color = Color3.fromRGB(255,0,0)},
    Hitbox = {Enabled = false, Size = 5, Transparency = 0.7, Part = "Head"},
    Stretch = {Enabled = false, Intensity = 150},
    Speed = {Enabled = false, Value = 100}
}

-- Speed Hack
local OriginalWalkSpeed = 16

local function ApplySpeed()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("Humanoid") then return end
    local Humanoid = character.Humanoid
    if Settings.Speed.Enabled then
        Humanoid.WalkSpeed = Settings.Speed.Value
    else
        Humanoid.WalkSpeed = OriginalWalkSpeed
    end
end

if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
    OriginalWalkSpeed = LocalPlayer.Character.Humanoid.WalkSpeed
end

LocalPlayer.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid")
    OriginalWalkSpeed = humanoid.WalkSpeed
    ApplySpeed()
end)

-- FOV Stretch
local function ForceApplyStretch()
    if not Camera then return end
    if Settings.Stretch.Enabled then
        Camera.FieldOfView = Settings.Stretch.Intensity
    else
        Camera.FieldOfView = 70
    end
end

RunService.Stepped:Connect(ForceApplyStretch)
RunService.Heartbeat:Connect(ForceApplyStretch)
RunService.RenderStepped:Connect(ForceApplyStretch)

spawn(function()
    while true do
        ForceApplyStretch()
        task.wait(0.01)
    end
end)

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Transparency = 1

-- ESP storage
local ESPObjects = {}
local OriginalHitboxSizes = {}

-- Team check
local function IsTeammate(Player)
    if not Settings.Aimbot.TeamCheck then return false end
    if Player == LocalPlayer then return true end
    if Settings.Aimbot.TeamCheckMode == "TeamColor" then
        return Player.TeamColor == LocalPlayer.TeamColor
    else
        return Player.Team == LocalPlayer.Team
    end
end

-- Line of sight
local function hasLineOfSight(origin, targetPart)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character or workspace}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local direction = (targetPart.Position - origin)
    local result = workspace:Raycast(origin, direction, rayParams)
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

-- Get closest enemy
local function GetClosestEnemy()
    local center = Camera.ViewportSize / 2
    local Closest = nil
    local ClosestDist = Settings.FOV.Radius
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health > 0 then
            if IsTeammate(Player) then continue end
            local Part = Player.Character:FindFirstChild(Settings.Aimbot.AimPart)
            if Part then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Part.Position)
                if OnScreen then
                    local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - center).Magnitude
                    if Dist < ClosestDist then
                        local Visible = true
                        if Settings.Aimbot.VisibleCheck then
                            Visible = hasLineOfSight(Camera.CFrame.Position, Part)
                        end
                        if Visible then
                            ClosestDist = Dist
                            Closest = {Part = Part, Player = Player, ScreenPos = Vector2.new(ScreenPos.X, ScreenPos.Y)}
                        end
                    end
                end
            end
        end
    end
    return Closest
end

-- Aim function
local function AimAt(targetScreenPos)
    local center = Camera.ViewportSize / 2
    local delta = targetScreenPos - center
    if Settings.Aimbot.UseCamera then
        local targetPart = GetClosestEnemy().Part
        local AimCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
        local smoothness = Settings.Aimbot.AimSpeed / 10
        if smoothness >= 1 then
            Camera.CFrame = AimCFrame
        else
            Camera.CFrame = Camera.CFrame:Lerp(AimCFrame, smoothness)
        end
    else
        local speedFactor = 11 - Settings.Aimbot.AimSpeed
        local moveX = delta.X / speedFactor
        local moveY = delta.Y / speedFactor
        if Settings.Aimbot.AimSpeed >= 10 then
            mousemoverel(delta.X, delta.Y)
        else
            pcall(function() mousemoverel(moveX, moveY) end)
        end
    end
end

-- Create ESP
local function CreateESP(Player)
    if ESPObjects[Player] then return end
    local objs = {
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Skeleton = {},
        FootTracer = Drawing.new("Line"),
        HB_BG = Drawing.new("Square"),
        HB_FG = Drawing.new("Square"),
        DistanceText = Drawing.new("Text")
    }
    for i = 1, 6 do objs.Skeleton[i] = Drawing.new("Line") objs.Skeleton[i].Thickness = 2 end
    objs.Box.Thickness = 2 objs.Box.Filled = false
    objs.Tracer.Thickness = 2
    objs.FootTracer.Thickness = 2
    objs.DistanceText.Size = 16 objs.DistanceText.Outline = true objs.DistanceText.Center = true
    ESPObjects[Player] = objs
end

-- Update ESP
local function UpdateESP()
    if not Settings.ESP.Enabled then
        for _, objs in pairs(ESPObjects) do
            objs.Box.Visible = false
            objs.Tracer.Visible = false
            for _, line in pairs(objs.Skeleton) do line.Visible = false end
            objs.FootTracer.Visible = false
            objs.HB_BG.Visible = false
            objs.HB_FG.Visible = false
            objs.DistanceText.Visible = false
        end
        return
    end

    for Player, objs in pairs(ESPObjects) do
        local Char = Player.Character
        if not Char or not Char:FindFirstChild("Head") or not Char:FindFirstChild("HumanoidRootPart") or not Char:FindFirstChild("Humanoid") or Char.Humanoid.Health <= 0 then
            objs.Box.Visible = false objs.Tracer.Visible = false
            for _, line in pairs(objs.Skeleton) do line.Visible = false end
            objs.FootTracer.Visible = false objs.HB_BG.Visible = false objs.HB_FG.Visible = false objs.DistanceText.Visible = false
            continue
        end

        local Head = Char.Head
        local Root = Char.HumanoidRootPart
        local Humanoid = Char.Humanoid
        local HeadPos = Camera:WorldToViewportPoint(Head.Position)
        local NeckPos = Camera:WorldToViewportPoint(Root.Position + Vector3.new(0, 1.5, 0))
        local PelvisPos = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 2, 0))
        local LeftArm = Char:FindFirstChild("Left Arm") or Char:FindFirstChild("LeftUpperArm")
        local RightArm = Char:FindFirstChild("Right Arm") or Char:FindFirstChild("RightUpperArm")
        local LeftLeg = Char:FindFirstChild("Left Leg") or Char:FindFirstChild("LeftUpperLeg")
        local RightLeg = Char:FindFirstChild("Right Leg") or Char:FindFirstChild("RightUpperLeg")
        local LeftArmPos = LeftArm and Camera:WorldToViewportPoint(LeftArm.Position) or NeckPos
        local RightArmPos = RightArm and Camera:WorldToViewportPoint(RightArm.Position) or NeckPos
        local LeftLegPos = LeftLeg and Camera:WorldToViewportPoint(LeftLeg.Position) or PelvisPos
        local RightLegPos = RightLeg and Camera:WorldToViewportPoint(RightLeg.Position) or PelvisPos
        local TopPos = Camera:WorldToViewportPoint(Root.Position + Vector3.new(0, 3, 0))
        local BottomPos = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 4, 0))

        if HeadPos.Z > 0 then
            local Height = math.abs(TopPos.Y - BottomPos.Y)
            local Width = Height / 2
            local Distance = math.floor((Camera.CFrame.Position - Root.Position).Magnitude)

            local IsTeam = IsTeammate(Player)
            local BoxColor = IsTeam and Settings.ESP.BoxColorTeam or Settings.ESP.BoxColorEnemy
            local TracerColor = IsTeam and Settings.ESP.TeamColor or Settings.ESP.EnemyColor
            local FootTracerColor = TracerColor
            local DistanceColor = Settings.ESP.DistanceColor

            if Settings.ESP.Box then
                objs.Box.Size = Vector2.new(Width, Height)
                objs.Box.Position = Vector2.new(TopPos.X - Width/2, TopPos.Y)
                objs.Box.Color = BoxColor
                objs.Box.Visible = true
            end
            if Settings.ESP.Tracer then
                objs.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                objs.Tracer.To = Vector2.new(TopPos.X, TopPos.Y + Height)
                objs.Tracer.Color = TracerColor
                objs.Tracer.Visible = true
            end
            if Settings.ESP.Skeleton then
                local lines = {
                    {HeadPos, NeckPos}, {NeckPos, PelvisPos},
                    {NeckPos, LeftArmPos}, {NeckPos, RightArmPos},
                    {PelvisPos, LeftLegPos}, {PelvisPos, RightLegPos}
                }
                for i, line in ipairs(lines) do
                    objs.Skeleton[i].From = Vector2.new(line[1].X, line[1].Y)
                    objs.Skeleton[i].To = Vector2.new(line[2].X, line[2].Y)
                    objs.Skeleton[i].Color = Settings.ESP.SkeletonColor
                    objs.Skeleton[i].Visible = true
                end
            end
            if Settings.ESP.FootTracer then
                objs.FootTracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                objs.FootTracer.To = Vector2.new(BottomPos.X, BottomPos.Y)
                objs.FootTracer.Color = FootTracerColor
                objs.FootTracer.Visible = true
            end
            if Settings.ESP.HealthBar then
                local Health = Humanoid.Health / Humanoid.MaxHealth
                objs.HB_BG.Size = Vector2.new(4, Height)
                objs.HB_BG.Position = Vector2.new(TopPos.X - Width/2 - 7, TopPos.Y)
                objs.HB_BG.Color = Color3.new(0,0,0)
                objs.HB_BG.Transparency = 0.5
                objs.HB_BG.Visible = true
                objs.HB_FG.Size = Vector2.new(4, Height * Health)
                objs.HB_FG.Position = Vector2.new(TopPos.X - Width/2 - 7, TopPos.Y + Height * (1 - Health))
                objs.HB_FG.Color = Color3.fromRGB(0,255,0):Lerp(Color3.fromRGB(255,0,0), 1 - Health)
                objs.HB_FG.Visible = true
            end
            if Settings.ESP.Distance then
                objs.DistanceText.Text = Distance .. " studs"
                objs.DistanceText.Position = Vector2.new(TopPos.X, TopPos.Y - 20)
                objs.DistanceText.Color = DistanceColor
                objs.DistanceText.Visible = true
            end
        else
            objs.Box.Visible = false objs.Tracer.Visible = false
            for _, line in pairs(objs.Skeleton) do line.Visible = false end
            objs.FootTracer.Visible = false objs.HB_BG.Visible = false objs.HB_FG.Visible = false objs.DistanceText.Visible = false
        end
    end
end

-- Update Hitboxes
local function UpdateHitboxes()
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild(Settings.Hitbox.Part) then
            local Part = Player.Character[Settings.Hitbox.Part]
            if Settings.Hitbox.Enabled then
                if not OriginalHitboxSizes[Player] then OriginalHitboxSizes[Player] = Part.Size end
                Part.Size = Vector3.new(Settings.Hitbox.Size, Settings.Hitbox.Size, Settings.Hitbox.Size)
                Part.Transparency = Settings.Hitbox.Transparency
                Part.CanCollide = false
                Part.Material = Enum.Material.ForceField
            else
                if OriginalHitboxSizes[Player] then
                    Part.Size = OriginalHitboxSizes[Player]
                    Part.Transparency = 0
                    Part.CanCollide = true
                    Part.Material = Enum.Material.Plastic
                end
            end
        end
    end
end

-- Init ESP
for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= LocalPlayer then
        CreateESP(Player)
        Player.CharacterAdded:Connect(function()
            CreateESP(Player)
            UpdateHitboxes()
        end)
    end
end

Players.PlayerAdded:Connect(function(Player)
    if Player ~= LocalPlayer then
        Player.CharacterAdded:Connect(function()
            CreateESP(Player)
            UpdateHitboxes()
        end)
    end
end)

-- Main loop
local LastTarget = nil
RunService.RenderStepped:Connect(function()
    local center = Camera.ViewportSize / 2
    FOVCircle.Visible = Settings.FOV.Show
    FOVCircle.Position = center
    FOVCircle.Radius = Settings.FOV.Radius
    FOVCircle.Color = Settings.FOV.Color

    local Target = GetClosestEnemy()
    if Settings.Aimbot.Enabled and Target then
        AimAt(Target.ScreenPos)
    end

    UpdateESP()
    UpdateHitboxes()
    ApplySpeed()

    if Settings.Trigger.Enabled and Target then
        if Target ~= LastTarget then
            mouse1press()
            task.wait(Settings.Trigger.Delay)
            mouse1release()
            LastTarget = Target
        end
    else
        LastTarget = nil
    end
end)

-- Menu

-- Aimbot Tab
MainTab:CreateToggle({Name = "Aimbot Enabled", CurrentValue = true, Callback = function(v) Settings.Aimbot.Enabled = v end})
MainTab:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) Settings.Aimbot.TeamCheck = v end})
MainTab:CreateDropdown({Name = "Team Check Mode", Options = {"TeamColor", "Team"}, CurrentOption = "TeamColor", Callback = function(o) Settings.Aimbot.TeamCheckMode = o end})
MainTab:CreateToggle({Name = "Visible Check", CurrentValue = true, Callback = function(v) Settings.Aimbot.VisibleCheck = v end})
MainTab:CreateDropdown({Name = "Aim Part", Options = {"Head", "HumanoidRootPart"}, CurrentOption = "Head", Callback = function(o) Settings.Aimbot.AimPart = o end})
MainTab:CreateSlider({Name = "Aim Speed (1=smooth, 10=instant)", Range = {1, 10}, Increment = 1, CurrentValue = 10, Callback = function(v) Settings.Aimbot.AimSpeed = v end})
MainTab:CreateToggle({Name = "Use Camera Aimbot", CurrentValue = false, Callback = function(v) Settings.Aimbot.UseCamera = v end})

-- Trigger Tab
TriggerTab:CreateToggle({Name = "Auto Trigger Enabled", CurrentValue = true, Callback = function(v) Settings.Trigger.Enabled = v end})
TriggerTab:CreateSlider({Name = "Shoot Delay", Range = {0.01, 0.3}, Increment = 0.01, Suffix = "s", CurrentValue = 0.05, Callback = function(v) Settings.Trigger.Delay = v end})

-- Wallhack Tab
VHTab:CreateToggle({Name = "ESP Enabled", CurrentValue = true, Callback = function(v) Settings.ESP.Enabled = v end})
VHTab:CreateToggle({Name = "Boxes", CurrentValue = true, Callback = function(v) Settings.ESP.Box = v end})
VHTab:CreateToggle({Name = "Tracers", CurrentValue = true, Callback = function(v) Settings.ESP.Tracer = v end})
VHTab:CreateToggle({Name = "Skeleton", CurrentValue = true, Callback = function(v) Settings.ESP.Skeleton = v end})
VHTab:CreateToggle({Name = "Foot Tracers", CurrentValue = true, Callback = function(v) Settings.ESP.FootTracer = v end})
VHTab:CreateToggle({Name = "Health Bar", CurrentValue = true, Callback = function(v) Settings.ESP.HealthBar = v end})
VHTab:CreateToggle({Name = "Distance", CurrentValue = true, Callback = function(v) Settings.ESP.Distance = v end})
VHTab:CreateColorPicker({Name = "Enemy Color", Color = Color3.fromRGB(255,0,0), Callback = function(v) Settings.ESP.EnemyColor = v end})
VHTab:CreateColorPicker({Name = "Team Color", Color = Color3.fromRGB(0,255,0), Callback = function(v) Settings.ESP.TeamColor = v end})
VHTab:CreateColorPicker({Name = "Box Enemy Color", Color = Color3.fromRGB(255,0,0), Callback = function(v) Settings.ESP.BoxColorEnemy = v end})
VHTab:CreateColorPicker({Name = "Box Team Color", Color = Color3.fromRGB(0,255,0), Callback = function(v) Settings.ESP.BoxColorTeam = v end})
VHTab:CreateColorPicker({Name = "Skeleton Color", Color = Color3.fromRGB(255,165,0), Callback = function(v) Settings.ESP.SkeletonColor = v end})
VHTab:CreateColorPicker({Name = "Distance Text Color", Color = Color3.fromRGB(255,255,255), Callback = function(v) Settings.ESP.DistanceColor = v end})

-- Visuals Tab
VisualTab:CreateToggle({Name = "Show FOV", CurrentValue = true, Callback = function(v) Settings.FOV.Show = v end})
VisualTab:CreateSlider({Name = "FOV Radius", Range = {50, 500}, Increment = 10, CurrentValue = 200, Callback = function(v) Settings.FOV.Radius = v end})
VisualTab:CreateColorPicker({Name = "FOV Color", Color = Color3.fromRGB(255,0,0), Callback = function(v) Settings.FOV.Color = v end})

-- Hitbox Tab
HitboxTab:CreateToggle({Name = "Hitbox Enabled", CurrentValue = false, Callback = function(v) Settings.Hitbox.Enabled = v end})
HitboxTab:CreateSlider({Name = "Hitbox Size", Range = {2, 15}, Increment = 0.5, CurrentValue = 5, Callback = function(v) Settings.Hitbox.Size = v end})
HitboxTab:CreateSlider({Name = "Hitbox Transparency", Range = {0, 1}, Increment = 0.1, CurrentValue = 0.7, Callback = function(v) Settings.Hitbox.Transparency = v end})
HitboxTab:CreateDropdown({Name = "Hitbox Part", Options = {"Head", "HumanoidRootPart"}, CurrentOption = "Head", Callback = function(o) Settings.Hitbox.Part = o end})

-- Speed Tab
SpeedTab:CreateToggle({Name = "Speed Hack Enabled", CurrentValue = false, Callback = function(v) Settings.Speed.Enabled = v ApplySpeed() end})
SpeedTab:CreateSlider({Name = "Walk Speed", Range = {16, 300}, Increment = 5, Suffix = " studs/s", CurrentValue = 100, Callback = function(v) Settings.Speed.Value = v if Settings.Speed.Enabled then ApplySpeed() end end})

-- Extra Tab
ExtraTab:CreateToggle({Name = "Stretch Screen", CurrentValue = false, Callback = function(v) Settings.Stretch.Enabled = v ForceApplyStretch() end})
ExtraTab:CreateSlider({Name = "Stretch Intensity (FOV)", Range = {70, 170}, Increment = 5, CurrentValue = 150, Callback = function(v) Settings.Stretch.Intensity = v if Settings.Stretch.Enabled then ForceApplyStretch() end end})

Rayfield:Notify({Title = "SWILL Loaded", Content = "All functions restored. FOV Stretch fully operational.", Duration = 15})
print("SWILL Auto Trigger - FULL VERSION loaded successfully")
