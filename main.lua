local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Очистка старого Rayfield
if Rayfield then
    pcall(function() Rayfield:Destroy() end)
end

-- Загрузка Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Окно
local Window = Rayfield:CreateWindow({
    Name = "SWILL Auto Trigger",
    LoadingTitle = "Tracers Fixed + No Ghost Lines",
    LoadingSubtitle = "by Swill Way",
    ConfigurationSaving = {Enabled = true, FolderName = "SWILL_AutoTrigger", FileName = "Config"}
})

-- Вкладки
local MainTab = Window:CreateTab("Aimbot", 4483362458)
local VHTab = Window:CreateTab("Wallhack", 4483362458)
local TriggerTab = Window:CreateTab("Auto Trigger", 4483362458)
local VisualTab = Window:CreateTab("Visuals", 4483362458)
local HitboxTab = Window:CreateTab("Hitbox", 4483362458)
local CameraTab = Window:CreateTab("Camera", 4483362458)

-- Настройки
local Settings = {
    Aimbot = {Enabled = true, TeamCheck = true, TeamCheckMode = "TeamColor", VisibleCheck = true, AimPart = "Head", AimSpeed = 10, UseCamera = false},
    ESP = {Enabled = true, Box = true, Tracer = true, Skeleton = true, FootTracer = true, HealthBar = true, Distance = true, EnemyColor = Color3.fromRGB(255,0,0), TeamColor = Color3.fromRGB(0,255,0), SkeletonColor = Color3.fromRGB(255,165,0)},
    Trigger = {Enabled = true, Delay = 0.05, TeamCheck = true},
    FOV = {Radius = 200, Show = true, Color = Color3.fromRGB(255,0,0)},
    Hitbox = {Enabled = false, Size = 5, Transparency = 0.7, Part = "Head"},
    CameraFOV = {Value = 70}
}

-- Применение FOV камеры
RunService.RenderStepped:Connect(function()
    Camera.FieldOfView = Settings.CameraFOV.Value
end)

-- FOV круг
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Transparency = 1

-- ESP объекты
local ESPObjects = {}
local OriginalHitboxSizes = {}

-- Функция полной очистки всех Drawing для игрока
local function ClearESP(Player)
    if ESPObjects[Player] then
        local objs = ESPObjects[Player]
        objs.Box.Visible = false
        objs.Tracer.Visible = false
        objs.FootTracer.Visible = false
        objs.HB_BG.Visible = false
        objs.HB_FG.Visible = false
        objs.DistanceText.Visible = false
        for _, line in pairs(objs.Skeleton) do
            line.Visible = false
        end
    end
end

-- Проверка тиммейта
local function IsTeammate(Player)
    if not Settings.Aimbot.TeamCheck then return false end
    if Player == LocalPlayer then return true end
    if Settings.Aimbot.TeamCheckMode == "TeamColor" then
        return Player.TeamColor == LocalPlayer.TeamColor
    else
        return Player.Team == LocalPlayer.Team
    end
end

-- Видимость
local function hasLineOfSight(origin, targetPart)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character or workspace}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local direction = (targetPart.Position - origin)
    local result = workspace:Raycast(origin, direction, rayParams)
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

-- Ближайший враг
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

-- Прицеливание
local function AimAt(targetScreenPos)
    local center = Camera.ViewportSize / 2
    local delta = targetScreenPos - center
    if Settings.Aimbot.UseCamera then
        local targetPart = GetClosestEnemy().Part
        local AimCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
        local smoothness = Settings.Aimbot.AimSpeed / 10
        Camera.CFrame = smoothness >= 1 and AimCFrame or Camera.CFrame:Lerp(AimCFrame, smoothness)
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

-- Создание ESP
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
    for i = 1, 6 do objs.Skeleton[i] = Drawing.new("Line"); objs.Skeleton[i].Thickness = 2 end
    objs.Box.Thickness = 2; objs.Box.Filled = false
    objs.Tracer.Thickness = 2
    objs.FootTracer.Thickness = 2
    objs.DistanceText.Size = 16; objs.DistanceText.Outline = true; objs.DistanceText.Center = true
    ESPObjects[Player] = objs
end

