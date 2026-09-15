--[[ Skull ]]--
local mod = ChampionOverhaul
local game = Game()

local CHAMPION = "skull"

-- Save alive entities
local init = function(npc)
    npc:GetData().co_champion_skull_entities = {}

    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if entity:IsVulnerableEnemy()
        and entity:CanShutDoors()
        and not mod:GetChampion(entity, CHAMPION)
        and not entity:IsBoss() then
            local info = {
                id = GetPtrHash(entity),
                _type = entity.Type,
                variant = entity.Variant,
                subtype = entity.SubType,
                pos = entity.Position
            }
            table.insert(npc:GetData().co_champion_skull_entities, info)
        end
    end
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.25, 0.25, 0.25, 1, 0.1, 0.1, 0.1),
    colorIntensity = false,
    weight = 0.1,
    drop = "5.10.11", -- Bone heart
    hasIcon = true,
    init = init
})

-- Respawn dead entities
---@param entity Entity
---@param amount number
function mod:SkullDeath(entity, amount)
    if not self:GetChampion(entity, CHAMPION) then return end
    if entity.HitPoints > amount then return end

    local data = entity:GetData().co_champion_skull_entities
    if not (data and #data > 0) then return end

    local respawned = false

    for _, marked in ipairs(data) do
        local alive = false

        for _, ent in ipairs(Isaac.GetRoomEntities()) do
            if GetPtrHash(ent) == marked.id then alive = true break end
        end

        if not alive then
            respawned = true

            -- Respawn entity
            local newEntity = Isaac.Spawn(marked._type, marked.variant, marked.subtype, marked.pos, Vector.Zero, entity)
            newEntity.MaxHitPoints = newEntity.MaxHitPoints * 2
            newEntity.HitPoints = newEntity.MaxHitPoints
            newEntity.CollisionDamage = entity.CollisionDamage
            newEntity:SetColor(entity.Color, 0, 100, false, false)

            -- Beam effect
            self:BeamEffect(entity.Position, newEntity.Position, Color(0,0,0), true)
        end
    end

    if respawned then
        game:ShakeScreen(15)
        game:Darken(1, 15)
        entity:ToNPC():PlaySound(SoundEffect.SOUND_DEATH_CARD)
    end

    self:SetDeath(entity)
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.SkullDeath)