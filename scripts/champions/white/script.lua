--[[ White ]]--
local mod = ChampionOverhaul

local CHAMPION = "white"

---@param npc EntityNPC
local init = function(npc)
    local fly = Isaac.Spawn(EntityType.ENTITY_ETERNALFLY, 0, 0, npc.Position, Vector.Zero, npc)
    fly:GetData().co_Champion_white_fly = true
    fly.Parent = npc
    mod:SetChampionRef(fly, npc)
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0),
    weight = 0.5,
    init = init
})

-- Eternal Fly Morph
---@param npc EntityNPC
function mod:EternalFlyDeath(npc)
    if not npc:GetData().co_Champion_white_fly then return end

    -- Host-switching
    local newHost = false
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if entity:IsVulnerableEnemy()
        and entity:CanShutDoors()
        and not entity:IsBoss()
        and not entity:IsDead() then
            newHost = true

            npc:PlaySound(863)

            -- New eternal fly
            local fly = Isaac.Spawn(EntityType.ENTITY_ETERNALFLY, 0, 0, entity.Position, Vector.Zero, entity)
            fly:GetData().co_Champion_white_fly = true
            fly.Parent = entity
            self:SetChampionRef(fly, npc)

            -- Beam effect
            self:BeamEffect(npc.Position, fly.Position, Color(1,1,1,1), true)

            break
        end
    end

    -- Reward
    if not newHost and self:CanDrop(npc) then
        local amount = npc:GetDropRNG():RandomInt(3) + 1
        print(amount)
        while amount > 0 do
            amount = amount - 1
            Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY, 5, npc.Position, Vector.Zero, npc)
        end
    end

    -- Removes current fly
    npc:Remove()

    return false
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_MORPH, mod.EternalFlyDeath)