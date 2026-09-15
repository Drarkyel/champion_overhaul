--[[ Teal ]]--
local mod = ChampionOverhaul
local game = Game()
local sound = SFXManager()

local CHAMPION = "teal"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0, 0.5, 0.5, 1),
    weight = 0.5,
    drop = "5.10.8" -- Half soul heart
})

-- Shoots a haemolacria projectile
---@param npc EntityNPC
function mod:TealShot(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    local player = npc:GetPlayerTarget()
    if not player then return end

    local startPos = npc.Position
    local targetPos = player.Position

    local flightTime = 45
    local acceleration = 1.2

    -- Horizontal velocity
    local velocity = ((targetPos - startPos) / flightTime) * 1.5

    -- Vertical velocity
    local fallingSpeed = -(acceleration * flightTime / 2)

    -- Shot
    npc:PlaySound(SoundEffect.SOUND_LITTLE_SPIT, 1, 2, false, 0.5)
    local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 6, 0, startPos, velocity, npc)
    proj:GetData().co_champion_teal_shot = true
    proj:ToProjectile().FallingAccel = acceleration
    proj:ToProjectile().FallingSpeed = fallingSpeed
    proj:ToProjectile().CollisionDamage = npc.CollisionDamage
    proj:ToProjectile().Scale = 2.5
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.TealShot)

---@param projectile EntityProjectile
function mod:TealParticles(projectile)
    if not projectile:GetData().co_champion_teal_shot then return end
    if projectile.FrameCount % 2 ~= 0 then return end

    local particle = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.HAEMO_TRAIL,
        0,
        projectile.Position + Vector(0, projectile.Height),
        RandomVector() * 0.5,
        projectile
    ):ToEffect()

    particle.Color = Color(1, 1, 1, 1, 0, 1, 1)
    particle.SpriteScale = Vector(0.75, 0.75)
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.TealParticles)

---@param projectile EntityProjectile
function mod:TealSplash(projectile)
    if not projectile:GetData().co_champion_teal_shot then return end

    game:ShakeScreen(10)
    sound:Play(SoundEffect.SOUND_BOSS1_EXPLOSIONS, 1, 2, false, 1.25)

    -- Splash effect
    local splash = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 1, projectile.Position, Vector.Zero, nil)
    splash:GetSprite().Color = projectile:GetSprite().Color
    splash.SpriteScale = Vector(1.25, 1.25)

    local radius = 80

    -- Player damage
    for _, player in ipairs(Isaac.FindInRadius(projectile.Position, radius, EntityPartition.PLAYER)) do
        player:TakeDamage(projectile.CollisionDamage, 0, EntityRef(projectile), 30)
    end

    -- Entity HP
    for _, entity in ipairs(Isaac.FindInRadius(projectile.Position, radius, EntityPartition.ENEMY)) do
        local npc = entity:ToNPC()
        if not (npc and entity:IsVulnerableEnemy() and entity:CanShutDoors()) then goto continue end

        local iconSubtype = 0

        -- Heal amount
        local heal = math.floor(entity.MaxHitPoints / 2)
        entity.HitPoints = entity.HitPoints + heal

        if entity.HitPoints <= heal then
            -- Heal
            entity:SetColor(Color(1, 0, 0, 1), 20, 0, true, false)
            npc:PlaySound(SoundEffect.SOUND_VAMP_GULP, 1, 2, false, 1.25)
        else
            -- Overheal
            entity:SetColor(Color(0, 0.5, 0.5, 1), 20, 0, true, false)
            npc:PlaySound(SoundEffect.SOUND_VAMP_GULP, 1, 2, false, 0.5)
            iconSubtype = 4
        end

        local heart = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, iconSubtype, entity.Position, Vector.Zero, nil)
        heart:ToEffect():FollowParent(entity)
        heart:GetSprite().Offset = Vector(0, -48)

        ::continue::
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_DEATH, mod.TealSplash)