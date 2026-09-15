--[[ Orange ]]--
local mod = ChampionOverhaul

local CHAMPION = "orange"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(1, 0.675, 0, 1),
    colorIntensity = false,
    weight = 0.5,
    drop = "5.60.0", -- Locked Chest
})

local DROP_TIMEOUT = 55

-- Orange attack drops coins
---@param entity Entity
---@param source EntityRef
function mod:OrangeDamage(entity, _, _, source)
    if not self:HasChampionSource(source.Entity, CHAMPION) then return end

    local player = entity:ToPlayer()
    if not player then return end

    local pickups = {}

    local coins = player:GetNumCoins()
    local bombs = player:GetNumBombs()
    local keys = player:GetNumKeys()

    -- Only add pickups that the player has enough to drop
    if coins > 0 then
        table.insert(pickups, {
            type = PickupVariant.PICKUP_COIN,
            subtype = CoinSubType.COIN_PENNY,
            min = 3,
            max = 5,
            weight = 5,
            count = coins
        })
    end

    if bombs > 0 then
        table.insert(pickups, {
            type = PickupVariant.PICKUP_BOMB,
            subtype = BombSubType.BOMB_NORMAL,
            min = 2,
            max = 4,
            weight = 3,
            count = bombs
        })
    end

    if keys > 0 then
        table.insert(pickups, {
            type = PickupVariant.PICKUP_KEY,
            subtype = KeySubType.KEY_NORMAL,
            min = 1,
            max = 3,
            weight = 1,
            count = keys
        })
    end

    -- No valid pickup
    if #pickups == 0 then return end

    -- Weighted random
    local totalWeight = 0

    for _, pickup in ipairs(pickups) do
        totalWeight = totalWeight + pickup.weight
    end

    local roll = math.random(totalWeight)
    local selected

    for _, pickup in ipairs(pickups) do
        roll = roll - pickup.weight

        if roll <= 0 then
            selected = pickup
            break
        end
    end

    -- Random amount
    local amount = math.random(selected.min, selected.max)
    amount = math.min(amount, selected.count)

    -- Remove resources
    if selected.type == PickupVariant.PICKUP_COIN then
        player:AddCoins(-amount)
    elseif selected.type == PickupVariant.PICKUP_BOMB then
        player:AddBombs(-amount)
    elseif selected.type == PickupVariant.PICKUP_KEY then
        player:AddKeys(-amount)
    end

    -- Spawn pickups
    for _ = 1, amount do
        local speed = 1 + math.random()
        local velocity = EntityPickup.GetRandomPickupVelocity(player.Position, nil, 0) * speed
        local pickup = Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            selected.type,
            selected.subtype,
            player.Position,
            velocity,
            player
        )

        pickup:ToPickup().Timeout = DROP_TIMEOUT
    end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.OrangeDamage, EntityType.ENTITY_PLAYER)