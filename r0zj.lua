local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

-- RemoteEvent for jumpscare
local jumpscareEvent = ReplicatedStorage:FindFirstChild("AdminJumpscare")
if not jumpscareEvent then
    jumpscareEvent = Instance.new("RemoteEvent")
    jumpscareEvent.Name = "AdminJumpscare"
    jumpscareEvent.Parent = ReplicatedStorage
end

-- CONFIG
local DISTANCE_THRESHOLD = 4
local MIN_ALIVE_TIME = 4

-- VARIABLES
local lockTarget = nil
local active = false
local scope = nil
local scopeEnabled = true
local spawnTimes = {}

-- TRACK SPAWNS
local function trackPlayer(plr)
    plr.CharacterAdded:Connect(function()
        spawnTimes[plr.UserId] = tick()
    end)
end
for _,p in ipairs(Players:GetPlayers()) do trackPlayer(p) end
Players.PlayerAdded:Connect(trackPlayer)

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "r0zjLockGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Panel
local Panel = Instance.new("Frame", ScreenGui)
Panel.Size = UDim2.new(0, 180, 0, 140)
Panel.Position = UDim2.new(1, -200, 0.35, 0)
Panel.BackgroundColor3 = Color3.fromRGB(15,15,15)
Panel.BorderColor3 = Color3.fromRGB(0,255,0)

-- Retro Title
local Title = Instance.new("TextLabel", Panel)
Title.Size = UDim2.new(1,0,0,28)
Title.Text = "r0zj lock"
Title.Font = Enum.Font.Code
Title.TextColor3 = Color3.fromRGB(0,255,0)
Title.BackgroundTransparency = 1
Title.TextScaled = true

-- Buttons
local LockOnBtn = Instance.new("TextButton", Panel)
LockOnBtn.Size = UDim2.new(1,-12,0,32)
LockOnBtn.Position = UDim2.new(0,6,0,38)
LockOnBtn.Text = "Lock On"
LockOnBtn.Font = Enum.Font.Code
LockOnBtn.TextColor3 = Color3.fromRGB(0,255,0)
LockOnBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)
LockOnBtn.BorderColor3 = Color3.fromRGB(0,255,0)

local LockOffBtn = Instance.new("TextButton", Panel)
LockOffBtn.Size = UDim2.new(1,-12,0,32)
LockOffBtn.Position = UDim2.new(0,6,0,74)
LockOffBtn.Text = "Lock Off"
LockOffBtn.Font = Enum.Font.Code
LockOffBtn.TextColor3 = Color3.fromRGB(255,0,0)
LockOffBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)
LockOffBtn.BorderColor3 = Color3.fromRGB(255,0,0)

local ToggleScopeBtn = Instance.new("TextButton", Panel)
ToggleScopeBtn.Size = UDim2.new(1,-12,0,32)
ToggleScopeBtn.Position = UDim2.new(0,6,0,110)
ToggleScopeBtn.Text = "Toggle Scope"
ToggleScopeBtn.Font = Enum.Font.Code
ToggleScopeBtn.TextColor3 = Color3.fromRGB(0,255,255)
ToggleScopeBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)
ToggleScopeBtn.BorderColor3 = Color3.fromRGB(0,255,255)

-- Pop-up function
local function showPopup(username)
    local popup = Instance.new("TextLabel", ScreenGui)
    popup.Size = UDim2.new(0,200,0,30)
    popup.Position = UDim2.new(0.5,-100,0.2,0)
    popup.BackgroundTransparency = 0.8
    popup.BackgroundColor3 = Color3.fromRGB(0,0,0)
    popup.BorderColor3 = Color3.fromRGB(0,255,0)
    popup.Font = Enum.Font.Code
    popup.Text = "Locked on "..username
    popup.TextColor3 = Color3.fromRGB(0,255,0)
    popup.TextScaled = true
    task.spawn(function()
        for i=1,60 do
            popup.TextTransparency = i/60
            task.wait(0.01)
        end
        popup:Destroy()
    end)
