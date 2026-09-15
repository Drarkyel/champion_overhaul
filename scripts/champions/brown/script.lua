--[[ Brown ]]--
local mod = ChampionOverhaul
local game = Game()

local CHAMPION = "brown"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.545, 0.27, 0.176),
    weight = 0.25,
    drop = "999.14.11" -- Charming poop,
})

---@param npc EntityNPC
function mod:BrownPoops(npc)
    if not self:GetChampion(npc, CHAMPION) then return end
    if npc.FrameCount < 33 or npc.FrameCount % 10 ~= 0 then return end

    npc:GetData().co_champion_brown_poops = npc:GetData().co_champion_brown_poops or {}
    local poops = #npc:GetData().co_champion_brown_poops

    -- Poop limit
    local roomShape = game:GetRoom():GetRoomShape()
    local poopLimit = self.ROOM_GRIDSCALE[roomShape] or 10
    if poops >= poopLimit then return end

    -- Chance to spawn poop
    local chance = math.random(5 + poops)
    if chance > 1 then return end

    -- New poop
    local pos = Isaac.GetFreeNearPosition(npc.Position, 40)
    local poop = Isaac.GridSpawn(GridEntityType.GRID_POOP, 0, pos)
    if poop then
        local poopEntity = poop:ToPoop()
        if poopEntity then poopEntity:ReduceSpawnRate() end

        npc:PlaySound(SoundEffect.SOUND_FART, 1, 2, false, 1.5)

        table.insert(npc:GetData().co_champion_brown_poops, poop:GetGridIndex())
    end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.BrownPoops)

---@param entity Entity
function mod:BrownFart(entity)
    if not self:GetChampion(entity, CHAMPION) then return end

    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, entity)
    entity:ToNPC():PlaySound(SoundEffect.SOUND_FART)

    ---@type integer[]
    local data = entity:GetData().co_champion_brown_poops
    if not (data and #data > 0) then return end

    local room = game:GetRoom()

    -- Get rid of brown poops
    local posList = {}
    for _, gridIndex in ipairs(data) do
        local gridEntity = room:GetGridEntity(gridIndex)

        if gridEntity and gridEntity:ToPoop() then
            gridEntity:Destroy(true)
            room:RemoveGridEntity(gridIndex, 0, false)

            table.insert(posList, gridEntity.Position)
        end
    end

    -- Update room
    room:Update()

    -- Spawn red poops
    for _, pos in ipairs(posList) do
        Isaac.GridSpawn(GridEntityType.GRID_POOP, GridPoopVariant.RED, pos)
    end

    self:SetDeath(entity)
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, mod.BrownFart)