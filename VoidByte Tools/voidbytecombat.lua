if not game:IsLoaded() then
    game.Loaded:Wait()
end

local env = getfenv()
local genv = (typeof(getgenv) == "function" and getgenv()) or env
local function getGlobal(name: string): any
    local val = nil
    pcall(function()
        if genv and genv[name] ~= nil then
            val = genv[name]
        elseif (env :: any)[name] ~= nil then
            val = (env :: any)[name]
        end
    end)
    return val
end

if genv and genv.ProjectDeltaUnload then
    pcall(genv.ProjectDeltaUnload)
end
pcall(function()
    game:GetService("RunService"):UnbindFromRenderStep("IdenticalMouseFree")
end)

local checkcaller    = getGlobal("checkcaller")
local hookfunction   = getGlobal("hookfunction")
local newcclosure    = getGlobal("newcclosure")
local getconnections = getGlobal("getconnections")
local getupvalues    = getGlobal("getupvalues")
local getupvalue     = getGlobal("getupvalue")
local gethui         = getGlobal("gethui")
local Drawing        = getGlobal("Drawing")
local readfile       = getGlobal("readfile")
local writefile      = getGlobal("writefile")
local isfile         = getGlobal("isfile")
local delfile        = getGlobal("delfile")
local makefolder     = getGlobal("makefolder")
local isfolder       = getGlobal("isfolder")

if not Drawing then
    pcall(function()
        Drawing = (getfenv() :: any).Drawing or (getgenv and getgenv().Drawing)
    end)
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local activeConnections: { RBXScriptConnection } = {}
local cleanUpInstances: { Instance } = {}
local cleanUpDrawings: { any } = {}
local hookedFunctions: { [any]: any } = {}
local cachedAmmoAttributes: { [Instance]: { [string]: any } } = {}
local isRunning = true

local function TrackConnection(conn: RBXScriptConnection): RBXScriptConnection
    table.insert(activeConnections, conn)
    return conn
end

local function TrackInstance<T>(inst: T): T
    table.insert(cleanUpInstances, inst :: any)
    return inst
end

local function TrackDrawing<T>(drawObj: T): T
    table.insert(cleanUpDrawings, drawObj)
    return drawObj
end

local function GetUIRoot(): Instance
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    return CoreGui:FindFirstChild("RobloxGui") or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
end
local RootContainer = GetUIRoot()

pcall(function()
    for _, container in ipairs({ RootContainer, CoreGui, CoreGui:FindFirstChild("RobloxGui"), LocalPlayer:FindFirstChild("PlayerGui") }) do
        if container then
            local old1 = container:FindFirstChild("Identical_ProjectDelta")
            if old1 then old1:Destroy() end
            local old2 = container:FindFirstChild("Identical_TargetInfo")
            if old2 then old2:Destroy() end
        end
    end
end)

local MainScreenGui = Instance.new("ScreenGui")
MainScreenGui.Name = "Identical_ProjectDelta"
MainScreenGui.ResetOnSpawn = false
MainScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainScreenGui.DisplayOrder = 999
pcall(function()
    MainScreenGui.IgnoreGuiInset = true
end)
MainScreenGui.Parent = RootContainer
TrackInstance(MainScreenGui)

local RootGui = MainScreenGui

local IdenticalTheme = {
    WindowBackground = Color3.fromRGB(12, 13, 16),
    Background       = Color3.fromRGB(12, 13, 16),
    Inline           = Color3.fromRGB(9, 10, 12),
    Card             = Color3.fromRGB(16, 18, 24),
    CardTop          = Color3.fromRGB(20, 23, 30),
    CardBottom       = Color3.fromRGB(14, 16, 21),
    CardBorder       = Color3.fromRGB(42, 48, 60),
    Border           = Color3.fromRGB(36, 42, 52),
    BorderLight      = Color3.fromRGB(56, 64, 80),
    Accent           = Color3.fromRGB(131, 194, 242),
    AccentLight      = Color3.fromRGB(165, 218, 255),
    AccentDark       = Color3.fromRGB(75, 140, 210),
    Text             = Color3.fromRGB(240, 244, 252),
    TextMuted        = Color3.fromRGB(195, 202, 215),
    TextDim          = Color3.fromRGB(140, 148, 162),
    Element          = Color3.fromRGB(20, 24, 31),
    ElementBorder    = Color3.fromRGB(48, 56, 70),
    ElementHover     = Color3.fromRGB(32, 38, 48),
    TextBorder       = Color3.fromRGB(0, 0, 0)
}
local IdenticalFont = Enum.Font.GothamMedium
local IdenticalBoldFont = Enum.Font.GothamBold
local CONFIG_FOLDER = "Identical"
local CONFIG_FILE = "Identical/ProjectDelta_Config.json"
local LEGACY_CONFIG_FILE = "ProjectDelta_Config.json"

local Config: { [string]: any } = {
    MenuKey = Enum.KeyCode.RightShift,
    UIEnabled = true,
    AutoSave = true,

    AimbotEnabled = false,
    AimbotKey = Enum.UserInputType.MouseButton2,
    AimbotBone = "Head",
    AimbotSmoothness = 1.0,
    AimbotFOV = 120,
    DrawFOV = false,
    FOVColor = IdenticalTheme.Accent,
    TargetNPCs = true,

    NoRecoil = false,
    NoSpread = false,
    NoDrag = false,
    NoDrop = false,
    InstantAim = false,

    PlayerESP = false,
    ESPBoxes = true,
    ESPHealthBar = true,
    ESPNames = true,
    ESPDistance = true,
    ESPTracers = false,
    ContainerESP = false,
    ContainerKey = Enum.KeyCode.P,
    ContainerMaxDist = 200,
    PlayerMaxDist = 2000,
    NPC_ESP = false,
    NPCMaxDist = 1500,
    Vehicle_ESP = false,
    VehicleMaxDist = 2000,
    DroppedItemESP = false,
    DroppedItemMaxDist = 300,

    BulletTracers = false,
    TracerColor = IdenticalTheme.Accent,
    HitMarkers = false,
    HitmarkerColor = Color3.fromRGB(255, 255, 255),
    HitSound = false,
    SelectedHitSound = "Skeet",
    HitSoundVolume = 3,
    HitLogsEnabled = false,
    HitLogsLifetime = 5,
    HitLogsSize = 13,
    HitLogsFont = "Monospace",

    ThirdPerson = false,
    ThirdPersonDist = 12,
    FullBright = false,
    ClockTime = 14,
    ClockTimeEnabled = false,
    RemoveGrass = false,
    RemoveFoliage = false,

    TargetHUDEnabled = true,
    InventoryViewerEnabled = true,

    HackerDetector = true,
    HackerSpeedThreshold = 35,
    HackerSpeedDuration = 0.8,
}

local uiUpdateCallbacks: { [string]: (any) -> () } = {}

local function SerializeConfig(): string
    local serializable: { [string]: any } = {}
    for k, v in pairs(Config) do
        if typeof(v) == "EnumItem" then
            serializable[k] = { _type = "EnumItem", enum = tostring(v.EnumType), name = v.Name }
        elseif typeof(v) == "Color3" then
            serializable[k] = { _type = "Color3", r = v.R, g = v.G, b = v.B }
        else
            serializable[k] = v
        end
    end
    return HttpService:JSONEncode(serializable)
end

local function SaveConfig(): boolean
    if not writefile then return false end
    local ok = pcall(function()
        if makefolder and isfolder and not isfolder(CONFIG_FOLDER) then
            pcall(makefolder, CONFIG_FOLDER)
        end
        writefile(CONFIG_FILE, SerializeConfig())
    end)
    return ok
end

local autoSaveDebounce = false
local function TriggerAutoSave()
    if not Config.AutoSave then return end
    if autoSaveDebounce then return end
    autoSaveDebounce = true
    task.delay(0.5, function()
        SaveConfig()
        autoSaveDebounce = false
    end)
end

local function LoadConfig(): boolean
    local targetPath = nil
    if isfile and isfile(CONFIG_FILE) then
        targetPath = CONFIG_FILE
    elseif isfile and isfile(LEGACY_CONFIG_FILE) then
        targetPath = LEGACY_CONFIG_FILE
    end
    if not targetPath or not readfile then return false end
    local ok, content = pcall(readfile, targetPath)
    if not ok or not content or content == "" then return false end

    local decodeOk, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not decodeOk or type(data) ~= "table" then return false end

    for k, v in pairs(data) do
        if type(v) == "table" and v._type == "EnumItem" then
            local enumType = (Enum :: any)[v.enum]
            if enumType and enumType[v.name] then
                Config[k] = enumType[v.name]
            end
        elseif type(v) == "table" and v._type == "Color3" then
            Config[k] = Color3.new(v.r, v.g, v.b)
        else
            Config[k] = v
        end
        if uiUpdateCallbacks[k] then
            pcall(uiUpdateCallbacks[k], Config[k])
        end
    end
    return true
end

local notifContainer = Instance.new("Frame")
notifContainer.Name = "IdenticalNotifs"
notifContainer.Size = UDim2.new(0, 260, 1, -20)
notifContainer.Position = UDim2.new(1, -270, 0, 10)
notifContainer.BackgroundTransparency = 1
notifContainer.Parent = RootGui
TrackInstance(notifContainer)

local notifLayout = Instance.new("UIListLayout", notifContainer)
notifLayout.Padding = UDim.new(0, 6)
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

local function Notify(title: string, msg: string, color: Color3?, duration: number?)
    duration = duration or 3.5
    color = color or IdenticalTheme.Accent

    local card = Instance.new("Frame", notifContainer)
    card.Size = UDim2.new(1, 0, 0, 24)
    card.BackgroundColor3 = IdenticalTheme.Card
    card.BorderSizePixel = 0

    local cardGrad = Instance.new("UIGradient", card)
    cardGrad.Rotation = 90
    cardGrad.Color = ColorSequence.new(IdenticalTheme.CardTop, IdenticalTheme.CardBottom)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color = IdenticalTheme.CardBorder
    stroke.Thickness = 1

    local bar = Instance.new("Frame", card)
    bar.Size = UDim2.new(1, 0, 0, 2)
    bar.Position = UDim2.new(0, 0, 1, -2)
    bar.BackgroundColor3 = color
    bar.BorderSizePixel = 0

    local lbl = Instance.new("TextLabel", card)
    lbl.Size = UDim2.new(1, -12, 1, -2)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = IdenticalFont
    lbl.Text = string.format("[%s] %s", title, msg)
    lbl.TextColor3 = IdenticalTheme.Text
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    task.delay(duration, function()
        if not card or not card.Parent then return end
        local tw = TweenService:Create(card, TweenInfo.new(0.2), {BackgroundTransparency = 1})
        tw:Play()
        tw.Completed:Connect(function() card:Destroy() end)
    end)
end

local watermarkFrame = Instance.new("Frame")
watermarkFrame.Name = "IdenticalWatermark"
watermarkFrame.Size = UDim2.new(0, 275, 0, 22)
watermarkFrame.Position = UDim2.new(1, -290, 0, 8)
watermarkFrame.BackgroundColor3 = IdenticalTheme.Card
watermarkFrame.BorderSizePixel = 0
watermarkFrame.Parent = RootGui
TrackInstance(watermarkFrame)

local wmGrad = Instance.new("UIGradient", watermarkFrame)
wmGrad.Rotation = 90
wmGrad.Color = ColorSequence.new(IdenticalTheme.CardTop, IdenticalTheme.CardBottom)

local wmStroke = Instance.new("UIStroke", watermarkFrame)
wmStroke.Color = IdenticalTheme.CardBorder
wmStroke.Thickness = 1

local wmLiner = Instance.new("Frame", watermarkFrame)
wmLiner.Size = UDim2.new(1, 0, 0, 2)
wmLiner.Position = UDim2.new(0, 0, 0, 0)
wmLiner.BackgroundColor3 = IdenticalTheme.Accent
wmLiner.BorderSizePixel = 0

local wmLabel = Instance.new("TextLabel", watermarkFrame)
wmLabel.Size = UDim2.new(1, -12, 1, -2)
wmLabel.Position = UDim2.new(0, 8, 0, 1)
wmLabel.BackgroundTransparency = 1
wmLabel.Font = IdenticalFont
wmLabel.Text = string.format("identical | %s | %s", os.date("%b %d %Y"), LocalPlayer.Name)
wmLabel.TextColor3 = IdenticalTheme.Text
wmLabel.TextSize = 11
wmLabel.TextXAlignment = Enum.TextXAlignment.Left

local frameCount = 0
local lastFpsCheck = tick()
TrackConnection(RunService.RenderStepped:Connect(function()
    frameCount += 1
    local now = tick()
    if now - lastFpsCheck >= 1.0 then
        local fps = math.round(frameCount / (now - lastFpsCheck))
        frameCount = 0
        lastFpsCheck = now
        wmLabel.Text = string.format("identical | %s | %d fps | %s", os.date("%b %d %Y"), fps, os.date("%H:%M:%S"))
    end
end))

local function GetEquippedItem(char: Model?): string
    if not char then return "None" end

    local holdingObj = char:FindFirstChild("Holding")
    if holdingObj and holdingObj:IsA("ObjectValue") and holdingObj.Value then
        return holdingObj.Value.Name
    end

    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Model") and not c.Name:find("Shirt") and not c.Name:find("Pants") 
           and not c.Name:find("Helmet") and not c.Name:find("Vest") and not c.Name:find("Backpack") 
           and not c.Name:find("Armor") and not c.Name:find("Gloves") and not c.Name:find("Rig") 
           and not c.Name:find("Bandoiler") and not c.Name:find("Smersh") and not c.Name:find("Tortilla")
           and not c.Name:find("Wraps") and not c.Name:find("Cap") and not c.Name:find("Hood") 
           and not c.Name:find("Knee") and not c.Name:find("Mask") and not c.Name:find("Torso")
           and not c.Name:find("Legs") and not c.Name:find("Boots") and not c.Name:find("Hand") then
            if c:FindFirstChild("ItemProperties") or c:FindFirstChild("Handle") or c:FindFirstChild("Barrel") or c:FindFirstChild("Blade") or c:FindFirstChild("Receiver") or c:FindFirstChild("Part") then
                return c.Name
            end
        end
    end

    local tool = char:FindFirstChildOfClass("Tool")
    if tool then return tool.Name end

    return "None"
