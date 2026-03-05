--===================================
-- MINIVERSE + FIRE VS ICE - FULL VERSION
-- MINIVERSE: X-RAY BLOCK (Y = -12.00)
-- FIRE VS ICE: Turun ke Y = -8.59 dulu sebelum ke target
--===================================

--// SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

--================ SETTINGS GLOBAL =================
local SPEED = 0.5
local speedMultiplier = 1
local UNDER_OFFSET = 4
local TURUN_Y = -8.59      -- Turun ke sini dulu
local BLOCK_Y = -12.00     -- Block di sini

--================ STATE (DIPISAH UNTUK FIRE & ICE) =================
local fireRunning = false
local iceRunning = false

-- TABEL TERPISAH biar gak saling tabrak
local fireProcessed = {}
local iceProcessed = {}

--================ PEMBAGIAN WILAYAH =================
local BATAS_WILAYAH = 2250

--================ FUNGSI TWEEN TANPA NOCLIP =================
local function safeTweenTo(pos)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(SPEED, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(pos)}
    )
    
    tween:Play()
    tween.Completed:Wait()
end

--================ FUNGSI FIRE ICE TWEEN (TURUN DULU KE Y = -8.59) =================
local function fireIceTween(targetPos)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local currentPos = hrp.Position

    -- LANGKAH 1: Turun ke Y = -8.59 dulu
    local turunPos = Vector3.new(currentPos.X, TURUN_Y, currentPos.Z)
    
    local distance1 = (currentPos - turunPos).Magnitude
    local baseSpeed = 30
    local studsPerSecond = baseSpeed + (speedMultiplier * 10)
    local time1 = distance1 / studsPerSecond
    time1 = math.clamp(time1, 0.3, 1.5)
    
    local tween1 = TweenService:Create(
        hrp,
        TweenInfo.new(time1, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(turunPos)}
    )
    tween1:Play()
    tween1.Completed:Wait()
    
    -- LANGKAH 2: Ke target (dengan anti void)
    if targetPos.Y < -50 then
        targetPos = Vector3.new(targetPos.X, 5, targetPos.Z)
    end
    
    local distance2 = (turunPos - targetPos).Magnitude
    local time2 = distance2 / studsPerSecond
    time2 = math.clamp(time2, 0.5, 2.5)
    
    local tween2 = TweenService:Create(
        hrp,
        TweenInfo.new(time2, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(targetPos)}
    )
    tween2:Play()
    tween2.Completed:Wait()
end

