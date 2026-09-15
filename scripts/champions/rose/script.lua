--[[ Rose ]]--
local mod = ChampionOverhaul
local game = Game()

local CHAMPION = "rose"

local ORBITAL_COUNT = 4
local ORBITAL_RADIUS = 36
local ORBITAL_SPEED = 8

local RICOCHET_DURATION = 240

-- Spawn ricochet effects
local init = function(npc)
    local direction = math.random(2) == 1 and 1 or -1

    for i = 1, ORBITAL_COUNT do
        local angle = ((i - 1) / ORBITAL_COUNT) * 360

        ---@diagnostic disable
        local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 6, 0, npc.Position, Vector.Zero, npc):ToProjectile()
        proj:GetData().co_champion_rose = {
            Champion = GetPtrHash(npc),
            Angle = angle,
            Direction = direction,
            Radius = ORBITAL_RADIUS,
            Released = false,
            Duration = RICOCHET_DURATION
        }

        proj.Parent = npc
        proj.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        proj.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        proj:AddProjectileFlags(ProjectileFlags.BOUNCE)
        proj.Scale = 0.05
        proj.FallingSpeed = 0
        proj.FallingAccel = -0.1
    end
end

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.76, 0.117, 0.337),
    weight = 0.25,
    drop = "5.20.5", -- Lucky penny
    init = init
})

-- Orbitals
---@param projectile EntityProjectile
function mod:RoseOrbitals(projectile)
    local data = projectile:GetData().co_champion_rose
    if not data then return end

    -- Ricochet projectile
    if data.Released then
        projectile:GetData().co_champion_rose.Duration = data.Duration - 1

        if data.Duration <= 0 then
            projectile.FallingAccel = 0.1
            return
        end

        return
    end

    -- Orbital
    local champion = projectile.Parent
    if not champion or not champion:Exists() or champion:IsDead() then return end

    projectile:GetData().co_champion_rose.Angle = data.Angle + data.Direction * ORBITAL_SPEED

    local offset = Vector.FromAngle(projectile:GetData().co_champion_rose.Angle) * data.Radius

    projectile.Position = champion.Position + offset
    projectile.Velocity = Vector.Zero

    projectile.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    projectile.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.RoseOrbitals, 6)

-- Death
---@param npc EntityNPC
function mod:RoseDeath(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    npc:PlaySound(SoundEffect.SOUND_SLOTSPAWN, 1, 2, false, 1.5)

    local championID = GetPtrHash(npc)
    for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE, 6)) do
        local data = entity:GetData().co_champion_rose
        if not data then goto continue end

        if data.Champion ~= championID then goto continue end

        entity:GetData().co_champion_rose.Released = true
        entity.Parent = nil

        local direction = Vector.FromAngle(data.Angle)
        local speed = game.Difficulty == Difficulty.DIFFICULTY_NORMAL and 6 or 8

        local projectile = entity:ToProjectile()
        projectile.Velocity = direction * speed
        projectile.Scale = 1
        projectile.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
        projectile.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

        ::continue::
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.RoseDeath)