end

local ValueCache: { [string]: number } = {
    ["6B45"] = 16, ["AS Val"] = 16, ["ATC Key"] = 4, ["Airfield Key"] = 6, ["Altyn"] = 16,
    ["Altyn Visor"] = 8, ["Attak-5 60L"] = 16, ["Bolts"] = 1, ["Crane Key"] = 6, ["DAGR"] = 8,
    ["Duct Tape"] = 1, ["Fast MT"] = 10, ["Flare Gun"] = 8, ["Fueling Station Key"] = 4,
    ["Garage Key"] = 4, ["Hammer"] = 1, ["JPC"] = 10, ["Lighthouse Key"] = 6, ["M4A1"] = 12,
    ["Nails"] = 1, ["Nuts"] = 1, ["Saiga 12"] = 8, ["Super Glue"] = 1, ["Village Key"] = 4, ["Wrench"] = 1
}

local ValueTiers = {
    { Min = 32, Color = Color3.fromRGB(248, 113, 113) },
    { Min = 16, Color = Color3.fromRGB(251, 146, 60) },
    { Min = 8,  Color = Color3.fromRGB(168, 85, 247) },
    { Min = 4,  Color = Color3.fromRGB(52, 211, 153) },
    { Min = 0,  Color = Color3.fromRGB(220, 220, 220) },
}

local function GetItemColor(val: number): Color3
    for _, tier in ipairs(ValueTiers) do
        if val >= tier.Min then return tier.Color end
    end
    return Color3.fromRGB(220, 220, 220)
end

local ValidItemNames: { [string]: boolean } = {}
local ItemIcons: { [string]: string } = {}
local ValidNPCNames: { [string]: boolean } = {}
local ValidVehicleNames: { [string]: boolean } = {}

local function CacheProjectDeltaData()
    task.spawn(function()
        local RS = ReplicatedStorage
        local blacklist = {
            "MeshPart", "Part", "UnionOperation", "Weld", "WeldConstraint", "Mesh", "SpecialMesh",
            "HelmetMask", "Harness", "UT", "Hood", "RL", "LU", "RU", "LL", "RA", "LA", "TR", "HD",
            "Handle", "Casing", "ItemProperties", "Folder", "Configuration", "Model", "SelectionBox",
            "SurfaceAppearance", "Texture", "Decal"
        }

        local itemContainers = { RS:FindFirstChild("ItemsList"), RS:FindFirstChild("ItemsListModels") }
        for _, container in ipairs(itemContainers) do
            if container then
                for _, obj in ipairs(container:GetChildren()) do
                    if not table.find(blacklist, obj.Name) then
                        ValidItemNames[obj.Name] = true
                        local props = obj:FindFirstChild("ItemProperties")
                        if props then
                            local icon = props:FindFirstChild("ItemIcon")
                            if icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) then
                                ItemIcons[obj.Name] = (icon :: any).Image
                                local callSign = props:GetAttribute("CallSign")
                                if callSign then
                                    ItemIcons[tostring(callSign)] = (icon :: any).Image
                                end
                            end
                        end
                    end
                end
            end
        end

        local presets = RS:FindFirstChild("AiPresets")
        if presets then
            for _, v in ipairs(presets:GetChildren()) do
                ValidNPCNames[v.Name] = true
            end
        end

        local vehicles = RS:FindFirstChild("Vehicles")
        if vehicles then
            for _, v in ipairs(vehicles:GetChildren()) do
                ValidVehicleNames[v.Name] = true
            end
        end
    end)
end
CacheProjectDeltaData()


local function ScanTargetInventory(target: Player | Model): {string}
    local items: {string} = {}
    local targetPlayer = if target:IsA("Player") then target else Players:GetPlayerFromCharacter(target)

    if targetPlayer then
        local rsPlayers = ReplicatedStorage:FindFirstChild("Players")
        local playerFolder = rsPlayers and rsPlayers:FindFirstChild(targetPlayer.Name)
        local invFolder = playerFolder and playerFolder:FindFirstChild("Inventory")
        if invFolder then
            for _, itemObj in ipairs(invFolder:GetChildren()) do
                local itemName: string? = nil
                if itemObj:IsA("ObjectValue") and itemObj.Value then
                    local targetModel = itemObj.Value
                    local props = targetModel:FindFirstChild("ItemProperties")
                    itemName = (props and tostring(props:GetAttribute("CallSign") or props:GetAttribute("ItemName"))) or targetModel.Name
                    if not ItemIcons[itemName or ""] and props and props:FindFirstChild("ItemIcon") then
                        local icon = props:FindFirstChild("ItemIcon") :: any
                        ItemIcons[itemName or ""] = icon.Image
                    end
                else
                    local props = itemObj:FindFirstChild("ItemProperties")
                    itemName = (props and tostring(props:GetAttribute("CallSign"))) or tostring(itemObj:GetAttribute("CallSign")) or itemObj.Name
                end
                if itemName and not table.find(items, itemName) then
                    table.insert(items, itemName)
                end
            end
        end
    end

    local char = if target:IsA("Player") then target.Character else target
    if char and char:IsA("Model") then
        local held = GetEquippedItem(char)
        if held ~= "None" and not table.find(items, held) then
            table.insert(items, held)
        end
    end

    return items
end

local trackedNPCs: { [Model]: boolean } = {}

local function IsAlive(player: Player): boolean
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    return hum ~= nil and root ~= nil and hum.Health > 0
end

local function GetClosestPlayerToMouse(maxFov: number?): (any, Vector3?, Vector3?)
    local shortestDist = maxFov or math.huge
    local bestTarget: any = nil
    local bestPos: Vector3? = nil
    local bestRawPos: Vector3? = nil
    local mousePos = UserInputService:GetMouseLocation()

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsAlive(p) and p.Character then
            local bone = p.Character:FindFirstChild(Config.AimbotBone) or p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
            if bone and bone:IsA("BasePart") then
                local sPos, onScreen = Camera:WorldToViewportPoint(bone.Position)
                if onScreen then
                    local screenVec = Vector2.new(sPos.X, sPos.Y)
                    local dist = (mousePos - screenVec).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        bestTarget = p
                        bestRawPos = bone.Position
                        bestPos = bone.Position
                    end
                end
            end
        end
    end

    if Config.TargetNPCs then
        for npc, _ in pairs(trackedNPCs) do
            if npc and npc.Parent and npc:IsA("Model") then
                local hum = npc:FindFirstChildOfClass("Humanoid")
                local isVendor = npc:GetAttribute("Interaction") ~= nil or npc:FindFirstChild("faceTarget") ~= nil
                if hum and hum.Health > 0 and not isVendor then
                    local bone = npc:FindFirstChild(Config.AimbotBone) or npc:FindFirstChild("Head") or npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
                    if bone and bone:IsA("BasePart") then
                        local sPos, onScreen = Camera:WorldToViewportPoint(bone.Position)
                        if onScreen then
                            local screenVec = Vector2.new(sPos.X, sPos.Y)
                            local dist = (mousePos - screenVec).Magnitude
                            if dist < shortestDist then
                                shortestDist = dist
                                bestTarget = npc
                                bestRawPos = bone.Position
                                bestPos = bone.Position
                            end
                        end
                    end
                end
            end
        end
    end

    return bestTarget, bestPos, bestRawPos
end

local function ApplyAmmoMods()
    local ammoTypes = ReplicatedStorage:FindFirstChild("AmmoTypes")
    if not ammoTypes then return end

    for _, ammo in ipairs(ammoTypes:GetChildren()) do
        if not cachedAmmoAttributes[ammo] then
            cachedAmmoAttributes[ammo] = {
                Recoil = ammo:GetAttribute("RecoilStrength") :: number?,
                Drop = ammo:GetAttribute("ProjectileDrop") :: number?,
                Drag = ammo:GetAttribute("Drag") :: number?
            }
        end

        local original = cachedAmmoAttributes[ammo]
        if Config.NoRecoil then
            ammo:SetAttribute("RecoilStrength", 0)
        elseif original.Recoil ~= nil then
            ammo:SetAttribute("RecoilStrength", original.Recoil)
        end

        if Config.NoDrop then
            ammo:SetAttribute("ProjectileDrop", 0)
        elseif original.Drop ~= nil then
            ammo:SetAttribute("ProjectileDrop", original.Drop)
        end

        if Config.NoDrag then
            ammo:SetAttribute("Drag", 0)
        elseif original.Drag ~= nil then
            ammo:SetAttribute("Drag", original.Drag)
        end
    end
end

local function RestoreAmmoMods()
    for ammo, original in pairs(cachedAmmoAttributes) do
        if ammo and ammo.Parent then
            if original.Recoil ~= nil then ammo:SetAttribute("RecoilStrength", original.Recoil) end
            if original.Drop ~= nil then ammo:SetAttribute("ProjectileDrop", original.Drop) end
            if original.Drag ~= nil then ammo:SetAttribute("Drag", original.Drag) end
        end
    end
end

local isAimbotActive = false
TrackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Config.AimbotKey or input.KeyCode == Config.AimbotKey then
        isAimbotActive = true
    end
end))

TrackConnection(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Config.AimbotKey or input.KeyCode == Config.AimbotKey then
        isAimbotActive = false
    end
end))

TrackConnection(RunService.RenderStepped:Connect(function()
    if not isRunning then return end
    ApplyAmmoMods()

    if Config.AimbotEnabled and isAimbotActive then
        local targetPlr, targetPos = GetClosestPlayerToMouse(Config.AimbotFOV)
        if targetPlr and targetPos then
            local currentCF = Camera.CFrame
            local targetCF = CFrame.new(currentCF.Position, targetPos)
            local smoothFactor = math.clamp(0.2 / math.max(Config.AimbotSmoothness, 0.05), 0.02, 1.0)
            Camera.CFrame = currentCF:Lerp(targetCF, smoothFactor)
        end
    end
end))

local aimbotFovCircle = (Drawing and Drawing.new("Circle")) :: any
if aimbotFovCircle then
    aimbotFovCircle.Thickness = 1
    aimbotFovCircle.NumSides = 48
    aimbotFovCircle.Filled = false
    aimbotFovCircle.Transparency = 0.8
    aimbotFovCircle.Color = IdenticalTheme.Accent
    TrackDrawing(aimbotFovCircle)

    TrackConnection(RunService.RenderStepped:Connect(function()
        if isRunning and Config.DrawFOV and Config.AimbotEnabled and not isUIVisible then
            local mouseLoc = UserInputService:GetMouseLocation()
            aimbotFovCircle.Visible = true
            aimbotFovCircle.Position = mouseLoc
            aimbotFovCircle.Radius = Config.AimbotFOV
            aimbotFovCircle.Color = Config.FOVColor
        else
            aimbotFovCircle.Visible = false
        end
    end))
end

local mainFrame: Frame? = nil
local targetMainFrame: Frame? = nil
local TargetInfoGui: ScreenGui? = nil
local isUIVisible = true
local ToggleUI: ((boolean?) -> ())? = nil

local function IsInsideRect(pt: Vector2, rPos: Vector2, rSize: Vector2, pad: number?): boolean
    local p = pad or 0
    return pt.X >= (rPos.X - p) and pt.X <= (rPos.X + rSize.X + p)
       and pt.Y >= (rPos.Y - p) and pt.Y <= (rPos.Y + rSize.Y + p)
end

local function RectsOverlap(posA: Vector2, sizeA: Vector2, posB: Vector2, sizeB: Vector2, pad: number?): boolean
    local p = pad or 0
    return (posA.X < posB.X + sizeB.X + p) and (posA.X + sizeA.X > posB.X - p)
       and (posA.Y < posB.Y + sizeB.Y + p) and (posA.Y + sizeA.Y > posB.Y - p)
end

local function IsOccludedByUI(screenPos: Vector2, elemSize: Vector2?): boolean
    if isUIVisible and mainFrame and mainFrame.Visible then
        local mPos = mainFrame.AbsolutePosition
        local mSize = mainFrame.AbsoluteSize
        if elemSize then
            if RectsOverlap(screenPos, elemSize, mPos, mSize, 12) then return true end
        else
            if IsInsideRect(screenPos, mPos, mSize, 35) then return true end
        end
    end
    if TargetInfoGui and TargetInfoGui.Enabled and targetMainFrame and targetMainFrame.Visible then
        local tPos = targetMainFrame.AbsolutePosition
        local tSize = targetMainFrame.AbsoluteSize
        if elemSize then
            if RectsOverlap(screenPos, elemSize, tPos, tSize, 10) then return true end
        else
            if IsInsideRect(screenPos, tPos, tSize, 25) then return true end
        end
    end
    return false
end

local playerEspDrawings: { [Player]: { Box: any, HealthBar: any, NameText: any, DistText: any, Tracer: any } } = {}

local function CreatePlayerEsp(p: Player)
    if not Drawing or playerEspDrawings[p] then return end
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = IdenticalTheme.Accent
    box.Visible = false
    TrackDrawing(box)

    local hpBar = Drawing.new("Line")
    hpBar.Thickness = 2
    hpBar.Color = Color3.fromRGB(0, 255, 120)
    hpBar.Visible = false
    TrackDrawing(hpBar)

    local nameText = Drawing.new("Text")
    nameText.Size = 12
    nameText.Font = 2
    nameText.Center = true
    nameText.Outline = true
    nameText.Color = IdenticalTheme.Text
    nameText.Visible = false
    TrackDrawing(nameText)

    local distText = Drawing.new("Text")
    distText.Size = 11
    distText.Font = 2
    distText.Center = true
    distText.Outline = true
    distText.Color = IdenticalTheme.TextMuted
    distText.Visible = false
    TrackDrawing(distText)

    local tracer = Drawing.new("Line")
    tracer.Thickness = 1
    tracer.Color = IdenticalTheme.Accent
    tracer.Visible = false
    TrackDrawing(tracer)

    playerEspDrawings[p] = { Box = box, HealthBar = hpBar, NameText = nameText, DistText = distText, Tracer = tracer }
end

local function RemovePlayerEsp(p: Player)
    local esp = playerEspDrawings[p]
    if esp then
        pcall(function() esp.Box:Remove() end)
        pcall(function() esp.HealthBar:Remove() end)
        pcall(function() esp.NameText:Remove() end)
        pcall(function() esp.DistText:Remove() end)
        pcall(function() esp.Tracer:Remove() end)
        playerEspDrawings[p] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then CreatePlayerEsp(p) end
