--========================================================
-- COMBINED BLOXY PARADOX LOADER
-- + Execution Default = 100% Normal (No Auto-Load)
-- + Strict "Confirm" Button Trigger ONLY
-- + Perfect Era Isolation (2010-2014 vs Modern/None)
-- + Safe Native Dialog Bypass (No overlap, no glitching)
-- + Player dialog bubbles render perfectly (Folder host)
-- + Regular Chat Bubbles 100% Untouched
-- + 2015/2016 use the 2017 chat bubbles (only after Confirm, only when 2015 or 2016 is chosen)
--========================================================

if getgenv().ClassicDialogCleanup then
    pcall(getgenv().ClassicDialogCleanup)
    getgenv().ClassicDialogCleanup = nil
end
-- running this script again starts from normal: no 2017 bubbles until Confirm
if getgenv().Bubble2017Cleanup then
    pcall(getgenv().Bubble2017Cleanup)
    getgenv().Bubble2017Cleanup = nil
end
getgenv().BloxyEraLoopId = nil

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local mainAddons = {
    "https://gist.githubusercontent.com/eloredo413-hue/b902b556dbdc8595dd62bbc1964b809e/raw/53f08968605e02116c4b11877e5aa9da8d8d081b/Old%2520Sound%2520Replace%2520Addon",
    "https://gist.githubusercontent.com/eloredo413-hue/ab9f65a116c2d16f989ec72cf254a72f/raw/d6cc1e5239b675e639556af59509192bfdeca1f3/Quick%2520Texture%2520load%2520studs",
    "https://gist.githubusercontent.com/eloredo413-hue/524e76f705199e08a78a72e7bf79b27d/raw/768a58df75a996d9a306b471526cdd2c31d812a1/Hammer%2520stuff%25201",
    "https://gist.githubusercontent.com/eloredo413-hue/09b2609e8aff413a178a16ac8477b612/raw/20961a4f1364c9805b1e93ab34f14abc4cc3998f/Particles%2520addon",
    "https://gist.githubusercontent.com/eloredo413-hue/71f4843dc549f0a415ba9978e7a7de28/raw/54749c226b40163de09c82286a69926d389cc40b/Wizard%2520smooth",
    "https://gist.githubusercontent.com/eloredo413-hue/f156101652b68d2fdcbbeae4dc0481d6/raw/028c65e676eda5d90f9c3a0595347b102df2a0b9/2010%2520hook",
    "https://gist.githubusercontent.com/eloredo413-hue/05925bea976af10969d45b0213b95a3d/raw/3742e5f667698cdbea748c150418aaf4f18749c4/Camera%2520Physics%2520Addon",
    -- TEST: disabled old "More guis" copy
    -- "https://gist.githubusercontent.com/eloredo413-hue/84575df86d6267ef937df9093516b4eb/raw/c6c19cd99d63dd6b37d03a89fc667c5eb7bd36e2/More%2520guis",
    -- TEST: disabled old "More guis" copy
    -- "https://gist.githubusercontent.com/eloredo413-hue/e927d9ce080849c543a08162cedb8c98/raw/46b20b8242e4c700b300f514ac3b580365a6ec4c/More%2520guis",
    "https://gist.githubusercontent.com/eloredo413-hue/0386978714c4e0c69e9de2415b36ee66/raw/5471dd8099e097c97f210374934382fbc843afaf/Explosion%2520Replace%2520Addon",
}

local URL_TOPBAR_HOOK       = "https://gist.githubusercontent.com/eloredo413-hue/822858f51ce223feb25b5aa27147b98f/raw/aed2718e1f5deff9bd8286d878d4c34a8f2103b8/More%2520guis"
local URL_SAFECHAT_HOOK     = "https://gist.githubusercontent.com/eloredo413-hue/47847c9c0567c5b365c8bfa249d59190/raw/036418365fc79e40e7dc1d1120fca6de9e4600a0/Safe%2520chat%2520Hook"
local URL_BUBBLE_SCRIPT     = "https://gist.githubusercontent.com/eloredo413-hue/b60bebc8596be9e0174e23ca00edd14e/raw/37f520332a1a89676e03079e39743e2c93852e40/Chat%2520bubble%2520fix%25202011"
local URL_HAMMER_2          = "https://gist.githubusercontent.com/eloredo413-hue/cb580c5dd38155af6f0772db96c5c131/raw/67c40ac116e51426c5242c7a6b04106397a07016/Hammer%2520stuff%25202"
local URL_BUBBLE_2015_2016  = "https://gist.githubusercontent.com/eloredo413-hue/f37d62b43e7435cd46dd495b5ed1bcfc/raw/b4ae511afdec2e92e9b956a8ddc4803d9929d0da/Chat%2520bubble%2520fix"

