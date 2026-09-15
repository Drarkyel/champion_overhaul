--[[ Crimson ]]--
local mod = ChampionOverhaul

local CHAMPION = "crimson"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.863, 0.078, 0.235),
    weight = 0.25,
    drop = "5.10.9" -- Scared heart
})

-- Prioritize red hearts
---@param player EntityPlayer
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param countdown integer
function mod:CrimsonDamage(player, amount, flags, source, countdown)
    if not self:HasChampionSource(source.Entity, CHAMPION) then return end
    if flags & DamageFlag.DAMAGE_CLONES ~= 0 then return end

    local hearts = player:GetHearts()

    local ref = self:GetChampionRef(source, CHAMPION)
    if ref then
        -- Steals container
        if player:GetMaxHearts() >= 2 and hearts < amount then
            -- Steal
            player:AddMaxHearts(-2)
            player:SetColor(Color(0, 0, 0), 20, 0, true, false)
            ref:ToNPC():PlaySound(SoundEffect.SOUND_VAMP_DOUBLE)

            -- Red beam
            self:BeamEffect(player.Position, ref.Position, Color(1, 0, 0), true)

            -- Heart effect
            local heart = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 0, ref.Position, Vector.Zero, nil)
            heart:ToEffect():FollowParent(ref)
            heart:GetSprite().Offset = Vector(0, -48)

            -- Full heal
            if ref.HitPoints < ref.MaxHitPoints then
                ref.HitPoints = ref.MaxHitPoints
                ref:SetColor(Color(1, 1, 1, 1, 0.5, 0, 0), 20, 0, true, false)
            end

            -- No damage
            local newFlag = flags | DamageFlag.DAMAGE_FAKE | DamageFlag.DAMAGE_CLONES
            player:TakeDamage(amount, newFlag, EntityRef(ref), countdown)

            return false
        end
    end

    -- Red heart damage
    local getRef = (ref ~= nil) and EntityRef(ref) or source
    local newFlag = flags | DamageFlag.DAMAGE_RED_HEARTS | DamageFlag.DAMAGE_CLONES
    player:TakeDamage(amount, newFlag, getRef, countdown)

    return false
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, mod.CrimsonDamage)