end
TrackConnection(Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then CreatePlayerEsp(p) end
end))
TrackConnection(Players.PlayerRemoving:Connect(RemovePlayerEsp))

TrackConnection(RunService.RenderStepped:Connect(function()
    if not isRunning or not Config.PlayerESP then
        for _, esp in pairs(playerEspDrawings) do
            esp.Box.Visible = false
            esp.HealthBar.Visible = false
            esp.NameText.Visible = false
            esp.DistText.Visible = false
            esp.Tracer.Visible = false
        end
        return
    end

    local cam = Workspace.CurrentCamera or Camera
    Camera = cam

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not myRoot then
        for _, esp in pairs(playerEspDrawings) do
            esp.Box.Visible = false
            esp.HealthBar.Visible = false
            esp.NameText.Visible = false
            esp.DistText.Visible = false
            esp.Tracer.Visible = false
        end
        return
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not playerEspDrawings[p] then
            CreatePlayerEsp(p)
        end
    end

    for p, esp in pairs(playerEspDrawings) do
        local char = p.Character
        local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if char and root and hum and hum.Health > 0 then
            local dist = (root.Position - myRoot.Position).Magnitude
            if dist <= Config.PlayerMaxDist then
                local rootPos, onScreen = cam:WorldToViewportPoint(root.Position)
                if onScreen and rootPos.Z > 0 then
                    local head = char:FindFirstChild("Head") :: BasePart?
                    local headWorld = if head then head.Position + Vector3.new(0, 0.6, 0) else root.Position + Vector3.new(0, 2.5, 0)
                    local legWorld = root.Position - Vector3.new(0, 3.0, 0)

                    local headPos = cam:WorldToViewportPoint(headWorld)
                    local legPos = cam:WorldToViewportPoint(legWorld)

                    local height = math.abs(legPos.Y - headPos.Y)
                    local width = height * 0.55
                    local topY = math.min(headPos.Y, legPos.Y)
                    local topLeft = Vector2.new(rootPos.X - width * 0.5, topY)

                    local isOccluded = IsOccludedByUI(topLeft, Vector2.new(width, height)) or IsOccludedByUI(Vector2.new(rootPos.X, rootPos.Y))

                    if not isOccluded and Config.ESPBoxes then
                        esp.Box.Visible = true
                        esp.Box.Size = Vector2.new(width, height)
                        esp.Box.Position = topLeft
                        esp.Box.Color = IdenticalTheme.Accent
                    else
                        esp.Box.Visible = false
                    end

                    if not isOccluded and Config.ESPHealthBar then
                        esp.HealthBar.Visible = true
                        local hpRatio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                        esp.HealthBar.From = Vector2.new(topLeft.X - 4, topY + height)
                        esp.HealthBar.To = Vector2.new(topLeft.X - 4, topY + (height * (1 - hpRatio)))
                        esp.HealthBar.Color = Color3.fromRGB(math.floor(255 * (1 - hpRatio)), math.floor(255 * hpRatio), 40)
                    else
                        esp.HealthBar.Visible = false
                    end

                    if not isOccluded and Config.ESPNames then
                        esp.NameText.Visible = true
                        esp.NameText.Text = p.Name
                        esp.NameText.Position = Vector2.new(rootPos.X, topY - 14)
                    else
                        esp.NameText.Visible = false
                    end

                    if not isOccluded and Config.ESPDistance then
                        esp.DistText.Visible = true
                        esp.DistText.Text = string.format("%d studs", math.round(dist))
                        esp.DistText.Position = Vector2.new(rootPos.X, topY + height + 2)
                    else
                        esp.DistText.Visible = false
                    end

                    if not isOccluded and Config.ESPTracers then
                        esp.Tracer.Visible = true
                        esp.Tracer.From = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y)
                        esp.Tracer.To = Vector2.new(rootPos.X, topY + height)
                        esp.Tracer.Color = IdenticalTheme.Accent
                    else
                        esp.Tracer.Visible = false
                    end
                else
                    esp.Box.Visible = false
                    esp.HealthBar.Visible = false
                    esp.NameText.Visible = false
                    esp.DistText.Visible = false
                    esp.Tracer.Visible = false
                end
            else
                esp.Box.Visible = false
                esp.HealthBar.Visible = false
                esp.NameText.Visible = false
                esp.DistText.Visible = false
                esp.Tracer.Visible = false
            end
        else
            esp.Box.Visible = false
            esp.HealthBar.Visible = false
            esp.NameText.Visible = false
            esp.DistText.Visible = false
            esp.Tracer.Visible = false
        end
    end
end))

local activeWorldDrawings: { [Instance]: any } = {}

local function ClearWorldDrawing(inst: Instance)
    if activeWorldDrawings[inst] then
        pcall(function() activeWorldDrawings[inst]:Remove() end)
        activeWorldDrawings[inst] = nil
    end
end

local function TrackContainer(container: Instance)
    if not Drawing or activeWorldDrawings[container] or not container:IsA("Model") then return end
    local prim = container.PrimaryPart or container:FindFirstChildWhichIsA("BasePart")
    if not prim then return end

    local text = Drawing.new("Text")
    TrackDrawing(text)
    text.Center = true
    text.Font = 2
    text.Outline = true
    text.Size = 12
    text.Visible = false
    activeWorldDrawings[container] = text

    local conn: RBXScriptConnection?
    conn = TrackConnection(RunService.RenderStepped:Connect(function()
        if not isRunning or not Config.ContainerESP or not container.Parent then
            text.Visible = false
            return
        end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
        local cPart = container.PrimaryPart or prim
        if not root or not cPart or not cPart.Parent then
            text.Visible = false
            return
        end

        local dist = (cPart.Position - root.Position).Magnitude
        if dist > (Config.ContainerMaxDist or 300) then
            text.Visible = false
            return
        end

        local sPos, onScreen = Camera:WorldToViewportPoint(cPart.Position)
        if not onScreen or sPos.Z <= 0 or (Config.HideESPInMenu and isUIVisible) or IsOccludedByUI(Vector2.new(sPos.X, sPos.Y)) then
            text.Visible = false
            return
        end

        local inv = container:FindFirstChild("Inventory")
        local totalPrice, totalVal, lootSummary = 0, 0, ""
        if inv then
            for _, item in ipairs(inv:GetChildren()) do
                local props = item:FindFirstChild("ItemProperties")
                if props then
                    local callSign = props:GetAttribute("CallSign") or item.Name
                    local amount = props:GetAttribute("Amount") or 1
                    totalPrice += (props:GetAttribute("Price") or 0)
                    totalVal += ((ValueCache[callSign] or 0) * amount)
                    lootSummary = lootSummary .. string.format("\n• %s (x%d)", callSign, amount)
                end
            end
        end

        local nextSpawn = (container:GetAttribute("NextSpawn") or 0) - os.time()
        local nameStr = container:GetAttribute("DisplayName") or container.Name
        local spawnStr = if nextSpawn > 0 then string.format(" [Respawn: %ds]", nextSpawn) else ""

        text.Color = GetItemColor(totalVal)
        text.Position = Vector2.new(sPos.X, sPos.Y)
        text.Text = string.format("[BOX] %s ($%d)%s%s\n%d studs", nameStr, totalPrice, spawnStr, lootSummary, math.round(dist))
        text.Visible = true
    end))

    container.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if conn then conn:Disconnect() end
            ClearWorldDrawing(container)
        end
    end)
end

local npcEspDrawings: { [Model]: { Box: any, HealthBar: any, NameText: any, DistText: any, Tracer: any } } = {}

local function CreateNpcEsp(npc: Model)
    if not Drawing or npcEspDrawings[npc] then return end

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = Color3.fromRGB(255, 80, 80)
    box.Visible = false
    TrackDrawing(box)

    local hpBar = Drawing.new("Line")
    hpBar.Thickness = 2
    hpBar.Color = Color3.fromRGB(0, 255, 120)
    hpBar.Visible = false
    TrackDrawing(hpBar)

    local nameText = Drawing.new("Text")
    nameText.Size = 12
    nameText.Font = 2
    nameText.Center = true
    nameText.Outline = true
    nameText.Color = IdenticalTheme.Text
    nameText.Visible = false
    TrackDrawing(nameText)

    local distText = Drawing.new("Text")
    distText.Size = 11
    distText.Font = 2
    distText.Center = true
    distText.Outline = true
    distText.Color = IdenticalTheme.TextMuted
    distText.Visible = false
    TrackDrawing(distText)

    local tracer = Drawing.new("Line")
    tracer.Thickness = 1
    tracer.Color = Color3.fromRGB(255, 80, 80)
    tracer.Visible = false
    TrackDrawing(tracer)

    npcEspDrawings[npc] = { Box = box, HealthBar = hpBar, NameText = nameText, DistText = distText, Tracer = tracer }
end

local function RemoveNpcEsp(npc: Instance)
    local esp = npcEspDrawings[npc :: Model]
    if esp then
        pcall(function() esp.Box:Remove() end)
        pcall(function() esp.HealthBar:Remove() end)
        pcall(function() esp.NameText:Remove() end)
        pcall(function() esp.DistText:Remove() end)
        pcall(function() esp.Tracer:Remove() end)
        npcEspDrawings[npc :: Model] = nil
    end
    ClearWorldDrawing(npc)
    if npc:IsA("Model") then
        trackedNPCs[npc] = nil
    end
end

local function TrackExplosiveOrPart(part: BasePart)
    if not Drawing or activeWorldDrawings[part] then return end
    local text = Drawing.new("Text")
    TrackDrawing(text)
    text.Center = true
    text.Font = 2
    text.Outline = true
    text.Size = 12
    text.Visible = false
    text.Color = Color3.fromRGB(255, 200, 50)
    activeWorldDrawings[part] = text

    local conn: RBXScriptConnection?
    conn = TrackConnection(RunService.RenderStepped:Connect(function()
        if not isRunning or not Config.NPC_ESP or not part.Parent then
            text.Visible = false
            return
        end

        local char = LocalPlayer.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not myRoot or not part.Parent then
            text.Visible = false
            return
        end

        local dist = (part.Position - myRoot.Position).Magnitude
        if dist > (Config.NPCMaxDist or 1500) then
            text.Visible = false
            return
        end

        local sPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen or sPos.Z <= 0 or (Config.HideESPInMenu and isUIVisible) or IsOccludedByUI(Vector2.new(sPos.X, sPos.Y)) then
            text.Visible = false
            return
        end

        text.Position = Vector2.new(sPos.X, sPos.Y)
        text.Text = string.format("[EXPLOSIVE] %s\n%d studs", part.Name, math.round(dist))
        text.Visible = true
    end))

    part.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if conn then conn:Disconnect() end
            ClearWorldDrawing(part)
        end
    end)
end

local function TrackNPC(npc: Instance)
    if npc:IsA("Model") then
        trackedNPCs[npc] = true
        CreateNpcEsp(npc)
        npc.AncestryChanged:Connect(function(_, parent)
            if not parent then
                RemoveNpcEsp(npc)
            end
        end)
    elseif npc:IsA("BasePart") then
        TrackExplosiveOrPart(npc)
    end
end

TrackConnection(RunService.RenderStepped:Connect(function()
    if not isRunning or not Config.NPC_ESP then
        for _, esp in pairs(npcEspDrawings) do
            esp.Box.Visible = false
            esp.HealthBar.Visible = false
            esp.NameText.Visible = false
            esp.DistText.Visible = false
            esp.Tracer.Visible = false
        end
        return
    end

    local cam = Workspace.CurrentCamera or Camera
    Camera = cam

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not myRoot then
        for _, esp in pairs(npcEspDrawings) do
            esp.Box.Visible = false
            esp.HealthBar.Visible = false
            esp.NameText.Visible = false
            esp.DistText.Visible = false
            esp.Tracer.Visible = false
        end
        return
    end

    for npc, _ in pairs(trackedNPCs) do
        if npc and npc.Parent and not npcEspDrawings[npc] then
            CreateNpcEsp(npc)
        end
    end

    for npc, esp in pairs(npcEspDrawings) do
        if not npc or not npc.Parent then
            RemoveNpcEsp(npc)
            continue
        end

        local root = npc.PrimaryPart or (npc:FindFirstChild("HumanoidRootPart") :: BasePart?) or (npc:FindFirstChild("Torso") :: BasePart?) or (npc:FindFirstChild("UpperTorso") :: BasePart?)
        local hum = npc:FindFirstChildOfClass("Humanoid")
        local head = npc:FindFirstChild("Head") :: BasePart?

        if not root and head then
            root = head
        end

        if root and hum and hum.Health > 0 then
            local dist = (root.Position - myRoot.Position).Magnitude
            if dist <= (Config.NPCMaxDist or 1500) then
                local rootPos, onScreen = cam:WorldToViewportPoint(root.Position)
                if onScreen and rootPos.Z > 0 then
                    local headWorld = if head then head.Position + Vector3.new(0, 0.6, 0) else root.Position + Vector3.new(0, 2.5, 0)
                    local foot = npc:FindFirstChild("LeftFoot") or npc:FindFirstChild("RightFoot") or npc:FindFirstChild("Left Leg") or npc:FindFirstChild("Right Leg")
                    local legWorld = if foot and foot:IsA("BasePart") then foot.Position - Vector3.new(0, 0.5, 0) else root.Position - Vector3.new(0, 3.0, 0)

                    local headPos = cam:WorldToViewportPoint(headWorld)
                    local legPos = cam:WorldToViewportPoint(legWorld)

                    local height = math.abs(legPos.Y - headPos.Y)
                    local width = height * 0.55
                    local topY = math.min(headPos.Y, legPos.Y)
                    local topLeft = Vector2.new(rootPos.X - width * 0.5, topY)

                    local isOccluded = (Config.HideESPInMenu and isUIVisible) or IsOccludedByUI(topLeft, Vector2.new(width, height)) or IsOccludedByUI(Vector2.new(rootPos.X, rootPos.Y))

                    local dispName = npc:GetAttribute("DisplayName")
                    local nameStr = (dispName and tostring(dispName)) or npc:GetAttribute("CallSign") or npc.Name
                    if dispName and dispName ~= npc.Name then
                        nameStr = string.format("%s (%s)", tostring(dispName), npc.Name)
                    end

                    local interaction = npc:GetAttribute("Interaction")
                    local tag = "[AI]"
                    local tagColor = Color3.fromRGB(255, 85, 85)

                    if interaction or npc:FindFirstChild("faceTarget") then
                        tag = "[VENDOR]"
                        tagColor = Color3.fromRGB(80, 220, 160)
                    elseif ValidNPCNames[npc.Name] or npc:GetAttribute("Preset") or npc.Name:find("AI") then
                        tag = "[AI]"
                        tagColor = Color3.fromRGB(255, 85, 85)
                    else
                        tag = "[AI]"
                        tagColor = Color3.fromRGB(255, 110, 90)
                    end

                    if not isOccluded and Config.ESPBoxes then
                        esp.Box.Visible = true
                        esp.Box.Size = Vector2.new(width, height)
                        esp.Box.Position = topLeft
                        esp.Box.Color = tagColor
                    else
                        esp.Box.Visible = false
                    end

                    if not isOccluded and Config.ESPHealthBar then
                        esp.HealthBar.Visible = true
                        local maxHp = math.max(hum.MaxHealth, 1)
                        local hpRatio = math.clamp(hum.Health / maxHp, 0, 1)
                        esp.HealthBar.From = Vector2.new(topLeft.X - 4, topY + height)
                        esp.HealthBar.To = Vector2.new(topLeft.X - 4, topY + (height * (1 - hpRatio)))
                        esp.HealthBar.Color = Color3.fromRGB(math.floor(255 * (1 - hpRatio)), math.floor(255 * hpRatio), 40)
                    else
                        esp.HealthBar.Visible = false
                    end

                    if not isOccluded and Config.ESPNames then
                        esp.NameText.Visible = true
                        esp.NameText.Text = string.format("%s %s", tag, nameStr)
                        esp.NameText.Position = Vector2.new(rootPos.X, topY - 14)
                        esp.NameText.Color = tagColor
                    else
                        esp.NameText.Visible = false
                    end

                    if not isOccluded and Config.ESPDistance then
                        esp.DistText.Visible = true
                        esp.DistText.Text = string.format("%d studs", math.round(dist))
                        esp.DistText.Position = Vector2.new(rootPos.X, topY + height + 2)
                    else
                        esp.DistText.Visible = false
                    end

                    if not isOccluded and Config.ESPTracers then
                        esp.Tracer.Visible = true
                        esp.Tracer.From = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y)
                        esp.Tracer.To = Vector2.new(rootPos.X, topY + height)
                        esp.Tracer.Color = tagColor
                    else
                        esp.Tracer.Visible = false
                    end
                else
                    esp.Box.Visible = false
                    esp.HealthBar.Visible = false
                    esp.NameText.Visible = false
                    esp.DistText.Visible = false
                    esp.Tracer.Visible = false
                end
            else
                esp.Box.Visible = false
                esp.HealthBar.Visible = false
                esp.NameText.Visible = false
                esp.DistText.Visible = false
                esp.Tracer.Visible = false
            end
        else
            esp.Box.Visible = false
            esp.HealthBar.Visible = false
            esp.NameText.Visible = false
            esp.DistText.Visible = false
            esp.Tracer.Visible = false
        end
    end
end))


