local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local function pulseCrystal(crystal)
    local originalSize = crystal.Size
    local tween = TweenService:Create(
        crystal,
        TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Size = originalSize * 1.12}
    )
    tween:Play()
end

local function watchDungeon()
    local dungeon = Workspace:WaitForChild("RiftboundDungeon", 20)
    if not dungeon then
        return
    end

    for _, object in ipairs(dungeon:GetDescendants()) do
        if object.Name == "RiftCrystal" and object:IsA("BasePart") then
            pulseCrystal(object)
        end
    end
end

watchDungeon()