-- The 2017 chat bubbles (taken from the 2017 core gui's OldBubbleChat) as a script of their own.
-- They are used for 2015 and 2016. (The gist above is now only used for 2017-2020, as before.)
local URL_BUBBLE_2017 = "https://raw.githubusercontent.com/eloredo413-hue/E/ccr-f33d83ed-bgaekc/2017_bubble_chat.lua"

local function loadUrl(url, label)
    local ok, src = pcall(game.HttpGet, game, url)
    if not ok or type(src) ~= "string" then return false end
    local chunk = loadstring(src)
    if not chunk then return false end
    return pcall(chunk)
end

--========================================================
-- UNCONDITIONAL MAIN ADDONS (Always Load)
--========================================================
for i, url in ipairs(mainAddons) do loadUrl(url, "addon" .. i) task.wait(0.1) end
loadUrl(URL_TOPBAR_HOOK, "Topbar Hook")
task.wait(0.5)
loadUrl(URL_SAFECHAT_HOOK, "SafeChat Hook")
task.wait(1)
loadUrl(URL_HAMMER_2, "Hammer stuff 2")

--========================================================
-- SYSTEM INJECTORS
--========================================================
task.spawn(function()
    local player = Players.LocalPlayer
    local pg = player:WaitForChild("PlayerGui")

    local dialogLoaded_Classic = false

    -- Text of a saved choice: a string, or (if the config stores a table) its string values.
    local function choiceText(value)
        if type(value) == "string" then return value end
        if type(value) == "table" then
            local parts = {}
            for _, v in pairs(value) do
                if type(v) == "string" then table.insert(parts, v) end
            end
            return table.concat(parts, " ")
        end
        return nil
    end

    -- classic    = 2010-2014 / mobile
    -- bubble2017 = 2015 / 2016 (they use the 2017 bubbles)
    -- modern     = 2017-2020
    -- none       = anything else (no GUI selected): nothing is touched
    -- 2015 / 2016 win when the text names one of them (a label such as "2016 (2014 style)" is
    -- 2016); the classic years and "mobile" only decide when no 2015 / 2016 is named.
    local function classifyEra(text)
        local s = string.lower(text or "")
        if s:find("2015", 1, true) or s:find("2016", 1, true) then return "bubble2017" end
        if s:find("2010", 1, true) or s:find("2011", 1, true) or s:find("2012", 1, true)
           or s:find("2013", 1, true) or s:find("2014", 1, true) or s:find("mobile", 1, true) then
            return "classic"
        end
        if s:find("2017", 1, true) or s:find("2018", 1, true) or s:find("2019", 1, true) or s:find("2020", 1, true) then
            return "modern"
        end
        return "none"
    end

    local function getSelectedEra()
        local actual = "none"
        pcall(function()
            if readfile and isfile and isfile("BloxyParadoxConfig.json") then
                local cfg = HttpService:JSONDecode(readfile("BloxyParadoxConfig.json"))
                actual = (cfg.Choices and cfg.Choices.Topbar) or cfg.Topbar or cfg.topbar or cfg.TopbarChoice or cfg.TopbarID or "none"
            end
        end)

        local text = choiceText(actual)
        if not text then return "none", tostring(actual) end
        return classifyEra(text), text
    end

    local TextChatService = game:GetService("TextChatService")
    local nativeBubblesHidden = false
    local hiddenNativeBubbles = {}
    local savedBubbleEnabled = nil

    local function sweepNativeBubbles()
        pcall(function()
            for _, obj in ipairs(CoreGui:GetDescendants()) do
                if obj:IsA("BillboardGui") and obj.Enabled
                   and not obj:GetAttribute("ClassicOwned")
                   and string.find(string.lower(obj.Name), "bubble", 1, true) then
                    obj.Enabled = false
                    hiddenNativeBubbles[obj] = true
                end
            end
        end)
    end

    local function setNativeBubbles(hide)
        if hide then
            nativeBubblesHidden = true
            pcall(function()
                local cfg = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
                if cfg then
                    if savedBubbleEnabled == nil then savedBubbleEnabled = cfg.Enabled end
                    cfg.Enabled = false
                end
            end)
            sweepNativeBubbles()
        elseif nativeBubblesHidden then
            nativeBubblesHidden = false
            pcall(function()
                local cfg = TextChatService:FindFirstChildOfClass("BubbleChatConfiguration")
                if cfg and savedBubbleEnabled ~= nil then cfg.Enabled = savedBubbleEnabled end
                savedBubbleEnabled = nil
            end)
            for obj in pairs(hiddenNativeBubbles) do
                pcall(function() obj.Enabled = true end)
            end
            hiddenNativeBubbles = {}
        end
    end

    --========================================================
    -- BUBBLE SCRIPTS (one per era)
    -- Loaded with retries; remembered only when they really started; the previous era's bubbles
    -- are stopped (through the cleanup function the script registered) before the next era's
    -- script starts, so two eras never run on top of each other.
    --========================================================
    local BUBBLE_SOURCES = {
        classic    = function() return { URL_BUBBLE_SCRIPT } end,
        bubble2017 = function() return { URL_BUBBLE_2017 .. "?cb=" .. tostring(os.time()), URL_BUBBLE_2017 } end,
        modern     = function() return { URL_BUBBLE_2015_2016 } end,
    }
    -- a downloaded script must contain its end marker (a cut-short download is tried again)
    local BUBBLE_MARKERS = { bubble2017 = "end of 2017_bubble_chat.lua" }
    local CLEANUP_WORDS = { "cleanup", "unload", "destroy", "stop", "disable" }

    local activeBubbleEra = nil     -- era whose bubble script is running right now
    local bubbleCleanups = {}       -- era -> functions that stop that script
    local cannotStop = {}           -- era -> true: it ran but registered no cleanup (stays running)
    local bubbleBusy = false
    local desiredBubbleEra = nil    -- the era the last Confirm asked for (nil = no GUI selected)
    local lastFailedEra = nil       -- an era whose download failed (tried again on the next Confirm)

    local function snapshotGenv()
        local copy = {}
        pcall(function() for k, v in pairs(getgenv()) do copy[k] = v end end)
        return copy
    end

    local function fetchBubbleSource(urls, marker)
        for _, url in ipairs(urls) do
            for attempt = 1, 2 do
                local ok, src = pcall(game.HttpGet, game, url)
                if ok and type(src) == "string" and #src > 20 and not src:find("^%s*<") and not src:find("^404")
                   and (not marker or src:find(marker, 1, true)) then
                    return src, url
                end
                task.wait(0.4)
            end
        end
        return nil
    end

    local function stopBubbleScript(era)
        if era == "bubble2017" and getgenv().Bubble2017Cleanup then
            pcall(getgenv().Bubble2017Cleanup)
        end
        for _, fn in ipairs(bubbleCleanups[era] or {}) do pcall(fn) end
        bubbleCleanups[era] = nil
        if activeBubbleEra == era then activeBubbleEra = nil end
        getgenv().BloxyBubbleEra = activeBubbleEra
    end

    local function startBubbleScript(era)
        if activeBubbleEra == era or bubbleBusy then return end
        bubbleBusy = true
        pcall(function()
            -- a script that cannot be stopped is still running: do not start a second copy
            if cannotStop[era] then
                if activeBubbleEra then stopBubbleScript(activeBubbleEra) end
                activeBubbleEra = era
                getgenv().BloxyBubbleEra = era
                return
            end

            local src, usedUrl = fetchBubbleSource(BUBBLE_SOURCES[era](), BUBBLE_MARKERS[era])
            if not src then
                lastFailedEra = era
                warn("[Loader] could not download the " .. era .. " bubble script (will retry on the next Confirm)")
                return
            end
            -- the choice may have changed while it was downloading (another era, or none)
            if desiredBubbleEra ~= era then return end
            if activeBubbleEra then stopBubbleScript(activeBubbleEra) end
            local chunk, compileError = loadstring(src)
            if not chunk then
                warn("[Loader] the " .. era .. " bubble script did not compile:", compileError)
                return
            end

            -- The script runs on its own thread. Most return at once; one that keeps running in
            -- its main part (a loop) must not hold this loader up, so it is waited for 3 seconds.
            local before = snapshotGenv()
            local finished, runOk, runError = false, true, nil
            task.spawn(function()
                runOk, runError = pcall(chunk)
                finished = true
            end)
            local waited = 0
            while not finished and waited < 3 do
                task.wait(0.1)
                waited = waited + 0.1
            end
            if finished and not runOk then
                warn("[Loader] the " .. era .. " bubble script errored:", runError)
                return
            end

            -- any new global function named like a cleanup stops this script later
            local cleanups = {}
            pcall(function()
                for key, value in pairs(getgenv()) do
                    if before[key] ~= value and type(value) == "function" then
                        local lowered = string.lower(tostring(key))
                        for _, word in ipairs(CLEANUP_WORDS) do
                            if lowered:find(word, 1, true) then table.insert(cleanups, value) break end
                        end
                    end
                end
            end)
            bubbleCleanups[era] = cleanups
            cannotStop[era] = (#cleanups == 0) or nil
            activeBubbleEra = era
            getgenv().BloxyBubbleEra = era
            print("[Loader] " .. era .. " bubbles loaded from " .. tostring(usedUrl):sub(1, 90))
        end)
        bubbleBusy = false
        -- the last Confirm may have asked for another era while this one was loading
        if desiredBubbleEra and desiredBubbleEra ~= activeBubbleEra and lastFailedEra ~= desiredBubbleEra then
            task.spawn(startBubbleScript, desiredBubbleEra)
        end
    end

    local function injectClassicDialogs()
        if getgenv().ClassicDialogCleanup then pcall(getgenv().ClassicDialogCleanup) end

        local LocalPlayer = Players.LocalPlayer
        local connections = {}
        local SESSION_ID = tostring(os.clock())
        local parentGui = (gethui and gethui()) or CoreGui or pg

        local activeNPC, activeDialog = nil, nil
        local dialogGeneration = 0
        local hookedNPCs = {}
        local dialogCounter = 0
        local disabledNative = {}

        local OVERHEAD_ICONS = {
            Neutral  = "rbxassetid://44197302",
            Friendly = "rbxassetid://44197280",
            Enemy    = "rbxassetid://44197248",
        }
        local TONE_BACKGROUNDS = {
            Neutral  = "rbxassetid://112937316668112",
            Friendly = "rbxassetid://87266893464059",
            Enemy    = "rbxassetid://137202834516465",
        }
        local TONE_TAILS_BOTTOM = {
            Neutral  = "rbxassetid://123812487475700",
            Friendly = "rbxassetid://133902375146299",
            Enemy    = "rbxassetid://96906382970929",
        }
        local TONE_TAILS_RIGHT = {
            Neutral  = "rbxassetid://105269546831524",
            Friendly = "rbxassetid://90128448889142",
            Enemy    = "rbxassetid://115414034377238",
        }
        local PURPOSE_ICONS = {
            Quest = "rbxassetid://4542442173",
            Help  = "rbxassetid://4542442707",
            Shop  = "rbxassetid://4542442549",
        }
        local TONE_COLORS = {
            Neutral  = Color3.fromRGB(0, 0, 175),
            Friendly = Color3.fromRGB(0, 145, 35),
            Enemy    = Color3.fromRGB(175, 0, 0),
        }

        local function enumLeaf(val) return (tostring(val):match("[^.]+$")) or "" end
        local function getTone(dialog)
            if not dialog then return "Neutral" end
            local t = enumLeaf(dialog.Tone)
            return TONE_BACKGROUNDS[t] and t or "Neutral"
        end

        local function measureBubble(text)
            text = tostring(text or "")
            if text == "" then return 120, 44 end
            local measurement = TextService:GetTextSize(text, 16, Enum.Font.SourceSans, Vector2.new(280, 2000))
            return math.clamp(measurement.X + 32, 120, 320), math.clamp(measurement.Y + 28, 44, 400)
        end

        local gui = Instance.new("ScreenGui")
        gui.Name = "ClassicDialogExecutorGui"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 100
        gui.Parent = parentGui

        if getgenv().ClassicDialogDebug == nil then getgenv().ClassicDialogDebug = true end
        local function dbg(...)
            if getgenv().ClassicDialogDebug then warn("[ClassicDialog]", ...) end
        end

        local billboardHost
        local function ensureHost()
            if billboardHost and billboardHost.Parent then return billboardHost end
            dbg("creating billboard host folder")
            billboardHost = Instance.new("Folder")
            billboardHost.Name = "ClassicDialogBillboardHost"
            local success = pcall(function() billboardHost.Parent = CoreGui end)
            if not success then billboardHost.Parent = pg end
            return billboardHost
        end
        ensureHost()

        local noticeGui = Instance.new("ScreenGui")
        noticeGui.Name = "ClassicDialogNoticeGui"
        noticeGui.ResetOnSpawn = false
        noticeGui.DisplayOrder = 101
        noticeGui.Parent = parentGui

        local function showSystemNotice(text, duration)
            duration = duration or 2.5
            local existing = noticeGui:FindFirstChild("Notice")
            if existing then existing:Destroy() end

            local measured = TextService:GetTextSize(text, 20, Enum.Font.SourceSans, Vector2.new(2000, 2000))
            local boxWidth = math.max(measured.X + 32, 250)

            local frame = Instance.new("Frame")
            frame.Name = "Notice"
            frame.AnchorPoint = Vector2.new(0.5, 0.5)
            frame.Size = UDim2.new(0, boxWidth, 0, 40)
            frame.Position = UDim2.new(0.5, 0, 0.5, 0)
            frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            frame.BackgroundTransparency = 0.4
            frame.BorderSizePixel = 0
            frame.ZIndex = 100
            frame.Parent = noticeGui

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = frame

            local label = Instance.new("TextLabel")
            label.Name = "Text"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.Position = UDim2.new(0, 0, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextSize = 20
            label.Font = Enum.Font.SourceSans
            label.ZIndex = 101
            label.Parent = frame

            task.delay(duration, function()
                if frame and frame.Parent then frame:Destroy() end
            end)
        end

        local dialogWrap = Instance.new("Frame")
        dialogWrap.Name = "DialogWrap"
        dialogWrap.Size = UDim2.new(0, 382, 0, 64)
        dialogWrap.Position = UDim2.new(0, 15, 1, -99)
        dialogWrap.BackgroundTransparency = 1
        dialogWrap.Visible = false
        dialogWrap.Parent = gui

        local boxBg = Instance.new("ImageLabel")
        boxBg.Size = UDim2.new(0, 330, 1, 0)
        boxBg.BackgroundTransparency = 1
        boxBg.Image = TONE_BACKGROUNDS.Neutral
        boxBg.ScaleType = Enum.ScaleType.Slice
        boxBg.SliceCenter = Rect.new(16, 16, 16, 16)
        boxBg.SliceScale = 0.55
        boxBg.Parent = dialogWrap

        local boxInterior = Instance.new("Frame")
        boxInterior.Size = UDim2.new(1, -20, 1, -20)
        boxInterior.Position = UDim2.new(0, 10, 0, 10)
        boxInterior.BackgroundColor3 = TONE_COLORS.Neutral
        boxInterior.BorderSizePixel = 0
        boxInterior.Parent = boxBg
        Instance.new("UICorner", boxInterior).CornerRadius = UDim.new(0, 12)

        local boxSideTail = Instance.new("ImageLabel")
        boxSideTail.AnchorPoint = Vector2.new(0, 0.5)
        boxSideTail.Size = UDim2.new(0, 52, 0, 36)
        boxSideTail.Position = UDim2.new(1, -12, 0.5, 0)
        boxSideTail.BackgroundTransparency = 1
        boxSideTail.Image = TONE_TAILS_RIGHT.Neutral
        boxSideTail.ScaleType = Enum.ScaleType.Fit
        boxSideTail.Parent = boxBg

        local choicesContainer = Instance.new("ScrollingFrame")
        choicesContainer.Size = UDim2.new(1, -20, 1, -16)
        choicesContainer.Position = UDim2.new(0, 10, 0, 8)
        choicesContainer.BackgroundTransparency = 1
        choicesContainer.BorderSizePixel = 0
        choicesContainer.ScrollingDirection = Enum.ScrollingDirection.Y
        choicesContainer.ScrollBarThickness = 4
        choicesContainer.Parent = boxBg

        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 2)
        listLayout.Parent = choicesContainer

        local function updateBoxHeight(itemCount)
            local contentHeight = (itemCount * 28) + (math.max(0, itemCount - 1) * 2) + 16
            local finalHeight = math.clamp(contentHeight, 64, 520)
            dialogWrap.Size = UDim2.new(0, 382, 0, finalHeight)
            dialogWrap.Position = UDim2.new(0, 15, 1, -finalHeight - 35)
            choicesContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
        end

        local function clearChoices()
            for _, child in ipairs(choicesContainer:GetChildren()) do
                if child:IsA("GuiObject") and child ~= listLayout then child:Destroy() end
            end
        end

        local function showPlayerBubble(text, duration, tone)
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
            if not head then return end

            local old = ensureHost():FindFirstChild("PlayerDialogBubble")
            if old then old:Destroy() end

            local bw, bh = measureBubble(text)
            tone = tone or "Neutral"

            local bg = {
                Neutral = "rbxassetid://112937316668112",
                Friendly = "rbxassetid://87266893464059",
                Enemy = "rbxassetid://137202834516465"
            }
            local tails = {
                Neutral = "rbxassetid://123812487475700",
                Friendly = "rbxassetid://133902375146299",
                Enemy = "rbxassetid://96906382970929"
            }

            local bb = Instance.new("BillboardGui")
            bb.Name = "PlayerDialogBubble"
            bb.Adornee = head
            bb.Size = UDim2.new(0, bw + 4, 0, bh + 22)
            bb.StudsOffsetWorldSpace = Vector3.new(0, 4.6, 0)
            bb.AlwaysOnTop = false
            bb.MaxDistance = math.huge
            bb:SetAttribute("ClassicOwned", true)
            bb.Parent = ensureHost()

            local bubble = Instance.new("ImageLabel")
            bubble.Name = "Body"
            bubble.Size = UDim2.new(1, 0, 0, bh)
            bubble.Position = UDim2.new(0, 0, 0, 0)
            bubble.BackgroundTransparency = 1
            bubble.Image = bg[tone] or bg.Neutral
            bubble.ScaleType = Enum.ScaleType.Slice
            bubble.SliceCenter = Rect.new(16, 16, 16, 16)
            bubble.SliceScale = 0.55
            bubble.ZIndex = 1
            bubble.Parent = bb

            local tail = Instance.new("ImageLabel")
            tail.Name = "Tail"
            tail.AnchorPoint = Vector2.new(0.5, 0)
            tail.Size = UDim2.new(0, 22, 0, 22)
            tail.Position = UDim2.new(0.5, 0, 0, bh - 7)
            tail.BackgroundTransparency = 1
            tail.Image = tails[tone] or tails.Neutral
            tail.ScaleType = Enum.ScaleType.Fit
            tail.ZIndex = 3
            tail.Parent = bb

            local label = Instance.new("TextLabel")
            label.Name = "Text"
            label.Size = UDim2.new(1, -24, 1, -16)
            label.Position = UDim2.new(0, 12, 0, 8)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextSize = 16
            label.Font = Enum.Font.SourceSans
            label.TextWrapped = true
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.TextYAlignment = Enum.TextYAlignment.Center
            label.ZIndex = 4
            label.Parent = bubble

            task.delay(duration or 3, function() if bb and bb.Parent then bb:Destroy() end end)
        end

        local function setBubbleActive(bb, text, dialog)
            if not bb then return end
            local tone = getTone(dialog)
            local bw, bh = measureBubble(text)

            bb:SetAttribute("IsInDialog", true)
            bb.Size = UDim2.new(0, bw, 0, bh + 22)

            local iconBubble = bb:FindFirstChild("IconBubble")
            if iconBubble then iconBubble.Visible = false end

            local textFrame = bb:FindFirstChild("TextBubble")
            if textFrame then
                textFrame.Visible = true
                textFrame.Image = TONE_BACKGROUNDS[tone] or TONE_BACKGROUNDS.Neutral
                textFrame.Size = UDim2.new(1, 0, 0, bh)
                textFrame.Position = UDim2.new(0, 0, 0, 0)

                local bubbleText = textFrame:FindFirstChild("BubbleText")
                if bubbleText then
                    bubbleText.Visible = true
                    bubbleText.Text = tostring(text or "")
                end
            end

            local bubbleTail = bb:FindFirstChild("BubbleTail")
            if bubbleTail then
                bubbleTail.Image = TONE_TAILS_BOTTOM[tone] or TONE_TAILS_BOTTOM.Neutral
                bubbleTail.Position = UDim2.new(0.5, 0, 0, bh - 7)
                bubbleTail.Visible = true
            end
        end

        local function restoreBubbleIcon(bb, dialog)
            if not bb then return end
            bb:SetAttribute("IsInDialog", false)

            local textFrame = bb:FindFirstChild("TextBubble")
            if textFrame then textFrame.Visible = false end

            local bubbleTail = bb:FindFirstChild("BubbleTail")
            if bubbleTail then bubbleTail.Visible = false end

            local tone = getTone(dialog)
            local iconBubble = bb:FindFirstChild("IconBubble")
            if iconBubble then
                iconBubble.Image = OVERHEAD_ICONS[tone] or OVERHEAD_ICONS.Neutral
                iconBubble.Visible = true

                local purposeIcon = iconBubble:FindFirstChild("PurposeIcon")
                if purposeIcon then
                    local pStr = dialog and enumLeaf(dialog.Purpose) or "Help"
                    purposeIcon.Image = PURPOSE_ICONS[pStr] or PURPOSE_ICONS.Help
                    purposeIcon.Visible = true
                end
            end

            local cam = Workspace.CurrentCamera
            if cam and bb.Adornee then
                local dist = (cam.CFrame.Position - bb.Adornee.Position).Magnitude
                local zoom = math.clamp(30 / math.max(dist, 3), 0.1, 2.5)
                bb:SetAttribute("CurrentZoom", zoom)
                bb.Size = UDim2.new(0, 46 * zoom, 0, 60 * zoom)
                if iconBubble then
                    local pIcon = iconBubble:FindFirstChild("PurposeIcon")
                    if pIcon then
                        pIcon.Size = UDim2.new(0, 28 * zoom, 0, 28 * zoom)
                        pIcon.Position = UDim2.new(0.5, -(28 * zoom / 2), 0, 4 * zoom)
                    end
                end
            end
        end

        local function endDialog()
            dbg("dialog ended from:", debug.traceback("", 2))
            dialogGeneration = dialogGeneration + 1
            dialogWrap.Visible = false

            local oldNPC = activeNPC
            local oldDialog = activeDialog
            activeNPC, activeDialog = nil, nil
            clearChoices()

            if oldNPC and oldDialog then
                local data = hookedNPCs[oldDialog]
                if data and data.bb then
                    pcall(function() restoreBubbleIcon(data.bb, oldDialog) end)
                end
            end
        end

        local function createChoiceButton(text, layoutOrder)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -4, 0, 28)
            btn.BackgroundTransparency = 1
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 15
            btn.Font = Enum.Font.SourceSans
            btn.Text = "  " .. tostring(text)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.LayoutOrder = layoutOrder
            btn.Parent = choicesContainer
            btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0.88 end)
            btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 1 end)
            return btn
        end

        local function getDialogChoices(node)
            local choices = {}
            pcall(function()
                for _, child in ipairs(node:GetChildren()) do
                    if child:IsA("DialogChoice") then table.insert(choices, child) end
                end
            end)
            return choices
        end

        local function displayNode(node, promptText)
            if not node then return end
            local generation = dialogGeneration
            clearChoices()

            local text = promptText or (node:IsA("Dialog") and node.InitialPrompt) or (node:IsA("DialogChoice") and node.ResponseDialog) or ""
            if activeNPC and activeDialog then
                local data = hookedNPCs[activeDialog]
                if data and data.bb then setBubbleActive(data.bb, text, activeDialog) end
            end

            local choices = getDialogChoices(node)
            updateBoxHeight(#choices + 1)

            for index, choice in ipairs(choices) do
                local userText = (choice.UserDialog ~= "" and choice.UserDialog) or choice.Name
                local btn = createChoiceButton(index .. ") " .. userText, index)

                btn.Activated:Connect(function()
                    if generation ~= dialogGeneration or not activeDialog then return end

                    showPlayerBubble(userText, 2.5, getTone(activeDialog))

                    local responseText = choice.ResponseDialog or ""
                    local subChoices = getDialogChoices(choice)

                    if #subChoices > 0 then
                        dialogGeneration = dialogGeneration + 1
                        local nextGen = dialogGeneration
                        task.delay(0.2, function()
                            if nextGen == dialogGeneration and activeNPC and activeDialog then
                                displayNode(choice, responseText)
                            end
                        end)
                    else
                        dialogGeneration = dialogGeneration + 1
                        local endGen = dialogGeneration
                        if activeNPC then
                            local data = hookedNPCs[activeDialog]
                            if data and data.bb then setBubbleActive(data.bb, responseText, activeDialog) end
                        end
                        task.delay(1.5, function()
                            if endGen == dialogGeneration then endDialog() end
                        end)
                    end
                end)
            end

            local goodbyeText = "Goodbye!"
            pcall(function()
                local g = node.GoodbyeDialog
                if type(g) == "string" and g ~= "" then goodbyeText = g end
            end)
            local goodbyeBtn = createChoiceButton((#choices + 1) .. ") " .. goodbyeText, #choices + 1)
            goodbyeBtn.Activated:Connect(function()
                if generation ~= dialogGeneration or not activeDialog then return end
                showPlayerBubble(goodbyeText, 2, getTone(activeDialog))
                endDialog()
            end)

            task.defer(function() choicesContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y) end)
        end

        local function startDialog(dialog, head)
            if activeNPC == head and activeDialog == dialog then return end
            dialogGeneration = dialogGeneration + 1
            activeNPC = head
            activeDialog = dialog

            local tone = getTone(dialog)
            boxBg.Image = TONE_BACKGROUNDS[tone] or TONE_BACKGROUNDS.Neutral
            boxInterior.BackgroundColor3 = TONE_COLORS[tone] or TONE_COLORS.Neutral
            boxSideTail.Image = TONE_TAILS_RIGHT[tone] or TONE_TAILS_RIGHT.Neutral

            local prompt = dialog.InitialPrompt or ""
            local data = hookedNPCs[dialog]
            if data and data.bb then setBubbleActive(data.bb, prompt, dialog) end

            dialogWrap.Visible = true
            displayNode(dialog, prompt)
        end

        local function hookDialog(dialog)
            if not dialog or not dialog:IsA("Dialog") or dialog:GetAttribute("ClassicHooked") == SESSION_ID then return end

            local head = dialog:FindFirstAncestorWhichIsA("BasePart") or (dialog.Parent and dialog.Parent:IsA("BasePart") and dialog.Parent)
            if not head then task.delay(1, function() hookDialog(dialog) end) return end

            dialog:SetAttribute("ClassicHooked", SESSION_ID)

            local origDist = dialog:GetAttribute("OrigDist")
            if not origDist then
                origDist = dialog.ConversationDistance
                dialog:SetAttribute("OrigDist", origDist)
            end
            pcall(function() dialog.ConversationDistance = 0 end)

            dialogCounter = dialogCounter + 1
            local bbName = "ClassicExecutorDialogGui_" .. dialogCounter

            local tone = getTone(dialog)

            local bb = Instance.new("BillboardGui")
            bb.Name = bbName
            bb.Adornee = head
            bb.Size = UDim2.new(0, 46, 0, 60)
            bb.StudsOffsetWorldSpace = Vector3.new(0, 4.6, 0)
            bb.AlwaysOnTop = false
            bb.Active = true
            bb.MaxDistance = math.huge
            bb:SetAttribute("ClassicOwned", true)
            bb.Parent = ensureHost()
            bb:SetAttribute("IsInDialog", false)

            local iconBubble = Instance.new("ImageLabel")
            iconBubble.Name = "IconBubble"
            iconBubble.Size = UDim2.new(1, 0, 1, 0)
            iconBubble.BackgroundTransparency = 1
            iconBubble.Image = OVERHEAD_ICONS[tone] or OVERHEAD_ICONS.Neutral
            iconBubble.ScaleType = Enum.ScaleType.Fit
            iconBubble.ZIndex = 1
            iconBubble.Visible = true
            iconBubble.Parent = bb

            local clickBtn = Instance.new("TextButton")
            clickBtn.Size = UDim2.new(1, 0, 1, 0)
            clickBtn.BackgroundTransparency = 1
            clickBtn.Text = ""
            clickBtn.ZIndex = 10
            clickBtn.Parent = iconBubble

            clickBtn.MouseButton1Click:Connect(function()
                local char = LocalPlayer.Character
                local myHead = char and char:FindFirstChild("Head")
                if not myHead then return end

                local dist = (myHead.Position - head.Position).Magnitude
                local maxDist = dialog:GetAttribute("OrigDist") or 25
                if dist <= maxDist then
                    startDialog(dialog, head)
                end
            end)

            local pStr = dialog.Purpose and enumLeaf(dialog.Purpose) or "Help"
            local purposeIcon = Instance.new("ImageLabel")
            purposeIcon.Name = "PurposeIcon"
            purposeIcon.Size = UDim2.new(0, 28, 0, 28)
            purposeIcon.Position = UDim2.new(0.5, -14, 0, 4)
            purposeIcon.BackgroundTransparency = 1
            purposeIcon.Image = PURPOSE_ICONS[pStr] or PURPOSE_ICONS.Help
            purposeIcon.ScaleType = Enum.ScaleType.Fit
            purposeIcon.ZIndex = 3
            purposeIcon.Visible = true
            purposeIcon.Parent = iconBubble

            local textFrame = Instance.new("ImageLabel")
            textFrame.Name = "TextBubble"
            textFrame.Size = UDim2.new(1, 0, 1, 0)
            textFrame.BackgroundTransparency = 1
            textFrame.Image = TONE_BACKGROUNDS[tone] or TONE_BACKGROUNDS.Neutral
            textFrame.ScaleType = Enum.ScaleType.Slice
            textFrame.SliceCenter = Rect.new(16, 16, 16, 16)
            textFrame.SliceScale = 0.55
            textFrame.ZIndex = 2
            textFrame.Visible = false
            textFrame.Parent = bb

            local bubbleText = Instance.new("TextLabel")
            bubbleText.Name = "BubbleText"
            bubbleText.Size = UDim2.new(1, -24, 1, -16)
            bubbleText.Position = UDim2.new(0, 12, 0, 8)
            bubbleText.BackgroundTransparency = 1
            bubbleText.TextColor3 = Color3.fromRGB(255, 255, 255)
            bubbleText.TextSize = 16
            bubbleText.Font = Enum.Font.SourceSans
            bubbleText.TextWrapped = true
            bubbleText.ZIndex = 3
            bubbleText.Parent = textFrame

            local bubbleTail = Instance.new("ImageLabel")
            bubbleTail.Name = "BubbleTail"
            bubbleTail.BackgroundTransparency = 1
            bubbleTail.Image = TONE_TAILS_BOTTOM[tone] or TONE_TAILS_BOTTOM.Neutral
            bubbleTail.ScaleType = Enum.ScaleType.Fit
            bubbleTail.Size = UDim2.new(0, 22, 0, 22)
            bubbleTail.AnchorPoint = Vector2.new(0.5, 0)
            bubbleTail.Visible = false
            bubbleTail.ZIndex = 3
            bubbleTail.Parent = bb

            hookedNPCs[dialog] = { head = head, bb = bb }

            local stepConn
            stepConn = RunService.RenderStepped:Connect(function()
                if not head.Parent or not dialog.Parent then
                    if bb.Parent then bb:Destroy() end
                    hookedNPCs[dialog] = nil
                    stepConn:Disconnect()
                    return
                end

                if not bb.Parent or not bb:IsDescendantOf(game) then
                    dbg("icon was removed by something else, re-hooking")
                    stepConn:Disconnect()
                    hookedNPCs[dialog] = nil
                    dialog:SetAttribute("ClassicHooked", nil)
                    task.defer(function() hookDialog(dialog) end)
                    return
                end

                if bb:GetAttribute("IsInDialog") == true then return end

                local cam = Workspace.CurrentCamera
                if not cam then return end

                local dist = (cam.CFrame.Position - head.Position).Magnitude
                local zoom = math.clamp(30 / math.max(dist, 3), 0.1, 2.5)
                local storedZoom = bb:GetAttribute("CurrentZoom") or -1

                if math.abs(zoom - storedZoom) > 0.05 then
                    bb:SetAttribute("CurrentZoom", zoom)
                    bb.Size = UDim2.new(0, 46 * zoom, 0, 60 * zoom)
                    purposeIcon.Size = UDim2.new(0, 28 * zoom, 0, 28 * zoom)
                    purposeIcon.Position = UDim2.new(0.5, -(28 * zoom / 2), 0, 4 * zoom)
                end
            end)
            table.insert(connections, stepConn)
        end

        local function isHookedHead(part)
            if not part then return false end
            for _, data in pairs(hookedNPCs) do
                if data.head == part then return true end
            end
            return false
        end

        local function suppressNative(obj)
            if not obj:IsA("BillboardGui") then return end
            if obj:GetAttribute("ClassicOwned") then return end
            if billboardHost and obj:IsDescendantOf(billboardHost) then return end
            local isDialogLike = string.find(string.lower(obj.Name), "dialog", 1, true) ~= nil
            local onHead = isHookedHead(obj.Adornee) or isHookedHead(obj.Parent)
            if (onHead or isDialogLike and isHookedHead(obj.Adornee)) and obj.Enabled then
                pcall(function() obj.Enabled = false end)
                disabledNative[obj] = true
            end
        end

        local lastScan = 0
        table.insert(connections, RunService.RenderStepped:Connect(function()
            local now = os.clock()
            if now - lastScan >= 0.2 then
                lastScan = now
                pcall(ensureHost)
                for _, g in ipairs({ gui, noticeGui }) do
                    if not g.Parent then pcall(function() g.Parent = parentGui end) end
                end
                for _, data in pairs(hookedNPCs) do
                    if data.head then
                        for _, obj in ipairs(data.head:GetChildren()) do
                            if obj:IsA("BillboardGui") and not obj:GetAttribute("ClassicOwned") and obj.Enabled then
                                pcall(function() obj.Enabled = false end)
                                disabledNative[obj] = true
                            end
                        end
                    end
                end
                for _, container in ipairs({ pg, CoreGui }) do
                    pcall(function()
                        for _, obj in ipairs(container:GetDescendants()) do
                            suppressNative(obj)
                        end
                    end)
                end
            end

            if not activeNPC or not activeDialog then return end

            local char = LocalPlayer.Character
            local myHead = char and char:FindFirstChild("Head")

            local maxDist = 25
            pcall(function()
                local orig = activeDialog:GetAttribute("OrigDist")
                if type(orig) == "number" and orig > 0 then maxDist = orig end
            end)

            if not myHead or not activeNPC.Parent or (myHead.Position - activeNPC.Position).Magnitude > (maxDist + 5) then
                showSystemNotice("Chat ended because you walked away", 2.5)
                endDialog()
            end
        end))

        local function scanContainer(c)
            pcall(function()
                for _, d in ipairs(c:GetDescendants()) do
                    if d:IsA("Dialog") then hookDialog(d) end
                end
            end)
        end

        scanContainer(Workspace)
        table.insert(connections, Workspace.DescendantAdded:Connect(function(d)
            if d:IsA("Dialog") then task.defer(function() hookDialog(d) end) end
        end))

        getgenv().ClassicDialogCleanup = function()
            dialogGeneration = dialogGeneration + 1
            activeNPC, activeDialog = nil, nil
            pcall(function() gui:Destroy() end)
            pcall(function() billboardHost:Destroy() end)
            pcall(function() noticeGui:Destroy() end)
            for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end

            for dialog, data in pairs(hookedNPCs) do
                pcall(function()
                    dialog:SetAttribute("ClassicHooked", nil)
                    local orig = dialog:GetAttribute("OrigDist")
                    if orig then
                        dialog.ConversationDistance = orig
                        dialog:SetAttribute("OrigDist", nil)
                    end
                end)
            end
            for obj in pairs(disabledNative) do
                pcall(function() obj.Enabled = true end)
            end
            disabledNative = {}
            hookedNPCs = {}
            dialogLoaded_Classic = false
        end

        dialogLoaded_Classic = true
    end

    local function evaluateAndLoad()
        local era, raw = getSelectedEra()
        print("[Loader] topbar choice \"" .. tostring(raw) .. "\" -> era: " .. era)
        getgenv().BloxyEra = era
        desiredBubbleEra = (era ~= "none") and era or nil
        if lastFailedEra == era then lastFailedEra = nil end

        if era == "none" then
            if getgenv().ClassicDialogCleanup then pcall(getgenv().ClassicDialogCleanup) end
            dialogLoaded_Classic = false
            setNativeBubbles(false)
            if activeBubbleEra then stopBubbleScript(activeBubbleEra) end
            -- nothing selected: the 2017 bubbles must not stay on
            if getgenv().Bubble2017Cleanup then pcall(getgenv().Bubble2017Cleanup) end
            return
        end

        if era == "classic" then
            setNativeBubbles(true)
            task.spawn(startBubbleScript, "classic")
            if not dialogLoaded_Classic then
                dialogLoaded_Classic = true
                task.spawn(injectClassicDialogs)
            end

        elseif era == "bubble2017" then
            -- 2015 / 2016: the 2017 bubbles. The modern bubbles stay as they are until the 2017
            -- script is really running (it switches them off itself, and back on when it stops).
            setNativeBubbles(false)
            if getgenv().ClassicDialogCleanup then pcall(getgenv().ClassicDialogCleanup) end
            dialogLoaded_Classic = false
            task.spawn(startBubbleScript, "bubble2017")

        elseif era == "modern" then
            setNativeBubbles(false)
            if getgenv().ClassicDialogCleanup then pcall(getgenv().ClassicDialogCleanup) end
            dialogLoaded_Classic = false
            task.spawn(startBubbleScript, "modern")
        end
    end

    -- Confirm: the era is read from the saved config. The config may be written a moment after
    -- the click, so it is read again a little later (the second reading changes nothing when the
    -- era is the same; it only fixes a reading that was taken before the config was saved).
    local function onConfirm()
        for _, delay in ipairs({ 0.5, 2, 4 }) do
            task.delay(delay, evaluateAndLoad)
        end
    end

    local function checkConfirmHooks()
        if not pg or not pg.Parent then return end
        for _, obj in ipairs(pg:GetDescendants()) do
            if obj:IsA("TextButton") and string.find(string.lower(obj.Text or ""), "confirm", 1, true) and not obj:GetAttribute("BPHookedConfirm") then
                obj:SetAttribute("BPHookedConfirm", true)
                obj.MouseButton1Click:Connect(onConfirm)
            end
        end
    end

    local lastHookScan = 0
    RunService.RenderStepped:Connect(function()
        local now = os.clock()
        if now - lastHookScan < 0.25 then return end
        lastHookScan = now
        checkConfirmHooks()
    end)
end)

print("[Loader] All scripts loaded.")
