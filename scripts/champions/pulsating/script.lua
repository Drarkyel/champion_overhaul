--[[ Pulsating ]]--
local mod = ChampionOverhaul
local game = Game()

local CHAMPION = "pulsating"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    colorIntensity = false,
    weight = 0.25,
    drop = "5.10.12", -- Rotten heart
    hasShader = false
})

local SPAWN_DELAY = 30
local FLY_AMOUNT = 5

-- Pulsating effect
function mod:PulsatingSprite(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    -- Pulsating effect
    local frame = npc.FrameCount - 33
    local period = 35

    local t = (1 - math.cos(2 * math.pi * frame / period)) * 0.5;
    local scale = 1.0 + 0.25 * t

    npc.Scale = scale

    -- Spawn delay
    if not npc:GetData().co_champion_pulsating_delay then return end

    npc:GetData().co_champion_pulsating_delay = npc:GetData().co_champion_pulsating_delay + 1
    if npc:GetData().co_champion_pulsating_delay >= SPAWN_DELAY then npc:GetData().co_champion_pulsating_delay = nil end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PulsatingSprite)

-- Spawn flies
---@param entity Entity
---@param amount number
function mod:PulsatingFly(entity, amount)
    if not self:GetChampion(entity, CHAMPION) then return end
    if entity:GetData().co_champion_pulsating_delay then return end
    if entity.FrameCount < 33 or entity.HitPoints <= amount then return end

    -- Fly amount
    local flyCount = 0
    local flies = Isaac.FindByType(EntityType.ENTITY_ATTACKFLY)
    for _, fly in ipairs(flies) do
        if fly:GetData().co_champion_pulsating_owner == GetPtrHash(entity) then
            flyCount = flyCount + 1
        end
    end
    if flyCount >= FLY_AMOUNT then return end

    -- Reset delay
    entity:GetData().co_champion_pulsating_delay = 0

    -- Spawn fly
    local velocity = EntityPickup.GetRandomPickupVelocity(entity.Position, nil, 0)

    local fly = Isaac.Spawn(EntityType.ENTITY_ATTACKFLY, 0, 0, entity.Position, velocity, entity)
    self:SetChampionRef(fly, entity)
    fly:GetData().co_champion_pulsating_owner = GetPtrHash(entity)
    fly:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    fly:GetSprite():ReplaceSpritesheet(0, "../scripts/champions/pulsating/brown_fly.png", true)
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.PulsatingFly)

---@param entity Entity
function mod:PulsatingAtk(entity)
    if not self:HasChampionSource(entity, CHAMPION) then return end

    local player = Isaac.GetPlayer()
    local targetPos = entity:GetPredictedTargetPosition(player, 0.5)

    local direction = (targetPos - entity.Position):Normalized()
    local speed = game.Difficulty == Difficulty.DIFFICULTY_NORMAL and 10 or 12
    local velocity = direction * speed

    local shot = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 5, 0, entity.Position, velocity, entity)
    self:SetChampionRef(shot, entity)
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, mod.PulsatingAtk, EntityType.ENTITY_ATTACKFLY)