-- Обновление ESP (с полной очисткой при необходимости)
local function UpdateESP()
    -- Если ESP полностью выключен — чистим всё
    if not Settings.ESP.Enabled then
        for _, objs in pairs(ESPObjects) do
            ClearESP(_)
        end
        return
    end

    for Player, objs in pairs(ESPObjects) do
        local Char = Player.Character
        if not Char or not Char:FindFirstChild("Head") or not Char:FindFirstChild("HumanoidRootPart") or not Char:FindFirstChild("Humanoid") or Char.Humanoid.Health <= 0 then
            ClearESP(Player)
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

        if HeadPos.Z <= 0 then
            ClearESP(Player)
            continue
        end

        local Height = math.abs(TopPos.Y - BottomPos.Y)
        local Width = Height / 2
        local Color = IsTeammate(Player) and Settings.ESP.TeamColor or Settings.ESP.EnemyColor
        local Distance = math.floor((Camera.CFrame.Position - Root.Position).Magnitude)

        -- Box
        objs.Box.Visible = Settings.ESP.Box
        if Settings.ESP.Box then
            objs.Box.Size = Vector2.new(Width, Height)
            objs.Box.Position = Vector2.new(TopPos.X - Width/2, TopPos.Y)
            objs.Box.Color = Color
        end

        -- Tracer (от центра экрана к верху)
        objs.Tracer.Visible = Settings.ESP.Tracer
        if Settings.ESP.Tracer then
            objs.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            objs.Tracer.To = Vector2.new(TopPos.X, TopPos.Y + Height)
            objs.Tracer.Color = Color
        end

        -- Skeleton
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
        else
            for i = 1, 6 do objs.Skeleton[i].Visible = false end
        end

        -- Foot Tracer
        objs.FootTracer.Visible = Settings.ESP.FootTracer
        if Settings.ESP.FootTracer then
            objs.FootTracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            objs.FootTracer.To = Vector2.new(BottomPos.X, BottomPos.Y)
            objs.FootTracer.Color = Color
        end

        -- Health Bar
        objs.HB_BG.Visible = Settings.ESP.HealthBar
        objs.HB_FG.Visible = Settings.ESP.HealthBar
        if Settings.ESP.HealthBar then
            local Health = Humanoid.Health / Humanoid.MaxHealth
            objs.HB_BG.Size = Vector2.new(4, Height)
            objs.HB_BG.Position = Vector2.new(TopPos.X - Width/2 - 7, TopPos.Y)
            objs.HB_BG.Color = Color3.new(0,0,0)
            objs.HB_BG.Transparency = 0.5

            objs.HB_FG.Size = Vector2.new(4, Height * Health)
            objs.HB_FG.Position = Vector2.new(TopPos.X - Width/2 - 7, TopPos.Y + Height * (1 - Health))
            objs.HB_FG.Color = Color3.fromRGB(0,255,0):Lerp(Color3.fromRGB(255,0,0), 1 - Health)
        end

        -- Distance
        objs.DistanceText.Visible = Settings.ESP.Distance
        if Settings.ESP.Distance then
            objs.DistanceText.Text = Distance .. " studs"
            objs.DistanceText.Position = Vector2.new(TopPos.X, TopPos.Y - 20)
            objs.DistanceText.Color = Color
        end
    end
end

-- Hitbox обновление (без изменений)
local function UpdateHitboxes()
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild(Settings.Hitbox.Part) then
            local Part = Player.Character[Settings.Hitbox.Part]
            if Settings.Hitbox.Enabled then
                if not OriginalHitboxSizes[Player] then OriginalHitboxSizes[Player] = Part.Size end
                Part.Size = Vector3.new(Settings.Hitbox.Size, Settings.Hitbox.Size, Settings.Hitbox.Size)
                Part.Transparency = Settings.Hitbox.Transparency
                Part.CanCollide = false
            else
                if OriginalHitboxSizes[Player] then
                    Part.Size = OriginalHitboxSizes[Player]
                    Part.Transparency = 0
                    Part.CanCollide = true
                end
            end
        end
    end
end

-- Инициализация
for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= LocalPlayer then
        CreateESP(Player)
        Player.CharacterAdded:Connect(function() CreateESP(Player); UpdateHitboxes() end)
    end
end

Players.PlayerAdded:Connect(function(Player)
    Player.CharacterAdded:Connect(function() CreateESP(Player); UpdateHitboxes() end)
end)

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

