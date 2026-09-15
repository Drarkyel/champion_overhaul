--[[ Pulsing Yellow ]]--
local mod = ChampionOverhaul

local CHAMPION = "pulsing_yellow"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(1, 1, 0, 1),
    colorType = 2,
    weight = 0.1,
    drop = "5.90.3", -- Mega battery
    projectileFlags = ProjectileFlags.WIGGLE,
    hasShader = false
})

local DODGE_DISTANCE = 60
local DODGE_STRENGTH = 2.5

---@param npc EntityNPC
function mod:PulsingYellowDodge(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    local closestTear
    local closestDistance = math.huge

    local tears = Isaac.FindInRadius(npc.Position, DODGE_DISTANCE, EntityPartition.TEAR)
    for _, entity in ipairs(tears) do
        local tear = entity:ToTear()

        if tear then
            local distance = npc.Position:DistanceSquared(tear.Position)

            if distance < closestDistance then
                closestDistance = distance
                closestTear = tear
            end
        end
    end

    if not closestTear then return end

    local velocity = closestTear.Velocity
    if velocity:LengthSquared() == 0 then return end

    local direction = velocity:Normalized()
    local toNPC = (npc.Position - closestTear.Position):Normalized()

    -- Only dodge tears that are moving toward the NPC
    if direction:Dot(toNPC) <= 0 then return end

    -- Perpendicular to the tear's trajectory
    local dodgeDirection = Vector(-direction.Y, direction.X)

    -- Choose the side closest to the NPC
    if (npc.Position - closestTear.Position):Dot(dodgeDirection) < 0 then
        dodgeDirection = -dodgeDirection
    end

    npc.Velocity = npc.Velocity + dodgeDirection * DODGE_STRENGTH
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PulsingYellowDodge)