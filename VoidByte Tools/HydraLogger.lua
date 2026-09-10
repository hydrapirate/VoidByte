--// HYDRA LOGGER (ENGLISH) + Alert Player + Save
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local SavedLogs = {}
local AlertList = {} -- usernames em lowercase
local AlertCount = 0

-- ===================== SAVE / LOAD =====================
local SAVE_FILE = "HydraLogger_Alerts.txt"

local function saveAlertList()
	if not writefile then return end
	local lines = {}
	for username, _ in pairs(AlertList) do
		table.insert(lines, username)
	end
	pcall(function()
		writefile(SAVE_FILE, table.concat(lines, "\n"))
	end)
end

local function loadAlertList()
	if not readfile or not isfile then return end
	pcall(function()
		if isfile(SAVE_FILE) then
			local content = readfile(SAVE_FILE)
			for line in string.gmatch(content, "[^\r\n]+") do
				local name = string.lower(string.gsub(line, "%s+", ""))
				if name ~= "" then
					AlertList[name] = true
				end
			end
		end
	end)
end

-- Carrega a lista ao iniciar
loadAlertList()

-- Remove old GUI
pcall(function()
	game.CoreGui.HydraLogger:Destroy()
end)

local gui = Instance.new("ScreenGui")
gui.Name = "HydraLogger"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

-- Main
local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 440, 0, 340)
main.Position = UDim2.new(0.32, 0, 0.18, 0)
main.BackgroundColor3 = Color3.fromRGB(18,18,18)
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0,8)

-- Top
local top = Instance.new("Frame", main)
top.Size = UDim2.new(1,0,0,34)
top.BackgroundColor3 = Color3.fromRGB(124,58,237)
top.BorderSizePixel = 0
Instance.new("UICorner", top).CornerRadius = UDim.new(0,8)

local title = Instance.new("TextLabel", top)
title.BackgroundTransparency = 1
title.Position = UDim2.new(0,10,0,0)
title.Size = UDim2.new(1,-100,1,0)
title.Font = Enum.Font.GothamBold
title.Text = "Hydra Logger"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left

-- Alert Button
local alertBtn = Instance.new("TextButton", top)
alertBtn.Size = UDim2.new(0,50,1,0)
alertBtn.Position = UDim2.new(1,-120,0,0)
alertBtn.BackgroundTransparency = 1
alertBtn.Text = "Alert"
alertBtn.Font = Enum.Font.GothamBold
alertBtn.TextColor3 = Color3.new(1,1,1)
alertBtn.TextSize = 14

local minimize = Instance.new("TextButton", top)
minimize.Size = UDim2.new(0,30,1,0)
minimize.Position = UDim2.new(1,-60,0,0)
minimize.BackgroundTransparency = 1
minimize.Text = "—"
minimize.Font = Enum.Font.GothamBold
minimize.TextColor3 = Color3.new(1,1,1)
minimize.TextSize = 18

local close = Instance.new("TextButton", top)
close.Size = UDim2.new(0,30,1,0)
close.Position = UDim2.new(1,-30,0,0)
close.BackgroundTransparency = 1
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextColor3 = Color3.new(1,1,1)
close.TextSize = 16

-- Badge de alerta (quando minimizado)
local alertBadge = Instance.new("Frame", top)
alertBadge.Size = UDim2.new(0, 52, 0, 22)
alertBadge.Position = UDim2.new(1, -175, 0.5, -11)
alertBadge.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
alertBadge.Visible = false
Instance.new("UICorner", alertBadge).CornerRadius = UDim.new(1,0)

local alertBadgeText = Instance.new("TextLabel", alertBadge)
alertBadgeText.BackgroundTransparency = 1
alertBadgeText.Size = UDim2.new(1,0,1,0)
alertBadgeText.Font = Enum.Font.GothamBold
alertBadgeText.Text = "⚠️ 0"
alertBadgeText.TextColor3 = Color3.new(1,1,1)
alertBadgeText.TextSize = 12

-- Logs
local scroll = Instance.new("ScrollingFrame", main)
scroll.Position = UDim2.new(0,10,0,42)
scroll.Size = UDim2.new(1,-20,1,-112)
scroll.BackgroundColor3 = Color3.fromRGB(24,24,24)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0,6)

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0,4)

-- Search
local search = Instance.new("TextBox", main)
search.Position = UDim2.new(0,10,1,-64)
search.Size = UDim2.new(1,-20,0,24)
search.PlaceholderText = "Search player, username or message..."
search.Text = ""
search.Font = Enum.Font.Gotham
search.TextColor3 = Color3.new(1,1,1)
search.BackgroundColor3 = Color3.fromRGB(32,32,32)
search.TextSize = 13
Instance.new("UICorner", search).CornerRadius = UDim.new(0,6)

