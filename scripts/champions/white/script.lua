--[[ White ]]--

local CHAMPION = "white"

---@param npc EntityNPC
local init = function(npc)
    local fly = Isaac.Spawn(EntityType.ENTITY_ETERNALFLY, 0, 0, npc.Position, Vector.Zero, npc)
    fly.Parent = npc
    fly.CollisionDamage = npc.CollisionDamage
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0),
    weight = 0.25,
    drop = "3.43.5.1.3", -- Conquest flies (1-3)
    init = init
})