--[[ Azure ]]--
local mod = ChampionOverhaul
local game = Game()

local CHAMPION = "azure"

-- Register
--[[
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.85, 1, 1),
    weight = 0.5
})
]]

local PILL_LIST = {
    PillEffect.PILLEFFECT_RANGE_UP,
    PillEffect.PILLEFFECT_SPEED_UP,
    PillEffect.PILLEFFECT_TEARS_UP,
    PillEffect.PILLEFFECT_LUCK_UP,
    PillEffect.PILLEFFECT_SHOT_SPEED_UP,
}

-- Stats-up pill drop
---@param npc EntityNPC
function mod:AzureDeath(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    local seed = npc.InitSeed
    local pill = PILL_LIST[seed % #PILL_LIST + 1]

    local itemPool = game:GetItemPool()
    local pillColor = itemPool:ForceAddPillEffect(pill)

    local pos = Isaac.GetFreeNearPosition(npc.Position, 0)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, pillColor, pos, Vector.Zero, npc)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.AzureDeath)