local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
-- Variables
local selectedPlayer = nil
local mode = "None" -- "Normal", "Smart" or "None"
local tpConnection = nil
local sitConnection = nil
local isMinimized = false
local dragging = false
local dragStart = nil
local startPos = nil
local wasJumping = false
-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TPLoopGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 440)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -220)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame
-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "VoidByteSit"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar
-- Minimize
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "Minimize"
MinimizeBtn.Size = UDim2.new(0, 28, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -60, 0, 2)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 18
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = TitleBar
local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeBtn
-- Close
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "Close"
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -30, 0, 2)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn
-- Content
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -32)
Content.Position = UDim2.new(0, 0, 0, 32)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame
-- Search
local SearchBox = Instance.new("TextBox")
SearchBox.Name = "Search"
SearchBox.Size = UDim2.new(1, -20, 0, 28)
SearchBox.Position = UDim2.new(0, 10, 0, 10)
SearchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
SearchBox.Text = ""
SearchBox.PlaceholderText = "Search name or username..."
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
SearchBox.TextSize = 13
SearchBox.Font = Enum.Font.Gotham
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = Content
local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 6)
SearchCorner.Parent = SearchBox
-- Player List
local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Name = "PlayerList"
PlayerList.Size = UDim2.new(1, -20, 0, 180)
PlayerList.Position = UDim2.new(0, 10, 0, 48)
PlayerList.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
PlayerList.BorderSizePixel = 0
PlayerList.ScrollBarThickness = 4
PlayerList.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerList.Parent = Content
local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 6)
ListCorner.Parent = PlayerList
local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.Name
ListLayout.Padding = UDim.new(0, 4)
ListLayout.Parent = PlayerList
-- Selected Label
local SelectedLabel = Instance.new("TextLabel")
SelectedLabel.Name = "Selected"
SelectedLabel.Size = UDim2.new(1, -20, 0, 20)
SelectedLabel.Position = UDim2.new(0, 10, 0, 238)
SelectedLabel.BackgroundTransparency = 1
SelectedLabel.Text = "Selected: None"
SelectedLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
SelectedLabel.TextSize = 12
SelectedLabel.Font = Enum.Font.Gotham
SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedLabel.Parent = Content
-- Normal Button
local NormalBtn = Instance.new("TextButton")
NormalBtn.Name = "NormalBtn"
NormalBtn.Size = UDim2.new(0.5, -15, 0, 36)
NormalBtn.Position = UDim2.new(0, 10, 0, 268)
NormalBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 70)
NormalBtn.Text = "Normal"
NormalBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NormalBtn.TextSize = 14
NormalBtn.Font = Enum.Font.GothamBold
NormalBtn.Parent = Content
local NormalCorner = Instance.new("UICorner")
NormalCorner.CornerRadius = UDim.new(0, 6)
NormalCorner.Parent = NormalBtn
-- Smart Button
local SmartBtn = Instance.new("TextButton")
SmartBtn.Name = "SmartBtn"
SmartBtn.Size = UDim2.new(0.5, -15, 0, 36)
SmartBtn.Position = UDim2.new(0.5, 5, 0, 268)
SmartBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 160)
SmartBtn.Text = "Let people take you along :3"
SmartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SmartBtn.TextSize = 11
SmartBtn.Font = Enum.Font.GothamBold
SmartBtn.Parent = Content
local SmartCorner = Instance.new("UICorner")
SmartCorner.CornerRadius = UDim.new(0, 6)
SmartCorner.Parent = SmartBtn
-- Status
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "Status"
StatusLabel.Size = UDim2.new(1, -20, 0, 20)
StatusLabel.Position = UDim2.new(0, 10, 0, 315)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Disabled"
StatusLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = Content
-- Info
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Name = "Info"
InfoLabel.Size = UDim2.new(1, -20, 0, 40)
InfoLabel.Position = UDim2.new(0, 10, 0, 340)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Normal = select from the list\nSmart = just touch someone"
InfoLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
InfoLabel.TextSize = 11
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
InfoLabel.Parent = Content
-- Helpers
local function getPlayerDisplay(player)
	local display = player.DisplayName
	local user = player.Name
	if display == user then
		return user
	else
		return display .. " (@" .. user .. ")"
	end
end
local function forceSit(state)
	local char = LocalPlayer.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Sit = state
		end
	end
end
local function stopEverything()
	mode = "None"
	selectedPlayer = nil
	wasJumping = false
	if tpConnection then
		tpConnection:Disconnect()
		tpConnection = nil
	end
	if sitConnection then
		sitConnection:Disconnect()
		sitConnection = nil
	end
	forceSit(false)
	NormalBtn.Text = "Normal"
	NormalBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 70)
	SmartBtn.Text = "Let people take you along :3"
	SmartBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 160)
	SelectedLabel.Text = "Selected: None"
	SelectedLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
	StatusLabel.Text = "Status: Disabled"
	StatusLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
end
local function startLoop()
	if tpConnection then
		tpConnection:Disconnect()
		tpConnection = nil
	end
	if sitConnection then
		sitConnection:Disconnect()
		sitConnection = nil
	end
	-- Force Sit every ~0.1s
	sitConnection = RunService.Heartbeat:Connect(function()
		if mode ~= "None" then
			forceSit(true)
		end
	end)
	tpConnection = RunService.Heartbeat:Connect(function()
		if mode == "None" or not selectedPlayer then return end
		local myChar = LocalPlayer.Character
		if not myChar then return end
		local humanoid = myChar:FindFirstChildOfClass("Humanoid")
		if humanoid then
			-- In Smart mode: if jump, stop
			if mode == "Smart" then
				if humanoid.Jump or humanoid:GetState() == Enum.HumanoidStateType.Jumping then
					if not wasJumping then
						wasJumping = true
						stopEverything()
						StatusLabel.Text = "Status: Stopped (you jumped)"
						StatusLabel.TextColor3 = Color3.fromRGB(255, 180, 50)
					end
					return
				else
					wasJumping = false
				end
			end
		end
		local targetChar = selectedPlayer.Character
		if targetChar then
			local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
			local myHRP = myChar:FindFirstChild("HumanoidRootPart")
			if targetHRP and myHRP then
				local neckPos = targetHRP.CFrame * CFrame.new(0, 1.6, 0.8)
				myHRP.CFrame = neckPos
			end
		end
	end)
