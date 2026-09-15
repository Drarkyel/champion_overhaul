--[[ Crown ]]--
local mod = ChampionOverhaul

local CHAMPION = "crown"

-- Set entities marked to protect
---@param npc EntityNPC
local init = function(npc)
    local entities = Isaac.FindByType(npc.Type, -1, -1, false, true)
    for i = 1, #entities do
        if not mod:GetChampion(entities[i], CHAMPION) and entities[i]:CanShutDoors() then
            entities[i]:GetData().co_champion_crown_friend = true
            npc.MaxHitPoints = npc.MaxHitPoints + entities[i].MaxHitPoints
            npc.HitPoints = npc.MaxHitPoints
        end
    end
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    colorIntensity = false,
    weight = 0.1,
    drop = "5.0.0", -- Random pickup
    hasShader = false,
    hasIcon = true,
    init = init
})

local DAMAGE_DELAY = 10

-- Avoids protection too fast
---@param npc EntityNPC
function mod:CrownDelay(npc)
    if not self:GetChampion(npc, CHAMPION) then return end
    if not npc:GetData().co_champion_crown_delay then return end

    npc:GetData().co_champion_crown_delay = npc:GetData().co_champion_crown_delay + 1
    if npc:GetData().co_champion_crown_delay < DAMAGE_DELAY then return end

    npc:GetData().co_champion_crown_delay = nil
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.CrownDelay)

-- Protects similar entities
---@param entity Entity
---@param amount number
---@param flags EntityFlag
---@param source EntityRef
---@param countdown integer
function mod:CrownDamage(entity, amount, flags, source, countdown)
    -- Properly kills crown champion
    if self:GetChampion(entity, CHAMPION) and entity.HitPoints <= amount then self:SetDeath(entity) end

    -- Friends
    if not entity:GetData().co_champion_crown_friend then return end
    if flags & DamageFlag.DAMAGE_CLONES ~= 0 then return end

    local crown = Isaac.FindByType(entity.Type, entity.Variant, -1, false, true)
    for i = 1, #crown do
        if self:GetChampion(crown[i], CHAMPION) and not crown[i]:GetData().co_champion_crown_delay then
            crown[i]:ToNPC():PlaySound(SoundEffect.SOUND_FLIP_POOF)

            -- Swaps position
            local canTeleport = not (self:IsStationary(crown[i]) or self:IsStationary(entity))

            if canTeleport then
                local pos = entity.Position
                entity.Position = crown[i].Position
                crown[i].Position = pos
            end

            -- Effects
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, entity)
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, crown[i].Position, Vector.Zero, crown[i])

            local flag = flags | DamageFlag.DAMAGE_CLONES
            crown[i]:TakeDamage(amount, flag, source, countdown)

            crown[i]:GetData().co_champion_crown_delay = 0

            return false
        end
    end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.CrownDamage)