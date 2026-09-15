--[[ Yellow ]]--
local mod = ChampionOverhaul

local CHAMPION = "yellow"

ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.9, 0.9, 0, 1),
    weight = 1.0,
    drop = "5.90.1", -- Battery
})

local MAX_SPEED = 8
local MOVE_SPEED = 1.05
local SHOT_SPEED = 1.2

-- NPC speed
---@param npc EntityNPC
function mod:YellowSpeed(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    local length = npc.Velocity:Length()
    local speed = length * MOVE_SPEED
    if speed > MAX_SPEED then return end

    npc.Velocity = npc.Velocity * MOVE_SPEED
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.YellowSpeed)

-- Projectile speed
---@param projectile EntityProjectile
function mod:YellowProjectileSpeed(projectile)
    if not self:HasChampionSource(projectile, CHAMPION) then return end

    projectile.Velocity = projectile.Velocity * SHOT_SPEED
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, mod.YellowProjectileSpeed)