end
-- Update list
local function updatePlayerList(filter)
	filter = string.lower(filter or "")
	for _, child in pairs(PlayerList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local count = 0
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local displayLower = string.lower(player.DisplayName)
			local userLower = string.lower(player.Name)
			if filter == "" or string.find(displayLower, filter) or string.find(userLower, filter) then
				local btn = Instance.new("TextButton")
				btn.Name = player.Name
				btn.Size = UDim2.new(1, -8, 0, 32)
				btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
				btn.Text = getPlayerDisplay(player)
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
				btn.TextSize = 12
				btn.Font = Enum.Font.Gotham
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.Parent = PlayerList
				local padding = Instance.new("UIPadding")
				padding.PaddingLeft = UDim.new(0, 8)
				padding.Parent = btn
				local btnCorner = Instance.new("UICorner")
				btnCorner.CornerRadius = UDim.new(0, 4)
				btnCorner.Parent = btn
				btn.MouseButton1Click:Connect(function()
					-- Only allow selection if in Normal mode
					if mode == "Smart" then return end
					selectedPlayer = player
					SelectedLabel.Text = "Selected: " .. getPlayerDisplay(player)
					SelectedLabel.TextColor3 = Color3.fromRGB(100, 220, 140)
					for _, b in pairs(PlayerList:GetChildren()) do
						if b:IsA("TextButton") then
							b.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
						end
					end
					btn.BackgroundColor3 = Color3.fromRGB(70, 100, 160)
				end)
				count = count + 1
			end
		end
	end
	PlayerList.CanvasSize = UDim2.new(0, 0, 0, count * 36)
end
updatePlayerList()
Players.PlayerAdded:Connect(function()
	updatePlayerList(SearchBox.Text)
end)
Players.PlayerRemoving:Connect(function(player)
	if selectedPlayer == player then
		stopEverything()
	end
	updatePlayerList(SearchBox.Text)
end)
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	updatePlayerList(SearchBox.Text)
end)
-- Touch detection (only for Smart)
local function setupTouchDetection(char)
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end
	hrp.Touched:Connect(function(hit)
		if mode ~= "Smart" then return end
		local otherChar = hit:FindFirstAncestorOfClass("Model")
		if not otherChar then return end
		local otherPlayer = Players:GetPlayerFromCharacter(otherChar)
		if otherPlayer and otherPlayer ~= LocalPlayer then
			selectedPlayer = otherPlayer
			SelectedLabel.Text = "Selected: " .. getPlayerDisplay(otherPlayer) .. " (touched)"
			SelectedLabel.TextColor3 = Color3.fromRGB(100, 220, 140)
			StatusLabel.Text = "Status: Smart active on " .. otherPlayer.DisplayName
			StatusLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
			startLoop()
		end
	end)
end
-- Character respawn
LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.4)
	setupTouchDetection(char)
	if mode ~= "None" then
		local humanoid = char:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid.Sit = true
		end
		startLoop()
		if mode == "Normal" then
			NormalBtn.Text = "DISABLE"
			NormalBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
			StatusLabel.Text = "Status: Normal active"
		elseif mode == "Smart" then
			SmartBtn.Text = "DISABLE"
			SmartBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
			StatusLabel.Text = "Status: Smart active - touch someone"
		end
		StatusLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
	end
end)
if LocalPlayer.Character then
	setupTouchDetection(LocalPlayer.Character)
end
-- NORMAL Button
NormalBtn.MouseButton1Click:Connect(function()
	if mode == "Normal" then
		-- Turn off
		stopEverything()
	else
		-- Turn on Normal mode
		if not selectedPlayer then
			StatusLabel.Text = "Select a player first!"
			StatusLabel.TextColor3 = Color3.fromRGB(255, 180, 50)
			return
		end
		mode = "Normal"
		SmartBtn.Text = "Let people take you along :3"
		SmartBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 160)
		NormalBtn.Text = "DISABLE"
		NormalBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
		StatusLabel.Text = "Status: Normal active"
		StatusLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
		forceSit(true)
		startLoop()
	end
end)
-- SMART Button
SmartBtn.MouseButton1Click:Connect(function()
	if mode == "Smart" then
		-- Turn off
		stopEverything()
	else
		-- Turn on Smart mode (no need to select)
		mode = "Smart"
		selectedPlayer = nil
		NormalBtn.Text = "Normal"
		NormalBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 70)
		SmartBtn.Text = "DISABLE"
		SmartBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
		SelectedLabel.Text = "Selected: Waiting for touch..."
		SelectedLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
		StatusLabel.Text = "Status: Smart active - touch someone"
		StatusLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
		forceSit(true)
		startLoop()
	end
end)
-- Minimize
MinimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		Content.Visible = false
		MainFrame.Size = UDim2.new(0, 300, 0, 32)
		MinimizeBtn.Text = "+"
	else
		Content.Visible = true
		MainFrame.Size = UDim2.new(0, 300, 0, 440)
		MinimizeBtn.Text = "−"
	end
end)
-- Close
CloseBtn.MouseButton1Click:Connect(function()
	stopEverything()
	ScreenGui:Destroy()
end)
-- Drag
TitleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
	end
end)
TitleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)
