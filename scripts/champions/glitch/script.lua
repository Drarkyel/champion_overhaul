--[[ Glitch ]]--
local mod = ChampionOverhaul
local game = Game()

local CHAMPION = "glitch"

-- Mark init entities
local init = function(npc)
    npc:GetData().co_champion_glitch_entities = {}

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
            table.insert(npc:GetData().co_champion_glitch_entities, info)
        end
    end
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    colorIntensity = false,
    weight = 0.01,
    hasShader = false,
    init= init
})

-- Sprite anomaly
---@param npc EntityNPC
function mod:GlitchSprite(npc)
    if not self:GetChampion(npc, CHAMPION) then return end
    if npc.FrameCount < 33 or npc.FrameCount % 10 ~= 0 then return end

    local sprite = npc:GetSprite()
    local spriteChange = math.random(3)

    if spriteChange == 1 then
        -- Flip
        sprite.FlipX = (math.random(3) == 1) and true or false
        sprite.FlipY = (math.random(3) == 1) and true or false
    elseif spriteChange == 2 then
        -- Rotation
        local rotationChance = math.random(3)
        local rotation
        if rotationChance == 1 then
            rotation = math.floor(360 * math.random())
        elseif rotationChance == 2 then
            rotation = sprite.Rotation
        else
            rotation = 0
        end
        sprite.Rotation = rotation
    else
        -- Sprite speed
        local speedChance = math.random(5)
        local speed
        if speedChance < 2 then
            speed = 0.5 + math.random()
        elseif speedChance < 4 then
            speed = sprite.PlaybackSpeed
        else
            speed = 1
        end
        sprite.PlaybackSpeed = speed
    end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.GlitchSprite)

-- Respawn dead entities
---@param entity Entity
---@param amount number
function mod:GlitchReroll(entity, amount)
    if not self:GetChampion(entity, CHAMPION) then return end
    if entity.HitPoints > amount then return end

    local data = entity:GetData().co_champion_glitch_entities
    if not (data and #data > 0) then return end

    local triggered = false

    for _, marked in ipairs(data) do
        local alive = false

        -- Rerolls alive entities
        for _, ent in ipairs(Isaac.GetRoomEntities()) do
            if GetPtrHash(ent) == marked.id then
                alive = true
                triggered = true
                game:RerollEnemy(ent)
            break end
        end

        -- Rerolls dead entities
        if not alive then
            triggered = true
            local respawned = Isaac.Spawn(marked._type, marked.variant, marked.subtype, marked.pos, Vector.Zero, entity)
            game:RerollEnemy(respawned)
        end
    end

     -- Delirium effect
    if triggered then
        local backdrop = game:GetRoom():GetBackdropType()
        game:ShowHallucination(30, backdrop)
    end

    self:SetDeath(entity)
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.GlitchReroll)

-- Glitch item upon death
---@param npc EntityNPC
function mod:GlitchDeath(npc)
    if not self:GetChampion(npc, CHAMPION) then return end
    if not self:CanDrop(npc) then return end

    local pool = ProceduralItemManager.CreateProceduralItem(npc.InitSeed, 0)
    local pos = Isaac.GetFreeNearPosition(npc.Position, 10)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pool, pos, Vector.Zero, npc)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.GlitchDeath)