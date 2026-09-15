--[[ Gold ]]--
local mod = ChampionOverhaul
local game = Game()

local CHAMPION = "gold"

---@param npc EntityNPC
local init = function(npc)
    npc:PlaySound(SoundEffect.SOUND_ULTRA_GREED_PULL_SLOT)
    npc:GetData().co_champion_gold_delay = 0
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.831, 0.686, 0.216),
    weight = 0.01,
    init = init
})

local DESPAWN_DURATION = 150

-- Tries to despawn
---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param countdown integer
function mod:GoldResetDelay(entity, amount, flags, source, countdown)
    if not self:GetChampion(entity, CHAMPION) then return end
    if entity:GetData().co_champion_gold_damage then return end

    -- Particles
    if entity:GetData().co_champion_gold_delay and entity:GetData().co_champion_gold_delay > 5 then
        entity:ToNPC():PlaySound(SoundEffect.SOUND_BALL_AND_CHAIN_HIT, 0.5, 2, false, 3)
        local velocity = RandomVector() * (3 + 2 * math.random())
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.COIN_PARTICLE, 0, entity.Position, velocity, entity)
    end

    entity:GetData().co_champion_gold_delay = 0

    -- Reduces damage received
    entity:GetData().co_champion_gold_damage = true
    local damage = amount * 0.5
    entity:TakeDamage(damage, flags, source, countdown)
    entity:GetData().co_champion_gold_damage = nil

    return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.GoldResetDelay)

-- Tries to despawn
---@param npc EntityNPC
function mod:GoldDespawn(npc)
    if not self:GetChampion(npc, CHAMPION) then return end
    if not npc:GetData().co_champion_gold_delay then return end

    -- Blings
    if npc.FrameCount % 15 == 0 then
        local angle = math.random(0, 359)
        local distance = 15 + 5 * math.random()

        local offset = Vector.FromAngle(angle) * distance + Vector(0, -15)
        local pos = npc.Position + offset

        local bling = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ULTRA_GREED_BLING, 0, pos, Vector.Zero, nil)
        bling.DepthOffset = 1000
    end

    -- Alpha reduce
    local alpha = math.max(0, 1 - (npc:GetData().co_champion_gold_delay / DESPAWN_DURATION))
    npc:GetSprite().Color = Color(1, 1, 1, alpha)

    npc:GetData().co_champion_gold_delay = npc:GetData().co_champion_gold_delay + 1
    if npc:GetData().co_champion_gold_delay < DESPAWN_DURATION then return end

    npc:PlaySound(SoundEffect.SOUND_FIRE_RUSH, 1, 2, false, 1.5)

    -- Despawns
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position, Vector.Zero, npc)
    npc:Remove()
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.GoldDespawn)

-- Gold death
---@param npc EntityNPC
function mod:GoldDeath(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    npc:PlaySound(SoundEffect.SOUND_ULTRA_GREED_COIN_DESTROY)

    -- Gold room
    game:ShakeScreen(30)
    local room = game:GetRoom()
    room:TurnGold()

    -- Particles
    for _ = 1, 30 do
        local velocity = RandomVector() * (3 + 5 * math.random())
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.COIN_PARTICLE, 0, npc.Position, velocity, npc)
    end

    -- Spawn item
    local pos = Isaac.GetFreeNearPosition(npc.Position, 10)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 0, pos, Vector.Zero, npc)
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, pos, Vector.Zero, npc)

    -- Midas effect to enemies
    local player = Isaac.GetPlayer()
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if entity:IsVulnerableEnemy() and entity:CanShutDoors() then
            entity:AddMidasFreeze(EntityRef(player), 150)
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.GoldDeath)