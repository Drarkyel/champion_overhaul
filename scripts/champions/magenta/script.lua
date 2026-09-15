--[[ Magenta ]]--
local mod = ChampionOverhaul

local CHAMPION = "magenta"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(1, 0, 1, 1),
    weight = 0.5,
    drop = "5.300.0", -- Card
    hasShader = true
})

local DELAY = 20

-- Sprinker projectiles
---@param npc EntityNPC
function mod:MagentaShoot(npc)
    if not self:GetChampion(npc, CHAMPION) then return end
    if npc.FrameCount < 33 or npc.HitPoints == npc.MaxHitPoints then return end

    local min = DELAY / 5
    local hpScale = npc.HitPoints / npc.MaxHitPoints
    local factor = math.floor(math.max(min, DELAY * hpScale))

    if npc.FrameCount % factor ~= 0 then return end

    local params = ProjectileParams()
    params.FallingAccelModifier = 0.85 + 0.15 * math.random()
    params.FallingSpeedModifier = -14 + 6 * math.random()
    params.Variant = 6

    local speed = 0.8 + 0.4 * (1 - hpScale) * math.random()
    local velocity = EntityPickup.GetRandomPickupVelocity(npc.Position, nil, 0) * speed

    npc:FireProjectiles(npc.Position, velocity, 0, params)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.MagentaShoot)