--[[ Pulsing Purple ]]--
local mod = ChampionOverhaul
local game = Game()
local sound = SFXManager()

local CHAMPION = "pulsing_purple"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.615, 0, 1, 1),
    colorType = 2,
    weight = 0.1,
    drop = "5.301.1", -- Rune
    hasShader = false
})

-- Trigger shots
---@param npc EntityNPC
function mod:PulsingPurpleSpawnShot(npc)
    if not self:GetChampion(npc, CHAMPION) then return end
    if npc.FrameCount < 33 or npc.FrameCount % 50 ~= 0 then return end

    local roomShape = game:GetRoom():GetRoomShape()
    local limit = self.ROOM_GRIDSCALE[roomShape] or 10

    -- Current projectiles
    local projAmount = 0
    for _, proj in ipairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE, 6)) do
        local data = proj:GetData().co_champion_pulsingpurple
        if data and data.Ref == GetPtrHash(npc) then
            projAmount = projAmount + 1
        end
    end
    if projAmount >= limit then return end

    -- Get random pos
    local randomPos = game:GetRoom():GetRandomPosition(0)

    npc:PlaySound(SoundEffect.SOUND_STONESHOOT, 1, 2, false, 0.5)

    local projData = {
        Pos = randomPos,
        Ref = GetPtrHash(npc),
        Atk = false
    }

    -- Spawn purple shot
    local shot = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 6, 0, npc.Position, Vector.Zero, npc)
    shot:GetData().co_champion_pulsingpurple = projData
    shot:ToProjectile().CollisionDamage = npc.CollisionDamage
    shot:ToProjectile().FallingSpeed = 0
    shot:ToProjectile().FallingAccel = -0.1
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PulsingPurpleSpawnShot)

-- Projectile movement
---@param projectile EntityProjectile
function mod:PulsingPurpleShotTarget(projectile)
    if not projectile:GetData().co_champion_pulsingpurple then return end

    -- Wall collision
    projectile.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

    -- Particles
    local particle = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.HAEMO_TRAIL,
        0,
        projectile.Position + Vector(0, projectile.Height),
        RandomVector() * 2,
        projectile
    ):ToEffect()
    particle.Color = Color(1, 1, 1, 1, 0.615, 0, 1)
    particle.SpriteScale = Vector(0.5, 0.5)

    -- Initial spawn only
    local atk = projectile:GetData().co_champion_pulsingpurple.Atk
    if atk then return end

    local targetPos = projectile:GetData().co_champion_pulsingpurple.Pos

    -- Keeps moving toward pos
    local distance = projectile.Position:Distance(targetPos)

    if distance <= 5 then
        projectile.Velocity = Vector.Zero
        return
    end

    local direction = (targetPos - projectile.Position):Normalized()
    projectile.Velocity = direction * 5
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.PulsingPurpleShotTarget)

-- Shots target player upon death
---@param npc EntityNPC
function mod:PulsingPurpleDeath(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    local player = Isaac.GetPlayer()
    local speed = game.Difficulty == Difficulty.DIFFICULTY_NORMAL and 12 or 15

    local projAmount = 0
    for _, proj in ipairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE, 6)) do
        local data = proj:GetData().co_champion_pulsingpurple
        if data and data.Ref == GetPtrHash(npc) then
            projAmount = projAmount + 1

            proj:GetData().co_champion_pulsingpurple.Atk = true
            local direction = (player.Position - proj.Position):Normalized()
            local velocity = direction * speed

            proj.Velocity = velocity
        end
    end

    if projAmount == 0 then return end
    sound:Play(SoundEffect.SOUND_STEAM_HALFSEC, 1, 2, false, 0.5)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.PulsingPurpleDeath)