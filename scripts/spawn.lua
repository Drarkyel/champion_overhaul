--[[ Spawn ]]--
local mod = ChampionOverhaul
local game = Game()

-- Champion conditions
function ChampionOverhaul:IsChampionAvailable(champion)
    local levelStage = game:GetLevel():GetAbsoluteStage()
    local isDangerous = champion.weight < 0.25

    -- No restriction
    if game.Challenge == Challenge.CHALLENGE_ULTRA_HARD then
        return true
    end

    -- Requirements
    local everythingIsHarder = Isaac.GetPersistentGameData():Unlocked(Achievement.EVERYTHING_IS_TERRIBLE)
    local minimumStage = everythingIsHarder and LevelStage.STAGE1_2 or LevelStage.STAGE3_1

    if isDangerous and levelStage < minimumStage then
        return false
    end

    return true
end

-- Get random champion
---@param seed integer
---@return integer
function ChampionOverhaul:GetRandomChampion(seed)
    local rng = RNG()
    rng:SetSeed(seed, 0)

    local totalWeight = 0
    local candidates = {}

    for id, champion in pairs(self.ChampionData) do
        if self:IsChampionAvailable(champion) then
            totalWeight = totalWeight + champion.weight

            candidates[#candidates + 1] = {
                id = id,
                weight = champion.weight
            }
        end
    end

    if totalWeight <= 0 then return -1 end

    local roll = rng:RandomFloat() * totalWeight
    local accumulated = 0

    for _, candidate in pairs(candidates) do
        accumulated = accumulated + candidate.weight

        if roll < accumulated then
            return candidate.id
        end
    end

    return -1
end

-- Enables champion to spawn in waves
---@param npc EntityNPC
function mod:ChampionWave(npc)
    -- Must be Hard Mode
    if game.Difficulty ~= Difficulty.DIFFICULTY_HARD then return end
    -- Must be npc spawned by wave
    if not npc:HasEntityFlags(EntityFlag.FLAG_AMBUSH) then return end
    -- Avoids npc unable to be champion
    if not EntityConfig.GetEntity(npc.Type, npc.Variant):CanBeChampion() then return end
    -- Avoids champions and bosses
    if npc:IsChampion() or npc:IsBoss() then return end
    -- Avoids modded champions
    if self:IsChampion(npc) then return end

    -- Factor used as chance to trigger a champion
    local factor = 100

    -- Unlock factors
    local hasEIT = Isaac.GetPersistentGameData():Unlocked(Achievement.EVERYTHING_IS_TERRIBLE)
    local hasEIT2 = Isaac.GetPersistentGameData():Unlocked(Achievement.EVERYTHING_IS_TERRIBLE_2)
    if hasEIT then factor = factor / 2 end
    if hasEIT2 then factor = factor / 2 end

    -- Boss room punishment
    local room = game:GetRoom()
    if room:GetType() == RoomType.ROOM_BOSS then factor = factor * 2 end

    local player = Isaac.GetPlayer()

    -- Champion Belt factor
    local championbeltAmount = player:GetCollectibleNum(CollectibleType.COLLECTIBLE_CHAMPION_BELT)
    factor = factor - 10 * championbeltAmount

    -- Purple Heart factor
    local purpleheartAmount = player:GetTrinketMultiplier(TrinketType.TRINKET_PURPLE_HEART)
    factor = factor / (1 + purpleheartAmount)

    -- Ultra Hard Challenge
    if game.Challenge == Challenge.CHALLENGE_ULTRA_HARD then factor = 1 end

    factor = math.max(1, factor)

    local rng = npc.InitSeed % math.floor(factor)
    if rng > 5 then return end

    npc:MakeChampion(npc.InitSeed, ChampionColor.RED, true)
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.ChampionWave)