end

-- HELPER FUNCTIONS
local function isAlive(plr)
    if not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getClosestAlive()
    local closest,closestDist = nil,math.huge
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and isAlive(plr) and plr.Character:FindFirstChild("HumanoidRootPart") then
            local aliveSince = spawnTimes[plr.UserId]
            if aliveSince and tick() - aliveSince >= MIN_ALIVE_TIME then
                local dist = (root.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                if dist < closestDist then
                    closest,closestDist = plr,dist
                end
            end
        end
    end
    return closest
end

-- Scope creation (+ crosshair)
local function createScope(head)
    if scope then scope:Destroy() end
    if not scopeEnabled then return end

    scope = Instance.new("BillboardGui")
    scope.Adornee = head
    scope.AlwaysOnTop = true
    scope.Size = UDim2.new(0,80,0,80)
    scope.Parent = head

    local thickness = 2
    local gap = 12
    local length = 20
    local sides = {"Top","Bottom","Left","Right"}

    for _,side in pairs(sides) do
        local line = Instance.new("Frame", scope)
        line.BackgroundColor3 = Color3.fromRGB(255,0,0)
        line.BorderSizePixel = 0
        if side == "Top" then
            line.Size = UDim2.new(0,length,0,thickness)
            line.Position = UDim2.new(0.5,-length/2,0,0)
        elseif side == "Bottom" then
            line.Size = UDim2.new(0,length,0,thickness)
            line.Position = UDim2.new(0.5,-length/2,1,-thickness)
        elseif side == "Left" then
            line.Size = UDim2.new(0,thickness,0,length)
            line.Position = UDim2.new(0,0,0.5,-length/2)
        elseif side == "Right" then
            line.Size = UDim2.new(0,thickness,0,length)
            line.Position = UDim2.new(1-thickness,0,0.5,-length/2)
        end
    end
end

local function clearScope()
    if scope then scope:Destroy() scope = nil end
end

-- Lock target
local function setTarget(target)
    if not target then return end
    lockTarget = target
    active = true
    showPopup(target.Name)
    if scopeEnabled then
        local head = target.Character:FindFirstChild("Head")
        if head then createScope(head) end
    end
end

-- BUTTONS
LockOnBtn.MouseButton1Click:Connect(function()
    local target = getClosestAlive()
    if target then setTarget(target) end
end)

LockOffBtn.MouseButton1Click:Connect(function()
    active = false
    lockTarget = nil
    clearScope()
end)

ToggleScopeBtn.MouseButton1Click:Connect(function()
    scopeEnabled = not scopeEnabled
    if scopeEnabled and lockTarget and lockTarget.Character then
        local head = lockTarget.Character:FindFirstChild("Head")
        if head then createScope(head) end
    else
        clearScope()
    end
end)

-- CAMERA FOLLOW + AUTO SWITCH
RunService.RenderStepped:Connect(function()
    if active and lockTarget and isAlive(lockTarget) and lockTarget.Character then
        local head = lockTarget.Character:FindFirstChild("Head")
        if head then
            local camPos = Camera.CFrame.Position
            local look = (head.Position - camPos).Unit
            Camera.CFrame = CFrame.new(camPos, camPos + look)

            local dist = (head.Position - root.Position).Magnitude
            if dist < DISTANCE_THRESHOLD then
                jumpscareEvent:FireServer(lockTarget.Name)
                active = false
                lockTarget = nil
                clearScope()
            end
        end
    elseif active and (not lockTarget or not isAlive(lockTarget)) then
        -- auto-switch to new alive target
        local newTarget = getClosestAlive()
        if newTarget then setTarget(newTarget) else active=false lockTarget=nil clearScope() end
    end
end)

-- TITLE ANIMATION
task.spawn(function()
    local t = 0
    while true do
        t += RunService.RenderStepped:Wait()
        Title.Position = UDim2.new(0,0,0, math.sin(t*2)*2)
        Title.TextTransparency = (math.sin(t*4)*0.2)+0.2
    end
end)
