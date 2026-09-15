--[[ Pearl ]]--
local mod = ChampionOverhaul
local game = Game()

local CHAMPION = "pearl"

-- Pearl data
---@param npc EntityNPC
local init = function(npc)
    npc:GetData().co_champion_pearl = {
        Delay = 0,
        Pos = nil,
        Stationary = mod:IsStationary(npc)
    }
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.85, 0.85, 0.85),
    weight = 0.1,
    drop = "5.51.0", -- Bomb chest
    init = init
})

local TELEPORT_DELAY = 90
local TELEPORT_DURATION = 20

-- Teleports around
---@param npc EntityNPC
function mod:PearlDelay(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    local data = npc:GetData().co_champion_pearl
    if not data then return end

    -- Waiting
    if data.Delay < TELEPORT_DELAY then
        npc:GetData().co_champion_pearl.Delay = data.Delay + 1
        return
    end

    -- Starts teleport
    if npc.FrameCount % 10 ~= 0 or math.random(5) > 1 then return end

    npc:GetData().co_champion_pearl.Delay = 0

    local pos = Isaac.GetFreeNearPosition(game:GetRoom():GetRandomPosition(0), 10)
    npc:GetData().co_champion_pearl.Pos = pos

    npc:AddFreeze(EntityRef(npc), TELEPORT_DURATION)
    npc:PlaySound(855, 1, 2, false, 1)

    local mark = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.EFFECT_NULL, 0, pos, Vector.Zero, npc)
    mark:GetData().co_Champion_pearl_mark = true

    local sprite = mark:GetSprite()
    sprite:Load("../scripts/champions/pearl/mark.anm2", true)
    sprite:Play("Idle", true)

    Isaac.CreateTimer(function()
        self:PearlTeleport(npc)
    end, TELEPORT_DURATION, 1, false)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PearlDelay)

-- Teleports to target
---@param npc EntityNPC
function mod:PearlTeleport(npc)
    if not npc:Exists() then return end

    local data = npc:GetData().co_champion_pearl
    if not (data and data.Pos) then return end

    local oldPos = npc.Position
    local newPos = data.Pos

    npc:GetData().co_champion_pearl.Delay = 0
    npc:GetData().co_champion_pearl.Pos = nil

    if not data.Stationary then
        -- Teleport entity
        npc.Position = newPos

        for i = 1, 8 do
            local angle = 45 * (i - 1)
            local velocity = Vector.FromAngle(angle) * 3

            self:SpawnParticle("../scripts/champions/pearl/particle.png", velocity, oldPos)
        end
    else
        -- Trigger splash effect
        npc:PlaySound(SoundEffect.SOUND_DEMON_HIT, 1, 2, false, 5)
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ENEMY_GHOST, 2, newPos, Vector.Zero, npc)

        -- Splash damage
        for _, entity in ipairs(Isaac.FindInRadius(newPos, 60, EntityPartition.PLAYER)) do
            if entity:ToPlayer() then entity:TakeDamage(npc.CollisionDamage, 0, EntityRef(npc), 30) end
        end
    end
end

-- Mark timeout
---@param effect EntityEffect
function mod:PearlMark(effect)
    if not effect:GetData().co_Champion_pearl_mark then return end

    -- Beam effect
    local spawner = effect.SpawnerEntity
    if spawner then
        if effect.FrameCount % 5 == 0 then
            self:BeamEffect(spawner.Position, effect.Position, Color(1.5, 1.5, 1.5), false)
        end
    end

    -- Removes
    if not effect:GetSprite():IsFinished("Idle") then return end

    effect:Remove()
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.PearlMark, EffectVariant.EFFECT_NULL)