local function TrackVehicle(veh: Instance)
    if not Drawing or activeWorldDrawings[veh] or not veh:IsA("Model") then return end
    local root = veh.PrimaryPart or veh:FindFirstChildWhichIsA("BasePart")
    if not root then return end

    local text = Drawing.new("Text")
    TrackDrawing(text)
    text.Center = true
    text.Font = 2
    text.Outline = true
    text.Size = 12
    text.Visible = false
    text.Color = Color3.fromRGB(255, 215, 0)
    activeWorldDrawings[veh] = text

    local conn: RBXScriptConnection?
    conn = TrackConnection(RunService.RenderStepped:Connect(function()
        if not isRunning or not veh.Parent or not Config.Vehicle_ESP then
            text.Visible = false
            return
        end

        local char = LocalPlayer.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not myRoot or not root or not root.Parent then
            text.Visible = false
            return
        end

        local dist = (root.Position - myRoot.Position).Magnitude
        if dist > (Config.VehicleMaxDist or 1500) then
            text.Visible = false
            return
        end

        local sPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen or sPos.Z <= 0 or (Config.HideESPInMenu and isUIVisible) or IsOccludedByUI(Vector2.new(sPos.X, sPos.Y)) then
            text.Visible = false
            return
        end

        text.Position = Vector2.new(sPos.X, sPos.Y)
        text.Text = string.format("[VEHICLE] %s\n%d studs", veh.Name, math.round(dist))
        text.Visible = true
    end))

    veh.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if conn then conn:Disconnect() end
            ClearWorldDrawing(veh)
        end
    end)
end

local function TrackDroppedItem(item: Instance)
    if not Drawing or activeWorldDrawings[item] or not item:IsA("Model") then return end
    local root = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
    if not root then return end

    local text = Drawing.new("Text")
    TrackDrawing(text)
    text.Center = true
    text.Font = 2
    text.Outline = true
    text.Size = 12
    text.Visible = false
    activeWorldDrawings[item] = text

    local conn: RBXScriptConnection?
    conn = TrackConnection(RunService.RenderStepped:Connect(function()
        if not isRunning or not item.Parent or not Config.DroppedItemESP then
            text.Visible = false
            return
        end

        local char = LocalPlayer.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not myRoot or not root or not root.Parent then
            text.Visible = false
            return
        end

        local dist = (root.Position - myRoot.Position).Magnitude
        if dist > (Config.DroppedItemMaxDist or 300) then
            text.Visible = false
            return
        end

        local sPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen or sPos.Z <= 0 or (Config.HideESPInMenu and isUIVisible) or IsOccludedByUI(Vector2.new(sPos.X, sPos.Y)) then
            text.Visible = false
            return
        end

        local callSign = item:GetAttribute("CallSign") or item.Name
        local val = ValueCache[callSign] or 0
        text.Color = GetItemColor(val)
        text.Position = Vector2.new(sPos.X, sPos.Y)
        text.Text = string.format("[ITEM] %s ($%d)\n%d studs", callSign, val, math.round(dist))
        text.Visible = true
    end))

    item.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if conn then conn:Disconnect() end
            ClearWorldDrawing(item)
        end
    end)
end

task.spawn(function()
    local function ScanObject(v: Instance)
        if not v or not v.Parent then return end
        if v:IsA("Humanoid") and v.Parent and v.Parent:IsA("Model") then
            local pModel = v.Parent
            local isPlr = Players:GetPlayerFromCharacter(pModel)
            if not isPlr and pModel.Name ~= LocalPlayer.Name and not pModel.Name:lower():find("viewmodel") then
                TrackNPC(pModel)
            end
            return
        end
        if v:IsA("Model") then
            local isPlr = Players:GetPlayerFromCharacter(v)
            if not isPlr and v.Name ~= LocalPlayer.Name and not v.Name:lower():find("viewmodel") then
                local hum = v:FindFirstChildOfClass("Humanoid")
                if not hum then
                    local nameLower = v.Name:lower()
                    if nameLower:find("crate") or nameLower:find("container") or nameLower:find("box") or nameLower:find("bag") or v:FindFirstChild("Inventory") then
                        TrackContainer(v)
                    end
                    if ValidVehicleNames[v.Name] or v:FindFirstChild("DriveSeat") or v:FindFirstChild("VehicleSeat") then
                        TrackVehicle(v)
                    end
                    local droppedFolder = Workspace:FindFirstChild("DroppedItems")
                    if (v.Parent == Workspace or (droppedFolder and v.Parent == droppedFolder))
                        and (v:GetAttribute("CallSign") or ValidItemNames[v.Name])
                        and not v:FindFirstChild("Inventory") then
                        TrackDroppedItem(v)
                    end
                    if ValidNPCNames[v.Name] or v:GetAttribute("Preset") or v:GetAttribute("Interaction") or v.Name:find("AI") then
                        TrackNPC(v)
                    end
                else
                    TrackNPC(v)
                end
            end
        elseif v:IsA("BasePart") then
            if v.Name:find("MON50") or v.Name:find("MINE") then
                TrackNPC(v)
            end
        end
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        ScanObject(obj)
    end
    TrackConnection(Workspace.DescendantAdded:Connect(ScanObject))

    local droppedFolder = Workspace:FindFirstChild("DroppedItems")
    if droppedFolder then
        for _, item in ipairs(droppedFolder:GetChildren()) do
            TrackDroppedItem(item)
        end
        TrackConnection(droppedFolder.ChildAdded:Connect(TrackDroppedItem))
    end
end)

TrackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Config.ContainerKey then
        Config.ContainerESP = not Config.ContainerESP
        Notify("ESP", if Config.ContainerESP then "Container ESP Enabled" else "Container ESP Disabled")
        if uiUpdateCallbacks["ContainerESP"] then
            uiUpdateCallbacks["ContainerESP"](Config.ContainerESP)
        end
    end
end))

local SoundIds = {
    Skeet = "rbxassetid://4817809188",
    Rust  = "rbxassetid://5043539486",
    Bell  = "rbxassetid://6534947240",
    Ding  = "rbxassetid://2868798606",
}

local function PlayHitSound()
    if not Config.HitSound then return end
    local id = SoundIds[Config.SelectedHitSound] or SoundIds.Skeet
    local s = Instance.new("Sound", SoundService)
    s.SoundId = id
    s.Volume = Config.HitSoundVolume
    s:Play()
    Debris:AddItem(s, 2)
end

local function CreateBulletTracer(origin: Vector3, endPos: Vector3)
    if not Config.BulletTracers then return end
    task.spawn(function()
        local dist = (origin - endPos).Magnitude
        local travelTime = 0.05
        local lifetime = 0.35

        local core = Instance.new("Part")
        core.Name = "IdenticalTracerCore"
        core.Anchored = true
        core.CanCollide = false
        core.CanQuery = false
        core.CastShadow = false
        core.Material = Enum.Material.Neon
        core.Color = Color3.new(1, 1, 1)
        core.Size = Vector3.new(0.05, 0.05, 0)
        core.CFrame = CFrame.new(origin, endPos)
        core.Parent = Workspace
        TrackInstance(core)

        local glow = core:Clone()
        glow.Name = "IdenticalTracerGlow"
        glow.Color = Config.TracerColor or IdenticalTheme.Accent
        glow.Size = Vector3.new(0.18, 0.18, 0)
        glow.Transparency = 0.4
        glow.Parent = Workspace
        TrackInstance(glow)

        local ts = TweenService:Create(core, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
            Size = Vector3.new(0.05, 0.05, dist),
            CFrame = CFrame.new(origin:Lerp(endPos, 0.5), endPos)
        })
        local tsGlow = TweenService:Create(glow, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
            Size = Vector3.new(0.18, 0.18, dist),
            CFrame = CFrame.new(origin:Lerp(endPos, 0.5), endPos)
        })
        ts:Play()
        tsGlow:Play()

        task.delay(travelTime, function()
            local fadeOut = TweenService:Create(core, TweenInfo.new(lifetime), {Transparency = 1})
            local fadeOutGlow = TweenService:Create(glow, TweenInfo.new(lifetime), {Transparency = 1})
            fadeOut:Play()
            fadeOutGlow:Play()
            task.delay(lifetime, function()
                pcall(function() core:Destroy() end)
                pcall(function() glow:Destroy() end)
            end)
        end)
    end)
end

local function CreateHitMarker(hitPart: BasePart?, pos: Vector3)
    if not Config.HitMarkers or not hitPart or not Drawing then return end
    task.spawn(function()
        local line1 = Drawing.new("Line")
        local line2 = Drawing.new("Line")
        line1.Thickness = 1.5
        line1.Color = Config.HitmarkerColor or Color3.fromRGB(255, 255, 255)
        line2.Thickness = 1.5
        line2.Color = Config.HitmarkerColor or Color3.fromRGB(255, 255, 255)
        TrackDrawing(line1)
        TrackDrawing(line2)

        local start = tick()
        local lifetime = 0.35
        local size = 6
        local offset = hitPart.CFrame:PointToObjectSpace(pos)

        while isRunning and (tick() - start < lifetime) do
            if not hitPart or not hitPart.Parent then break end
            local currentPos = hitPart.CFrame:PointToWorldSpace(offset)
            local sPos, onScreen = Camera:WorldToViewportPoint(currentPos)
            local alpha = 1 - ((tick() - start) / lifetime)

            if onScreen then
                line1.Visible = true
                line2.Visible = true
                line1.Transparency = alpha
                line2.Transparency = alpha

                line1.From = Vector2.new(sPos.X - size, sPos.Y - size)
                line1.To   = Vector2.new(sPos.X + size, sPos.Y + size)

                line2.From = Vector2.new(sPos.X + size, sPos.Y - size)
                line2.To   = Vector2.new(sPos.X - size, sPos.Y + size)
            else
                line1.Visible = false
                line2.Visible = false
            end
            RunService.RenderStepped:Wait()
        end

        pcall(function() line1:Remove() end)
        pcall(function() line2:Remove() end)
    end)
end

local hitLogsList: { any } = {}
local function CreateHitLog(partName: string, targetName: string)
    if not Config.HitLogsEnabled or not Drawing then return end
    task.spawn(function()
        local text = Drawing.new("Text")
        text.Size = Config.HitLogsSize or 13
        text.Font = 2
        text.Center = true
        text.Outline = true
        text.Color = Config.HitLogsColor or IdenticalTheme.Accent
        text.Text = string.format("[%s] hit %s in %s", os.date("%H:%M:%S"), targetName:lower(), partName:lower())
        text.Visible = true
        TrackDrawing(text)

        table.insert(hitLogsList, text)
        local center = Camera.ViewportSize * 0.5
        for i, logItem in ipairs(hitLogsList) do
            logItem.Position = Vector2.new(center.X, center.Y + 120 + (i * 16))
        end

        task.delay(Config.HitLogsLifetime or 4, function()
            local idx = table.find(hitLogsList, text)
            if idx then table.remove(hitLogsList, idx) end
            pcall(function() text:Remove() end)
        end)
    end)
end

