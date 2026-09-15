--[[ Shield ]]--
local mod = ChampionOverhaul
local sound = SFXManager()

local CHAMPION = "shield"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    colorIntensity = false,
    weight = 0.1,
    drop = "5.300.51", -- Holy card
    hpScale = 1,
    hasShader = false,
    hasIcon = true
})

local SHIELD_DURATION = 240

-- Breaks shield upon damage
---@param entity Entity
function mod:ShieldBreak(entity)
    if not self:GetChampion(entity, CHAMPION) then return end

    -- Prevents damage
    if entity:GetData().co_champion_shield_delay then
        if entity:GetData().co_champion_shield_delay < SHIELD_DURATION then
            entity:ToNPC():PlaySound(SoundEffect.SOUND_BISHOP_HIT, 1, 10)
            return false end
        return
    end

    -- Broke shield
    if entity:GetData().co_champion_shield_delay then return end

    entity:GetData().co_champion_icon = nil
    entity:GetData().co_champion_shield_delay = 0
    entity:ToNPC():PlaySound(SoundEffect.SOUND_BISHOP_HIT, 1, 2, false, 0.5)

    -- Aura effect
    local aura = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HALLOWED_GROUND, 0, entity.Position, Vector.Zero, nil)
    aura.SpriteScale = Vector(0.5, 0.5)

    -- Shield effect
    local shield = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.EFFECT_NULL, 0, entity.Position, Vector.Zero, nil)
    shield:GetData().co_champion_shield_effect = true
    shield:GetSprite():Load("../scripts/champions/shield/shield.anm2", true)
    shield:GetSprite():Play("Idle", true)
    shield:ToEffect():FollowParent(entity)
    shield:ToEffect().Timeout = SHIELD_DURATION
    shield:ToEffect().DepthOffset = 25
    shield.SpriteScale = Vector(1.2, 1.2)
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.ShieldBreak)

-- Shield damage delay
---@param npc EntityNPC
function mod:ShieldDamageDelay(npc)
    if not self:GetChampion(npc, CHAMPION) then return end
    if not npc:GetData().co_champion_shield_delay then return end

    -- Delay
    if npc:GetData().co_champion_shield_delay >= SHIELD_DURATION then return end

    npc:GetData().co_champion_shield_delay = npc:GetData().co_champion_shield_delay + 1
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ShieldDamageDelay)

-- Shield effect delay
---@param effect EntityEffect
function mod:ShieldEffectDelay(effect)
    if not effect:GetData().co_champion_shield_effect then return end

    -- Shield changes
    local ending = math.floor(SHIELD_DURATION * 0.2)
    if effect.Timeout <= 0 then
        sound:Play(SoundEffect.SOUND_BISHOP_HIT, 1, 2, false, 1.5)

        -- Aura effect
        local aura = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HALLOWED_GROUND, 0, effect.Position, Vector.Zero, nil)
        aura.SpriteScale = Vector(0.5, 0.5)

        effect:Remove()
    elseif effect.Timeout == ending then
        effect:GetSprite():Play("Ending")
    end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.ShieldEffectDelay, EffectVariant.EFFECT_NULL)