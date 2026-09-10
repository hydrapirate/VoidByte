--// HYDRA LOGGER (ENGLISH)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local SavedLogs = {}

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
title.Size = UDim2.new(1,-70,1,0)
title.Font = Enum.Font.GothamBold
title.Text = "Hydra Logger"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left

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

-- Search (bottom)
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
	end
end)

local function createLog(data)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1,-6,0,24) -- altura mínima, será ajustada
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
	text.TextWrapped = true -- agora permite quebra de linha

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

	-- Ajusta a altura do holder automaticamente com base no texto
	task.defer(function()
		local textHeight = text.TextBounds.Y
		local newHeight = math.max(24, textHeight + 8) -- padding vertical
		holder.Size = UDim2.new(1, -6, 0, newHeight)
		
		-- Reposiciona o botão de copiar no centro vertical
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
		if filter == ""
			or string.find(string.lower(log.raw), filter, 1, true) then
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

	elseif kind == "LEFT" then
		raw = ("[%s] LEFT | %s (@%s)"):format(time, display, username)

		rich = string.format(
			'<font color="#9CA3AF">[%s]</font> <font color="#EF4444">LEFT</font> | <font color="#C084FC">%s</font> <font color="#60A5FA">(@%s)</font>',
			time, display, username
		)

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

-- Buttons
local minimized = false

minimize.MouseButton1Click:Connect(function()
	minimized = not minimized

	scroll.Visible = not minimized
	search.Visible = not minimized
	copyAll.Visible = not minimized

	if minimized then
		main.Size = UDim2.new(0,440,0,34)
	else
		main.Size = UDim2.new(0,440,0,340)
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