pcall(function()
    local RS = game:GetService("ReplicatedStorage")
    local fpsMods = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("FPS")
    local bulletMod = fpsMods and fpsMods:FindFirstChild("Bullet")
    if not bulletMod then return end

    local bulletTable = require(bulletMod)
    if not bulletTable or type(bulletTable.CreateBullet) ~= "function" then return end

    local origCreateBullet = bulletTable.CreateBullet
    local function myCreateBullet(...)
        local args = { ... }
        if not isRunning then return origCreateBullet(table.unpack(args)) end

        local muzzle = args[5]
        local isCaller = checkcaller and checkcaller()

        if not isCaller and muzzle and typeof(muzzle) == "Instance" and muzzle:IsA("BasePart") then
            local currentMuzzleCF = muzzle.CFrame
            task.spawn(function()
                local origin = currentMuzzleCF.Position
                local dir = currentMuzzleCF.LookVector * 1500
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = { LocalPlayer.Character, Camera }

                local res = Workspace:Raycast(origin, dir, rayParams)
                local endPos = if res then res.Position else (origin + dir)

                if Config.BulletTracers then
                    CreateBulletTracer(origin, endPos)
                end

                if res and res.Instance then
                    local hitModel = res.Instance:FindFirstAncestorOfClass("Model")
                    local hitPlr = hitModel and Players:GetPlayerFromCharacter(hitModel)
                    local isNpc = hitModel and not hitPlr and hitModel:FindFirstChildOfClass("Humanoid")
                    if (hitPlr and hitPlr ~= LocalPlayer) or isNpc then
                        PlayHitSound()
                        CreateHitMarker(res.Instance, res.Position)
                        CreateHitLog(res.Instance.Name, hitPlr and hitPlr.Name or (hitModel and hitModel.Name or "Unknown"))
                    end
                end
            end)
        end

        return origCreateBullet(table.unpack(args))
    end

    if hookfunction and newcclosure then
        local oldClosure; oldClosure = hookfunction(origCreateBullet, newcclosure(function(...)
            return myCreateBullet(...)
        end))
        hookedFunctions[origCreateBullet] = oldClosure
    else
        bulletTable.CreateBullet = myCreateBullet
        hookedFunctions[bulletTable] = function()
            bulletTable.CreateBullet = origCreateBullet
        end
    end
end)
TargetInfoGui = Instance.new("ScreenGui")
TargetInfoGui.Name = "Identical_TargetInfo"
TargetInfoGui.ResetOnSpawn = false
TargetInfoGui.Enabled = false
TargetInfoGui.Parent = RootContainer
TrackInstance(TargetInfoGui)

targetMainFrame = Instance.new("Frame", TargetInfoGui)
targetMainFrame.Name = "MainFrame"
targetMainFrame.Size = UDim2.new(0, 185, 0, 220)
targetMainFrame.Position = UDim2.new(0.5, 200, 0.5, -110)
targetMainFrame.BackgroundColor3 = IdenticalTheme.Card
targetMainFrame.BorderSizePixel = 0
TrackInstance(targetMainFrame)

local targetCorner = Instance.new("UICorner", targetMainFrame)
targetCorner.CornerRadius = UDim.new(0, 3)

local targetGrad = Instance.new("UIGradient", targetMainFrame)
targetGrad.Rotation = 90
targetGrad.Color = ColorSequence.new(IdenticalTheme.CardTop, IdenticalTheme.CardBottom)

local targetMainStroke = Instance.new("UIStroke", targetMainFrame)
targetMainStroke.Color = IdenticalTheme.CardBorder
targetMainStroke.Thickness = 1

local targetTitleBar = Instance.new("Frame", targetMainFrame)
targetTitleBar.Name = "TitleBar"
targetTitleBar.Size = UDim2.new(1, 0, 0, 24)
targetTitleBar.BackgroundColor3 = Color3.fromRGB(20, 23, 29)
targetTitleBar.BorderSizePixel = 0

local targetTitleCorner = Instance.new("UICorner", targetTitleBar)
targetTitleCorner.CornerRadius = UDim.new(0, 3)

local targetTitleGrad = Instance.new("UIGradient", targetTitleBar)
targetTitleGrad.Rotation = 90
targetTitleGrad.Color = ColorSequence.new(Color3.fromRGB(24, 27, 34), Color3.fromRGB(17, 19, 24))

local targetTitleLabel = Instance.new("TextLabel", targetTitleBar)
targetTitleLabel.Size = UDim2.new(1, -8, 1, 0)
targetTitleLabel.Position = UDim2.new(0, 8, 0, 0)
targetTitleLabel.BackgroundTransparency = 1
targetTitleLabel.TextColor3 = Color3.fromRGB(245, 248, 255)
targetTitleLabel.TextSize = 12
targetTitleLabel.Font = IdenticalBoldFont
targetTitleLabel.Text = "TARGET INFO"
targetTitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local targetMainLiner = Instance.new("Frame", targetTitleBar)
targetMainLiner.Size = UDim2.new(1, 0, 0, 2)
targetMainLiner.Position = UDim2.new(0, 0, 1, -2)
targetMainLiner.BackgroundColor3 = IdenticalTheme.Accent
targetMainLiner.BorderSizePixel = 0

local targetStatsContainer = Instance.new("Frame", targetMainFrame)
targetStatsContainer.Name = "Stats"
targetStatsContainer.Size = UDim2.new(1, -10, 0, 52)
targetStatsContainer.Position = UDim2.new(0, 5, 0, 28)
targetStatsContainer.BackgroundTransparency = 1

local targetStatsLayout = Instance.new("UIListLayout", targetStatsContainer)
targetStatsLayout.Padding = UDim.new(0, 2)
targetStatsLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function CreateStatsLabel(defaultText: string): TextLabel
    local l = Instance.new("TextLabel", targetStatsContainer)
    l.Size = UDim2.new(1, 0, 0, 15)
    l.BackgroundTransparency = 1
    l.TextColor3 = IdenticalTheme.TextMuted
    l.TextSize = 12
    l.Font = IdenticalFont
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = defaultText
    return l
end

local targetHealthLabel = CreateStatsLabel("HP: 100/100")
local targetWeaponLabel = CreateStatsLabel("Tool: None")
local targetExtraLabel  = CreateStatsLabel("SPD: 16 | DIST: 0 studs")

local targetInvScroll = Instance.new("ScrollingFrame", targetMainFrame)
targetInvScroll.Name = "InvScroll"
targetInvScroll.Size = UDim2.new(1, -10, 1, -86)
targetInvScroll.Position = UDim2.new(0, 5, 0, 82)
targetInvScroll.BackgroundTransparency = 1
targetInvScroll.BorderSizePixel = 0
targetInvScroll.ScrollBarThickness = 2
targetInvScroll.ScrollBarImageColor3 = IdenticalTheme.Accent
targetInvScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
targetInvScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local targetInvGrid = Instance.new("UIGridLayout", targetInvScroll)
targetInvGrid.CellPadding = UDim2.new(0, 4, 0, 4)
targetInvGrid.CellSize = UDim2.new(0, 36, 0, 36)

do
    local isDragging = false
    local dragStart, startPos
    targetTitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = targetMainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then isDragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            targetMainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local lastTargetName = ""
local lastTargetItems = ""
local targetLastPos: Vector3? = nil
local targetLastTick: number = 0
local targetCalculatedSpeed: number = 0

TrackConnection(RunService.Heartbeat:Connect(function()
    if not isRunning or not (Config.TargetHUDEnabled or Config.InventoryViewerEnabled) then
        TargetInfoGui.Enabled = false
        lastTargetName = ""
        targetLastPos = nil
        return
    end

    local bestTarget, _ = GetClosestPlayerToMouse(500)

    if not bestTarget then
        TargetInfoGui.Enabled = false
        lastTargetName = ""
        targetLastPos = nil
        return
    end

    local isPlr = bestTarget:IsA("Player")
    local char = if isPlr then bestTarget.Character else bestTarget
    if not char then
        TargetInfoGui.Enabled = false
        lastTargetName = ""
        targetLastPos = nil
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChildWhichIsA("BasePart")) :: BasePart?
    if not hum or not root or hum.Health <= 0 then
        TargetInfoGui.Enabled = false
        lastTargetName = ""
        targetLastPos = nil
        return
    end

    TargetInfoGui.Enabled = true
    local targetDisplayName = if isPlr then bestTarget.Name else (bestTarget:GetAttribute("DisplayName") or bestTarget:GetAttribute("CallSign") or bestTarget.Name)
    local targetPrefix = if isPlr then "" else "[AI] "
    targetTitleLabel.Text = string.format("TARGET: %s%s", targetPrefix, tostring(targetDisplayName):upper())

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
    local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0

    targetHealthLabel.Text = string.format("HP: %d / %d", math.max(0, math.round(hum.Health)), math.round(hum.MaxHealth))
    
    local held = GetEquippedItem(char)
    targetWeaponLabel.Text = string.format("Tool: %s", held)

    local targetId = if isPlr then bestTarget.Name else bestTarget:GetDebugId()
    if targetId ~= lastTargetName then
        targetLastPos = root.Position
        targetLastTick = tick()
        targetCalculatedSpeed = 0
        lastTargetName = targetId
    else
        local now = tick()
        local dt = now - targetLastTick
        if dt >= 0.08 and targetLastPos then
            local deltaPos = (root.Position - targetLastPos) * Vector3.new(1, 0, 1)
            targetCalculatedSpeed = deltaPos.Magnitude / dt
            targetLastPos = root.Position
            targetLastTick = now
        elseif not targetLastPos then
            targetLastPos = root.Position
            targetLastTick = now
        end
    end

    local asmSpeed = (root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
    local liveSpeed = math.max(asmSpeed, targetCalculatedSpeed)
    if liveSpeed < 0.25 then liveSpeed = 0 end

    targetExtraLabel.Text = string.format("SPD: %d | DIST: %d studs", math.round(liveSpeed), math.round(dist))

    if Config.InventoryViewerEnabled and isPlr then
        targetInvScroll.Visible = true
        targetMainFrame.Size = UDim2.new(0, 180, 0, 220)
        local items = ScanTargetInventory(bestTarget)
        local itemsKey = table.concat(items, ",")
        if itemsKey ~= lastTargetItems or targetId ~= lastTargetName then
            lastTargetItems = itemsKey
            for _, child in ipairs(targetInvScroll:GetChildren()) do
                if child:IsA("Frame") then child:Destroy() end
            end
            for _, itemName in ipairs(items) do
                local itemCard = Instance.new("Frame", targetInvScroll)
                itemCard.BackgroundColor3 = IdenticalTheme.Element
                itemCard.BorderSizePixel = 0

                local cStroke = Instance.new("UIStroke", itemCard)
                cStroke.Color = IdenticalTheme.ElementBorder
                cStroke.Thickness = 1

                local icon = Instance.new("ImageLabel", itemCard)
                icon.Size = UDim2.new(1, -4, 1, -4)
                icon.Position = UDim2.new(0.5, 0, 0.5, 0)
                icon.AnchorPoint = Vector2.new(0.5, 0.5)
                icon.BackgroundTransparency = 1
                icon.Image = ItemIcons[itemName] or "rbxassetid://1316045217"
            end
        end
    else
        targetInvScroll.Visible = false
        targetMainFrame.Size = UDim2.new(0, 180, 0, 85)
    end
end))

local playerLastPositions: { [Player]: { Pos: Vector3, Time: number } } = {}
local playerHackerTimestamps: { [Player]: number } = {}
local playerAlertDebounce: { [Player]: number } = {}

TrackConnection(RunService.Heartbeat:Connect(function()
    if not isRunning or not Config.HackerDetector then return end

    local now = tick()
    local threshold = tonumber(Config.HackerSpeedThreshold) or 35
    local duration = tonumber(Config.HackerSpeedDuration) or 0.8

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local char = p.Character
            local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
            local hum = char:FindFirstChildOfClass("Humanoid")

            if root and hum and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead and not hum.SeatPart then
                local currentPos = root.Position
                local lastData = playerLastPositions[p]

                if lastData then
                    local dt = now - lastData.Time
                    if dt >= 0.25 then
                        local deltaHoriz = (currentPos - lastData.Pos) * Vector3.new(1, 0, 1)
                        local dist = deltaHoriz.Magnitude

                        if dist > 65 then
                            playerLastPositions[p] = { Pos = currentPos, Time = now }
                            playerHackerTimestamps[p] = nil
                        else
                            local actualSpeed = dist / dt

                            if actualSpeed >= threshold then
                                if not playerHackerTimestamps[p] then
                                    playerHackerTimestamps[p] = now
                                elseif (now - playerHackerTimestamps[p]) >= duration then
                                    local lastAlert = playerAlertDebounce[p] or 0
                                    if now - lastAlert >= 10.0 then
                                        playerAlertDebounce[p] = now
                                        Notify("HACKER DETECTED", string.format("%s moving abnormally fast! (%d studs/s)", p.Name, math.round(actualSpeed)), Color3.fromRGB(255, 65, 65), 4.5)
                                    end
                                end
                            else
                                playerHackerTimestamps[p] = nil
                            end

                            playerLastPositions[p] = { Pos = currentPos, Time = now }
                        end
                    end
                else
                    playerLastPositions[p] = { Pos = currentPos, Time = now }
                end
            else
                playerHackerTimestamps[p] = nil
                playerLastPositions[p] = nil
            end
        end
    end
end))

TrackConnection(Players.PlayerRemoving:Connect(function(p)
    playerLastPositions[p] = nil
    playerAlertDebounce[p] = nil
    playerHackerTimestamps[p] = nil
end))

mainFrame = Instance.new("Frame")
mainFrame.Name = "Identical_MainWindow"
mainFrame.Size = UDim2.new(0, 626, 0, 460)
mainFrame.Position = UDim2.new(0.5, -313, 0.5, -230)
mainFrame.BackgroundColor3 = IdenticalTheme.WindowBackground
mainFrame.BorderSizePixel = 0
mainFrame.Parent = RootGui
TrackInstance(mainFrame)

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 4)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(44, 50, 62)
mainStroke.Thickness = 1

local topAccentLine = Instance.new("Frame", mainFrame)
topAccentLine.Name = "TopAccentLine"
topAccentLine.Size = UDim2.new(1, 0, 0, 2)
topAccentLine.Position = UDim2.new(0, 0, 0, 0)
topAccentLine.BackgroundColor3 = IdenticalTheme.Accent
topAccentLine.BorderSizePixel = 0
topAccentLine.ZIndex = 5

