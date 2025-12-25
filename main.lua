-- SWILL Auto Triggerbot (стреляет при наведении) + Aimbot + Wallhack
-- Навёл на врага — сразу стреляет автоматически

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Загрузка Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Окно
local Window = Rayfield:CreateWindow({
    Name = "SWILL Auto Trigger",
    LoadingTitle = "Auto Trigger + Aimbot + VH",
    LoadingSubtitle = "by Swill Way",
    ConfigurationSaving = {Enabled = true, FolderName = "SWILL_AutoTrigger", FileName = "Config"}
})

-- Вкладки
local MainTab = Window:CreateTab("Aimbot", 4483362458)
local VHTab = Window:CreateTab("Wallhack", 4483362458)
local TriggerTab = Window:CreateTab("Auto Trigger", 4483362458)
local VisualTab = Window:CreateTab("Visuals", 4483362458)

-- Настройки
local Settings = {
    Aimbot = {Enabled = true, TeamCheck = true, VisibleCheck = true, AimPart = "Head", Smoothness = 0.15},
    ESP = {Enabled = true, Box = true, Tracer = true, HealthBar = true, EnemyColor = Color3.fromRGB(255,0,0), TeamColor = Color3.fromRGB(0,255,0)},
    Trigger = {Enabled = true, Delay = 0.05, TeamCheck = true},  -- Delay между выстрелами
    FOV = {Radius = 120, Show = true, Color = Color3.fromRGB(255,255,255)}
}

-- FOV круг
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Transparency = 1

-- ESP объекты
local ESPObjects = {}

-- Получение ближайшего врага в FOV
local function GetClosestEnemy()
    local Closest = nil
    local ClosestDist = Settings.FOV.Radius
    local MousePos = UserInputService:GetMouseLocation()
    
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health > 0 then
            if Settings.Trigger.TeamCheck and Player.Team == LocalPlayer.Team then continue end
            
            local Part = Player.Character:FindFirstChild(Settings.Aimbot.AimPart)
            if Part then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Part.Position)
                if OnScreen then
                    local Dist = (Vector2.new(MousePos.X, MousePos.Y) - Vector2.new(ScreenPos.X, ScreenPos.Y)).Magnitude
                    if Dist < ClosestDist then
                        local Visible = true
                        if Settings.Aimbot.VisibleCheck then
                            local RayParams = RaycastParams.new()
                            RayParams.FilterDescendantsInstances = {LocalPlayer.Character or {}}
                            RayParams.FilterType = Enum.RaycastFilterType.Blacklist
                            local Result = workspace:Raycast(Camera.CFrame.Position, (Part.Position - Camera.CFrame.Position), RayParams)
                            Visible = not Result or Result.Instance:IsDescendantOf(Player.Character)
                        end
                        if Visible then
                            ClosestDist = Dist
                            Closest = {Part = Part, Player = Player}
                        end
                    end
                end
            end
        end
    end
    return Closest
end

-- Создание ESP
local function CreateESP(Player)
    if ESPObjects[Player] then return end
    local Box = Drawing.new("Square")
    Box.Thickness = 2
    Box.Filled = false
    Box.Transparency = 1
    
    local Tracer = Drawing.new("Line")
    Tracer.Thickness = 2
    Tracer.Transparency = 1
    
    local HB_BG = Drawing.new("Square")
    local HB_FG = Drawing.new("Square")
    
    ESPObjects[Player] = {Box = Box, Tracer = Tracer, HB_BG = HB_BG, HB_FG = HB_FG}
end

-- Обновление ESP
local function UpdateESP()
    if not Settings.ESP.Enabled then
        for _, objs in pairs(ESPObjects) do
            objs.Box.Visible = false
            objs.Tracer.Visible = false
            objs.HB_BG.Visible = false
            objs.HB_FG.Visible = false
        end
        return
    end
    
    for Player, objs in pairs(ESPObjects) do
        local Char = Player.Character
        if Char and Char:FindFirstChild("Head") and Char:FindFirstChild("HumanoidRootPart") and Char:FindFirstChild("Humanoid") and Char.Humanoid.Health > 0 then
            local Head = Char.Head
            local Root = Char.HumanoidRootPart
            
            local HeadPos = Camera:WorldToViewportPoint(Head.Position + Vector3.new(0, 0.5, 0))
            local TopPos = Camera:WorldToViewportPoint(Root.Position + Vector3.new(0, 3, 0))
            local BottomPos = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 5, 0))
            
            if HeadPos.Z > 0 then
                local Height = math.abs(TopPos.Y - BottomPos.Y)
                local Width = Height / 2
                local Color = (Player.Team == LocalPlayer.Team) and Settings.ESP.TeamColor or Settings.ESP.EnemyColor
                
                if Settings.ESP.Box then
                    objs.Box.Size = Vector2.new(Width, Height)
                    objs.Box.Position = Vector2.new(TopPos.X - Width/2, TopPos.Y - Height/2)
                    objs.Box.Color = Color
                    objs.Box.Visible = true
                end
                
                if Settings.ESP.Tracer then
                    objs.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    objs.Tracer.To = Vector2.new(TopPos.X, TopPos.Y)
                    objs.Tracer.Color = Color
                    objs.Tracer.Visible = true
                end
                
                if Settings.ESP.HealthBar then
                    local Health = Char.Humanoid.Health / Char.Humanoid.MaxHealth
                    objs.HB_BG.Size = Vector2.new(4, Height)
                    objs.HB_BG.Position = Vector2.new(TopPos.X - Width/2 - 7, TopPos.Y - Height/2)
                    objs.HB_BG.Color = Color3.new(0,0,0)
                    objs.HB_BG.Transparency = 0.5
                    objs.HB_BG.Visible = true
                    
                    objs.HB_FG.Size = Vector2.new(4, Height * Health)
                    objs.HB_FG.Position = Vector2.new(TopPos.X - Width/2 - 7, TopPos.Y - Height/2 + Height * (1 - Health))
                    objs.HB_FG.Color = Color3.fromRGB(0,255,0):Lerp(Color3.fromRGB(255,0,0), 1 - Health)
                    objs.HB_FG.Visible = true
                end
            else
                objs.Box.Visible = false
                objs.Tracer.Visible = false
                objs.HB_BG.Visible = false
                objs.HB_FG.Visible = false
            end
        else
            objs.Box.Visible = false
            objs.Tracer.Visible = false
            objs.HB_BG.Visible = false
            objs.HB_FG.Visible = false
        end
    end