-- Redesigned champion spawn system
---@param npc EntityNPC
function mod:SpawnChampion(npc)
    if not npc:IsChampion() then return end -- Requires vanilla champion
    if self:IsChampion(npc) then return end -- Already spawned

    local id

    -- Get champion id
    if not npc:GetData().co_champion_debugID then
        id = self:GetRandomChampion(npc.InitSeed)
    else
        id = npc:GetData().co_champion_debugID
    end

    -- Set champion
    self:SetChampion(npc, id)
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.SpawnChampion)

-- Bring features to bosses
function mod:BossChampionDamage(npc)
    if not self:IsBossChampion(npc) then return end

    -- Collision damage
    local stageScale = game:GetLevel():GetAbsoluteStage() < LevelStage.STAGE4_1 and 1 or 2
    npc.CollisionDamage = 2 * stageScale
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.BossChampionDamage)

-- Champion death
---@param npc EntityNPC
function mod:ChampionDrop(npc)
    if not self:IsChampion(npc) then return end

    -- Gets rid of old pickups
    local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP)
    for i = 1, #pickups do
        local distance = pickups[i].Position:Distance(npc.Position)
        if distance < 15 then pickups[i]:Remove() end
    end

    -- Custom drop
    if not self:CanDrop(npc) then return end

    local drop = self.ChampionData[npc.SubType].drop
    if not drop or drop == "" then return end

    local type_, variant, subtype, min_drop, max_drop = drop:match("^(%d+)%.(%d+)%.(%d+)%.?(%d*)%.?(%d*)$")

    type_ = tonumber(type_) or 5
    variant = tonumber(variant) or 10
    subtype = tonumber(subtype) or 0
    min_drop = tonumber(min_drop) or 1
    max_drop = tonumber(max_drop) or min_drop

    -- Card drop
    if variant == 301 then
        local special = (subtype == 0) and 1 or 0 -- Special only
        local rune = (subtype == 1) and 1 or 0 -- Rune only
        local suit = (subtype == 2) and 1 or 0 -- Suit only
        local cardType = game:GetItemPool():GetCardEx(npc.InitSeed, special, rune, suit, false)

        local pos = Isaac.GetFreeNearPosition(npc.Position, 0)
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, cardType, pos, Vector.Zero, npc)
        return
    end

    -- Pill drop
    if variant == PickupVariant.PICKUP_PILL and subtype ~= 0 then
        local itemPool = game:GetItemPool()
        local pillColor = itemPool:ForceAddPillEffect(subtype)

        local pos = Isaac.GetFreeNearPosition(npc.Position, 0)
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, pillColor, pos, Vector.Zero, npc)
        return
    end

    local drop_count = math.random(min_drop, max_drop)

    -- Singular drop
    if drop_count == 1 then
        local pos = Isaac.GetFreeNearPosition(npc.Position, 0)

        if type_ ~= 999 then -- Entity
            Isaac.Spawn(type_, variant, subtype, pos, Vector.Zero, npc)
        else -- Grid
            Isaac.GridSpawn(variant, subtype, pos)
        end

        return
    end

    -- Multiple drops
    for _ = min_drop, max_drop do
        local velocity = EntityPickup.GetRandomPickupVelocity(npc.Position, nil, 0)

        Isaac.Spawn(type_, variant, subtype, npc.Position, velocity, npc)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.ChampionDrop)

--[[ Ultra Hard ]]--

-- Ultra Hard variable
local ultraHard = false

-- Fix crash related to Double Trouble in Ultra Hard Challenge
function mod:bossPreUltraHard()
    if game.Challenge ~= Challenge.CHALLENGE_ULTRA_HARD then return end

    ultraHard = true
    game.Challenge = Challenge.CHALLENGE_NULL
end
mod:AddCallback(ModCallbacks.MC_PRE_LEVEL_INIT, mod.bossPreUltraHard)

-- Adds missing curses to Ultra Hard challenge
function mod:bossPostUltraHard()
    if not ultraHard then return end

    ultraHard = false
    game.Challenge = Challenge.CHALLENGE_ULTRA_HARD
    game.Difficulty = Difficulty.DIFFICULTY_HARD
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.bossPostUltraHard)