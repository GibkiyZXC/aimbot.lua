local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Clear old Rayfield
if Rayfield then
    pcall(function() Rayfield:Destroy() end)
end

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Window
local Window = Rayfield:CreateWindow({
    Name = "SWILL Auto Trigger",
    LoadingTitle = "Camera Aimbot + Boxes + Perfect Skeleton",
    LoadingSubtitle = "by Swill Way | Updated 02.01.2026",
    ConfigurationSaving = {Enabled = true, FolderName = "SWILL_AutoTrigger", FileName = "Config"}
})

-- Tabs
local MainTab = Window:CreateTab("Aimbot", 4483362458)
local TriggerTab = Window:CreateTab("Auto Trigger", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)
local VisualTab = Window:CreateTab("Visuals", 4483362458)
local SpeedTab = Window:CreateTab("Speed", 4483362458)
local ExtraTab = Window:CreateTab("Extra", 4483362458)

-- Settings
local Settings = {
    Aimbot = {Enabled = true, TeamCheck = true, TeamCheckMode = "TeamColor", VisibleCheck = true, AimPart = "Head", AimSpeed = 8},
    ESP = {Enabled = true, Box = true, Tracer = true, Skeleton = true, FootTracer = true, HealthBar = true, Distance = true,
           EnemyColor = Color3.fromRGB(255,0,0), TeamColor = Color3.fromRGB(0,255,0),
           BoxColorEnemy = Color3.fromRGB(255,0,0), BoxColorTeam = Color3.fromRGB(0,255,0),
           SkeletonColor = Color3.fromRGB(255,165,0), DistanceColor = Color3.fromRGB(255,255,255)},
    Trigger = {Enabled = true, Delay = 0.05},
    FOV = {Radius = 200, Show = true, Color = Color3.fromRGB(255,0,0)},
    Stretch = {Enabled = false, Intensity = 150},
    Speed = {Enabled = false, Value = 100}
}

-- Speed Hack
local OriginalWalkSpeed = 16
local function ApplySpeed()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("Humanoid") then return end
    local Humanoid = character.Humanoid
    Humanoid.WalkSpeed = Settings.Speed.Enabled and Settings.Speed.Value or OriginalWalkSpeed
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
    Camera.FieldOfView = Settings.Stretch.Enabled and Settings.Stretch.Intensity or 70
end

RunService.Stepped:Connect(ForceApplyStretch)
RunService.Heartbeat:Connect(ForceApplyStretch)
RunService.RenderStepped:Connect(ForceApplyStretch)

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Transparency = 1

-- ESP storage
local ESPObjects = {}

-- ИСПРАВЛЕННЫЙ TEAM CHECK
local function IsTeammate(Player)
    if not Settings.Aimbot.TeamCheck then return false end
    if Player == LocalPlayer then return true end
    
    if Settings.Aimbot.TeamCheckMode == "TeamColor" then
        return Player.TeamColor == LocalPlayer.TeamColor
    else
        if Player.Team and LocalPlayer.Team then
            return Player.Team == LocalPlayer.Team
        else
            return Player.TeamColor == LocalPlayer.TeamColor
        end
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

-- Camera Aimbot
local function AimAt(targetPart)
    local AimCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
    local smoothness = Settings.Aimbot.AimSpeed / 10
    Camera.CFrame = Camera.CFrame:Lerp(AimCFrame, smoothness)
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
    objs.Box.Thickness = 2
    objs.Box.Filled = false
    for i = 1, 14 do
        objs.Skeleton[i] = Drawing.new("Line")
        objs.Skeleton[i].Thickness = 2
    end
    objs.Tracer.Thickness = 2
    objs.FootTracer.Thickness = 2
    objs.DistanceText.Size = 16
    objs.DistanceText.Outline = true
    objs.DistanceText.Center = true
    ESPObjects[Player] = objs
end