-- Copy All
local copyAll = Instance.new("TextButton", main)
copyAll.Position = UDim2.new(0,10,1,-34)
copyAll.Size = UDim2.new(1,-20,0,26)
copyAll.BackgroundColor3 = Color3.fromRGB(124,58,237)
copyAll.Text = "Copy All Logs"
copyAll.TextColor3 = Color3.new(1,1,1)
copyAll.Font = Enum.Font.GothamBold
copyAll.TextSize = 13
Instance.new("UICorner", copyAll).CornerRadius = UDim.new(0,6)

-- ===================== ALERT PANEL =====================
local alertPanel = Instance.new("Frame", gui)
alertPanel.Size = UDim2.new(0, 220, 0, 340)
alertPanel.Position = UDim2.new(0, main.AbsolutePosition.X + 450, 0, main.AbsolutePosition.Y)
alertPanel.BackgroundColor3 = Color3.fromRGB(18,18,18)
alertPanel.BorderSizePixel = 0
alertPanel.Visible = false
Instance.new("UICorner", alertPanel).CornerRadius = UDim.new(0,8)

local alertTop = Instance.new("Frame", alertPanel)
alertTop.Size = UDim2.new(1,0,0,34)
alertTop.BackgroundColor3 = Color3.fromRGB(124,58,237)
alertTop.BorderSizePixel = 0
Instance.new("UICorner", alertTop).CornerRadius = UDim.new(0,8)

local alertTitle = Instance.new("TextLabel", alertTop)
alertTitle.BackgroundTransparency = 1
alertTitle.Position = UDim2.new(0,10,0,0)
alertTitle.Size = UDim2.new(1,-40,1,0)
alertTitle.Font = Enum.Font.GothamBold
alertTitle.Text = "Alert Player"
alertTitle.TextColor3 = Color3.new(1,1,1)
alertTitle.TextSize = 15
alertTitle.TextXAlignment = Enum.TextXAlignment.Left

local closeAlert = Instance.new("TextButton", alertTop)
closeAlert.Size = UDim2.new(0,30,1,0)
closeAlert.Position = UDim2.new(1,-30,0,0)
closeAlert.BackgroundTransparency = 1
closeAlert.Text = "X"
closeAlert.Font = Enum.Font.GothamBold
closeAlert.TextColor3 = Color3.new(1,1,1)
closeAlert.TextSize = 16

-- Input + Add
local alertInput = Instance.new("TextBox", alertPanel)
alertInput.Position = UDim2.new(0,10,0,44)
alertInput.Size = UDim2.new(1,-70,0,28)
alertInput.PlaceholderText = "Username..."
alertInput.Text = ""
alertInput.Font = Enum.Font.Gotham
alertInput.TextColor3 = Color3.new(1,1,1)
alertInput.BackgroundColor3 = Color3.fromRGB(32,32,32)
alertInput.TextSize = 13
Instance.new("UICorner", alertInput).CornerRadius = UDim.new(0,6)

local addAlertBtn = Instance.new("TextButton", alertPanel)
addAlertBtn.Position = UDim2.new(1,-55,0,44)
addAlertBtn.Size = UDim2.new(0,45,0,28)
addAlertBtn.BackgroundColor3 = Color3.fromRGB(34,197,94)
addAlertBtn.Text = "Add"
addAlertBtn.TextColor3 = Color3.new(1,1,1)
addAlertBtn.Font = Enum.Font.GothamBold
addAlertBtn.TextSize = 13
Instance.new("UICorner", addAlertBtn).CornerRadius = UDim.new(0,6)

-- Lista de alertas
local alertScroll = Instance.new("ScrollingFrame", alertPanel)
alertScroll.Position = UDim2.new(0,10,0,82)
alertScroll.Size = UDim2.new(1,-20,1,-92)
alertScroll.BackgroundColor3 = Color3.fromRGB(24,24,24)
alertScroll.BorderSizePixel = 0
alertScroll.ScrollBarThickness = 4
Instance.new("UICorner", alertScroll).CornerRadius = UDim.new(0,6)

local alertLayout = Instance.new("UIListLayout", alertScroll)
alertLayout.Padding = UDim.new(0,4)

-- ===================== FUNÇÕES =====================
local function updateAlertBadge()
	if AlertCount > 0 then
		alertBadge.Visible = true
		alertBadgeText.Text = "⚠️ " .. tostring(AlertCount)
	else
		alertBadge.Visible = false
	end