--================ FUNGSI CEK PROMPT =================
local function targetHasPrompt(targetPart)
    if not targetPart or not targetPart.Parent then return false end
    
    for _, v in pairs(targetPart.Parent:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            return true
        end
    end
    
    for _, v in pairs(targetPart:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            return true
        end
    end
    
    return false
end

--================ FIND TARGET DENGAN TABEL PROCESSED TERPISAH =================
local function findBrainrotTargetByWilayah(warna, processedTable)
    local folder = workspace:FindFirstChild("ActiveBrainrots")
    if not folder then return nil end
    
    local semuaTarget = {}
    
    -- Cari di Secret
    local secret = folder:FindFirstChild("Secret")
    if secret and secret:FindFirstChild("RenderedBrainrot") then
        local rb = secret.RenderedBrainrot
        for _, child in pairs(rb:GetChildren()) do
            if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
                if child.Parent and child:IsDescendantOf(workspace) then
                    table.insert(semuaTarget, child)
                end
            end
        end
    end
    
    -- Cari di Cosmic
    local cosmic = folder:FindFirstChild("Cosmic")
    if cosmic and cosmic:FindFirstChild("RenderedBrainrot") then
        local rb = cosmic.RenderedBrainrot
        for _, child in pairs(rb:GetChildren()) do
            if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
                if child.Parent and child:IsDescendantOf(workspace) then
                    table.insert(semuaTarget, child)
                end
            end
        end
    end
    
    -- Filter berdasarkan wilayah DAN processedTable
    local targetWilayah = {}
    for _, target in ipairs(semuaTarget) do
        if not processedTable[target] then
            local x = target.Position.X
            if warna == "MERAH" and x < BATAS_WILAYAH then
                table.insert(targetWilayah, target)
            elseif warna == "BIRU" and x > BATAS_WILAYAH then
                table.insert(targetWilayah, target)
            end
        end
    end
    
    if #targetWilayah > 0 then
        return targetWilayah[1]
    end
    return nil
end

--================ AUTO INTERACT =================
local function autoInteract(model)
    for _,v in pairs(model:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            fireproximityprompt(v)
        end
    end
end

--================ MAIN LOOP DENGAN TRACKING TERPISAH =================
local function runLoop(flagGetter, warna)
    task.spawn(function()
        -- Pilih tabel processed yang sesuai (FIRE atau ICE)
        local processedTable = (warna == "MERAH" and fireProcessed or iceProcessed)
        local warnaText = (warna == "MERAH" and "🔴 FIRE" or "🔵 ICE")
        
        print("😈 Loop " .. warnaText .. " dimulai!")
        
        while flagGetter() do
            local targetPart = findBrainrotTargetByWilayah(warna, processedTable)
            
            if targetPart then
                if targetHasPrompt(targetPart) then
                    print("😈 [" .. warnaText .. "] Target valid")
                    
                    -- Tandai di tabel khusus
                    processedTable[targetPart] = true
                    
                    local underPos = targetPart.Position - Vector3.new(0, UNDER_OFFSET, 0)
                    fireIceTween(underPos)
                    task.wait(0.3)

                    if targetPart.Parent then
                        autoInteract(targetPart.Parent)
                    end
                    
                    -- Bersihkan kalau kebanyakan
                    if #processedTable > 50 then
                        if warna == "MERAH" then 
                            fireProcessed = {} 
                        else 
                            iceProcessed = {} 
                        end
                    end
                else
                    print("😈 [" .. warnaText .. "] Target tanpa prompt, cari lain")
                end
            else
                print("😈 [" .. warnaText .. "] Tidak ada target, tunggu 3 detik")
                task.wait(3)
            end
            task.wait(0.5)
        end
    end)
end

--================ TOGGLE FUNCTION =================
local function makeToggle(parent,text,y,color,callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1,-20,0,28)
    button.Position = UDim2.new(0,10,0,y)
    button.BackgroundColor3 = Color3.fromRGB(35,35,35)
    button.TextColor3 = Color3.new(1,1,1)
    button.Text = text.." : OFF"
    button.Font = Enum.Font.Gotham
    button.TextSize = 13
    button.Parent = parent
    Instance.new("UICorner", button).CornerRadius = UDim.new(0,6)

    local state = false
    button.MouseButton1Click:Connect(function()
        state = not state
        if state then
            button.BackgroundColor3 = color
            button.Text = text.." : ON"
        else
            button.BackgroundColor3 = Color3.fromRGB(35,35,35)
            button.Text = text.." : OFF"
        end
        callback(state)
    end)
    
    return button
end

--================ GUI: Escape Tsunami =================
local guiEscape = Instance.new("ScreenGui", CoreGui)
guiEscape.Name = "EscapeTsunami"
local frameEscape = Instance.new("Frame", guiEscape)
frameEscape.Size = UDim2.new(0,200,0,200)
frameEscape.Position = UDim2.new(0.3,0,0.4,0)
frameEscape.BackgroundColor3 = Color3.fromRGB(20,20,20)
frameEscape.Active = true
frameEscape.Draggable = true
Instance.new("UICorner", frameEscape).CornerRadius = UDim.new(0,10)

local titleEscape = Instance.new("TextLabel", frameEscape)
titleEscape.Size = UDim2.new(1,0,0,28)
titleEscape.BackgroundTransparency = 1
titleEscape.Text = "Escape Tsunami 🌊"
titleEscape.TextColor3 = Color3.fromRGB(0,255,255)
titleEscape.Font = Enum.Font.GothamBold
titleEscape.TextSize = 14

-- Minimize button
local minimizeBtn = Instance.new("TextButton", frameEscape)
minimizeBtn.Size = UDim2.new(0,20,0,20)
minimizeBtn.Position = UDim2.new(1,-25,0,4)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
minimizeBtn.Text = "–"
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 16
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0,4)

local contentEscape = Instance.new("Frame", frameEscape)
contentEscape.Size = UDim2.new(1,0,1,-28)
contentEscape.Position = UDim2.new(0,0,0,28)
contentEscape.BackgroundTransparency = 1

-- Minimize logic
local minimized = false
local normalHeight = 200
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        minimizeBtn.Text = "+"
        contentEscape.Visible = false
        frameEscape:TweenSize(UDim2.new(0,200,0,28), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
    else
        minimizeBtn.Text = "–"
        contentEscape.Visible = true
        frameEscape:TweenSize(UDim2.new(0,200,0,normalHeight), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
    end
end)

-- GO TO BASE
local goBaseBtn = Instance.new("TextButton", contentEscape)
goBaseBtn.Size = UDim2.new(1,-20,0,28)
goBaseBtn.Position = UDim2.new(0,10,0,5)
goBaseBtn.Text = "🚀 GO TO BASE"
goBaseBtn.BackgroundColor3 = Color3.fromRGB(0,255,255)
goBaseBtn.TextColor3 = Color3.new(0,0,0)
Instance.new("UICorner", goBaseBtn).CornerRadius = UDim.new(0,6)
goBaseBtn.MouseButton1Click:Connect(function()
    safeTweenTo(Vector3.new(152,3,-134))
end)

-- REMOVE WALL + ADD X-RAY BLOCK (Y = -12.00)
local removeWallBtn = Instance.new("TextButton", contentEscape)
removeWallBtn.Size = UDim2.new(1,-20,0,28)
removeWallBtn.Position = UDim2.new(0,10,0,40)
removeWallBtn.Text = "🧱 REMOVE WALL + X-RAY"
removeWallBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
removeWallBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", removeWallBtn).CornerRadius = UDim.new(0,6)
removeWallBtn.MouseButton1Click:Connect(function()
    print("😈 REMOVE WALL + ADD X-RAY BLOCK (Y = -12.00)")
    
    local blockY = -12.00  -- Block di sini
    local blockTransparency = 0.9
    local blockCanCollide = true
    
    -- BLOCK 1
    local block1 = Instance.new("Part")
    block1.Name = "XRayBlock_1"
    block1.Size = Vector3.new(4047.61, 1, 300)
    block1.Position = Vector3.new(199.145, blockY, 0.105)
    block1.Anchored = true
    block1.CanCollide = blockCanCollide
    block1.CanTouch = true
    block1.Transparency = blockTransparency
    block1.Material = Enum.Material.SmoothPlastic
    block1.Color = Color3.fromRGB(100, 200, 255)
    block1.Parent = workspace
    
    local hint1 = Instance.new("SelectionBox")
    hint1.Adornee = block1
    hint1.Color3 = Color3.fromRGB(0, 255, 255)
    hint1.Transparency = 0.8
    hint1.LineThickness = 0.05
    hint1.Parent = block1
    
    -- BLOCK 2
    local block2 = Instance.new("Part")
    block2.Name = "XRayBlock_2"
    block2.Size = Vector3.new(4047.61, 1, 300)
    block2.Position = Vector3.new(1083.26, blockY, 4.71)
    block2.Anchored = true
    block2.CanCollide = blockCanCollide
    block2.CanTouch = true
    block2.Transparency = blockTransparency
    block2.Material = Enum.Material.SmoothPlastic
    block2.Color = Color3.fromRGB(100, 200, 255)
    block2.Parent = workspace
    
    local hint2 = Instance.new("SelectionBox")
    hint2.Adornee = block2
    hint2.Color3 = Color3.fromRGB(0, 255, 255)
    hint2.Transparency = 0.8
    hint2.LineThickness = 0.05
    hint2.Parent = block2
    
    -- BLOCK 3
    local block3 = Instance.new("Part")
    block3.Name = "XRayBlock_3"
    block3.Size = Vector3.new(4047.61, 1, 300)
    block3.Position = Vector3.new(2278.70, blockY, 5.60)
    block3.Anchored = true
    block3.CanCollide = blockCanCollide
    block3.CanTouch = true
    block3.Transparency = blockTransparency
    block3.Material = Enum.Material.SmoothPlastic
    block3.Color = Color3.fromRGB(100, 200, 255)
    block3.Parent = workspace
    
    local hint3 = Instance.new("SelectionBox")
    hint3.Adornee = block3
    hint3.Color3 = Color3.fromRGB(0, 255, 255)
    hint3.Transparency = 0.8
    hint3.LineThickness = 0.05
    hint3.Parent = block3
    
    -- BLOCK 4
    local block4 = Instance.new("Part")
    block4.Name = "XRayBlock_4"
    block4.Size = Vector3.new(4047.61, 1, 300)
    block4.Position = Vector3.new(3285.74, blockY, -0.18)
    block4.Anchored = true
    block4.CanCollide = blockCanCollide
    block4.CanTouch = true
    block4.Transparency = blockTransparency
    block4.Material = Enum.Material.SmoothPlastic
    block4.Color = Color3.fromRGB(100, 200, 255)
    block4.Parent = workspace
    
    local hint4 = Instance.new("SelectionBox")
    hint4.Adornee = block4
    hint4.Color3 = Color3.fromRGB(0, 255, 255)
    hint4.Transparency = 0.8
    hint4.LineThickness = 0.05
    hint4.Parent = block4
    
    -- REMOVE WALL
    local wallCount = 0
    for _, wall in pairs(workspace:GetDescendants()) do
        if wall:IsA("BasePart") and not wall:IsA("Terrain") then
            local name = wall.Name:lower()
            if name:find("wall") or name:find("dinding") or name:find("tembok") or 
               name:find("barrier") or name:find("fence") or name:find("pagar") then
                wall:Destroy()
                wallCount = wallCount + 1
            end
        end
    end
    
    StarterGui:SetCore("SendNotification", {
        Title = "Escape Tsunami",
        Text = "✅ 4 X-RAY Block (Y=-12.00) + " .. wallCount .. " wall",
        Duration = 4
    })
end)

-- Infinite Jump
local infJumpConn = nil
makeToggle(contentEscape, "🦘 Inf Jump", 75, Color3.fromRGB(0,170,0), function(state)
    if state then
        if not infJumpConn then
            infJumpConn = UserInputService.JumpRequest:Connect(function()
                local char = player.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    else
        if infJumpConn then infJumpConn:Disconnect() end
    end
end)

-- Instant Interact
local instantConn = nil
makeToggle(contentEscape, "⚡ Instant", 110, Color3.fromRGB(170,0,170), function(state)
    if state then
        for _, prompt in pairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                prompt.HoldDuration = 0
            end
        end
        if not instantConn then
            instantConn = ProximityPromptService.PromptShown:Connect(function(prompt)
                prompt.HoldDuration = 0
            end)
        end
    else
        if instantConn then instantConn:Disconnect() end
        for _, prompt in pairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                prompt.HoldDuration = 1
            end
        end
    end
end)

-- God Mode (sederhana)
makeToggle(contentEscape, "👑 God Mode", 145, Color3.fromRGB(255,215,0), function(state)
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.MaxHealth = state and math.huge or 100
        char.Humanoid.Health = state and math.huge or 100
    end
end)

--================ GUI: Fire VS Ice =================
local guiFireIce = Instance.new("ScreenGui", CoreGui)
guiFireIce.Name = "FireVsIce"

local frameFI = Instance.new("Frame", guiFireIce)
frameFI.Size = UDim2.new(0,240,0,280)
frameFI.Position = UDim2.new(0.6,0,0.4,0)
frameFI.BackgroundColor3 = Color3.fromRGB(20,20,20)
frameFI.Active = true
frameFI.Draggable = true
Instance.new("UICorner", frameFI).CornerRadius = UDim.new(0,12)

-- HEADER
local headerFI = Instance.new("Frame", frameFI)
headerFI.Size = UDim2.new(1,0,0,35)
headerFI.BackgroundTransparency = 1

local titleFI = Instance.new("TextLabel", headerFI)
titleFI.Size = UDim2.new(1,0,1,0)
titleFI.BackgroundTransparency = 1
titleFI.Text = "Fire VS Ice 🔥❄️"
titleFI.TextColor3 = Color3.fromRGB(255,120,0)
titleFI.Font = Enum.Font.GothamBold
titleFI.TextSize = 14

local minimizeFIBtn = Instance.new("TextButton", headerFI)
minimizeFIBtn.Size = UDim2.new(0,25,0,25)
minimizeFIBtn.Position = UDim2.new(1,-30,0,5)
minimizeFIBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
minimizeFIBtn.Text = "-"
minimizeFIBtn.TextColor3 = Color3.new(1,1,1)
minimizeFIBtn.Font = Enum.Font.GothamBold
minimizeFIBtn.TextSize = 14
Instance.new("UICorner", minimizeFIBtn).CornerRadius = UDim.new(1,0)

local contentFI = Instance.new("Frame", frameFI)
contentFI.Size = UDim2.new(1,0,1,-35)
contentFI.Position = UDim2.new(0,0,0,35)
contentFI.BackgroundTransparency = 1

-- MINIMIZE
local fiMinimized = false
minimizeFIBtn.MouseButton1Click:Connect(function()
    fiMinimized = not fiMinimized
    if fiMinimized then
        minimizeFIBtn.Text = "+"
        contentFI.Visible = false
        frameFI:TweenSize(UDim2.new(0,240,0,35),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,true)
    else
        minimizeFIBtn.Text = "-"
        contentFI.Visible = true
        frameFI:TweenSize(UDim2.new(0,240,0,280),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,true)
    end
end)

-- INFO
local wilayahInfo = Instance.new("TextLabel", contentFI)
wilayahInfo.Size = UDim2.new(1,-20,0,20)
wilayahInfo.Position = UDim2.new(0,10,0,5)
wilayahInfo.BackgroundTransparency = 1
wilayahInfo.TextColor3 = Color3.fromRGB(255,255,255)
wilayahInfo.Text = "📍 Batas: X = " .. BATAS_WILAYAH
wilayahInfo.Font = Enum.Font.GothamBold
wilayahInfo.TextSize = 12
wilayahInfo.TextXAlignment = Enum.TextXAlignment.Left

local turunInfo = Instance.new("TextLabel", contentFI)
turunInfo.Size = UDim2.new(1,-20,0,20)
turunInfo.Position = UDim2.new(0,10,0,25)
turunInfo.BackgroundTransparency = 1
turunInfo.TextColor3 = Color3.fromRGB(255,255,0)
turunInfo.Text = "⬇️ Turun ke Y = -8.59 dulu"
turunInfo.Font = Enum.Font.Gotham
turunInfo.TextSize = 11
turunInfo.TextXAlignment = Enum.TextXAlignment.Left

local multiInfo = Instance.new("TextLabel", contentFI)
multiInfo.Size = UDim2.new(1,-20,0,20)
multiInfo.Position = UDim2.new(0,10,0,45)
multiInfo.BackgroundTransparency = 1
multiInfo.TextColor3 = Color3.fromRGB(0,255,0)
multiInfo.Text = "✅ 2 TOMBOL BISA JALAN BARENG!"
multiInfo.Font = Enum.Font.GothamBold
multiInfo.TextSize = 11
multiInfo.TextXAlignment = Enum.TextXAlignment.Left

-- FIRE BUTTON
local fireBtn = Instance.new("TextButton", contentFI)
fireBtn.Size = UDim2.new(1,-20,0,35)
fireBtn.Position = UDim2.new(0,10,0,70)
fireBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
fireBtn.TextColor3 = Color3.new(1,1,1)
fireBtn.Text = "🔥 FIRE (MERAH) : OFF"
fireBtn.Font = Enum.Font.GothamBold
fireBtn.TextSize = 13
Instance.new("UICorner", fireBtn).CornerRadius = UDim.new(0,8)

fireBtn.MouseButton1Click:Connect(function()
    fireRunning = not fireRunning
    if fireRunning then
        fireBtn.Text = "🔥 FIRE (MERAH) : ON"
        fireBtn.BackgroundColor3 = Color3.fromRGB(255,0,0)
        runLoop(function() return fireRunning end, "MERAH")
    else
        fireBtn.Text = "🔥 FIRE (MERAH) : OFF"
        fireBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
        fireProcessed = {}
    end
end)

-- ICE BUTTON
local iceBtn = Instance.new("TextButton", contentFI)
iceBtn.Size = UDim2.new(1,-20,0,35)
iceBtn.Position = UDim2.new(0,10,0,110)
iceBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
iceBtn.TextColor3 = Color3.new(1,1,1)
iceBtn.Text = "❄️ ICE (BIRU) : OFF"
iceBtn.Font = Enum.Font.GothamBold
iceBtn.TextSize = 13
Instance.new("UICorner", iceBtn).CornerRadius = UDim.new(0,8)

iceBtn.MouseButton1Click:Connect(function()
    iceRunning = not iceRunning
    if iceRunning then
        iceBtn.Text = "❄️ ICE (BIRU) : ON"
        iceBtn.BackgroundColor3 = Color3.fromRGB(0,100,255)
        runLoop(function() return iceRunning end, "BIRU")
    else
        iceBtn.Text = "❄️ ICE (BIRU) : OFF"
        iceBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
        iceProcessed = {}
    end
end)

-- SPEED LABEL
local speedLabel = Instance.new("TextLabel", contentFI)
speedLabel.Size = UDim2.new(0,40,0,20)
speedLabel.Position = UDim2.new(0,10,0,155)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(255,255,255)
speedLabel.Text = "Speed:"
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 12
speedLabel.TextXAlignment = Enum.TextXAlignment.Left

local speedValue = Instance.new("TextLabel", contentFI)
speedValue.Size = UDim2.new(0,30,0,20)
speedValue.Position = UDim2.new(0,50,0,155)
speedValue.BackgroundTransparency = 1
speedValue.TextColor3 = Color3.fromRGB(0,255,100)
speedValue.Text = "1"
speedValue.Font = Enum.Font.GothamBold
speedValue.TextSize = 14
speedValue.TextXAlignment = Enum.TextXAlignment.Left

-- SLIDER
local sliderFrame = Instance.new("Frame", contentFI)
sliderFrame.Size = UDim2.new(1,-20,0,30)
sliderFrame.Position = UDim2.new(0,10,0,180)
sliderFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)
Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0,8)

local fill = Instance.new("Frame", sliderFrame)
fill.Size = UDim2.new(0.33,0,1,0)
fill.BackgroundColor3 = Color3.fromRGB(255,170,0)
Instance.new("UICorner", fill).CornerRadius = UDim.new(0,8)

local divider1 = Instance.new("Frame", sliderFrame)
divider1.Size = UDim2.new(0,2,1,0)
divider1.Position = UDim2.new(0.33,0,0,0)
divider1.BackgroundColor3 = Color3.fromRGB(80,80,80)

local divider2 = Instance.new("Frame", sliderFrame)
divider2.Size = UDim2.new(0,2,1,0)
divider2.Position = UDim2.new(0.66,0,0,0)
divider2.BackgroundColor3 = Color3.fromRGB(80,80,80)

local dragging = false

local function updateSpeedFromPercent(percent)
    percent = math.clamp(percent, 0, 1)
    
    if percent <= 0.33 then
        speedMultiplier = 1
        fill.Size = UDim2.new(0.33,0,1,0)
        fill.BackgroundColor3 = Color3.fromRGB(255,170,0)
        speedValue.Text = "1"
    elseif percent <= 0.66 then
        speedMultiplier = 2
        fill.Size = UDim2.new(0.66,0,1,0)
        fill.BackgroundColor3 = Color3.fromRGB(255,120,0)
        speedValue.Text = "2"
    else
        speedMultiplier = 3
        fill.Size = UDim2.new(1,0,1,0)
        fill.BackgroundColor3 = Color3.fromRGB(255,50,0)
        speedValue.Text = "3"
    end
end

sliderFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        local percent = math.clamp(
            (input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X,
            0,1
        )
        updateSpeedFromPercent(percent)
    end
end)

sliderFrame.InputEnded:Connect(function()
    dragging = false
end)

sliderFrame.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local percent = math.clamp(
            (input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X,
            0,1
        )
        updateSpeedFromPercent(percent)
    end
end)

-- Tombol + -
local minusBtn = Instance.new("TextButton", contentFI)
minusBtn.Size = UDim2.new(0,25,0,25)
minusBtn.Position = UDim2.new(1,-65,0,155)
minusBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
minusBtn.Text = "-"
minusBtn.TextColor3 = Color3.new(1,1,1)
minusBtn.Font = Enum.Font.GothamBold
minusBtn.TextSize = 16
Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0,6)
minusBtn.MouseButton1Click:Connect(function()
    speedMultiplier = math.max(1, speedMultiplier - 1)
    local percent = (speedMultiplier - 1) / 2
    updateSpeedFromPercent(percent)
end)

local plusBtn = Instance.new("TextButton", contentFI)
plusBtn.Size = UDim2.new(0,25,0,25)
plusBtn.Position = UDim2.new(1,-35,0,155)
plusBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
plusBtn.Text = "+"
plusBtn.TextColor3 = Color3.new(1,1,1)
plusBtn.Font = Enum.Font.GothamBold
plusBtn.TextSize = 16
Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0,6)
plusBtn.MouseButton1Click:Connect(function()
    speedMultiplier = math.min(3, speedMultiplier + 1)
    local percent = (speedMultiplier - 1) / 2
    updateSpeedFromPercent(percent)
end)