-- Update ESP (полный код без изменений)
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
            objs.Box.Visible = false
            objs.Tracer.Visible = false
            for _, line in pairs(objs.Skeleton) do line.Visible = false end
            objs.FootTracer.Visible = false
            objs.HB_BG.Visible = false
            objs.HB_FG.Visible = false
            objs.DistanceText.Visible = false
            continue
        end

        local Head = Char.Head
        local Root = Char.HumanoidRootPart
        local Humanoid = Char.Humanoid
        local TopPos = Camera:WorldToViewportPoint(Root.Position + Vector3.new(0, 3, 0))
        local BottomPos = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 4, 0))
        local HeadPosScreen = Camera:WorldToViewportPoint(Head.Position)
        if HeadPosScreen.Z <= 0 then
            objs.Box.Visible = false objs.Tracer.Visible = false
            for _, line in pairs(objs.Skeleton) do line.Visible = false end
            objs.FootTracer.Visible = false objs.HB_BG.Visible = false objs.HB_FG.Visible = false
            objs.DistanceText.Visible = false
            continue
        end

        local Height = math.abs(TopPos.Y - BottomPos.Y)
        local Width = Height / 2
        local Distance = math.floor((Camera.CFrame.Position - Root.Position).Magnitude)
        local IsTeam = IsTeammate(Player)
        local BoxColor = IsTeam and Settings.ESP.BoxColorTeam or Settings.ESP.BoxColorEnemy
        local TracerColor = IsTeam and Settings.ESP.TeamColor or Settings.ESP.EnemyColor

        if Settings.ESP.Box then
            objs.Box.Size = Vector2.new(Width, Height)
            objs.Box.Position = Vector2.new(TopPos.X - Width/2, TopPos.Y)
            objs.Box.Color = BoxColor
            objs.Box.Visible = true
        else
            objs.Box.Visible = false
        end

        if Settings.ESP.Tracer then
            objs.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            objs.Tracer.To = Vector2.new(TopPos.X, TopPos.Y + Height)
            objs.Tracer.Color = TracerColor
            objs.Tracer.Visible = true
        else
            objs.Tracer.Visible = false
        end

        if Settings.ESP.FootTracer then
            objs.FootTracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            objs.FootTracer.To = Vector2.new(BottomPos.X, BottomPos.Y)
            objs.FootTracer.Color = TracerColor
            objs.FootTracer.Visible = true
        else
            objs.FootTracer.Visible = false
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
        else
            objs.HB_BG.Visible = false objs.HB_FG.Visible = false
        end

        if Settings.ESP.Distance then
            objs.DistanceText.Text = Distance .. " studs"
            objs.DistanceText.Position = Vector2.new(TopPos.X, TopPos.Y - 20)
            objs.DistanceText.Color = Settings.ESP.DistanceColor
            objs.DistanceText.Visible = true
        else
            objs.DistanceText.Visible = false
        end

        if Settings.ESP.Skeleton then
            -- Perfect Skeleton (тот же код что и раньше)
            local UpperTorso = Char:FindFirstChild("UpperTorso") or Char:FindFirstChild("Torso")
            local LowerTorso = Char:FindFirstChild("LowerTorso") or Char:FindFirstChild("Torso")
            local LeftUpperArm = Char:FindFirstChild("LeftUpperArm") or Char:FindFirstChild("Left Arm")
            local RightUpperArm = Char:FindFirstChild("RightUpperArm") or Char:FindFirstChild("Right Arm")
            local LeftLowerArm = Char:FindFirstChild("LeftLowerArm") or LeftUpperArm
            local RightLowerArm = Char:FindFirstChild("RightLowerArm") or RightUpperArm
            local LeftHand = Char:FindFirstChild("LeftHand") or LeftLowerArm
            local RightHand = Char:FindFirstChild("RightHand") or RightLowerArm
            local LeftUpperLeg = Char:FindFirstChild("LeftUpperLeg") or Char:FindFirstChild("Left Leg")
            local RightUpperLeg = Char:FindFirstChild("RightUpperLeg") or Char:FindFirstChild("Right Leg")
            local LeftLowerLeg = Char:FindFirstChild("LeftLowerLeg") or LeftUpperLeg
            local RightLowerLeg = Char:FindFirstChild("RightLowerLeg") or RightUpperLeg
            local LeftFoot = Char:FindFirstChild("LeftFoot") or LeftLowerLeg
            local RightFoot = Char:FindFirstChild("RightFoot") or RightLowerLeg

            local HeadPos = Camera:WorldToViewportPoint(Head.Position + Vector3.new(0, 0.5, 0))
            local NeckPos = UpperTorso and Camera:WorldToViewportPoint(UpperTorso.Position + Vector3.new(0, 0.8, 0)) or HeadPos
            local PelvisPos = LowerTorso and Camera:WorldToViewportPoint(LowerTorso.Position - Vector3.new(0, 0.8, 0)) or NeckPos
            local LShoulderPos = LeftUpperArm and Camera:WorldToViewportPoint(LeftUpperArm.Position) or NeckPos
            local RShoulderPos = RightUpperArm and Camera:WorldToViewportPoint(RightUpperArm.Position) or NeckPos
            local LElbowPos = LeftLowerArm and Camera:WorldToViewportPoint(LeftLowerArm.Position) or LShoulderPos
            local RElbowPos = RightLowerArm and Camera:WorldToViewportPoint(RightLowerArm.Position) or RShoulderPos
            local LHandPos = LeftHand and Camera:WorldToViewportPoint(LeftHand.Position) or LElbowPos
            local RHandPos = RightHand and Camera:WorldToViewportPoint(RightHand.Position) or RElbowPos
            local LHipPos = LeftUpperLeg and Camera:WorldToViewportPoint(LeftUpperLeg.Position) or PelvisPos
            local RHipPos = RightUpperLeg and Camera:WorldToViewportPoint(RightUpperLeg.Position) or PelvisPos
            local LKneePos = LeftLowerLeg and Camera:WorldToViewportPoint(LeftLowerLeg.Position) or LHipPos
            local RKneePos = RightLowerLeg and Camera:WorldToViewportPoint(RightLowerLeg.Position) or RHipPos
            local LFootPos = LeftFoot and Camera:WorldToViewportPoint(LeftFoot.Position) or LKneePos
            local RFootPos = RightFoot and Camera:WorldToViewportPoint(RightFoot.Position) or RKneePos

            local lines = {
                {HeadPos, NeckPos}, {NeckPos, PelvisPos},
                {NeckPos, LShoulderPos}, {LShoulderPos, LElbowPos}, {LElbowPos, LHandPos},
                {NeckPos, RShoulderPos}, {RShoulderPos, RElbowPos}, {RElbowPos, RHandPos},
                {PelvisPos, LHipPos}, {LHipPos, LKneePos}, {LKneePos, LFootPos},
                {PelvisPos, RHipPos}, {RHipPos, RKneePos}, {RKneePos, RFootPos}
            }

            for i, line in ipairs(lines) do
                if objs.Skeleton[i] then
                    if line[1].Z > 0 and line[2].Z > 0 then
                        objs.Skeleton[i].From = Vector2.new(line[1].X, line[1].Y)
                        objs.Skeleton[i].To = Vector2.new(line[2].X, line[2].Y)
                        objs.Skeleton[i].Color = Settings.ESP.SkeletonColor
                        objs.Skeleton[i].Visible = true
                    else
                        objs.Skeleton[i].Visible = false
                    end
                end
            end
        else
            for _, line in pairs(objs.Skeleton) do line.Visible = false end
        end
    end
