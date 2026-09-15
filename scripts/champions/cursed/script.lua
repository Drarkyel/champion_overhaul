--[[ Pulsing Yellow ]]--
local mod = ChampionOverhaul
local sound = SFXManager()

local CHAMPION = "cursed"

local colors = {
    Color(0, 0, 0),
    Color(1, 0, 0)
}

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    colorVar = colors,
    colorType = 3,
    colorIntensity = false,
    weight = 0.1,
    drop = "5.55.0", -- Old chest
    hasShader = false,
    hasIcon = true
})

local COUNTDOWN = 15

-- Drastically reduces cooldown
---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param countdown integer
function mod:CrimsonDamage(entity, amount, flags, source, countdown)
    if entity:GetData().co_champion_cursed_damage then return end

    local player = entity:ToPlayer()
    if not player then return end

    -- Get any cursed champion alive
    local cursed
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if self:GetChampion(entity, CHAMPION) then
            cursed = entity:ToNPC()
            break
        end
    end
    if not cursed then return end

    cursed:PlaySound(SoundEffect.SOUND_MOTHER_LAUGH, 1, 2, false, 1.5)
    cursed:PlaySound(SoundEffect.SOUND_BISHOP_HIT, 1, 2, false, 0.5)

    player:GetData().co_champion_cursed_damage = true
    player:TakeDamage(amount, flags, source, countdown)
    player:ResetDamageCooldown()
    player:SetMinDamageCooldown(COUNTDOWN)
    player:GetData().co_champion_cursed_damage = nil

    -- Beam effect
    local color = Color(0, 0, 0)
    self:BeamEffect(cursed.Position, player.Position, color, true)
    player:SetColor(color, 10, 0, true, false)

    return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.CrimsonDamage, EntityType.ENTITY_PLAYER)