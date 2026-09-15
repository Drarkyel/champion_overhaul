--[[ Green ]]--
local mod = ChampionOverhaul

local CHAMPION = "green"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0, 1, 0, 1),
    weight = 1.0,
    drop = "5.70.0" -- Pill
})

local DELAY = 5
local TIMEOUT = 75

-- Green creep
---@param npc EntityNPC
function mod:GreenCreep(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    if npc.FrameCount % DELAY ~= 0 then return end

    -- Spawn green creep
    local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_GREEN, 0, npc.Position, Vector.Zero, npc)
    effect:ToEffect():SetTimeout(TIMEOUT)
    self:SetChampionRef(effect, npc)
    effect:Update()
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.GreenCreep)

-- Projectile creep size
---@param projectile EntityEffect
function mod:ShotCreep(projectile)
    if not self:HasChampionSource(projectile, CHAMPION) then return end

    -- Spawn green creep
    local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_GREEN, 0, projectile.Position, Vector.Zero, projectile.SpawnerEntity)
    effect:ToEffect():SetTimeout(TIMEOUT)
    self:SetChampionRef(effect, projectile)
    effect:Update()

    local size = projectile.Size
    effect:ToEffect().Scale = math.min(0.1 * size, 0.5)
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_DEATH, mod.ShotCreep)