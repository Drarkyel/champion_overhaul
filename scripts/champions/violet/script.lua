--[[ Violet ]]--
local mod = ChampionOverhaul

local CHAMPION = "violet"

-- Pulling effect
---@param npc EntityNPC
local init = function(npc)
    local effect = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.PULLING_EFFECT,
        0,
        npc.Position,
        Vector.Zero,
        nil
    )

    effect:ToEffect():FollowParent(npc)
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.7, 0.4, 1, 1),
    weight = 0.25,
    drop = "5.350.0", -- Trinket
    hasStartAnim = false,
    init = init
})

local PULL_RADIUS = 240
local MAX_PULL_STRENGTH = 0.5

local DEATH_PULL_RADIUS = 240
local DEATH_MAX_PULL_STRENGTH = 4
local DEATH_PULL_DURATION = 25

-- Pulls player
---@param npc EntityNPC
function mod:VioletPull(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    local player = Isaac.GetPlayer()
    local distance = npc.Position:Distance(player.Position)

    if distance >= PULL_RADIUS then return end

    local direction = npc.Position - player.Position
    if direction:Length() == 0 then return end

    local factor = 1 - (distance / PULL_RADIUS)
    local strength = MAX_PULL_STRENGTH * factor

    player.Velocity = player.Velocity + direction:Resized(strength)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.VioletPull)

-- Strong pull upon death
---@param npc EntityNPC
function mod:VioletDeath(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    npc:PlaySound(SoundEffect.SOUND_INFLATE, 1, 2, false, 1.5)

    local player = Isaac.GetPlayer()
    local deathPosition = npc.Position

    -- Particles
    local circleAmount = 3

    for i = 1, circleAmount do
        local particleAmount = 8 * i
        local radius = 65 * i
        local speed = 2.5 * i

        for j = 1, particleAmount do
            local angle = 360 / particleAmount * (j - 1)
            local direction = Vector.FromAngle(angle)

            local velocity = -direction * speed
            local pos = npc.Position + direction * radius

            self:SpawnParticle("../scripts/champions/violet/particle.png", velocity, pos)
        end
    end

    -- Pulling
    Isaac.CreateTimer(function()
        for _, entity in ipairs(Isaac.GetRoomEntities()) do
            if entity.Type ~= EntityType.ENTITY_PLAYER
            and entity.Type ~= EntityType.ENTITY_TEAR
            and entity.Type ~= EntityType.ENTITY_BOMB
            and entity.Type ~= EntityType.ENTITY_PICKUP
            and entity.Type ~= EntityType.ENTITY_PROJECTILE
            and not entity:IsEnemy() then goto continue end

            local direction = deathPosition - entity.Position
            local distance = direction:Length()

            if distance >= DEATH_PULL_RADIUS then return end
            if distance <= 1 then return end

            local factor = distance / DEATH_PULL_RADIUS
            local strength = DEATH_MAX_PULL_STRENGTH * factor

            entity.Velocity = entity.Velocity + direction:Resized(strength)

            ::continue::
        end
    end, 1, DEATH_PULL_DURATION, false)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.VioletDeath)