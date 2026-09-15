--[[ Pulsing Orange ]]--
local mod = ChampionOverhaul

local CHAMPION = "pulsing_orange"

-- Fast animation
---@param npc EntityNPC
local init = function(npc)
    npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    npc:GetSprite().PlaybackSpeed = 1.75
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(1.0, 0.675, 0.0),
    colorType = 2,
    colorIntensity = false,
    weight = 0.1,
    drop = "3.43.1.1.3", -- Famine locust (1-3)
    hasShader = false,
    init = init
})

local COOLDOWN_REDUCTION = 1

-- Fast attack pattern
function mod:PulsatingSprite(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    if npc.ProjectileCooldown <= 0 then return end

    npc.ProjectileCooldown = npc.ProjectileCooldown - COOLDOWN_REDUCTION
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PulsatingSprite)