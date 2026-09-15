--[[ Debug ]]--
local mod = ChampionOverhaul
local game = Game()

Console.RegisterCommand(
    "champion",
    "Spawns a champion enemy",
    "champion <champName|list> <type> [variant]",
    false,
    AutocompleteType.CUSTOM
)

-- Spawn champion command
local function ChampionCommand(_, cmd, params)
    if cmd ~= "champion" then return end

    local args = {}
    for word in string.gmatch(params or "", "%S+") do
        table.insert(args, word)
    end

    if #args == 0 or args[1]:lower() == "list" then
        print("Available champions:")
        for name, id in pairs(mod.ChampionID) do
            print(string.format(" %s (%d)", name, id))
        end
        return
    end

    local champName = args[1]:lower()
    local champID = mod.ChampionID[champName] or tonumber(args[1])

    if not champID then
        Console.PrintError("Unknown champion: " .. tostring(args[1]))
        return
    end

    local type_ = tonumber(args[2])
    local variant = tonumber(args[3]) or 0

    -- Missing type
    if not type_ then
        Console.PrintError("Usage: champion <name|id> <type> [variant]")
        return
    end

    -- Missing entity
    local getEntity = EntityConfig.GetEntity(type_, variant)
    if not getEntity then
        Console.PrintError("ERROR: Entity does not exist")
        return
    end

    -- Can not be champion
    local hasChampion = getEntity:CanBeChampion()
    if not hasChampion then
        Console.PrintError("ERROR: Entity is not allowed to be champion")
        return
    end

    local room = game:GetRoom()
    local pos = Isaac.GetFreeNearPosition(room:GetCenterPos(), 10)
    local entity = Isaac.Spawn(type_, variant, 0, pos, Vector.Zero, nil)

    entity:ToNPC():Morph(type_, variant, 0, 0)
    entity:GetData().co_champion_debugID = champID
end
mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, ChampionCommand)

-- Autocomplete
local function ChampionConsoleAutocomplete(_, cmd, params)
    if cmd ~= "champion" then return end

    local args = {}
    for word in string.gmatch(params or "", "%S+") do
        table.insert(args, word)
    end

    if #args <= 1 then
        local suggestions = { {"list", "Show all champions"} }
        for name, id in pairs(mod.ChampionID) do
            table.insert(suggestions, {name, "Champion ID " .. id})
        end
        return suggestions
    end
end
mod:AddCallback(ModCallbacks.MC_CONSOLE_AUTOCOMPLETE, ChampionConsoleAutocomplete, "champion")