local topAccentGrad = Instance.new("UIGradient", topAccentLine)
topAccentGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 135, 210)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(155, 215, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 135, 210))
})

local modalUnlocker = Instance.new("TextButton", mainFrame)
modalUnlocker.Name = "ModalUnlocker"
modalUnlocker.Size = UDim2.new(0, 1, 0, 1)
modalUnlocker.Position = UDim2.new(0, 0, 0, 0)
modalUnlocker.BackgroundTransparency = 1
modalUnlocker.Text = ""
modalUnlocker.Modal = true
TrackInstance(modalUnlocker)

local topbar = Instance.new("Frame", mainFrame)
topbar.Name = "Topbar"
topbar.Size = UDim2.new(1, 0, 0, 30)
topbar.Position = UDim2.new(0, 0, 0, 2)
topbar.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
topbar.BorderSizePixel = 0

local topbarCorner = Instance.new("UICorner", topbar)
topbarCorner.CornerRadius = UDim.new(0, 4)

local topbarGrad = Instance.new("UIGradient", topbar)
topbarGrad.Rotation = 90
topbarGrad.Color = ColorSequence.new(Color3.fromRGB(22, 25, 32), Color3.fromRGB(15, 17, 22))

local titleLabel = Instance.new("TextLabel", topbar)
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(0, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.AutomaticSize = Enum.AutomaticSize.X
titleLabel.BackgroundTransparency = 1
titleLabel.Font = IdenticalBoldFont
titleLabel.Text = "VoidByte Combat"
titleLabel.TextColor3 = Color3.fromRGB(245, 248, 255)
titleLabel.TextSize = 12
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local topbarBottomLine = Instance.new("Frame", topbar)
topbarBottomLine.Size = UDim2.new(1, 0, 0, 1)
topbarBottomLine.Position = UDim2.new(0, 0, 1, -1)
topbarBottomLine.BackgroundColor3 = Color3.fromRGB(36, 42, 54)
topbarBottomLine.BorderSizePixel = 0

local closeBtn = Instance.new("TextButton", topbar)
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 18, 0, 18)
closeBtn.Position = UDim2.new(1, -24, 0.5, -9)
closeBtn.BackgroundColor3 = Color3.fromRGB(22, 24, 29)
closeBtn.BorderSizePixel = 0
closeBtn.Font = IdenticalBoldFont
closeBtn.Text = "x"
closeBtn.TextColor3 = Color3.fromRGB(190, 195, 205)
closeBtn.TextSize = 11

local closeStroke = Instance.new("UIStroke", closeBtn)
closeStroke.Color = Color3.fromRGB(42, 48, 60)
closeStroke.Thickness = 1

local function OnCloseTriggered()
    if ToggleUI then
        ToggleUI(false)
    elseif mainFrame then
        mainFrame.Visible = false
        isUIVisible = false
    end
end

closeBtn.MouseButton1Click:Connect(OnCloseTriggered)
closeBtn.Activated:Connect(OnCloseTriggered)
closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end)
closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(22, 24, 29)
    closeBtn.TextColor3 = Color3.fromRGB(170, 175, 185)
end)

local minBtn = Instance.new("TextButton", topbar)
minBtn.Name = "MinButton"
minBtn.Size = UDim2.new(0, 18, 0, 18)
minBtn.Position = UDim2.new(1, -46, 0.5, -9)
minBtn.BackgroundColor3 = Color3.fromRGB(22, 24, 29)
minBtn.BorderSizePixel = 0
minBtn.Font = IdenticalFont
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(170, 175, 185)
minBtn.TextSize = 12

local minStroke = Instance.new("UIStroke", minBtn)
minStroke.Color = Color3.fromRGB(38, 42, 50)
minStroke.Thickness = 1

local function OnMinTriggered()
    if ToggleUI then
        ToggleUI(false)
    elseif mainFrame then
        mainFrame.Visible = false
        isUIVisible = false
    end
end

minBtn.MouseButton1Click:Connect(OnMinTriggered)
minBtn.Activated:Connect(OnMinTriggered)
minBtn.MouseEnter:Connect(function()
    minBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 44)
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end)
minBtn.MouseLeave:Connect(function()
    minBtn.BackgroundColor3 = Color3.fromRGB(22, 24, 29)
    minBtn.TextColor3 = Color3.fromRGB(170, 175, 185)
end)

local tabsContainer = Instance.new("Frame", topbar)
tabsContainer.Name = "TabsContainer"
tabsContainer.Size = UDim2.new(1, -230, 1, 0)
tabsContainer.Position = UDim2.new(0, 180, 0, 0)
tabsContainer.BackgroundTransparency = 1

local function UpdateTabsPosition()
    local titleWidth = titleLabel.AbsoluteSize.X
    local startX = math.max(175, titleWidth + 24)
    tabsContainer.Position = UDim2.new(0, startX, 0, 0)
end
titleLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateTabsPosition)
task.defer(UpdateTabsPosition)

local tabsLayout = Instance.new("UIListLayout", tabsContainer)
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.Padding = UDim.new(0, 12)
tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local inlineFrame = Instance.new("Frame", mainFrame)
inlineFrame.Name = "Inline"
inlineFrame.Size = UDim2.new(1, -12, 1, -40)
inlineFrame.Position = UDim2.new(0, 6, 0, 34)
inlineFrame.BackgroundColor3 = IdenticalTheme.Inline
inlineFrame.BorderSizePixel = 0

local inlineStroke = Instance.new("UIStroke", inlineFrame)
inlineStroke.Color = Color3.fromRGB(26, 29, 36)
inlineStroke.Thickness = 1

do
    local isDragging = false
    local dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then isDragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local pages: { [string]: { Button: TextButton, Liner: Frame, Glow: Frame, Container: Frame } } = {}
local activePageName = ""

local function CreatePage(pageName: string): (ScrollingFrame, ScrollingFrame)
    local tabBtn = Instance.new("TextButton", tabsContainer)
    tabBtn.Name = pageName .. "_Tab"
    tabBtn.Size = UDim2.new(0, 0, 1, 0)
    tabBtn.AutomaticSize = Enum.AutomaticSize.X
    tabBtn.BackgroundTransparency = 1
    tabBtn.Font = IdenticalFont
    tabBtn.Text = pageName
    tabBtn.TextColor3 = IdenticalTheme.TextMuted
    tabBtn.TextSize = 12

    local glow = Instance.new("Frame", tabBtn)
    glow.Size = UDim2.new(1, 8, 1, 0)
    glow.Position = UDim2.new(0, -4, 0, 0)
    glow.BackgroundColor3 = IdenticalTheme.Accent
    glow.BorderSizePixel = 0
    glow.Visible = false

    local glowGrad = Instance.new("UIGradient", glow)
    glowGrad.Rotation = -90
    glowGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.40),
        NumberSequenceKeypoint.new(0.18, 0.70),
        NumberSequenceKeypoint.new(0.55, 0.95),
        NumberSequenceKeypoint.new(1, 1)
    }

    local liner = Instance.new("Frame", tabBtn)
    liner.Size = UDim2.new(1, 8, 0, 2)
    liner.Position = UDim2.new(0, -4, 1, -2)
    liner.BackgroundColor3 = IdenticalTheme.Accent
    liner.BorderSizePixel = 0
    liner.Visible = false

    local pageFrame = Instance.new("Frame", inlineFrame)
    pageFrame.Name = pageName .. "_Page"
    pageFrame.Size = UDim2.new(1, 0, 1, 0)
    pageFrame.BackgroundTransparency = 1
    pageFrame.Visible = false

    local colLeft = Instance.new("ScrollingFrame", pageFrame)
    colLeft.Size = UDim2.new(0.5, -6, 1, -10)
    colLeft.Position = UDim2.new(0, 5, 0, 5)
    colLeft.BackgroundTransparency = 1
    colLeft.BorderSizePixel = 0
    colLeft.ScrollBarThickness = 2
    colLeft.ScrollBarImageColor3 = IdenticalTheme.Accent
    colLeft.AutomaticCanvasSize = Enum.AutomaticSize.Y
    colLeft.CanvasSize = UDim2.new(0, 0, 0, 0)

    local colLeftLayout = Instance.new("UIListLayout", colLeft)
    colLeftLayout.Padding = UDim.new(0, 8)

    local colRight = Instance.new("ScrollingFrame", pageFrame)
    colRight.Size = UDim2.new(0.5, -6, 1, -10)
    colRight.Position = UDim2.new(0.5, 1, 0, 5)
    colRight.BackgroundTransparency = 1
    colRight.BorderSizePixel = 0
    colRight.ScrollBarThickness = 2
    colRight.ScrollBarImageColor3 = IdenticalTheme.Accent
    colRight.AutomaticCanvasSize = Enum.AutomaticSize.Y
    colRight.CanvasSize = UDim2.new(0, 0, 0, 0)

    local colRightLayout = Instance.new("UIListLayout", colRight)
    colRightLayout.Padding = UDim.new(0, 8)

    pages[pageName] = { Button = tabBtn, Liner = liner, Glow = glow, Container = pageFrame }

    local function SwitchTo()
        for pName, data in pairs(pages) do
            local isCurrent = (pName == pageName)
            data.Container.Visible = isCurrent
            data.Liner.Visible = isCurrent
            data.Glow.Visible = isCurrent
            data.Button.TextColor3 = if isCurrent then Color3.fromRGB(248, 250, 255) else IdenticalTheme.TextMuted
        end
        activePageName = pageName
    end

    tabBtn.MouseButton1Click:Connect(SwitchTo)
    tabBtn.MouseEnter:Connect(function()
        if activePageName ~= pageName then
            tabBtn.TextColor3 = Color3.fromRGB(210, 215, 225)
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if activePageName ~= pageName then
            tabBtn.TextColor3 = IdenticalTheme.TextMuted
        end
    end)

    if activePageName == "" or pageName == "Visuals" then SwitchTo() end

    return colLeft, colRight
end

