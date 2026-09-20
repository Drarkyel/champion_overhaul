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

local EXPLOSION_RADIUS = 1.5
local EXPLOSION_DAMAGE = 100

-- Explodes upon death
---@param npc EntityNPC
function mod:DarkCyanExplosion(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    game:ShakeScreen(10)

    -- Trigger explosion
    game:BombExplosionEffects(
        npc.Position,
        npc.CollisionDamage, -- Requires damage check
        TearFlags.TEAR_NORMAL,
        Color.Default,
        npc,
        EXPLOSION_RADIUS
    )

    -- Deals minor damage to enemies
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if not entity:IsVulnerableEnemy() then goto continue end

        local distance = entity.Position:Distance(npc.Position)
        if distance > 60 * EXPLOSION_RADIUS then goto continue end

        entity:TakeDamage(EXPLOSION_DAMAGE, DamageFlag.DAMAGE_EXPLOSION, EntityRef(npc), 0)

        ::continue::
    end
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