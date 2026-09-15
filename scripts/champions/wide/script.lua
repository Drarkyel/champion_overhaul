--[[ Wide ]]--
local mod = ChampionOverhaul
local game = Game()

local CHAMPION = "wide"
local FIX_CAMERA = false

local init = function()
    FIX_CAMERA = true
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    colorIntensity = false,
    weight = 0.01,
    drop = "5.40.7", -- Giga bomb
    hasShader = false,
    hasShadow = false,
    init = init
})

local WIDE_SCALE = Vector(2.0, 1.0)

-- Fix camera
local function FixCamera()
    local room = game:GetRoom()
    local camera = room:GetCamera()
    camera:SetClampEnabled(true)
end

-- Wide effect
function mod:WideCamera(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    local sprite = npc:GetSprite()
    sprite.Scale = WIDE_SCALE

    local camera = game:GetRoom():GetCamera()
    camera:SetClampEnabled(false)
    camera:SetFocusPosition(npc.Position)
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_RENDER, mod.WideCamera)

-- Death drop
---@param npc EntityNPC
function mod:WideDeath(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    -- Brings camera back
    game:ShakeScreen(15)
    FixCamera()

    -- Effect
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 3, npc.Position, Vector.Zero, npc)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.WideDeath)

-- Update camera by room
function mod:UpdateCamera()
    if not FIX_CAMERA then return end

    FIX_CAMERA = false
    FixCamera()
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.UpdateCamera)