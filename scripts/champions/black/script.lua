--[[ Black ]]--
local mod = ChampionOverhaul

local CHAMPION = "black"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.1, 0.1, 0.1, 1),
    colorIntensity = false,
    weight = 0.25,
    drop = "5.10.6" -- Black heart
})

-- Fragmented damage
---@param player EntityPlayer
---@param amount number
---@param flags EntityFlag
---@param source EntityRef
---@param countdown integer
function mod:BlackForceDamage(player, amount, flags, source, countdown)
    if not self:GetChampionRef(source, CHAMPION) then return end
    if flags & DamageFlag.DAMAGE_CLONES ~= 0 then return end

    local newFlag = flags | DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_CLONES

    for i = 1, amount do
        player:TakeDamage(1, newFlag, source, countdown)
        if i ~= amount then player:ResetDamageCooldown() end
    end
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, mod.BlackForceDamage)

-- Projectile effect
---@param projectile EntityProjectile
function mod:BlackParticles(projectile)
    if not self:HasChampionSource(projectile, CHAMPION) then return end

    if projectile.FrameCount % 2 ~= 0 then return end

    local particle = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.HAEMO_TRAIL,
        0,
        projectile.Position + Vector(0, projectile.Height),
        Vector.Zero,
        projectile
    ):ToEffect()

    particle.Color = Color(1, 1, 1, 1, 1, 0, 0)
    particle.SpriteScale = Vector(0.75, 0.75)
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.BlackParticles)