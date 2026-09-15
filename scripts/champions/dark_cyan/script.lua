--[[ Dark Cyan ]]--
local mod = ChampionOverhaul
local game = Game()

local CHAMPION = "dark_cyan"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0, 0.25, 0.25, 1),
    colorIntensity = false,
    weight = 1.0,
    drop = "5.40.1" -- Bomb
})

local EXPLOSION_DAMAGE_PCT = 0.1
local EXPLOSION_RADIUS = 1.5

-- Take less damage from bombs
---@param entity Entity
---@param amount number
---@param flags EntityFlag
---@param source EntityRef
---@param countdown integer
function mod:DarkCyanExplosionResistance(entity, amount, flags, source, countdown)
    if not self:GetChampion(entity, CHAMPION) then return end
    if flags & DamageFlag.DAMAGE_EXPLOSION == 0 then return end
    if flags & DamageFlag.DAMAGE_CLONES ~= 0 then return end

    local damage = amount * EXPLOSION_DAMAGE_PCT
    local newFlag = flags | DamageFlag.DAMAGE_CLONES
    entity:TakeDamage(damage, newFlag, source, countdown)

    return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.DarkCyanExplosionResistance)

-- Explodes upon death
---@param npc EntityNPC
function mod:DarkCyanExplosion(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    game:ShakeScreen(10)

    game:BombExplosionEffects(
        npc.Position,
        npc.CollisionDamage, -- Requires damage check
        TearFlags.TEAR_NORMAL,
        Color.Default,
        npc,
        EXPLOSION_RADIUS
    )
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.DarkCyanExplosion)

-- Fix explosion damage
---@param entity Entity
---@param flags EntityFlag
---@param source EntityRef
---@param countdown integer
function mod:ForceExplosionDamage(entity, _, flags, source, countdown)
    if flags & DamageFlag.DAMAGE_EXPLOSION == 0 then return end
    if flags & DamageFlag.DAMAGE_CLONES ~= 0 then return end

    local champion = source.Entity
    if not self:GetChampion(champion, CHAMPION) then return end

    local player = entity:ToPlayer()
    if not player then return end

    player:TakeDamage(champion.CollisionDamage, flags | DamageFlag.DAMAGE_CLONES, source, countdown)

    return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.ForceExplosionDamage, EntityType.ENTITY_PLAYER)