local function CreateSection(parentCol: ScrollingFrame, title: string): Frame
    local card = Instance.new("Frame", parentCol)
    card.Name = title:gsub("%s+", "_") .. "_Card"
    card.Size = UDim2.new(1, -2, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = IdenticalTheme.Card
    card.BorderSizePixel = 0

    local cardCorner = Instance.new("UICorner", card)
    cardCorner.CornerRadius = UDim.new(0, 3)

    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color = IdenticalTheme.CardBorder
    cardStroke.Thickness = 1

    local cardLayout = Instance.new("UIListLayout", card)
    cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cardLayout.Padding = UDim.new(0, 0)

    local header = Instance.new("Frame", card)
    header.Name = "Header"
    header.LayoutOrder = 1
    header.Size = UDim2.new(1, 0, 0, 24)
    header.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
    header.BorderSizePixel = 0

    local headerCorner = Instance.new("UICorner", header)
    headerCorner.CornerRadius = UDim.new(0, 3)

    local pip = Instance.new("Frame", header)
    pip.Name = "AccentPip"
    pip.Size = UDim2.new(0, 3, 0, 12)
    pip.Position = UDim2.new(0, 8, 0.5, -6)
    pip.BackgroundColor3 = IdenticalTheme.Accent
    pip.BorderSizePixel = 0

    local pipCorner = Instance.new("UICorner", pip)
    pipCorner.CornerRadius = UDim.new(0, 1)

    local sHeader = Instance.new("TextLabel", header)
    sHeader.Name = "Title"
    sHeader.Size = UDim2.new(1, -24, 1, 0)
    sHeader.Position = UDim2.new(0, 18, 0, 0)
    sHeader.BackgroundTransparency = 1
    sHeader.Font = IdenticalBoldFont
    sHeader.Text = title:upper()
    sHeader.TextColor3 = Color3.fromRGB(238, 242, 250)
    sHeader.TextSize = 11
    sHeader.TextXAlignment = Enum.TextXAlignment.Left

    local divider = Instance.new("Frame", card)
    divider.Name = "Divider"
    divider.LayoutOrder = 2
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.BackgroundColor3 = Color3.fromRGB(36, 42, 54)
    divider.BorderSizePixel = 0

    local content = Instance.new("Frame", card)
    content.Name = "Content"
    content.LayoutOrder = 3
    content.Size = UDim2.new(1, 0, 0, 0)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.BackgroundTransparency = 1

    local contentPad = Instance.new("UIPadding", content)
    contentPad.PaddingTop = UDim.new(0, 8)
    contentPad.PaddingBottom = UDim.new(0, 10)
    contentPad.PaddingLeft = UDim.new(0, 10)
    contentPad.PaddingRight = UDim.new(0, 10)

    local contentLayout = Instance.new("UIListLayout", content)
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder

    return content
end
local function AddToggle(parentSection: Frame, labelText: string, configKey: string, callback: ((boolean) -> ())?): (boolean) -> ()
    local row = Instance.new("Frame", parentSection)
    row.Size = UDim2.new(1, 0, 0, 20)
    row.BackgroundTransparency = 1

    local box = Instance.new("TextButton", row)
    box.Size = UDim2.new(0, 14, 0, 14)
    box.Position = UDim2.new(0, 0, 0.5, -7)
    box.BackgroundColor3 = if Config[configKey] then IdenticalTheme.Accent else Color3.fromRGB(20, 24, 32)
    box.BorderSizePixel = 0
    box.Text = if Config[configKey] then "✓" else ""
    box.TextColor3 = Color3.fromRGB(15, 25, 40)
    box.TextSize = 10
    box.Font = IdenticalBoldFont

    local boxCorner = Instance.new("UICorner", box)
    boxCorner.CornerRadius = UDim.new(0, 2)

    local boxStroke = Instance.new("UIStroke", box)
    boxStroke.Color = if Config[configKey] then Color3.fromRGB(20, 45, 75) else IdenticalTheme.ElementBorder
    boxStroke.Thickness = 1

    local lbl = Instance.new("TextButton", row)
    lbl.Size = UDim2.new(1, -24, 1, 0)
    lbl.Position = UDim2.new(0, 24, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = IdenticalFont
    lbl.Text = labelText
    lbl.TextColor3 = if Config[configKey] then Color3.fromRGB(250, 252, 255) else IdenticalTheme.TextMuted
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local state = Config[configKey] == true

    local function SetState(val: boolean)
        state = val
        Config[configKey] = state
        box.BackgroundColor3 = if state then IdenticalTheme.Accent else Color3.fromRGB(20, 24, 32)
        box.Text = if state then "✓" else ""
        boxStroke.Color = if state then Color3.fromRGB(20, 45, 75) else IdenticalTheme.ElementBorder
        lbl.TextColor3 = if state then Color3.fromRGB(250, 252, 255) else IdenticalTheme.TextMuted
        if callback then pcall(callback, state) end
        TriggerAutoSave()
    end

    box.MouseButton1Click:Connect(function() SetState(not state) end)
    lbl.MouseButton1Click:Connect(function() SetState(not state) end)

    lbl.MouseEnter:Connect(function()
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    lbl.MouseLeave:Connect(function()
        lbl.TextColor3 = if state then Color3.fromRGB(250, 252, 255) else IdenticalTheme.TextMuted
    end)

    uiUpdateCallbacks[configKey] = function(newVal)
        state = newVal == true
        box.BackgroundColor3 = if state then IdenticalTheme.Accent else Color3.fromRGB(20, 24, 32)
        box.Text = if state then "✓" else ""
        boxStroke.Color = if state then Color3.fromRGB(20, 45, 75) else IdenticalTheme.ElementBorder
        lbl.TextColor3 = if state then Color3.fromRGB(250, 252, 255) else IdenticalTheme.TextMuted
    end

    return SetState
end

local function AddSlider(parentSection: Frame, labelText: string, configKey: string, min: number, max: number, suffix: string?, decimals: number?, callback: ((number) -> ())?)
    suffix = suffix or ""
    decimals = decimals or 0
    local default = Config[configKey] or min

    local container = Instance.new("Frame", parentSection)
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundTransparency = 1

    local headerRow = Instance.new("Frame", container)
    headerRow.Size = UDim2.new(1, 0, 0, 16)
    headerRow.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", headerRow)
    lbl.Size = UDim2.new(1, -85, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = IdenticalFont
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(215, 222, 235)
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = Instance.new("TextLabel", headerRow)
    valLbl.Size = UDim2.new(0, 85, 1, 0)
    valLbl.Position = UDim2.new(1, -85, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = IdenticalBoldFont
    valLbl.Text = tostring(default) .. suffix
    valLbl.TextColor3 = IdenticalTheme.Accent
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local track = Instance.new("Frame", container)
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 0, 21)
    track.BackgroundColor3 = Color3.fromRGB(13, 15, 20)
    track.BorderSizePixel = 0

    local trackCorner = Instance.new("UICorner", track)
    trackCorner.CornerRadius = UDim.new(0, 2)

    local trackStroke = Instance.new("UIStroke", track)
    trackStroke.Color = Color3.fromRGB(42, 48, 62)
    trackStroke.Thickness = 1

    local initialRatio = math.clamp((default - min) / (max - min), 0, 1)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(initialRatio, 0, 1, 0)
    fill.BackgroundColor3 = IdenticalTheme.Accent
    fill.BorderSizePixel = 0

    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(0, 2)

    local fillGrad = Instance.new("UIGradient", fill)
    fillGrad.Rotation = 90
    fillGrad.Color = ColorSequence.new(IdenticalTheme.AccentLight, IdenticalTheme.AccentDark)

    local thumb = Instance.new("Frame", fill)
    thumb.Size = UDim2.new(0, 3, 0, 10)
    thumb.Position = UDim2.new(1, -1, 0.5, -5)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0

    local thumbCorner = Instance.new("UICorner", thumb)
    thumbCorner.CornerRadius = UDim.new(0, 1)

    local isDragging = false
    local function Update(inputX: number)
        local ratio = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local rawVal = min + (ratio * (max - min))
        local mult = 10 ^ decimals
        local finalVal = math.round(rawVal * mult) / mult
        Config[configKey] = finalVal
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        valLbl.Text = tostring(finalVal) .. suffix
        if callback then pcall(callback, finalVal) end
        TriggerAutoSave()
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            Update(input.Position.X)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then isDragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            Update(input.Position.X)
        end
    end)

    uiUpdateCallbacks[configKey] = function(newVal)
        local ratio = math.clamp((newVal - min) / (max - min), 0, 1)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        valLbl.Text = tostring(newVal) .. suffix
    end
end

local function AddDropdown(parentSection: Frame, labelText: string, configKey: string, options: {string}, callback: ((string) -> ())?)
    local container = Instance.new("Frame", parentSection)
    container.Size = UDim2.new(1, 0, 0, 42)
    container.BackgroundTransparency = 1
    container.ZIndex = 10

    local default = Config[configKey] or options[1]

    local lbl = Instance.new("TextLabel", container)
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = IdenticalFont
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(215, 222, 235)
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 22)
    btn.Position = UDim2.new(0, 0, 0, 18)
    btn.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
    btn.BorderSizePixel = 0
    btn.Font = IdenticalFont
    btn.Text = "  " .. default
    btn.TextColor3 = Color3.fromRGB(240, 245, 255)
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 3)

    local bStroke = Instance.new("UIStroke", btn)
    bStroke.Color = Color3.fromRGB(48, 58, 76)
    bStroke.Thickness = 1

    local arrow = Instance.new("TextLabel", btn)
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -20, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Font = IdenticalBoldFont
    arrow.Text = "v"
    arrow.TextColor3 = IdenticalTheme.Accent
    arrow.TextSize = 11

    local list = Instance.new("Frame", container)
    list.Size = UDim2.new(1, 0, 0, #options * 22)
    list.Position = UDim2.new(0, 0, 0, 42)
    list.BackgroundColor3 = Color3.fromRGB(17, 21, 28)
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 50

    local listCorner = Instance.new("UICorner", list)
    listCorner.CornerRadius = UDim.new(0, 3)

    local listStroke = Instance.new("UIStroke", list)
    listStroke.Color = Color3.fromRGB(50, 62, 82)
    listStroke.Thickness = 1

    local listLayout = Instance.new("UIListLayout", list)
    listLayout.Padding = UDim.new(0, 1)

    local isOpen = false
    local current = default

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton", list)
        optBtn.Size = UDim2.new(1, 0, 0, 21)
        optBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
        optBtn.BorderSizePixel = 0
        optBtn.Font = IdenticalFont
        optBtn.Text = "  " .. opt
        optBtn.TextColor3 = if opt == current then IdenticalTheme.Accent else Color3.fromRGB(185, 192, 205)
        optBtn.TextSize = 12
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.ZIndex = 51

        optBtn.MouseEnter:Connect(function()
            optBtn.BackgroundColor3 = Color3.fromRGB(32, 40, 54)
            if opt ~= current then optBtn.TextColor3 = Color3.fromRGB(255, 255, 255) end
        end)
        optBtn.MouseLeave:Connect(function()
            optBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
            optBtn.TextColor3 = if opt == current then IdenticalTheme.Accent else Color3.fromRGB(185, 192, 205)
        end)

        optBtn.MouseButton1Click:Connect(function()
            current = opt
            Config[configKey] = current
            btn.Text = "  " .. current
            isOpen = false
            list.Visible = false
            arrow.Text = "v"
            container.Size = UDim2.new(1, 0, 0, 42)
            for _, child in ipairs(list:GetChildren()) do
                if child:IsA("TextButton") then
                    child.TextColor3 = if child.Text == "  " .. current then IdenticalTheme.Accent else Color3.fromRGB(185, 192, 205)
                end
            end
            if callback then pcall(callback, current) end
            TriggerAutoSave()
        end)
    end

    btn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        list.Visible = isOpen
        arrow.Text = if isOpen then "^" else "v"
        container.Size = if isOpen then UDim2.new(1, 0, 0, 42 + (#options * 22)) else UDim2.new(1, 0, 0, 42)
    end)

    btn.MouseEnter:Connect(function()
        bStroke.Color = IdenticalTheme.Accent
    end)
    btn.MouseLeave:Connect(function()
        if not isOpen then bStroke.Color = Color3.fromRGB(48, 58, 76) end
    end)

    uiUpdateCallbacks[configKey] = function(newVal)
        current = newVal
        btn.Text = "  " .. current
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
                child.TextColor3 = if child.Text == "  " .. current then IdenticalTheme.Accent else Color3.fromRGB(185, 192, 205)
            end
        end
    end
end

local function AddKeybind(parentSection: Frame, labelText: string, configKey: string, callback: ((Enum.KeyCode) -> ())?)
    local row = Instance.new("Frame", parentSection)
    row.Size = UDim2.new(1, 0, 0, 22)
    row.BackgroundTransparency = 1

    local defaultKey = Config[configKey] or Enum.KeyCode.RightShift

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -85, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = IdenticalFont
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(215, 222, 235)
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local bindBtn = Instance.new("TextButton", row)
    bindBtn.Size = UDim2.new(0, 80, 0, 20)
    bindBtn.Position = UDim2.new(1, -80, 0.5, -10)
    bindBtn.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
    bindBtn.BorderSizePixel = 0
    bindBtn.Font = IdenticalBoldFont
    bindBtn.Text = "[" .. defaultKey.Name .. "]"
    bindBtn.TextColor3 = IdenticalTheme.Accent
    bindBtn.TextSize = 11

    local bindCorner = Instance.new("UICorner", bindBtn)
    bindCorner.CornerRadius = UDim.new(0, 3)

    local bStroke = Instance.new("UIStroke", bindBtn)
    bStroke.Color = Color3.fromRGB(48, 58, 76)
    bStroke.Thickness = 1

    local listening = false
    bindBtn.MouseButton1Click:Connect(function()
        listening = true
        bindBtn.Text = "[...]"
        bindBtn.TextColor3 = Color3.fromRGB(255, 220, 80)
        bStroke.Color = Color3.fromRGB(255, 220, 80)
    end)

    TrackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            bindBtn.Text = "[" .. input.KeyCode.Name .. "]"
            bindBtn.TextColor3 = IdenticalTheme.Accent
            bStroke.Color = Color3.fromRGB(48, 58, 76)
            Config[configKey] = input.KeyCode
            if callback then pcall(callback, input.KeyCode) end
            TriggerAutoSave()
        end
    end))

    uiUpdateCallbacks[configKey] = function(newKey)
        bindBtn.Text = "[" .. newKey.Name .. "]"
    end
end

local function AddButton(parentSection: Frame, text: string, callback: () -> ())
    local btn = Instance.new("TextButton", parentSection)
    btn.Size = UDim2.new(1, 0, 0, 24)
    btn.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
    btn.BorderSizePixel = 0
    btn.Font = IdenticalBoldFont
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(245, 248, 255)
    btn.TextSize = 12

    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 3)

    local bStroke = Instance.new("UIStroke", btn)
    bStroke.Color = Color3.fromRGB(56, 68, 88)
    bStroke.Thickness = 1

    btn.MouseEnter:Connect(function()
        bStroke.Color = IdenticalTheme.Accent
        btn.BackgroundColor3 = Color3.fromRGB(40, 48, 64)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    btn.MouseLeave:Connect(function()
        bStroke.Color = Color3.fromRGB(56, 68, 88)
        btn.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
        btn.TextColor3 = Color3.fromRGB(245, 248, 255)
    end)

    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.06), {BackgroundColor3 = IdenticalTheme.AccentDark}):Play()
        task.wait(0.08)
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30, 36, 48)}):Play()
        pcall(callback)
    end)
end

isUIVisible = true

local function SetMouseFree(free: boolean)
    pcall(function()
        UserInputService.MouseBehavior = if free then Enum.MouseBehavior.Default else Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = free
    end)
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local mg = pg and pg:FindFirstChild("MainGui")
        if mg then
            local mb = mg:FindFirstChild("ModalButton")
            if mb and mb:IsA("TextButton") then
                mb.Modal = free
            end
            local mf = mg:FindFirstChild("MainFrame")
            local bf = mf and mf:FindFirstChild("BackpackFrame")
            if bf and bf.Visible then
                local invModObj = mg:FindFirstChild("InventoryFunctions", true)
                local invMod = invModObj and require(invModObj)
                if invMod and invMod.ToggleBackpack then
                    invMod.ToggleBackpack()
                else
                    bf.Visible = false
                end
            end
        end
    end)
end

local isMouseBound = false
local function FreeMouseStep()
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
end

local function UpdateMouseBinding()
    if isRunning and isUIVisible then
        if not isMouseBound then
            isMouseBound = true
            pcall(function()
                RunService:BindToRenderStep("IdenticalMouseFree", Enum.RenderPriority.Last.Value, FreeMouseStep)
            end)
        end
    else
        if isMouseBound then
            isMouseBound = false
            pcall(function()
                RunService:UnbindFromRenderStep("IdenticalMouseFree")
            end)
        end
    end
end

ToggleUI = function(state: boolean?)
    if state ~= nil then
        isUIVisible = state
    else
        isUIVisible = not isUIVisible
    end
    if mainFrame then
        mainFrame.Visible = isUIVisible
    end
    if modalUnlocker then
        modalUnlocker.Modal = isUIVisible
    end

    if isUIVisible then
        SetMouseFree(true)
    else
        SetMouseFree(false)
    end
    UpdateMouseBinding()
end

TrackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
    if input.KeyCode == Config.MenuKey or input.KeyCode == Enum.KeyCode.Insert then
        if UserInputService:GetFocusedTextBox() then return end
        if ToggleUI then ToggleUI() end
    end
end))

do
    local col1, col2 = CreatePage("Combat")
    local aimBox = CreateSection(col1, "Aimbot")
    AddToggle(aimBox, "Enable Camera Aimbot", "AimbotEnabled", function(v)
        Notify("Aimbot", if v then "Aimbot enabled (Hold RMB)" else "Aimbot disabled")
    end)
    AddDropdown(aimBox, "Target Bone", "AimbotBone", {"Head", "Neck", "HumanoidRootPart"}, function(v)
        Config.AimbotBone = v
    end)
    AddSlider(aimBox, "Aimbot FOV", "AimbotFOV", 30, 400, "°", 0, function(v)
        Config.AimbotFOV = v
    end)
    AddSlider(aimBox, "Smoothness", "AimbotSmoothness", 0.1, 5.0, "x", 1, function(v)
        Config.AimbotSmoothness = v
    end)
    AddToggle(aimBox, "Draw FOV Circle", "DrawFOV", function(v)
        Config.DrawFOV = v
    end)
    AddToggle(aimBox, "Target NPCs / AI", "TargetNPCs", function(v)
        Config.TargetNPCs = v
    end)

    local gunBox = CreateSection(col2, "Gun Mods")
    AddToggle(gunBox, "No Recoil", "NoRecoil", function(v)
        Config.NoRecoil = v
        Notify("Gun Mods", if v then "No Recoil enabled" else "No Recoil restored")
    end)
    AddToggle(gunBox, "No Bullet Drop", "NoDrop", function(v)
        Config.NoDrop = v
    end)
    AddToggle(gunBox, "No Drag", "NoDrag", function(v)
        Config.NoDrag = v
    end)
    AddToggle(gunBox, "Instant Aim / Zoom", "InstantAim", function(v)
        Config.InstantAim = v
    end)