-- INFO
local speedInfo = Instance.new("TextLabel", contentFI)
speedInfo.Size = UDim2.new(1,-20,0,20)
speedInfo.Position = UDim2.new(0,10,0,220)
speedInfo.BackgroundTransparency = 1
speedInfo.TextColor3 = Color3.fromRGB(150,150,150)
speedInfo.Text = "🐌 Speed: 40/50/60 studs/s"
speedInfo.Font = Enum.Font.Gotham
speedInfo.TextSize = 11
speedInfo.TextXAlignment = Enum.TextXAlignment.Left

local voidInfo = Instance.new("TextLabel", contentFI)
voidInfo.Size = UDim2.new(1,-20,0,20)
voidInfo.Position = UDim2.new(0,10,0,240)
voidInfo.BackgroundTransparency = 1
voidInfo.TextColor3 = Color3.fromRGB(100,255,100)
voidInfo.Text = "🛡️ Anti Void Aktif"
voidInfo.Font = Enum.Font.Gotham
voidInfo.TextSize = 11
voidInfo.TextXAlignment = Enum.TextXAlignment.Left

local wilayahLabel = Instance.new("TextLabel", contentFI)
wilayahLabel.Size = UDim2.new(1,-20,0,20)
wilayahLabel.Position = UDim2.new(0,10,0,260)
wilayahLabel.BackgroundTransparency = 1
wilayahLabel.TextColor3 = Color3.fromRGB(255,200,0)
wilayahLabel.Text = "🔴 MERAH (X<2250) | 🔵 BIRU (X>2250)"
wilayahLabel.Font = Enum.Font.GothamBold
wilayahLabel.TextSize = 11
wilayahLabel.TextXAlignment = Enum.TextXAlignment.Left

