--[[ Cyan ]]--
local mod = ChampionOverhaul

local CHAMPION = "cyan"

-- Start morph process
local init = function(npc)
    local devolved = EntityConfig.GetEntity(npc.Type, npc.Variant):GetDevolvedEntity()
    if not devolved then return end

    local id = tostring(devolved:GetType()) .. "." .. tostring(devolved:GetVariant())

    npc:GetData().co_champion_cyan_morphs = {id}
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0, 1, 1, 1),
    weight = 0.25,
    init = init
})

-- Drop nickel
---@param entity Entity
local function DropNickel(entity)
    mod:SetDeath(entity)

    local npc = entity:ToNPC()
    if not npc then return end

    if not mod:CanDrop(npc) then return end

    local pos = Isaac.GetFreeNearPosition(npc.Position, 0)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_NICKEL, pos, Vector.Zero, npc)
end

-- Morph system
---@param entity Entity
---@param amount number
function mod:CyanDevolve(entity, amount)
    if not entity:GetData().co_champion_cyan_morphs then return end
    if entity.HitPoints > amount then return end

    local devolved = EntityConfig.GetEntity(entity.Type, entity.Variant):GetDevolvedEntity()
    if not devolved then DropNickel(entity) return end

    -- Prevent morph loop
    for _, morphed in ipairs(entity:GetData().co_champion_cyan_morphs) do
        local _type, variant = morphed:match("^(%d+)%.(%d+)%$")
        if _type == tonumber(devolved:GetType()) and variant == tonumber(devolved:GetVariant()) then
            DropNickel(entity)
            return
        end
    end

    -- Save morph info
    local id = tostring(devolved:GetType()) .. "." .. tostring(devolved:GetVariant())
    table.insert(entity:GetData().co_champion_cyan_morphs, id)

    -- Devolve entity
    local morph = Isaac.Spawn(devolved:GetType(), devolved:GetVariant(), 0, entity.Position, Vector.Zero, entity)
    morph:GetData().co_champion_cyan_morphs = entity:GetData().co_champion_cyan_morphs
    morph:ToNPC():PlaySound(SoundEffect.SOUND_BOIL_HATCH)
    morph:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    morph.HitPoints = morph.MaxHitPoints
    morph.Color = Color(1, 1, 1, 1, 0, 0.25, 0.25)

    -- Spawn poof
    local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, morph.Position, Vector.Zero, morph)
    effect.Color = morph.Color

    entity:Remove()

    return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.CyanDevolve)

-- Drops nickel upon death
---@param npc EntityNPC
function mod:CyanDrop(npc)
    if not npc:GetData().co_champion_cyan_death then return end
    print("killed")
    if not self:CanDrop(npc) then return end
    print("working")

    local pos = Isaac.GetFreeNearPosition(npc.Position, 0)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_NICKEL, pos, Vector.Zero, npc)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.CyanDrop)