--[[ Yin Yang ]]--
local mod = ChampionOverhaul

local CHAMPION = "yin_yang"

local FLY_VAR = {
   black = {path = "../scripts/champions/yin_yang/black_willo.anm2", color = Color(0, 0, 0)},
   white = {path = "../scripts/champions/yin_yang/white_willo.anm2", color = Color(1, 1, 1)}
}

-- Spawn flies
---@param npc EntityNPC
local init = function(npc)
    for _, data in pairs(FLY_VAR) do
        local fly = Isaac.Spawn(EntityType.ENTITY_WILLO, 0, 0, npc.Position, Vector.Zero, npc)
        mod:SetChampionRef(fly, npc)
        fly:GetData().co_champion_yinyang = {Ref = GetPtrHash(npc), Color = data.color}
        fly.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        fly:SetInvincible(true)

        local sprite = fly:GetSprite()
        sprite:Load(data.path, true)
        sprite:Play("Idle", true)
    end
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    colorIntensity = false,
    weight = 0.1,
    drop = "5.10.10", -- Blended heart
    hasShader = false,
    hasIcon = true,
    init = init
})

-- Kill flies upon death
---@param npc EntityNPC
function mod:YinYangDeath(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    for _, fly in ipairs(Isaac.FindByType(EntityType.ENTITY_WILLO)) do
        local data = fly:GetData().co_champion_yinyang
        if data and data.Ref == GetPtrHash(npc) then fly:Die() end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.YinYangDeath)

-- Fly projectile changes
---@param projectile EntityProjectile
function mod:YinYangShotColor(projectile)
    local spawner = projectile.SpawnerEntity
    if not spawner then return end

    local data = spawner:GetData().co_champion_yinyang
    if not data then return end

    projectile.CollisionDamage = spawner.CollisionDamage
    projectile:GetSprite().Color = data.Color
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.YinYangShotColor)