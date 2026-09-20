ChampionOverhaul = RegisterMod("Champion Overhaul", 1)
local mod = ChampionOverhaul

mod.Version = "v1.1"

-- Repentogon
if not REPENTOGON then
	mod:Log("Requires Repentogon+!")
end

-- General Scripts
local scriptList = {"constants", "utils", "spawn", "controller", "changes", "debug"}
for _, script in ipairs(scriptList) do include("scripts." .. script) end

-- Champions
local championList = {
    -- Vanilla
    "red", "yellow", "green", "orange", "blue", "dark_cyan", "bright",
    "gray", "translucent", "dark", "magenta", "violet", "dark_red", "light_blue",
    "camouflage", "pulsing_green", "pulsing_gray", "white", "small", "large",
    "pulsing_red", "pulsating", "crown", "skull", "brown", "rainbow",
    -- Overhaul
    "purple", "light_orange", "indigo", "cyan", "teal", "pink", "black",
    "olive", "rose", "light", "crimson", "ivory", "beige", "pearl",
    "pulsing_yellow", "pulsing_orange", "pulsing_purple", "thief", "shield",
    "yin_yang", "cursed", "glitch", "wide", "gold"
}
for _, color in ipairs(championList) do include("scripts.champions." .. color .. ".script") end

-- Startup
mod:Log(mod.Version .. " Loaded")
