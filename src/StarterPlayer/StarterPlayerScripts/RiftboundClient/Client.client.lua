local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RiftboundRemotes")
local ActionRemote = Remotes:WaitForChild("Action")
local StateRemote = Remotes:WaitForChild("State")

local Client = {
    LastAttack = 0,
    CurrentQuest = nil,
    NoticeUntil = 0,
}

local function create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function makeHud()
    local gui = create("ScreenGui", {
        Name = "RiftboundHUD",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
    }, Player:WaitForChild("PlayerGui"))

    local panel = create("Frame", {
        Name = "Panel",
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.fromOffset(24, 24),
        Size = UDim2.fromOffset(310, 142),
        BackgroundColor3 = Color3.fromRGB(16, 19, 31),
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
    }, gui)
    create("UICorner", {CornerRadius = UDim.new(0, 12)}, panel)
    create("UIStroke", {Color = Color3.fromRGB(106, 83, 180), Transparency = 0.25}, panel)

    create("TextLabel", {
        Name = "Title",
        Position = UDim2.fromOffset(16, 10),
        Size = UDim2.new(1, -32, 0, 28),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "RIFTBOUND",
        TextColor3 = Color3.fromRGB(210, 197, 255),
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, panel)

    local quest = create("TextLabel", {
        Name = "Quest",
        Position = UDim2.fromOffset(16, 44),
        Size = UDim2.new(1, -32, 0, 42),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = "Quest: Defeat 5 Rift Stalkers (0/5)",
        TextColor3 = Color3.fromRGB(225, 228, 240),
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, panel)

    local hint = create("TextLabel", {
        Name = "Controls",
        Position = UDim2.fromOffset(16, 96),
        Size = UDim2.new(1, -32, 0, 30),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "CLICK  Attack     Q  Rift Burst     E  Interact",
        TextColor3 = Color3.fromRGB(148, 153, 176),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, panel)

    local notice = create("TextLabel", {
        Name = "Notice",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 0.88, 0),
        Size = UDim2.fromOffset(420, 44),
        BackgroundColor3 = Color3.fromRGB(20, 23, 37),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Color3.fromRGB(222, 207, 255),
        TextSize = 16,
        Visible = false,
    }, gui)
    create("UICorner", {CornerRadius = UDim.new(0, 10)}, notice)

    return {Gui = gui, Quest = quest, Notice = notice}
end

local Hud = makeHud()

local function showNotice(message)
    Hud.Notice.Text = tostring(message)
    Hud.Notice.Visible = true
    Client.NoticeUntil = os.clock() + 2.2
end

local function interact()
    local character = Player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local closest, closestDistance
    for _, folderName in ipairs({"RiftboundLoot", "RiftboundDungeon"}) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, object in ipairs(folder:GetChildren()) do
                if object:IsA("BasePart") and (object.Name:match("^Loot_") or object.Name == "ExitPortal") then
                    local distance = (object.Position - root.Position).Magnitude
                    if distance <= 13 and (not closestDistance or distance < closestDistance) then
                        closest = object
                        closestDistance = distance
                    end
                end
            end
        end
    end

    if closest then
        if closest.Name == "ExitPortal" then
            ActionRemote:FireServer("InteractExit")
        else
            ActionRemote:FireServer("Collect", closest)
        end
    else
        showNotice("Nothing nearby to interact with.")
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        ActionRemote:FireServer("Attack")
    elseif input.KeyCode == Enum.KeyCode.Q then
        ActionRemote:FireServer("RiftBurst")
    elseif input.KeyCode == Enum.KeyCode.E then
        interact()
    end
end)

StateRemote.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then
        return
    end

    if payload.Type == "Quest" and payload.Quest then
        Client.CurrentQuest = payload.Quest
        local quest = payload.Quest
        local status = quest.Complete and "COMPLETE" or string.format("%d/%d", quest.Current, quest.Goal)
        Hud.Quest.Text = string.format("%s  [%s]\n%s", quest.Title, status, quest.Description)
    elseif payload.Type == "Loot" and payload.Item then
        local item = payload.Item
        showNotice(string.format("Found %s [%s]  +5 Gold", item.ItemId, item.Rarity))
    elseif payload.Type == "Notice" then
        showNotice(payload.Message)
    elseif payload.Type == "Hit" then
        showNotice("Hit for " .. tostring(payload.Damage))
    elseif payload.Type == "Ability" then
        showNotice("Rift Burst hit " .. tostring(payload.Hits) .. " enemies")
    elseif payload.Type == "RunComplete" then
        showNotice("Dungeon cleared. The rift is sealed.")
    end
end)

RunService.RenderStepped:Connect(function()
    if Hud.Notice.Visible and os.clock() >= Client.NoticeUntil then
        Hud.Notice.Visible = false
    end
end)
