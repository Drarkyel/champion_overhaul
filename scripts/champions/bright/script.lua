--[[ Bright ]]--
local mod = ChampionOverhaul

local CHAMPION = "bright"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(1, 1, 1, 1, 0.5, 0.5, 0.5),
    colorIntensity = false,
    weight = 0.1,
    drop = "5.10.4", -- Eternal Heart
    hasSprite = false
})

-- Invincible until being the last enemy
function mod:BrightNoDamage(entity)
    if not self:GetChampion(entity, CHAMPION) then return end

    local hasEnemies = false
    for _, ent in ipairs(Isaac.GetRoomEntities()) do
        if ent:IsVulnerableEnemy() and ent:CanShutDoors() and not self:GetChampion(ent, CHAMPION) then
            hasEnemies = true
            break
        end
    end

    if hasEnemies then
        entity:ToNPC():PlaySound(SoundEffect.SOUND_BISHOP_HIT, 1, 10)
        return false
    end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.BrightNoDamage)