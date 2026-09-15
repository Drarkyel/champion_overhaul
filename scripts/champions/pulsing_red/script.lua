--[[ Pulsing Red ]]--
local mod = ChampionOverhaul

local CHAMPION = "pulsing_red"

-- Red pulling effect (HP)
---@param npc EntityNPC
local init = function(npc)
    local effect = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.PULLING_EFFECT,
        0,
        npc.Position,
        Vector.Zero,
        nil
    )

    effect.Color = Color(1, 0, 0, 1)
    effect:ToEffect():FollowParent(npc)
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(1, 0, 0, 1),
    colorType = 2,
    weight = 0.1,
    drop = "5.70.5", -- Full Heal pill
    hasShader = false,
    init = init
})

local HEAL_DELAY = 20
local HEAL_AMOUNT = 10
local HEAL_PENALITY = 0.1

-- Heals entities
---@param npc EntityNPC
function mod:PulsingRedHeal(npc)
    if not self:GetChampion(npc, CHAMPION) then return end
    if npc.FrameCount % HEAL_DELAY > 0 then return end

    -- Heal entities
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if entity:IsVulnerableEnemy()
        and entity:CanShutDoors()
        and entity.HitPoints < entity.MaxHitPoints
        and entity.Type ~= EntityType.ENTITY_BISHOP
        and not self:GetChampion(entity, CHAMPION) then
            -- Champion loses HP
            local newHP = HEAL_AMOUNT * HEAL_PENALITY
            if newHP <= 0 then return end

            npc.HitPoints = npc.HitPoints - newHP
            npc:PlaySound(SoundEffect.SOUND_VAMP_GULP)

            -- Heal
            entity.HitPoints = math.min(entity.MaxHitPoints, entity.HitPoints + HEAL_AMOUNT)

            -- Heart effect
            local heart = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 0, entity.Position, Vector.Zero, entity)
            heart:ToEffect():FollowParent(entity)
            heart:GetSprite().Offset = Vector(0, -48)

            local color = Color(1, 0, 0, 1)
            entity:SetColor(color, 20, 0, true, false)

            -- Healing beam
            self:BeamEffect(npc.Position, entity.Position, color, true)
        end
    end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PulsingRedHeal)