local blockLabel = Instance.new("TextLabel", contentFI)
blockLabel.Size = UDim2.new(1,-20,0,20)
blockLabel.Position = UDim2.new(0,10,0,280)
blockLabel.BackgroundTransparency = 1
blockLabel.TextColor3 = Color3.fromRGB(0,255,255)
blockLabel.Text = "🧱 Block di Y = -12.00 | Turun ke -8.59"
blockLabel.Font = Enum.Font.Gotham
blockLabel.TextSize = 11
blockLabel.TextXAlignment = Enum.TextXAlignment.Left

--===================================
-- FINAL EXECUTION
--===================================
print("😈😈😈 LOADING GUIS...")
print("😈 ESCAPE TSUNAMI: X-RAY BLOCK (Y = -12.00)")
print("😈 FIRE VS ICE: 🔴 FIRE & 🔵 ICE BISA JALAN BARENG!")
print("😈 ⬇️ Turun ke Y = -8.59 dulu")
print("😈 Tunggu sebentar...")
task.wait(0.5)

print("😈😈😈 KEDUA GUI SIAP!")
print("😈 Escape Tsunami di KIRI, Fire VS Ice di KANAN")
print("😈 ✅ 2 TOMBOL BISA DINYALAIN BARENG!")
print("😈 🔴 FIRE (X<2250) | 🔵 ICE (X>2250)")
print("😈 ⬇️ Turun ke Y = -8.59")
print("😈 🧱 X-RAY Block 90% di Y = -12.00")
print("😈 Selamat menggunakan Fathir! 😈🔥")
