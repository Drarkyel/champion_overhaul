--[[ Light ]]--
local mod = ChampionOverhaul

local CHAMPION = "light"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(1, 1, 1, 1, 1, 1, 1),
    colorIntensity = false,
    weight = 0.1,
    drop = "5.53.0", -- Eternal chest
})

-- Projectiles aim at player
---@param entity Entity
---@param source EntityRef
function mod:LightRemoveEnergy(entity, _, _, source)
    if not self:HasChampionSource(source.Entity, CHAMPION) then return end

    local player = entity:ToPlayer()
    if not player then return end

    local firstSlot = player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) and player:GetActiveCharge(ActiveSlot.SLOT_PRIMARY) > 0
    local secondSlot = player:GetActiveItem(ActiveSlot.SLOT_SECONDARY) and player:GetActiveCharge(ActiveSlot.SLOT_SECONDARY) > 0

    if not (firstSlot or secondSlot) then return end

    -- Discharge
    if firstSlot then
        -- Primary active item
        player:DischargeActiveItem(ActiveSlot.SLOT_PRIMARY)
    else
        -- Secondary active item
        player:DischargeActiveItem(ActiveSlot.SLOT_SECONDARY)
    end

    -- Battery effect
    local battery = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 3, entity.Position, Vector.Zero, nil)
    battery:ToEffect():FollowParent(player)
    battery:GetSprite().Offset = Vector(0, -48)
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.LightRemoveEnergy)

-- Dissolve tears
---@param projectile EntityProjectile
function mod:LightDissolve(projectile)
    if not self:HasChampionSource(projectile, CHAMPION) then return end

    local radius = projectile.Size + 8

    for _, entity in ipairs(Isaac.FindInRadius(projectile.Position, radius, EntityPartition.TEAR)) do
        local tear = entity:ToTear()
        if tear then tear:Die() end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.LightDissolve)