end

-- Init ESP
for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= LocalPlayer then
        CreateESP(Player)
        Player.CharacterAdded:Connect(function() CreateESP(Player) end)
    end
end

Players.PlayerAdded:Connect(function(Player)
    if Player ~= LocalPlayer then
        Player.CharacterAdded:Connect(function() CreateESP(Player) end)
    end
end)

-- Main loop
RunService.RenderStepped:Connect(function()
    local center = Camera.ViewportSize / 2
    FOVCircle.Visible = Settings.FOV.Show
    FOVCircle.Position = center
    FOVCircle.Radius = Settings.FOV.Radius
    FOVCircle.Color = Settings.FOV.Color

    local Target = GetClosestEnemy()

    if Settings.Aimbot.Enabled and Target then
        AimAt(Target.Part)
    end

    UpdateESP()
    ApplySpeed()

    -- Постоянный Auto Trigger
    if Settings.Trigger.Enabled and Target then
        mouse1press()
        task.wait(Settings.Trigger.Delay)
        mouse1release()
    end
end)

-- GUI
MainTab:CreateToggle({Name = "Aimbot Enabled", CurrentValue = true, Callback = function(v) Settings.Aimbot.Enabled = v end})
MainTab:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) Settings.Aimbot.TeamCheck = v end})
MainTab:CreateDropdown({Name = "Team Check Mode", Options = {"TeamColor", "Team"}, CurrentOption = "TeamColor", Callback = function(o) Settings.Aimbot.TeamCheckMode = o end})
MainTab:CreateToggle({Name = "Visible Check", CurrentValue = true, Callback = function(v) Settings.Aimbot.VisibleCheck = v end})
MainTab:CreateDropdown({Name = "Aim Part", Options = {"Head", "HumanoidRootPart"}, CurrentOption = "Head", Callback = function(o) Settings.Aimbot.AimPart = o end})
MainTab:CreateSlider({Name = "Aim Smoothness (1=smooth, 10=fast)", Range = {1, 10}, Increment = 1, CurrentValue = 8, Callback = function(v) Settings.Aimbot.AimSpeed = v end})