end

local function refreshAlertList()
	for _,v in ipairs(alertScroll:GetChildren()) do
		if v:IsA("Frame") then
			v:Destroy()
		end
	end

	for username,_ in pairs(AlertList) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1,-6,0,28)
		row.BackgroundColor3 = Color3.fromRGB(32,32,32)
		row.BorderSizePixel = 0
		Instance.new("UICorner", row).CornerRadius = UDim.new(0,5)

		local nameLabel = Instance.new("TextLabel", row)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Position = UDim2.new(0,8,0,0)
		nameLabel.Size = UDim2.new(1,-40,1,0)
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.Text = username
		nameLabel.TextColor3 = Color3.new(1,1,1)
		nameLabel.TextSize = 13
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left

		local removeBtn = Instance.new("TextButton", row)
		removeBtn.Size = UDim2.new(0,26,0,22)
		removeBtn.Position = UDim2.new(1,-30,0.5,-11)
		removeBtn.BackgroundColor3 = Color3.fromRGB(220,38,38)
		removeBtn.Text = "X"
		removeBtn.TextColor3 = Color3.new(1,1,1)
		removeBtn.Font = Enum.Font.GothamBold
		removeBtn.TextSize = 12
		Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0,4)

		removeBtn.MouseButton1Click:Connect(function()
			AlertList[username] = nil
			saveAlertList() -- salva ao remover
			refreshAlertList()
		end)

		row.Parent = alertScroll
	end

	alertScroll.CanvasSize = UDim2.new(0,0,0,alertLayout.AbsoluteContentSize.Y + 8)
end

-- Atualiza a lista visual após carregar
refreshAlertList()

alertLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	alertScroll.CanvasSize = UDim2.new(0,0,0,alertLayout.AbsoluteContentSize.Y + 8)
end)

addAlertBtn.MouseButton1Click:Connect(function()
	local name = string.lower(string.gsub(alertInput.Text, "%s+", ""))
	if name ~= "" and not AlertList[name] then
		AlertList[name] = true
		alertInput.Text = ""
		saveAlertList() -- salva ao adicionar
		refreshAlertList()
	end
end)

alertInput.FocusLost:Connect(function(enter)
	if enter then
		addAlertBtn.MouseButton1Click:Fire()
	end
end)

-- Drag
local dragging, dragInput, dragStart, startPos
top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)
top.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)
UIS.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
		if alertPanel.Visible then
			alertPanel.Position = UDim2.new(0, main.AbsolutePosition.X + 450, 0, main.AbsolutePosition.Y)
		end
	end
end)

local function createLog(data)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1,-6,0,24)
	holder.BackgroundColor3 = Color3.fromRGB(28,28,28)
	holder.BorderSizePixel = 0
	Instance.new("UICorner", holder).CornerRadius = UDim.new(0,5)

	local text = Instance.new("TextLabel", holder)
	text.BackgroundTransparency = 1
	text.Position = UDim2.new(0,6,0,0)
	text.Size = UDim2.new(1,-48,1,0)
	text.Font = Enum.Font.Code
	text.TextSize = 13
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.RichText = true
	text.Text = data.rich
	text.TextWrapped = true

	local copy = Instance.new("TextButton", holder)
	copy.Size = UDim2.new(0,34,0,18)
	copy.Position = UDim2.new(1,-38,0.5,-9)
	copy.BackgroundColor3 = Color3.fromRGB(45,45,45)
	copy.Text = "📋"
	copy.TextSize = 11
	copy.Font = Enum.Font.GothamBold
	copy.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", copy).CornerRadius = UDim.new(0,4)

	copy.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard(data.raw)
			copy.Text = "✓"
			task.wait(0.7)
			copy.Text = "📋"
		end
	end)

	holder.Parent = scroll

	task.defer(function()
		local textHeight = text.TextBounds.Y
		local newHeight = math.max(24, textHeight + 8)
		holder.Size = UDim2.new(1, -6, 0, newHeight)
		copy.Position = UDim2.new(1, -38, 0.5, -9)
	end)
end

local function refresh(filter)
	for _,v in ipairs(scroll:GetChildren()) do
		if v:IsA("Frame") then
			v:Destroy()
		end
	end
	filter = string.lower(filter or "")
	for _,log in ipairs(SavedLogs) do
		if filter == "" or string.find(string.lower(log.raw), filter, 1, true) then
			createLog(log)
		end
	end
	scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+8)
end

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+8)
end)

