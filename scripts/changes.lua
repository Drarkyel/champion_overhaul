--[[ Changes ]]--
local mod = ChampionOverhaul

-- Temporary disables boil regen
---@param entity Entity
---@param amount number
function mod:BoilDamage(entity, amount)
    entity:GetData().boil_data = {
        RegenDelay = 0,
        CurrentHP = entity.HitPoints - amount
    }
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.BoilDamage, EntityType.ENTITY_BOIL)

-- Boils regen fast, but has damage delay
function mod:BoilRegen(npc)
    if npc.HitPoints >= npc.MaxHitPoints then return end

    local data = npc:GetData().boil_data
    if data then
        npc.HitPoints = data.CurrentHP
        if data.RegenDelay < 60 then
            npc:GetData().boil_data.RegenDelay = data.RegenDelay + 1
            return
        end
        npc:GetData().boil_data = nil
    end

    npc.HitPoints = math.min(npc.HitPoints + 0.1, npc.MaxHitPoints)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.BoilRegen, EntityType.ENTITY_BOIL)

-- Daddy long legs
---@param npc EntityNPC
function mod:DaddyLongLegsSpeed(npc)
    npc.Velocity = npc.Velocity * 0.9
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.DaddyLongLegsSpeed, EntityType.ENTITY_BABY_LONG_LEGS)

-- Globins can only revive 3 times
---@param entity Entity
function mod:GlobinMorph(entity)
    entity:GetData().globin_deathcount = entity:GetData().globin_deathcount or 0
    entity:GetData().globin_deathcount = entity:GetData().globin_deathcount + 1
    if entity:GetData().globin_deathcount < 4 then return end

    self:SetDeath(entity)
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, mod.GlobinMorph, EntityType.ENTITY_GLOBIN)

-- Turdling/Dangle/Brownie immune to status effects
---@param npc EntityNPC
function mod:BrownieFamilyPure(npc)
    if not (
        (npc.Type == EntityType.ENTITY_GURGLING and npc.Variant == 2) -- Turdling
        or (npc.Type == EntityType.ENTITY_DINGLE and npc.Variant == 1) -- Dangle
        or npc.Type == EntityType.ENTITY_BROWNIE -- Brownie
    )
    then return end

    npc:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.BrownieFamilyPure)