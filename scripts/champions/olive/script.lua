--[[ Olive ]]--
local mod = ChampionOverhaul
local game = Game()

local CHAMPION = "olive"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.5, 0.5, 0, 1),
    weight = 0.25,
    drop = "3.43.2.1.3" -- Pestilence locust (1-3)
})

local PROJ_MIN_AMOUNT = 25
local PROJ_MAX_AMOUNT = 50

local BASE_SCALE = 1.0
local MIN_SCALE = 1.0
local MAX_SCALE = 1.5

-- Shrinks over HP
function mod:OliveSwell(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    local hpRatio = math.max(0, (1 - npc.HitPoints / npc.MaxHitPoints))
    local scale = MIN_SCALE + (MAX_SCALE - MIN_SCALE) * hpRatio

    npc.Scale = BASE_SCALE * scale
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.OliveSwell)

-- Burst in a shower of projectiles
---@param npc EntityNPC
function mod:OliveBurst(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    game:ShakeScreen(15)
    npc:PlaySound(SoundEffect.SOUND_BOSS2INTRO_WATER_EXPLOSION, 1, 2, false, 0.75)
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 3, npc.Position, Vector.Zero, npc)

    local amount = math.max(PROJ_MIN_AMOUNT, math.min(PROJ_MAX_AMOUNT, npc.MaxHitPoints * 1.5))
    for i = 1, amount do
        local speed = math.random() * 8
        local velocity = Vector.FromAngle(math.random(0, 359)) * speed

        local params = ProjectileParams()
        params.Variant = 6
        params.FallingAccelModifier = 1.25 + 0.5 * math.random()
        params.FallingSpeedModifier = -80

        npc:FireProjectiles(npc.Position, velocity, 0, params)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.OliveBurst)