end

-- Инициализация ESP
for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= LocalPlayer then
        CreateESP(Player)
        Player.CharacterAdded:Connect(function() CreateESP(Player) end)
    end
end
Players.PlayerAdded:Connect(function(Player)
    Player.CharacterAdded:Connect(function() CreateESP(Player) end)
end)

-- Последняя цель для предотвращения спама выстрелов
local LastTarget = nil

-- Основной цикл
RunService.RenderStepped:Connect(function()
    -- FOV
    FOVCircle.Visible = Settings.FOV.Show
    FOVCircle.Radius = Settings.FOV.Radius
    FOVCircle.Color = Settings.FOV.Color
    FOVCircle.Position = UserInputService:GetMouseLocation()
    
    -- Aimbot
    local Target = GetClosestEnemy()
    if Settings.Aimbot.Enabled and Target then
        local AimCFrame = CFrame.new(Camera.CFrame.Position, Target.Part.Position)
        Camera.CFrame = Camera.CFrame:Lerp(AimCFrame, Settings.Aimbot.Smoothness)
    end
    
    -- ESP
    UpdateESP()
    
    -- Автоматический Triggerbot: стреляет, когда навёл на врага
    if Settings.Trigger.Enabled and Target then
        if Target ~= LastTarget then
            -- Новый враг — сразу стреляем
            mouse1press()
            task.wait(Settings.Trigger.Delay)
            mouse1release()
            LastTarget = Target
        end
    else
        LastTarget = nil
    end
end)

-- Меню
MainTab:CreateToggle({Name = "Aimbot Enabled", CurrentValue = true, Callback = function(v) Settings.Aimbot.Enabled = v end})
MainTab:CreateToggle({Name = "Team Check", CurrentValue = true, Callback = function(v) Settings.Trigger.TeamCheck = v Settings.Aimbot.TeamCheck = v end})
MainTab:CreateToggle({Name = "Visible Check", CurrentValue = true, Callback = function(v) Settings.Aimbot.VisibleCheck = v end})
MainTab:CreateDropdown({Name = "Aim Part", Options = {"Head", "HumanoidRootPart"}, CurrentOption = "Head", Callback = function(o) Settings.Aimbot.AimPart = o end})
MainTab:CreateSlider({Name = "Smoothness", Range = {0.05, 0.5}, Increment = 0.01, CurrentValue = 0.15, Callback = function(v) Settings.Aimbot.Smoothness = v end})

TriggerTab:CreateToggle({Name = "Auto Trigger Enabled", CurrentValue = true, Callback = function(v) Settings.Trigger.Enabled = v end})
TriggerTab:CreateSlider({Name = "Shoot Delay", Range = {0.01, 0.3}, Increment = 0.01, Suffix = "s", CurrentValue = 0.05, Callback = function(v) Settings.Trigger.Delay = v end})

VHTab:CreateToggle({Name = "ESP Enabled", CurrentValue = true, Callback = function(v) Settings.ESP.Enabled = v end})
VHTab:CreateToggle({Name = "Boxes", CurrentValue = true, Callback = function(v) Settings.ESP.Box = v end})
VHTab:CreateToggle({Name = "Tracers", CurrentValue = true, Callback = function(v) Settings.ESP.Tracer = v end})
VHTab:CreateToggle({Name = "Health Bar", CurrentValue = true, Callback = function(v) Settings.ESP.HealthBar = v end})

VisualTab:CreateToggle({Name = "Show FOV", CurrentValue = true, Callback = function(v) Settings.FOV.Show = v end})
VisualTab:CreateSlider({Name = "FOV Radius", Range = {10, 500}, Increment = 10, CurrentValue = 120, Callback = function(v) Settings.FOV.Radius = v end})

Rayfield:Notify({Title = "SWILL Auto Trigger", Content = "Навёл — и сразу стреляет! Готово.", Duration = 7})

print("SWILL Auto Triggerbot (стреляет при наведении) загружен!")
