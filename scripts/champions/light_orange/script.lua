--[[ Light Orange ]]--
local mod = ChampionOverhaul

local CHAMPION = "light_orange"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(1, 0.4, 0, 1),
    weight = 0.25,
    drop = "5.20.4", -- Double penny
    projectileFlags = ProjectileFlags.BURST
})

local BASE_SCALE = 1.0
local MIN_SCALE = 0.35
local MAX_SCALE = 1.0

-- Shrinks over HP
function mod:LightOrangeShrink(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    local hpRatio = math.max(0, npc.HitPoints / npc.MaxHitPoints)
    local scale = MIN_SCALE + (MAX_SCALE - MIN_SCALE) * hpRatio

    npc.Scale = BASE_SCALE * scale
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.LightOrangeShrink)

-- Force death
---@param entity Entity
---@param amount number
function mod:LightOrangeDeath(entity, amount)
    if not self:GetChampion(entity, CHAMPION) then return end
    if entity.HitPoints > amount then return end

    self:SetDeath(entity)
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.LightOrangeDeath)

-- Spawn split
---@param npc EntityNPC
function mod:LightOrangeChildSplit(npc)
    if not self:GetChampionSpawner(npc, CHAMPION) then return end
    if npc.HitPoints ~= npc.MaxHitPoints then return end

    local damage = npc.MaxHitPoints / 2
    npc:TrySplit(damage, EntityRef(npc), false)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.LightOrangeChildSplit)