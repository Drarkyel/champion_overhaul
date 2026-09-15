--[[ Translucent ]]--
local mod = ChampionOverhaul

local CHAMPION = "translucent"
local DROP_TIMEOUT = 55

---@param npc EntityNPC
local init = function(npc)
    npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(1.25, 1.25, 1.25, 0.5),
    weight = 0.25,
    entityFlags = EntityFlag.FLAG_NO_TARGET,
    projectileFlags = ProjectileFlags.GHOST,
    init = init
})

---@param npc EntityNPC
function mod:TranslucentDrop(npc)
    if not self:GetChampion(npc, CHAMPION) then return end
    if not self:CanDrop(npc) then return end

    local amount = 1 + npc.DropSeed % 2

    -- Spawn pickups
    for _ = 1, amount do
        local pickupList = {
            PickupVariant.PICKUP_HEART,
            PickupVariant.PICKUP_COIN,
            PickupVariant.PICKUP_BOMB,
            PickupVariant.PICKUP_KEY,
        }

        local velocity = EntityPickup.GetRandomPickupVelocity(npc.Position, nil, 0)
        local pickup = Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            pickupList[math.random(4)],
            0,
            npc.Position,
            velocity,
            npc
        )

        -- Ghost like
        pickup:SetColor(Color(1, 1, 1, 0.5, 0, 0, 0), 0, 0, false, false)
        pickup.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

        -- Timeout
        pickup:ToPickup().Timeout = DROP_TIMEOUT
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.TranslucentDrop)