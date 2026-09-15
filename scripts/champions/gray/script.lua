--[[ Gray ]]--
local mod = ChampionOverhaul

local CHAMPION = "gray"
local FLAGS = EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK

-- Armor scale
---@param npc EntityNPC
local init = function(npc)
    npc:SetShieldStrength(npc.MaxHitPoints)
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.5, 0.5, 0.5, 1),
    weight = 1.0,
    drop = "5.30.1", -- Key,
    hpScale = 1,
    entityFlags = FLAGS,
    init = init
})

-- Reduces champion shield for healing entities
---@param entity Entity
---@param amount number
function mod:ChampionShieldNerf(entity, amount)
    if not self:GetChampion(entity, CHAMPION) then return end
    if entity:ToNPC():GetShieldStrength() > 0 then return end

    local shieldAmount = math.max(0, entity:ToNPC():GetShieldStrength() - math.min(1, 0.1 * amount))
    entity:ToNPC():SetShieldStrength(shieldAmount)
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.ChampionShieldNerf)