local function addLog(kind, display, username, message)
	local time = os.date("%H:%M:%S")
	local raw
	local rich
	local isAlert = false

	if kind == "CHAT" then
		raw = ("[%s] CHAT | %s (@%s): %s"):format(time, display, username, message)
		rich = string.format(
			'<font color="#9CA3AF">[%s]</font> <font color="#22C55E">CHAT</font> | <font color="#C084FC">%s</font> <font color="#60A5FA">(@%s)</font>: <font color="#FFFFFF">%s</font>',
			time, display, username, message
		)
	elseif kind == "JOIN" then
		raw = ("[%s] JOIN | %s (@%s)"):format(time, display, username)
		rich = string.format(
			'<font color="#9CA3AF">[%s]</font> <font color="#00FF7F">JOIN</font> | <font color="#C084FC">%s</font> <font color="#60A5FA">(@%s)</font>',
			time, display, username
		)
		if AlertList[string.lower(username)] then
			isAlert = true
			raw = ("[%s] ⚠️ ALERT JOIN | %s (@%s)"):format(time, display, username)
			rich = string.format(
				'<font color="#9CA3AF">[%s]</font> <font color="#EF4444"><b>⚠️ ALERT JOIN</b></font> | <font color="#EF4444"><b>%s</b></font> <font color="#F87171">(@%s)</font>',
				time, display, username
			)
		end
	elseif kind == "LEFT" then
		raw = ("[%s] LEFT | %s (@%s)"):format(time, display, username)
		rich = string.format(
			'<font color="#9CA3AF">[%s]</font> <font color="#EF4444">LEFT</font> | <font color="#C084FC">%s</font> <font color="#60A5FA">(@%s)</font>',
			time, display, username
		)
		if AlertList[string.lower(username)] then
			isAlert = true
			raw = ("[%s] ⚠️ ALERT LEFT | %s (@%s)"):format(time, display, username)
			rich = string.format(
				'<font color="#9CA3AF">[%s]</font> <font color="#EF4444"><b>⚠️ ALERT LEFT</b></font> | <font color="#EF4444"><b>%s</b></font> <font color="#F87171">(@%s)</font>',
				time, display, username
			)
		end
	else
		raw = ("[%s] %s"):format(time, message)
		rich = string.format(
			'<font color="#9CA3AF">[%s]</font> <font color="#F59E0B">%s</font>',
			time, message
		)
	end

	table.insert(SavedLogs,{
		raw = raw,
		rich = rich
	})

	if isAlert then
		AlertCount = AlertCount + 1
		updateAlertBadge()
	end

	refresh(search.Text)
end

-- Search
search:GetPropertyChangedSignal("Text"):Connect(function()
	refresh(search.Text)
end)

-- Players / Chat
local function hookPlayer(plr)
	plr.Chatted:Connect(function(msg)
		addLog("CHAT", plr.DisplayName, plr.Name, msg)
	end)
end

for _,p in ipairs(Players:GetPlayers()) do
	hookPlayer(p)
end

Players.PlayerAdded:Connect(function(plr)
	addLog("JOIN", plr.DisplayName, plr.Name)
	hookPlayer(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
	addLog("LEFT", plr.DisplayName, plr.Name)
end)

addLog("SYSTEM", nil, nil, "Logger initialized.")

-- Botões
local minimized = false
local alertOpen = false

minimize.MouseButton1Click:Connect(function()
	minimized = not minimized
	scroll.Visible = not minimized
	search.Visible = not minimized
	copyAll.Visible = not minimized

	if minimized then
		main.Size = UDim2.new(0,440,0,34)
		updateAlertBadge()
	else
		main.Size = UDim2.new(0,440,0,340)
		AlertCount = 0
		updateAlertBadge()
	end
end)

close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

copyAll.MouseButton1Click:Connect(function()
	if setclipboard then
		local list = {}
		for _,v in ipairs(SavedLogs) do
			table.insert(list, v.raw)
		end
		setclipboard(table.concat(list,"\n"))
		copyAll.Text = "Copied!"
		task.wait(1)
		copyAll.Text = "Copy All Logs"
	end
end)

-- Toggle Alert Panel
alertBtn.MouseButton1Click:Connect(function()
	alertOpen = not alertOpen
	alertPanel.Visible = alertOpen
	if alertOpen then
		alertPanel.Position = UDim2.new(0, main.AbsolutePosition.X + 450, 0, main.AbsolutePosition.Y)
	end
end)

closeAlert.MouseButton1Click:Connect(function()
	alertOpen = false
	alertPanel.Visible = false
end)

main:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
	if alertPanel.Visible then
		alertPanel.Position = UDim2.new(0, main.AbsolutePosition.X + 450, 0, main.AbsolutePosition.Y)
	end
end)