TriggerTab:CreateToggle({Name = "Auto Trigger Enabled", CurrentValue = true, Callback = function(v) Settings.Trigger.Enabled = v end})
TriggerTab:CreateSlider({Name = "Shoot Delay", Range = {0.01, 0.3}, Increment = 0.01, Suffix = "s", CurrentValue = 0.05, Callback = function(v) Settings.Trigger.Delay = v end})

ESPTab:CreateToggle({Name = "ESP Enabled", CurrentValue = true, Callback = function(v) Settings.ESP.Enabled = v end})
ESPTab:CreateToggle({Name = "Boxes", CurrentValue = true, Callback = function(v) Settings.ESP.Box = v end})
ESPTab:CreateToggle({Name = "Tracers", CurrentValue = true, Callback = function(v) Settings.ESP.Tracer = v end})
ESPTab:CreateToggle({Name = "Skeleton", CurrentValue = true, Callback = function(v) Settings.ESP.Skeleton = v end})
ESPTab:CreateToggle({Name = "Foot Tracers", CurrentValue = true, Callback = function(v) Settings.ESP.FootTracer = v end})
ESPTab:CreateToggle({Name = "Health Bar", CurrentValue = true, Callback = function(v) Settings.ESP.HealthBar = v end})
ESPTab:CreateToggle({Name = "Distance", CurrentValue = true, Callback = function(v) Settings.ESP.Distance = v end})
ESPTab:CreateColorPicker({Name = "Enemy Color", Color = Color3.fromRGB(255,0,0), Callback = function(v) Settings.ESP.EnemyColor = v Settings.ESP.BoxColorEnemy = v end})
ESPTab:CreateColorPicker({Name = "Team Color", Color = Color3.fromRGB(0,255,0), Callback = function(v) Settings.ESP.TeamColor = v Settings.ESP.BoxColorTeam = v end})
ESPTab:CreateColorPicker({Name = "Skeleton Color", Color = Color3.fromRGB(255,165,0), Callback = function(v) Settings.ESP.SkeletonColor = v end})

VisualTab:CreateToggle({Name = "Show FOV", CurrentValue = true, Callback = function(v) Settings.FOV.Show = v end})
VisualTab:CreateSlider({Name = "FOV Radius", Range = {50, 500}, Increment = 10, CurrentValue = 200, Callback = function(v) Settings.FOV.Radius = v end})
VisualTab:CreateColorPicker({Name = "FOV Color", Color = Color3.fromRGB(255,0,0), Callback = function(v) Settings.FOV.Color = v end})

SpeedTab:CreateToggle({Name = "Speed Hack Enabled", CurrentValue = false, Callback = function(v) Settings.Speed.Enabled = v ApplySpeed() end})
SpeedTab:CreateSlider({Name = "Walk Speed", Range = {16, 300}, Increment = 5, Suffix = " studs/s", CurrentValue = 100, Callback = function(v) Settings.Speed.Value = v if Settings.Speed.Enabled then ApplySpeed() end end})

ExtraTab:CreateToggle({Name = "Stretch Screen", CurrentValue = false, Callback = function(v) Settings.Stretch.Enabled = v ForceApplyStretch() end})
ExtraTab:CreateSlider({Name = "Stretch Intensity (FOV)", Range = {70, 170}, Increment = 5, CurrentValue = 150, Callback = function(v) Settings.Stretch.Intensity = v if Settings.Stretch.Enabled then ForceApplyStretch() end end})

Rayfield:Notify({Title = "SWILL Loaded", Content = "Full working version 02.01.2026 | Team Check fixed | Constant Trigger", Duration = 15})
print("SWILL - Full working code loaded")
