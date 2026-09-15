--[[ Pink ]]--
local mod = ChampionOverhaul
local game = Game()

local CHAMPION = "pink"

-- Spawns familiar
---@param npc EntityNPC
local init = function(npc)
    local angle = math.random(0, 359)
    local distance = math.random(60, 80)

    local offset = Vector.FromAngle(angle) * distance
    local pos = Isaac.GetFreeNearPosition(npc.Position + offset, 0)

    local familiar = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.EFFECT_NULL, 0, pos, Vector.Zero, nil)
    familiar:GetData().co_champion_pink = true
    familiar.Parent = npc

    local sprite = familiar:GetSprite()
    sprite:Load("../scripts/champions/pink/pink_familiar.anm2", true)
    sprite:Play("Idle", true)
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(1.0, 0.3, 0.7),
    weight = 1.0,
    init = init
})

local FOLLOW_DISTANCE = 45
local FOLLOW_STRENGTH = 0.035
local FOLLOW_DAMPING = 0.82
local MAX_FOLLOW_SPEED = 8
local VELOCITY_MATCH = 0.55

local function FollowChampion(effect, champion)
    local offset = champion.Position - effect.Position
    local distance = offset:Length()

    if distance < 0.5 then
        effect.Velocity = effect.Velocity * 0.7
        return
    end

    local direction = offset / distance
    local displacement = distance - FOLLOW_DISTANCE

    -- Spring force
    local springForce = direction * displacement * FOLLOW_STRENGTH

    -- Move adaptation
    local matchedVel = champion.Velocity * VELOCITY_MATCH

    -- Combine and smooth
    local desiredVel = springForce + matchedVel
    effect.Velocity = effect.Velocity * FOLLOW_DAMPING + desiredVel * (1 - FOLLOW_DAMPING)

    -- Soft speed limit
    local speed = effect.Velocity:Length()
    if speed > MAX_FOLLOW_SPEED then
        effect.Velocity = effect.Velocity * (MAX_FOLLOW_SPEED / speed)
    end
end

local TARGET_DISTANCE = 200

-- Familiar effect
---@param effect EntityEffect
function mod:PinkFamiliar(effect)
    if not effect:GetData().co_champion_pink then return end

    local sprite = effect:GetSprite()
    local champion = effect.Parent

    -- Init
    if sprite:IsFinished("Idle") or sprite:IsFinished("Shoot") then sprite:Play("Float") end

    -- Death
    if not champion then
        --effect.Position = Vector.Zero
        sprite:Play("Death")
        if sprite:IsFinished("Death") then effect:Remove() end
        return
    end

    -- Follow
    FollowChampion(effect, champion)

    -- Start attack
    if sprite:IsPlaying("Float") then
        local target = Isaac.GetPlayer()
        if not target then goto continue end

        local distance = target.Position:Distance(effect.Position)
        if distance > TARGET_DISTANCE then goto continue end

        sprite:Play("Shoot")

        ::continue::
    end

    -- Shoot
    if sprite:IsEventTriggered("Shoot") then
        local target = Isaac.GetPlayer()
        if not target then return end

        local predStrength = 0.1 * math.random(0, 3)
        local predPos = champion:GetPredictedTargetPosition(target, predStrength)
        local direction = (predPos - effect.Position):Normalized()
        local speed = game.Difficulty == Difficulty.DIFFICULTY_NORMAL and 8 or 12

        local velocity = direction * speed
        local shot = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, effect.Position, velocity, champion)
        shot:GetData().co_champion_pink = true
        shot:ToProjectile().Scale = 0.05
        shot.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        champion:ToNPC():PlaySound(SoundEffect.SOUND_KISS_LIPS1, 1, 2, false, 3)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.PinkFamiliar, EntityType.ENTITY_NULL)

-- Pink death
function mod:PinkDeath(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    npc:PlaySound(SoundEffect.SOUND_GOODEATH, 1, 2, false, 1.5)

    -- Friendly reward
    if not self:CanDrop(npc) then return end

    local player = Isaac.GetPlayer()
    local friend = Isaac.Spawn(npc.Type, npc.Variant, 0, npc.Position, Vector.Zero, player)
    friend:AddCharmed(EntityRef(player), -1)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.PinkDeath)

-- Pink shot ignores grid
function mod:PinkShotNoGrid(projectile)
    if not projectile:GetData().co_champion_pink then return end

    projectile.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.PinkShotNoGrid)