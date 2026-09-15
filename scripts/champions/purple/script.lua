--[[ Purple ]]--

local CHAMPION = "purple"
local FLAGS = EntityFlag.FLAG_NO_STATUS_EFFECTS

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.615, 0, 1, 1),
    weight = 0.5,
    drop = "5.10.3", -- Soul heart
    entityFlags = FLAGS,
    projectileFlags = ProjectileFlags.SMART
})