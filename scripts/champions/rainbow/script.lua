--[[ Rainbow ]]--
local mod = ChampionOverhaul
local game = Game()

local CHAMPION = "rainbow"

local colors = {
    Color(1.0, 0.0, 0.0, 1.0), -- Red
    Color(1.0, 0.5, 0.0, 1.0), -- Orange
    Color(1.0, 1.0, 0.0, 1.0), -- Yellow
    Color(0.0, 1.0, 0.0, 1.0), -- Green
    Color(0.0, 0.5, 1.0, 1.0), -- Blue
    Color(0.0, 0.0, 1.0, 1.0), -- Indigo
    Color(0.5, 0.0, 1.0, 1.0), -- Violet
}

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    colorVar = colors,
    colorType = 3,
    colorIntensity = false,
    weight = 0.01,
    hasShader = false
})

local PROJ_FLAGS = {
    ProjectileFlags.BACKSPLIT,
    ProjectileFlags.BOOMERANG,
    ProjectileFlags.BOUNCE,
    ProjectileFlags.BURST,
    ProjectileFlags.BURST3,
    ProjectileFlags.BURST8,
    ProjectileFlags.CONTINUUM,
    ProjectileFlags.EXPLODE,
    ProjectileFlags.FADEOUT,
    ProjectileFlags.GHOST,
    ProjectileFlags.GREED,
    ProjectileFlags.MEGA_WIGGLE,
    ProjectileFlags.SHIELDED,
    ProjectileFlags.SLOWED,
    ProjectileFlags.SMART,
    ProjectileFlags.WIGGLE
}

local CIRCLE_AMOUNT = 3
local PROJ_AMOUNT = 16

local PICKUP_LIST = {
    PickupVariant.PICKUP_HEART,
    PickupVariant.PICKUP_COIN,
    PickupVariant.PICKUP_KEY,
    PickupVariant.PICKUP_BOMB,
    PickupVariant.PICKUP_PILL,
    PickupVariant.PICKUP_TAROTCARD,
    PickupVariant.PICKUP_TRINKET
}

-- Gives random projectile flag
---@param projectile EntityProjectile
local function RandomShot(projectile)
    local idx = math.random(#PROJ_FLAGS)
    local flag = PROJ_FLAGS[idx]

    -- Nerf fire projectiles
    if projectile.Variant == 2 then
        if flag == ProjectileFlags.BACKSPLIT
        or flag == ProjectileFlags.BURST3
        or flag == ProjectileFlags.BURST8 then
        return end
    end
    projectile:AddProjectileFlags(flag)
end

-- Circle attack upon death
---@param npc EntityNPC
function mod:RainbowDeath(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    game:ShakeScreen(15)
    npc:PlaySound(SoundEffect.SOUND_HAPPY_RAINBOW, 1, 2, false, 1.5)

    -- Paint floor/wall
    local getColor = colors[math.random(#colors)]
    local room = game:GetRoom()
    room:SetFloorColor(Color(1, 1, 1, 1, getColor.R * 0.5, getColor.G * 0.5, getColor.B * 0.5))
    room:SetWallColor(Color(1, 1, 1, 1, getColor.R * 0.5, getColor.G * 0.5, getColor.B * 0.5))

    -- Circle amount
    for i = 1, CIRCLE_AMOUNT do
        -- Projectile amount
        for j = 1, PROJ_AMOUNT do
            local angle = 360 / PROJ_AMOUNT
            local direction = Vector.FromAngle(angle * (j - 1))

            local speed = game.Difficulty == Difficulty.DIFFICULTY_NORMAL and 1 or 2
            local velocity = direction * (speed + i)

            local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, npc.Position, velocity, npc)
            proj:GetData().co_champion_rainbow_atk = true
            proj:ToProjectile().FallingAccel = 0.01
            proj:ToProjectile().FallingSpeed = -3.5

            ---@diagnostic disable-next-line
            RandomShot(proj:ToProjectile())
        end
    end

    -- Rewards
    if not self:CanDrop(npc) then return end

    for _, pickup in ipairs(PICKUP_LIST) do
        local pos = Isaac.GetFreeNearPosition(npc.Position, 10)
        Isaac.Spawn(5, pickup, 0, pos, Vector.Zero, npc)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.RainbowDeath)

-- Final shots
---@param projectile EntityProjectile
function mod:RainbowFinalShot(projectile)
    if not projectile:GetData().co_champion_rainbow_atk then return end

    projectile.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.RainbowFinalShot)

-- Random projectile flag
---@param projectile EntityProjectile
function mod:RainbowRandomShot(projectile)
    if not self:HasChampionSource(projectile, CHAMPION) then return end

    RandomShot(projectile)
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, mod.RainbowRandomShot)