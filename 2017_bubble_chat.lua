--========================================================
-- 2017 BUBBLE CHAT (standalone)
--
-- The old Roblox bubble chat, as drawn by the "2017 core gui" (its OldBubbleChat part), as a
-- script of its own: white bubbles with a tail, the newest bubble in front, older ones stacked
-- above it and faded, small "..." bubble at medium distance, nothing when far away.
--
--  * Draws its own bubbles from TextChatService messages and switches the modern bubbles off
--    ONLY while it runs (BubbleChatConfiguration.Enabled is put back when it stops).
--  * Does not touch the chat window.
--  * Stop it with: getgenv().Bubble2017Cleanup()
--  * Games that still use the legacy chat already have these bubbles: it does nothing there.
--========================================================

local Environment = (getgenv or function() return _G end)
local Env = Environment()

if Env.Bubble2017Cleanup then
	pcall(Env.Bubble2017Cleanup)
	Env.Bubble2017Cleanup = nil
end

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Legacy chat games draw the 2017 bubbles themselves.
local UsesTextChatService = true

pcall(function()
	if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
		UsesTextChatService = false
	end
end)

if not UsesTextChatService then
	print("[2017 bubbles] this game uses the legacy chat: its own bubbles are the 2017 ones, nothing to do")
	return
end

--========================================================
-- SETTINGS (same numbers as the 2017 core gui)
--========================================================

local MAX_BUBBLE_WIDTH = 400
local MAX_TOTAL_BUBBLE_HEIGHT = 150

local NEAR_BUBBLE_DISTANCE = 45
local MAX_BUBBLE_DISTANCE = 80

local MIN_BUBBLE_LIFETIME = 12
local MAX_BUBBLE_LIFETIME = 20

local MIN_BUBBLE_LIFETIME_SELF = 8
local MAX_BUBBLE_LIFETIME_SELF = 15

local BUBBLE_FADE_TIME = 1.5

local MAX_CHAT_MESSAGE_LENGTH = 128

local ELLIPSES = "..."

local MAX_CHAT_MESSAGE_LENGTH_EXCLUSIVE = MAX_CHAT_MESSAGE_LENGTH - #ELLIPSES - 1

local BubbleFont = Font.fromEnum(Enum.Font.SourceSans)

local BubbleBackground = Color3.fromRGB(255, 255, 255)

local BubbleTextColor = Color3.fromRGB(60, 68, 75)

local BubbleTextSize = 22

local BUBBLE_IMAGE = "rbxasset://textures/ui/dialog_white.png"

local TAIL_IMAGE = "rbxasset://textures/ui/dialog_tail.png"

local ResizeBubbleTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local ShiftBubblesUpTweenInfo = TweenInfo.new(0.07, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

--========================================================
-- STATE
--========================================================

local Running = true

local Connections = {}

local AllBubbleGuis = {}

-- Most recent bubble is [1], the oldest is at the end.
local ChatBubbleQueues = {}

local SavedBubbleEnabled = nil

-- The two bubble textures come with the Roblox client. If this client does not have them the
-- bubbles are drawn as plain white rounded boxes instead of showing nothing.
local UseTextures = true

pcall(function()
	local Failed = false

	ContentProvider:PreloadAsync({ BUBBLE_IMAGE, TAIL_IMAGE }, function(_, Status)
		if Status == Enum.AssetFetchStatus.Failure or Status == Enum.AssetFetchStatus.TimedOut then
			Failed = true
		end
	end)

	if Failed then
		UseTextures = false
		print("[2017 bubbles] the bubble textures are missing in this client: plain bubbles are used")
	end
end)

--========================================================
-- MODERN BUBBLES OFF (while this script runs)
--========================================================

local function GetBubbleConfiguration()
	local Configuration = nil

	pcall(function()
		Configuration = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
	end)

	return Configuration
end

local function DisableModernBubbles()
	local Configuration = GetBubbleConfiguration()

	if not Configuration then
		return
	end

	pcall(function()
		if SavedBubbleEnabled == nil then
			SavedBubbleEnabled = Configuration.Enabled
		end

		if Configuration.Enabled then
			Configuration.Enabled = false
		end
	end)
end

DisableModernBubbles()

do
	local Configuration = GetBubbleConfiguration()

	if Configuration then
		table.insert(Connections, Configuration:GetPropertyChangedSignal("Enabled"):Connect(function()
			if Running and Configuration.Enabled then
				pcall(function()
					Configuration.Enabled = false
				end)
			end
		end))
	end
end

--========================================================
-- MESSAGES
--========================================================

local function GetMessageLength(Message)
	local Success, Length = pcall(function()
		return utf8.len(utf8.nfcnormalize(Message))
	end)

	if Success and Length then
		return Length
	end

	return #Message
end

local function SanitizeChatLine(Message)
	local Length = GetMessageLength(Message)

	if Length <= MAX_CHAT_MESSAGE_LENGTH_EXCLUSIVE then
		return Message
	end

	local ByteOffset

	pcall(function()
		ByteOffset = utf8.offset(Message, MAX_CHAT_MESSAGE_LENGTH_EXCLUSIVE + GetMessageLength(ELLIPSES) + 1)
	end)

	if not ByteOffset then
		return string.sub(Message, 1, MAX_CHAT_MESSAGE_LENGTH_EXCLUSIVE)
	end

	return string.sub(Message, 1, ByteOffset - 1)
end

local function LerpLength(Message, Minimum, Maximum)
	local Alpha = math.min(GetMessageLength(Message) / 75, 1)

	return Minimum + (Maximum - Minimum) * Alpha
end

--========================================================
-- QUEUES
--========================================================

local function RemoveBubbleFromQueue(Adornee, Bubble)
	local Queue = ChatBubbleQueues[Adornee]

	if not Queue then
		return
	end

	for Index, Value in ipairs(Queue) do
		if Value == Bubble then
			table.remove(Queue, Index)
			break
		end
	end

	if #Queue == 0 then
		ChatBubbleQueues[Adornee] = nil
	end
end

local function RemoveOldestFromQueue(Adornee)
	local Queue = ChatBubbleQueues[Adornee]

	if not Queue then
		return
	end

	local OldestBubble = Queue[#Queue]

	if not OldestBubble then
		return
	end

	table.remove(Queue, #Queue)

	if OldestBubble.Parent then
		OldestBubble:Destroy()
	end
end

local function AddBubbleToQueue(Adornee, ChatBubbleGui, Lifetime)
	local Queue = ChatBubbleQueues[Adornee]

	if not Queue then
		Queue = {}

		ChatBubbleQueues[Adornee] = Queue

		table.insert(Connections, Adornee.Destroying:Connect(function()
			ChatBubbleQueues[Adornee] = nil
		end))
	end

	local Gap = 4

	local BillboardFrameOfNew = ChatBubbleGui:FindFirstChild("BillboardFrame")

	local ChatBubble = BillboardFrameOfNew and BillboardFrameOfNew:FindFirstChild("ChatBubble")

	local NewBubbleHeight = 0

	if ChatBubble then
		NewBubbleHeight = ChatBubble.AbsoluteSize.Y

		if NewBubbleHeight <= 0 then
			NewBubbleHeight = ChatBubble.Size.Y.Offset
		end
	end

	local TotalYSpaceUsed = NewBubbleHeight

	-- shift the existing bubbles up
	for _, Bubble in ipairs(Queue) do
		local BillboardFrame = Bubble.Parent and Bubble:FindFirstChild("BillboardFrame")

		local ExistingBubble = BillboardFrame and BillboardFrame:FindFirstChild("ChatBubble")

		if ExistingBubble then
			local ShiftUp = NewBubbleHeight + Gap

			TweenService:Create(BillboardFrame, ShiftBubblesUpTweenInfo, {
				Position = BillboardFrame.Position - UDim2.fromOffset(0, ShiftUp),
			}):Play()

			TotalYSpaceUsed = TotalYSpaceUsed + ExistingBubble.AbsoluteSize.Y

			local ExistingText = ExistingBubble:FindFirstChild("BubbleText")

			if ExistingText then
				ExistingText.TextTransparency = 0.5
			end
		end
	end

	-- remove the oldest when it gets too tall
	if TotalYSpaceUsed > MAX_TOTAL_BUBBLE_HEIGHT then
		RemoveOldestFromQueue(Adornee)
	end

	table.insert(Queue, 1, ChatBubbleGui)

	-- remove this bubble after its lifetime
	task.delay(Lifetime + BUBBLE_FADE_TIME, function()
		if ChatBubbleGui.Parent then
			RemoveBubbleFromQueue(Adornee, ChatBubbleGui)
		end
	end)
end

--========================================================
-- LOOK
--========================================================

-- the rounded white body of a bubble
local function StyleBody(Label)
	if UseTextures then
		Label.Image = BUBBLE_IMAGE
		Label.ImageColor3 = BubbleBackground
		Label.ScaleType = Enum.ScaleType.Slice
		Label.SliceCenter = Rect.new(5, 5, 15, 15)
	else
		Label.BackgroundTransparency = 0
		Label.BackgroundColor3 = BubbleBackground

		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, 8)
		Corner.Parent = Label
	end
end

-- the little triangle under a bubble
local function StyleTail(Label)
	if UseTextures then
		Label.Image = TAIL_IMAGE
		Label.ImageColor3 = BubbleBackground
	else
		local Diamond = Instance.new("Frame")
		Diamond.Name = "Diamond"
		Diamond.AnchorPoint = Vector2.new(0.5, 0.5)
		Diamond.BackgroundColor3 = BubbleBackground
		Diamond.BorderSizePixel = 0
		Diamond.Position = UDim2.fromScale(0.5, 0.2)
		Diamond.Rotation = 45
		Diamond.Size = UDim2.fromOffset(12, 12)
		Diamond.Parent = Label
	end
end

local function MakePadding(Parent, Vertical)
	local Padding = Instance.new("UIPadding")
	Padding.Name = "UIPadding"
	Padding.PaddingBottom = UDim.new(0, Vertical)
	Padding.PaddingLeft = UDim.new(0, 12)
	Padding.PaddingRight = UDim.new(0, 12)
	Padding.PaddingTop = UDim.new(0, Vertical)
	Padding.Parent = Parent

	return Padding
end

--========================================================
-- CREATE A BUBBLE
--========================================================

local function CreateBubble(Adornee, Message, SentBySelf)
	if not Running or not Adornee or not Adornee.Parent then
		return
	end

	Message = SanitizeChatLine(Message)

	local ChatBubbleGui = Instance.new("BillboardGui")
	ChatBubbleGui.Name = "ChatBubbleGui"
	ChatBubbleGui.Size = UDim2.fromOffset(400, 250)
	ChatBubbleGui.Adornee = Adornee
	ChatBubbleGui:SetAttribute("ClassicOwned", true)
	ChatBubbleGui:SetAttribute("Bubble2017Owned", true)

	pcall(function()
		ChatBubbleGui.MaxDistance = MAX_BUBBLE_DISTANCE
	end)

	local BillboardFrame = Instance.new("Frame")
	BillboardFrame.Name = "BillboardFrame"
	BillboardFrame.AnchorPoint = Vector2.new(0.5, 0)
	BillboardFrame.BackgroundTransparency = 1
	BillboardFrame.Position = UDim2.fromScale(0.5, -0.5)
	BillboardFrame.Size = UDim2.fromScale(1, 1)
	BillboardFrame.Parent = ChatBubbleGui

	-- small "..." bubble (medium distance)
	local SmallTalkBubble = Instance.new("ImageLabel")
	SmallTalkBubble.Name = "SmallTalkBubble"
	SmallTalkBubble.AnchorPoint = Vector2.new(0.5, 1)
	SmallTalkBubble.BackgroundTransparency = 1
	SmallTalkBubble.BorderSizePixel = 0
	SmallTalkBubble.Position = UDim2.fromScale(0.5, 1)
	SmallTalkBubble.Size = UDim2.fromOffset(40, 30)
	SmallTalkBubble.Visible = false
	StyleBody(SmallTalkBubble)
	SmallTalkBubble.Parent = BillboardFrame

	local SmallTalkBubbleText = Instance.new("TextLabel")
	SmallTalkBubbleText.Name = "BubbleText"
	SmallTalkBubbleText.BackgroundTransparency = 1
	SmallTalkBubbleText.ClipsDescendants = true
	SmallTalkBubbleText.FontFace = BubbleFont
	SmallTalkBubbleText.Size = UDim2.fromScale(1, 1)
	SmallTalkBubbleText.Text = "..."
	SmallTalkBubbleText.TextColor3 = BubbleTextColor
	SmallTalkBubbleText.TextSize = BubbleTextSize
	SmallTalkBubbleText.Parent = SmallTalkBubble

	MakePadding(SmallTalkBubbleText, 12)

	local SmallTailFrame = Instance.new("Frame")
	SmallTailFrame.Name = "ChatBubbleTailFrame"
	SmallTailFrame.BackgroundTransparency = 1
	SmallTailFrame.Position = UDim2.fromScale(0.5, 1)
	SmallTailFrame.Size = UDim2.fromScale(0.5, 0.5)
	SmallTailFrame.SizeConstraint = Enum.SizeConstraint.RelativeXX
	SmallTailFrame.Parent = SmallTalkBubble

	local SmallTail = Instance.new("ImageLabel")
	SmallTail.Name = "ChatBubbleTail"
	SmallTail.BackgroundTransparency = 1
	SmallTail.BorderSizePixel = 0
	SmallTail.Position = UDim2.fromScale(-0.5, 0)
	SmallTail.Size = UDim2.fromScale(1, 0.5)
	StyleTail(SmallTail)
	SmallTail.Parent = SmallTailFrame

	-- main bubble
	local ChatBubble = Instance.new("ImageLabel")
	ChatBubble.Name = "ChatBubble"
	ChatBubble.AnchorPoint = Vector2.new(0.5, 1)
	ChatBubble.BackgroundTransparency = 1
	ChatBubble.BorderSizePixel = 0
	ChatBubble.Position = UDim2.fromScale(0.5, 1)
	ChatBubble.Visible = false
	StyleBody(ChatBubble)
	ChatBubble.Parent = BillboardFrame

	local BubbleText = Instance.new("TextLabel")
	BubbleText.Name = "BubbleText"
	BubbleText.BackgroundTransparency = 1
	BubbleText.ClipsDescendants = true
	BubbleText.FontFace = BubbleFont
	BubbleText.Size = UDim2.fromScale(1, 1)
	BubbleText.Text = ""
	BubbleText.TextColor3 = BubbleTextColor
	BubbleText.TextSize = BubbleTextSize
	BubbleText.TextWrapped = true
	BubbleText.Parent = ChatBubble

	local UIPadding = MakePadding(BubbleText, 12)

	local ChatBubbleTail = Instance.new("ImageLabel")
	ChatBubbleTail.Name = "ChatBubbleTail"
	ChatBubbleTail.BackgroundTransparency = 1
	ChatBubbleTail.BorderSizePixel = 0
	ChatBubbleTail.Position = UDim2.new(0.5, -14, 1, 0)
	ChatBubbleTail.Size = UDim2.fromOffset(30, 14)
	ChatBubbleTail.Visible = false
	StyleTail(ChatBubbleTail)
	ChatBubbleTail.Parent = BillboardFrame

	-- size from the text
	local TextSizeBounds = TextService:GetTextSize(
		Message,
		BubbleText.TextSize,
		BubbleText.Font,
		Vector2.new(MAX_BUBBLE_WIDTH, math.huge)
	)

	local Multiline = TextSizeBounds.Y > BubbleText.TextSize

	if not Multiline then
		UIPadding.PaddingTop = UDim.new(0, UIPadding.PaddingTop.Offset / 2)
		UIPadding.PaddingBottom = UDim.new(0, UIPadding.PaddingBottom.Offset / 2)
	end

	local ChatBubbleSize = UDim2.fromOffset(
		TextSizeBounds.X + UIPadding.PaddingLeft.Offset + UIPadding.PaddingRight.Offset + 1,
		TextSizeBounds.Y + UIPadding.PaddingTop.Offset + UIPadding.PaddingBottom.Offset
	)

	-- starts slightly bigger, then settles
	ChatBubble.Size = UDim2.fromOffset(ChatBubbleSize.X.Offset + 10, ChatBubbleSize.Y.Offset + 10)

	TweenService:Create(ChatBubble, ResizeBubbleTweenInfo, { Size = ChatBubbleSize }):Play()

	task.delay(ResizeBubbleTweenInfo.Time, function()
		if BubbleText.Parent then
			BubbleText.Text = Message
		end
	end)

	local Lifetime

	if SentBySelf then
		ChatBubbleGui.StudsOffset = Vector3.new(0, 1.8, 0)
		Lifetime = LerpLength(Message, MIN_BUBBLE_LIFETIME_SELF, MAX_BUBBLE_LIFETIME_SELF)
	else
		ChatBubbleGui.StudsOffset = Vector3.new(0, 2.4, 0)
		Lifetime = LerpLength(Message, MIN_BUBBLE_LIFETIME, MAX_BUBBLE_LIFETIME)
	end

	ChatBubbleGui.Parent = Adornee

	AllBubbleGuis[ChatBubbleGui] = true

	ChatBubbleGui.Destroying:Connect(function()
		AllBubbleGuis[ChatBubbleGui] = nil
	end)

	-- fade out
	task.delay(Lifetime, function()
		if not Running or not ChatBubbleGui.Parent then
			return
		end

		local FadeInfo = TweenInfo.new(BUBBLE_FADE_TIME, Enum.EasingStyle.Linear)

		for _, Object in ipairs(ChatBubbleGui:GetDescendants()) do
			if Object:IsA("ImageLabel") then
				TweenService:Create(Object, FadeInfo, { ImageTransparency = 1 }):Play()

				if not UseTextures and Object.BackgroundTransparency < 1 then
					TweenService:Create(Object, FadeInfo, { BackgroundTransparency = 1 }):Play()
				end
			elseif Object:IsA("TextLabel") then
				TweenService:Create(Object, FadeInfo, { TextTransparency = 1 }):Play()
			elseif Object:IsA("Frame") and Object.Name == "Diamond" then
				TweenService:Create(Object, FadeInfo, { BackgroundTransparency = 1 }):Play()
			end
		end
	end)

	Debris:AddItem(ChatBubbleGui, Lifetime + BUBBLE_FADE_TIME + 0.1)

	AddBubbleToQueue(Adornee, ChatBubbleGui, Lifetime)
end

--========================================================
-- RECEIVE TEXTCHAT MESSAGES
--========================================================

table.insert(Connections, TextChatService.MessageReceived:Connect(function(TextChatMessage)
	if not Running then
		return
	end

	local TextSource = TextChatMessage.TextSource

	-- system messages do not belong to a head
	if not TextSource then
		return
	end

	local Player = Players:GetPlayerByUserId(TextSource.UserId)

	if not Player then
		return
	end

	local Character = Player.Character

	if not Character then
		return
	end

	local Adornee = Character:FindFirstChild("Head") or Character:FindFirstChild("HumanoidRootPart") or Character

	local Message = TextChatMessage.Text

	if not Message or Message == "" then
		return
	end

	CreateBubble(Adornee, Message, Player == LocalPlayer)
end))

--========================================================
-- DISTANCE / VISIBILITY (every frame)
--========================================================

table.insert(Connections, RunService.Heartbeat:Connect(function()
	if not Running then
		return
	end

	Camera = workspace.CurrentCamera

	if not Camera then
		return
	end

	for Adornee, Queue in pairs(ChatBubbleQueues) do
		if not Adornee or not Adornee.Parent then
			ChatBubbleQueues[Adornee] = nil
		elseif #Queue > 0 then
			local MostRecentChatBubble = Queue[1]

			local DistanceFromAdornee = nil

			if MostRecentChatBubble and MostRecentChatBubble.Parent then
				pcall(function()
					DistanceFromAdornee = (Camera.CFrame.Position - Adornee:GetPivot().Position).Magnitude
				end)
			end

			if DistanceFromAdornee then
				for Index, BubbleGui in ipairs(Queue) do
					local BillboardFrame = BubbleGui.Parent and BubbleGui:FindFirstChild("BillboardFrame")

					if BillboardFrame then
						local MainBubble = BillboardFrame:FindFirstChild("ChatBubble")
						local SmallBubble = BillboardFrame:FindFirstChild("SmallTalkBubble")
						local MainTail = BillboardFrame:FindFirstChild("ChatBubbleTail")

						if DistanceFromAdornee < NEAR_BUBBLE_DISTANCE then
							-- near: the newest bubble has the tail
							if MainBubble then
								MainBubble.Visible = true
							end

							if MainTail then
								MainTail.Visible = Index == 1
							end

							if SmallBubble then
								SmallBubble.Visible = false
							end

							BubbleGui.Enabled = true
						elseif DistanceFromAdornee < MAX_BUBBLE_DISTANCE and Index == 1 then
							-- medium distance: only a small "..." bubble
							if MainBubble then
								MainBubble.Visible = false
							end

							if MainTail then
								MainTail.Visible = false
							end

							if SmallBubble then
								SmallBubble.Visible = true
							end

							BubbleGui.Enabled = true
						else
							-- far away
							BubbleGui.Enabled = false
						end
					end
				end
			end
		end
	end
end))

--========================================================
-- STOP
--========================================================

local function Stop()
	if not Running then
		return
	end

	Running = false

	for _, Connection in ipairs(Connections) do
		pcall(function()
			Connection:Disconnect()
		end)
	end

	Connections = {}

	for BubbleGui in pairs(AllBubbleGuis) do
		pcall(function()
			BubbleGui:Destroy()
		end)
	end

	AllBubbleGuis = {}

	ChatBubbleQueues = {}

	-- the modern bubbles come back
	pcall(function()
		local Configuration = GetBubbleConfiguration()

		if Configuration and SavedBubbleEnabled ~= nil then
			Configuration.Enabled = SavedBubbleEnabled
		end
	end)

	if Env.Bubble2017Cleanup == Stop then
		Env.Bubble2017Cleanup = nil
		Env.Bubble2017Running = nil
	end
end

Env.Bubble2017Cleanup = Stop

Env.Bubble2017Running = true

print("[2017 bubbles] running")

-- end of 2017_bubble_chat.lua
