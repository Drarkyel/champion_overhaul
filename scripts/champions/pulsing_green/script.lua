--[[ Pulsing Green ]]--
local mod = ChampionOverhaul

local CHAMPION = "pulsing_green"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0, 1, 0, 1),
    colorType = 2,
    weight = 0.1,
    drop = "5.20.1", -- Penny
    hasShader = false,
    hasSprite = false
})

-- Split mechanic
---@param entity Entity
---@param amount number
function mod:PulsingGreenSplit(entity, amount)
    if not self:GetChampion(entity, CHAMPION) then return end
    if entity.HitPoints > amount then return end

    entity:GetData().co_champion_pulsinggreen_morphs = entity:GetData().co_champion_pulsinggreen_morphs or 0
    local morphs = entity:GetData().co_champion_pulsinggreen_morphs

    if morphs >= 2 then self:SetDeath(entity) return end
    local nextMorph = morphs + 1

    entity:ToNPC():PlaySound(SoundEffect.SOUND_MEATY_DEATHS)

    -- Split entities
    for _ = 1, 2 do
        local pos = entity.Position
        local velocity = EntityPickup.GetRandomPickupVelocity(entity.Position, nil, 0)

        local child = Isaac.Spawn(entity.Type, entity.Variant, entity.SubType, pos, velocity, entity)
        child:GetData().co_champion_pulsinggreen_morphs = nextMorph
        child:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

        self:SetChampion(child, entity.SubType)

        -- HP scale
        local hpScale = 1 / (2 ^ morphs)
        child.MaxHitPoints = child.MaxHitPoints * hpScale
        child.HitPoints = child.MaxHitPoints

        -- Size scale
        local sizeScale = 1 - morphs / 4
        local gridColPts = EntityConfig.GetEntity(child.Type, child.Variant):GetGridCollisionPoints()

        child:SetSize(child.Size, Vector.One * sizeScale, math.floor(gridColPts * sizeScale))
        child:GetSprite().Scale = Vector.One * sizeScale
        child.Mass = entity.Mass * sizeScale
        child:ToNPC().Scale = sizeScale
    end

    entity:Remove()

    return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.PulsingGreenSplit)