-- Меню (все элементы как раньше)
MainTab:CreateToggle({Name = "Aimbot Enabled", CurrentValue = true, Callback = function(v) Settings.Aimbot.Enabled = v end})
MainTab:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) Settings.Aimbot.TeamCheck = v; Settings.Trigger.TeamCheck = v end})
MainTab:CreateDropdown({Name = "Team Check Mode", Options = {"TeamColor", "Team"}, CurrentOption = "TeamColor", Callback = function(o) Settings.Aimbot.TeamCheckMode = o end})
MainTab:CreateToggle({Name = "Visible Check", CurrentValue = true, Callback = function(v) Settings.Aimbot.VisibleCheck = v end})
MainTab:CreateDropdown({Name = "Aim Part", Options = {"Head", "HumanoidRootPart"}, CurrentOption = "Head", Callback = function(o) Settings.Aimbot.AimPart = o end})
MainTab:CreateSlider({Name = "Aim Speed (1=плавно, 10=мгновенно)", Range = {1, 10}, Increment = 1, CurrentValue = 10, Callback = function(v) Settings.Aimbot.AimSpeed = v end})
MainTab:CreateToggle({Name = "Use Camera Aimbot", CurrentValue = false, Callback = function(v) Settings.Aimbot.UseCamera = v end})

TriggerTab:CreateToggle({Name = "Auto Trigger Enabled", CurrentValue = true, Callback = function(v) Settings.Trigger.Enabled = v end})
TriggerTab:CreateSlider({Name = "Shoot Delay", Range = {0.01, 0.3}, Increment = 0.01, Suffix = "s", CurrentValue = 0.05, Callback = function(v) Settings.Trigger.Delay = v end})

VHTab:CreateToggle({Name = "ESP Enabled", CurrentValue = true, Callback = function(v) Settings.ESP.Enabled = v end})
VHTab:CreateToggle({Name = "Boxes", CurrentValue = true, Callback = function(v) Settings.ESP.Box = v end})
VHTab:CreateToggle({Name = "Tracers", CurrentValue = true, Callback = function(v) Settings.ESP.Tracer = v end})
VHTab:CreateToggle({Name = "Skeleton", CurrentValue = true, Callback = function(v) Settings.ESP.Skeleton = v end})
VHTab:CreateToggle({Name = "Foot Tracers", CurrentValue = true, Callback = function(v) Settings.ESP.FootTracer = v end})
VHTab:CreateToggle({Name = "Health Bar", CurrentValue = true, Callback = function(v) Settings.ESP.HealthBar = v end})
VHTab:CreateToggle({Name = "Distance", CurrentValue = true, Callback = function(v) Settings.ESP.Distance = v end})
VHTab:CreateColorPicker({Name = "Skeleton Color", Color = Color3.fromRGB(255,165,0), Callback = function(v) Settings.ESP.SkeletonColor = v end})

VisualTab:CreateToggle({Name = "Show FOV", CurrentValue = true, Callback = function(v) Settings.FOV.Show = v end})
VisualTab:CreateSlider({Name = "FOV Radius", Range = {50, 500}, Increment = 10, CurrentValue = 200, Callback = function(v) Settings.FOV.Radius = v end})

HitboxTab:CreateToggle({Name = "Hitbox Enabled", CurrentValue = false, Callback = function(v) Settings.Hitbox.Enabled = v end})
HitboxTab:CreateSlider({Name = "Hitbox Size", Range = {2, 15}, Increment = 0.5, CurrentValue = 5, Callback = function(v) Settings.Hitbox.Size = v end})
HitboxTab:CreateSlider({Name = "Hitbox Transparency", Range = {0, 1}, Increment = 0.1, CurrentValue = 0.7, Callback = function(v) Settings.Hitbox.Transparency = v end})
HitboxTab:CreateDropdown({Name = "Hitbox Part", Options = {"Head", "HumanoidRootPart"}, CurrentOption = "Head", Callback = function(o) Settings.Hitbox.Part = o end})

CameraTab:CreateSection("Player FOV Changer")
CameraTab:CreateSlider({Name = "Camera FOV", Range = {30, 120}, Increment = 1, Suffix = "°", CurrentValue = 70, Callback = function(v) Settings.CameraFOV.Value = v end})
CameraTab:CreateButton({Name = "Reset FOV to Default (70)", Callback = function() Settings.CameraFOV.Value = 70; Rayfield:Notify({Title = "FOV Reset", Content = "FOV сброшен на 70°", Duration = 5}) end})

Rayfield:Notify({Title = "SWILL Tracers Fixed", Content = "Теперь при выключении Tracers/Foot Tracers никаких лишних линий не остаётся.", Duration = 10})

print("SWILL запущен — tracers полностью исправлены!")
