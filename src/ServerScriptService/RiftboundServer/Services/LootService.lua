local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Riftbound.Config)
local Items = require(ReplicatedStorage.Riftbound.Shared.Items)

local LootService = {}
LootService.__index = LootService

function LootService.new()
    return setmetatable({
        Drops = {},
        Random = Random.new(),
        Folder = nil,
    }, LootService)
end

function LootService:_chooseRarity()
    local totalWeight = 0
    for _, rarity in ipairs(Config.Loot.Rarities) do
        totalWeight += rarity.Weight
    end

    local roll = self.Random:NextNumber(0, totalWeight)
    local cursor = 0
    for _, rarity in ipairs(Config.Loot.Rarities) do
        cursor += rarity.Weight
        if roll <= cursor then
            return rarity
        end
    end
    return Config.Loot.Rarities[1]
end

function LootService:Drop(position)
    if self.Random:NextNumber() > Config.Loot.DropChance then
        return
    end

    local itemIds = {}
    for itemId in pairs(Items) do
        table.insert(itemIds, itemId)
    end

    local itemId = itemIds[self.Random:NextInteger(1, #itemIds)]
    local rarity = self:_chooseRarity()
    local item = Items[itemId]

    local orb = Instance.new("Part")
    orb.Name = "Loot_" .. itemId
    orb.Shape = Enum.PartType.Ball
    orb.Size = Vector3.new(2.2, 2.2, 2.2)
    orb.Anchored = true
    orb.CanCollide = false
    orb.Material = Enum.Material.Neon
    orb.Color = self:_rarityColor(rarity.Name)
    orb.Position = position + Vector3.new(0, 2, 0)
    orb:SetAttribute("ItemId", itemId)
    orb:SetAttribute("Rarity", rarity.Name)
    orb:SetAttribute("Power", math.floor(item.Power * rarity.Multiplier))
    orb.Parent = self.Folder
    self.Drops[orb] = true

    local light = Instance.new("PointLight")
    light.Color = orb.Color
    light.Range = 10
    light.Brightness = 1.5
    light.Parent = orb
end

function LootService:_rarityColor(name)
    local colors = {
        Common = Color3.fromRGB(190, 195, 205),
        Uncommon = Color3.fromRGB(90, 220, 130),
        Rare = Color3.fromRGB(75, 150, 255),
        Epic = Color3.fromRGB(185, 95, 255),
        Mythic = Color3.fromRGB(255, 185, 65),
    }
    return colors[name] or Color3.new(1, 1, 1)
end

function LootService:Start()
    local old = Workspace:FindFirstChild("RiftboundLoot")
    if old then
        old:Destroy()
    end
    self.Folder = Instance.new("Folder")
    self.Folder.Name = "RiftboundLoot"
    self.Folder.Parent = Workspace
end

function LootService:Collect(player, orb)
    if not self.Drops[orb] or not orb.Parent then
        return false, "That drop is no longer available."
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or (root.Position - orb.Position).Magnitude > Config.Loot.PickupRange then
        return false, "Move closer to the loot."
    end

    local itemId = orb:GetAttribute("ItemId")
    local rarity = orb:GetAttribute("Rarity")
    local power = orb:GetAttribute("Power")
    self.Drops[orb] = nil
    orb:Destroy()
    return true, {
        ItemId = itemId,
        Rarity = rarity,
        Power = power,
    }
end

return LootService
