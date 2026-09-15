--[[ Small ]]--
local mod = ChampionOverhaul

local CHAMPION = "small"
local SIZE_SCALE = 0.5

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    colorIntensity = false,
    weight = 0.25,
    drop = "5.70.33", -- Smaller Pill
    sizeScale = SIZE_SCALE,
    hasShader = false
})

-- Small childs
function mod:SmallChild(npc)
    if not self:GetChampionSpawner(npc, CHAMPION) then return end

    local gridColPts = EntityConfig.GetEntity(npc.Type, npc.Variant):GetGridCollisionPoints()

    npc:SetSize(npc.Size, Vector.One:__mul(SIZE_SCALE), math.floor(gridColPts * SIZE_SCALE))
    npc:GetSprite().Scale = Vector.One:__mul(SIZE_SCALE)
    npc.Mass = npc.Mass * SIZE_SCALE
    npc.Scale = SIZE_SCALE
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.SmallChild)