end

do
    local col1, col2 = CreatePage("Visuals")

    local espBox = CreateSection(col1, "Player & Container Visuals")
    AddToggle(espBox, "Enable ESP", "PlayerESP", function(v)
        Config.PlayerESP = v
    end)
    AddToggle(espBox, "Bounding Boxes", "ESPBoxes", function(v)
        Config.ESPBoxes = v
    end)
    AddToggle(espBox, "Health Bar", "ESPHealthBar", function(v)
        Config.ESPHealthBar = v
    end)
    AddToggle(espBox, "Name", "ESPNames", function(v)
        Config.ESPNames = v
    end)
    AddToggle(espBox, "Tracers", "ESPTracers", function(v)
        Config.ESPTracers = v
    end)
    AddToggle(espBox, "Distance", "ESPDistance", function(v)
        Config.ESPDistance = v
    end)
    AddToggle(espBox, "Container ESP", "ContainerESP", function(v)
        Config.ContainerESP = v
    end)
    AddSlider(espBox, "Container Render Distance", "ContainerMaxDist", 100, 2000, " studs", 0, function(v)
        Config.ContainerMaxDist = v
    end)
    AddSlider(espBox, "Player ESP Max Distance", "PlayerMaxDist", 100, 5000, " studs", 0, function(v)
        Config.PlayerMaxDist = v
    end)
    AddToggle(espBox, "NPC ESP", "NPC_ESP", function(v)
        Config.NPC_ESP = v
    end)
    AddSlider(espBox, "NPC Render Distance", "NPCMaxDist", 100, 3000, " studs", 0, function(v)
        Config.NPCMaxDist = v
    end)
    AddToggle(espBox, "Vehicle ESP", "Vehicle_ESP", function(v)
        Config.Vehicle_ESP = v
    end)
    AddSlider(espBox, "Vehicle Render Distance", "VehicleMaxDist", 100, 5000, " studs", 0, function(v)
        Config.VehicleMaxDist = v
    end)
    AddToggle(espBox, "Dropped Item ESP", "DroppedItemESP", function(v)
        Config.DroppedItemESP = v
    end)
    AddSlider(espBox, "Dropped Item Render Distance", "DroppedItemMaxDist", 100, 2000, " studs", 0, function(v)
        Config.DroppedItemMaxDist = v
    end)

    local fxBox = CreateSection(col2, "Combat Visuals")
    AddToggle(fxBox, "Bullet Tracers", "BulletTracers", function(v)
        Config.BulletTracers = v
    end)
    AddToggle(fxBox, "Hit Markers", "HitMarkers", function(v)
        Config.HitMarkers = v
    end)
    AddToggle(fxBox, "Hit Sound", "HitSound", function(v)
        Config.HitSound = v
    end)
    AddDropdown(fxBox, "Sound Style", "SelectedHitSound", {"Skeet", "Rust", "Bell", "Ding"}, function(v)
        Config.SelectedHitSound = v
        PlayHitSound()
    end)
    AddSlider(fxBox, "Sound Volume", "HitSoundVolume", 1, 10, "x", 0, function(v)
        Config.HitSoundVolume = v
    end)
    AddToggle(fxBox, "Hit Logs", "HitLogsEnabled", function(v)
        Config.HitLogsEnabled = v
    end)
    AddSlider(fxBox, "Lifetime", "HitLogsLifetime", 1, 30, "s", 0, function(v)
        Config.HitLogsLifetime = v
    end)
    AddSlider(fxBox, "Text Size", "HitLogsSize", 10, 30, "px", 0, function(v)
        Config.HitLogsSize = v
    end)
end

local defaultLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
}

local defaultAtmosphere = {}
pcall(function()
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo then
        defaultAtmosphere.Density = atmo.Density
        defaultAtmosphere.Haze = atmo.Haze
        defaultAtmosphere.Glare = atmo.Glare
    end
end)

local isEnforcingLighting = false

local function RestoreLighting()
    pcall(function()
        Lighting.Brightness = defaultLighting.Brightness or 1
        Lighting.ClockTime = defaultLighting.ClockTime or 14
        Lighting.GlobalShadows = defaultLighting.GlobalShadows ~= false
        Lighting.Ambient = defaultLighting.Ambient or Color3.fromRGB(0, 0, 0)
        Lighting.OutdoorAmbient = defaultLighting.OutdoorAmbient or Color3.fromRGB(128, 128, 128)
        Lighting.FogEnd = defaultLighting.FogEnd or 1000
        Lighting.FogStart = defaultLighting.FogStart or 0

        local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmo and defaultAtmosphere.Density ~= nil then
            atmo.Density = defaultAtmosphere.Density
            atmo.Haze = defaultAtmosphere.Haze or 0
            atmo.Glare = defaultAtmosphere.Glare or 0
        end
    end)
end

local function EnforceLighting()
    if not isRunning or isEnforcingLighting then return end
    isEnforcingLighting = true

    pcall(function()
        if Config.FullBright then
            Lighting.Brightness = 2.5
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(180, 180, 180)
            Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0

            local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
            if atmo then
                atmo.Density = 0
                atmo.Haze = 0
                atmo.Glare = 0
            end

            for _, effect in ipairs(Lighting:GetChildren()) do
                if effect:IsA("ColorCorrectionEffect") then
                    if effect.Brightness < 0 then
                        effect.Brightness = 0
                    end
                elseif effect:IsA("BloomEffect") and effect.Intensity > 1 then
                    effect.Intensity = 1
                end
            end
        elseif Config.ClockTimeEnabled then
            local targetTime = Config.ClockTime or 14
            if math.abs(Lighting.ClockTime - targetTime) > 0.02 then
                Lighting.ClockTime = targetTime
            end
        end

        if Config.RemoveGrass then
            Workspace.Terrain.Decoration = false
        end
    end)

    isEnforcingLighting = false
end

TrackConnection(RunService.RenderStepped:Connect(function()
    if Config.FullBright or Config.ClockTimeEnabled or Config.RemoveGrass then
        EnforceLighting()
    end
end))

for _, prop in ipairs({"ClockTime", "Brightness", "GlobalShadows", "Ambient", "OutdoorAmbient", "FogEnd"}) do
    TrackConnection(Lighting:GetPropertyChangedSignal(prop):Connect(function()
        if not isRunning or isEnforcingLighting then return end
        if Config.FullBright then
            EnforceLighting()
        elseif Config.ClockTimeEnabled and prop == "ClockTime" then
            EnforceLighting()
        end
    end))
end

do
    local col1, col2 = CreatePage("Misc")
    local camBox = CreateSection(col1, "Camera")
    AddToggle(camBox, "Third Person Mode", "ThirdPerson", function(v)
        Config.ThirdPerson = v
    end)
    AddSlider(camBox, "Camera Distance", "ThirdPersonDist", 5, 30, " studs", 0, function(v)
        Config.ThirdPersonDist = v
    end)

    local lightBox = CreateSection(col2, "Lighting & Atmosphere")
    AddToggle(lightBox, "Fullbright", "FullBright", function(v)
        Config.FullBright = v
        if v then
            EnforceLighting()
            Notify("Lighting", "Fullbright locked ON")
        else
            RestoreLighting()
            Notify("Lighting", "Fullbright disabled, restoring natural lighting")
        end
    end)
    AddToggle(lightBox, "Lock Clock Time", "ClockTimeEnabled", function(v)
        Config.ClockTimeEnabled = v
        if v then
            EnforceLighting()
            Notify("Lighting", string.format("Clock Time locked to %d:00", math.round(Config.ClockTime or 14)))
        else
            RestoreLighting()
            Notify("Lighting", "Clock Time lock disabled")
        end
    end)
    AddSlider(lightBox, "Clock Time", "ClockTime", 0, 24, "h", 0, function(v)
        Config.ClockTime = v
        Config.ClockTimeEnabled = true
        local cb = uiUpdateCallbacks["ClockTimeEnabled"]
        if cb then pcall(cb, true) end
        EnforceLighting()
    end)
    AddToggle(lightBox, "Remove Grass", "RemoveGrass", function(v)
        Config.RemoveGrass = v
        pcall(function() Workspace.Terrain.Decoration = not v end)
    end)
    AddToggle(lightBox, "Remove Foliage", "RemoveFoliage", function(v)
        Config.RemoveFoliage = v
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("MeshPart") or obj:IsA("Part") then
                    local lower = obj.Name:lower()
                    if lower:find("leaf") or lower:find("leaves") or lower:find("foliage") or lower:find("bush") then
                        obj.Transparency = if v then 1 else 0
                    end
                end
            end
        end)
    end)
end

do
    local col1, col2 = CreatePage("Players")
    local thBox = CreateSection(col1, "Inventory Viewer")
    AddToggle(thBox, "Enabled", "InventoryViewerEnabled", function(v)
        Config.InventoryViewerEnabled = v
    end)
    AddToggle(thBox, "Target HUD", "TargetHUDEnabled", function(v)
        Config.TargetHUDEnabled = v
        TargetInfoGui.Enabled = v
    end)
    AddButton(thBox, "Reset Target HUD Position", function()
        targetMainFrame.Position = UDim2.new(0.5, 200, 0.5, -110)
        Notify("Target HUD", "Position reset to center-right")
    end)

    local hackerBox = CreateSection(col2, "Hacker Detector")
    AddToggle(hackerBox, "Speedhack Alert", "HackerDetector", function(v)
        Config.HackerDetector = v
        Notify("Detector", if v then "Speedhack alerts enabled" else "Speedhack alerts disabled")
    end)
    AddSlider(hackerBox, "Speed Threshold", "HackerSpeedThreshold", 25, 80, " studs/s", 0, function(v)
        Config.HackerSpeedThreshold = v
    end)
    AddSlider(hackerBox, "Min Duration", "HackerSpeedDuration", 0.5, 2.0, "s", 1, function(v)
        Config.HackerSpeedDuration = v
    end)
end

do
    local col1, col2 = CreatePage("Settings")
    local profBox = CreateSection(col1, "Profiles")
    AddToggle(profBox, "Automatic Save on Edit", "AutoSave", function(v)
        Config.AutoSave = v
        Notify("Config", if v then "AutoSave active" else "AutoSave disabled")
    end)
    AddButton(profBox, "Save Config", function()
        local ok = SaveConfig()
        if ok then
            Notify("Config", "Saved to " .. CONFIG_FILE, IdenticalTheme.Accent)
        else
            Notify("Config", "Failed to write file", Color3.fromRGB(255, 80, 80))
        end
    end)
    AddButton(profBox, "Load Config", function()
        local ok = LoadConfig()
        if ok then
            Notify("Config", "Loaded configuration from disk", IdenticalTheme.Accent)
        else
            Notify("Config", "No saved configuration found", Color3.fromRGB(255, 180, 60))
        end
    end)

    local mgmtBox = CreateSection(col2, "Theming & Hotkeys")
    AddKeybind(mgmtBox, "Menu Keybind", "MenuKey", function(k)
        Config.MenuKey = k
        Notify("Hotkey", "Menu key set to [" .. k.Name .. "]")
    end)
    AddKeybind(mgmtBox, "Container ESP Key", "ContainerKey", function(k)
        Config.ContainerKey = k
        Notify("Hotkey", "Container ESP key set to [" .. k.Name .. "]")
    end)
    AddButton(mgmtBox, "Unload Script", function()
        if genv and genv.ProjectDeltaUnload then
            genv.ProjectDeltaUnload()
        end
    end)
end

TrackConnection(RunService.RenderStepped:Connect(function()
    if not isRunning then return end
    if Config.ThirdPerson then
        LocalPlayer.CameraMaxZoomDistance = Config.ThirdPersonDist
        LocalPlayer.CameraMinZoomDistance = Config.ThirdPersonDist
    else
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = 128
    end
end))

local function UnloadScript()
    if not isRunning then return end
    isRunning = false

    for _, conn in ipairs(activeConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(activeConnections)

    if isMouseBound then
        isMouseBound = false
        pcall(function()
            RunService:UnbindFromRenderStep("IdenticalMouseFree")
        end)
    end

    for _, drawObj in ipairs(cleanUpDrawings) do
        pcall(function() drawObj:Remove() end)
    end
    table.clear(cleanUpDrawings)
    for _, drawObj in pairs(activeWorldDrawings) do
        pcall(function() drawObj:Remove() end)
    end
    table.clear(activeWorldDrawings)
    for _, esp in pairs(npcEspDrawings) do
        pcall(function() esp.Box:Remove() end)
        pcall(function() esp.HealthBar:Remove() end)
        pcall(function() esp.NameText:Remove() end)
        pcall(function() esp.DistText:Remove() end)
        pcall(function() esp.Tracer:Remove() end)
    end
    table.clear(npcEspDrawings)
    table.clear(trackedNPCs)

    for _, inst in ipairs(cleanUpInstances) do
        pcall(function() inst:Destroy() end)
    end
    table.clear(cleanUpInstances)

    for origFn, oldClosure in pairs(hookedFunctions) do
        pcall(function()
            if hookfunction and origFn and oldClosure then
                hookfunction(origFn, oldClosure)
            end
        end)
    end
    table.clear(hookedFunctions)

    pcall(RestoreAmmoMods)
    pcall(RestoreLighting)
    pcall(SetMouseFree, false)

    if genv then
        genv.ProjectDeltaUnload = nil
    end
end

if genv then
    genv.ProjectDeltaUnload = UnloadScript
end

pcall(function()
    if isfile and (isfile(CONFIG_FILE) or isfile(LEGACY_CONFIG_FILE)) then
        LoadConfig()
    else
        SaveConfig()
    end
end)

ToggleUI(true)

Notify("Identical", "Project Delta loaded! Press [" .. Config.MenuKey.Name .. "] to toggle.", IdenticalTheme.Accent, 4)