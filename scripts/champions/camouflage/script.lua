--[[ Camouflage ]]--
local mod = ChampionOverhaul

local CHAMPION = "camouflage"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    colorType = 1,
    weight = 0.25,
    drop = "5.301.2", -- Suit card
    hasShader = false,
    hasSprite = false
})

local DARKEN = 0.45

function mod:CamouflageColor(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    local sprite = npc:GetSprite()

    npc:UpdateDirtColor(true)
    local color = npc:GetDirtColor()

    sprite.Color = Color(0, 0, 0, 1, color.R * DARKEN, color.G * DARKEN, color.B * DARKEN)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.CamouflageColor)