--[[ Dark ]]--
local mod = ChampionOverhaul

local CHAMPION = "dark"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0, 0, 0, 1),
    weight = 0.1,
    drop = "5.360.0", -- Red Chest
    hasShadow = false
})

local FADE_START = -0.5
local FADE_DELAY = 0.04

---@param npc EntityNPC
function mod:DarkFade(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    local sprite = npc:GetSprite()
    if sprite:IsPlaying("Appear") then return end

    if not npc:GetData().co_dark_delay then npc:GetData().co_dark_delay = FADE_START end
    if npc:GetData().co_dark_delay < 1 then
        npc:GetData().co_dark_delay = npc:GetData().co_dark_delay + FADE_DELAY
    end

    local alpha = math.max(0, 1 - npc:GetData().co_dark_delay)

    -- Layer update
    for i = 0, sprite:GetLayerCount() - 1 do
        local layer = sprite:GetLayer(i)
        if layer then layer:SetColor(Color(1, 1, 1, alpha)) end
    end

    -- Black smoke effect
    local pos = Vector(npc.Position.X + 25 * math.random() - 12.5, npc.Position.Y)
    local velocity = Vector(0, -5)
    local offset = Vector(0, -15)
    local scale = Vector(0.35, 0.35)

    self:SpawnParticle("../scripts/champions/dark/particle.png", velocity, pos, offset, scale)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.DarkFade)

---@param entity Entity
function mod:DarkDamage(entity)
    if not self:GetChampion(entity, CHAMPION) then return end

    entity:SetColor(Color(1.0, 0, 0, 1, 1, 0, 0), 10, 1000, true, false)
    entity:GetData().co_dark_delay = FADE_START
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.DarkDamage)