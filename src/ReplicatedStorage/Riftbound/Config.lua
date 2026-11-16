local Config = {}

Config.World = {
    Seed = 41827,
    RoomCount = 13,
    RoomSize = 54,
    CorridorWidth = 18,
    WallHeight = 22,
}

Config.Player = {
    MaxHealth = 100,
    WalkSpeed = 16,
    BasicDamage = 24,
    BasicRange = 13,
    BasicCooldown = 0.55,
    RiftBurstDamage = 48,
    RiftBurstRadius = 19,
    RiftBurstCooldown = 7,
}

Config.Enemy = {
    MaxHealth = 65,
    Damage = 10,
    AttackRange = 5,
    DetectionRange = 62,
    AttackCooldown = 1.4,
    MoveSpeed = 11,
    SpawnPerRoom = 2,
}

Config.Loot = {
    DropChance = 0.72,
    PickupRange = 12,
    Rarities = {
        {Name = "Common", Weight = 62, Multiplier = 1},
        {Name = "Uncommon", Weight = 25, Multiplier = 1.25},
        {Name = "Rare", Weight = 10, Multiplier = 1.7},
        {Name = "Epic", Weight = 2.5, Multiplier = 2.4},
        {Name = "Mythic", Weight = 0.5, Multiplier = 3.5},
    },
}

Config.Network = {
    RequestInterval = 0.12,
    MaxRequestDistance = 24,
}

return Config
