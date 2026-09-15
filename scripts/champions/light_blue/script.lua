--[[ Light Blue ]]--
local mod = ChampionOverhaul
local game = Game()

local CHAMPION = "light_blue"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.482, 0.408, 0.933, 1),
    weight = 1.0,
    drop = "5.10.2", -- Half red heart
    hasShader = true
})

---@param npc EntityNPC
function mod:LightBlueDeath(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    local speed = game.Difficulty == Difficulty.DIFFICULTY_NORMAL and 0 or 1
    local direction = math.random(2) == 1 and 1 or -1

    for i = 1, 8 do
        local angle = (i - 1) * 45
        local velocity = Vector.FromAngle(angle)

        local projData = {
            Pos = npc.Position,
            Direction = direction,
            Speed = speed
        }

        npc:PlaySound(SoundEffect.SOUND_PLOP, 1, 2, false, 0.5)

        local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 6, 0, npc.Position + velocity, Vector.Zero, npc)
        self:SetChampionRef(proj, npc)
        proj:GetData().co_lightblue = projData
        proj:ToProjectile():AddFallingAccel(-0.05)
        proj:ToProjectile():AddProjectileFlags(ProjectileFlags.NO_WALL_COLLIDE)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.LightBlueDeath)

---@param projectile EntityProjectile
function mod:LightBlueProjectile(projectile)
    local data = projectile:GetData()
    if not data.co_lightblue then return end

    local center = data.co_lightblue.Pos
    local direction = data.co_lightblue.Direction
    local speed = data.co_lightblue.Speed

    local radial = projectile.Position - center

    if radial:Length() == 0 then
        radial = Vector(1,0)
    else
        radial = radial:Normalized()
    end

    local tangent = Vector(-radial.Y, radial.X) * direction

    local orbitSpeed = 6.0 + 2 * speed
    local expansionSpeed = 3.0 + 1.5 * speed

    projectile.Velocity = tangent * orbitSpeed + radial * expansionSpeed
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.LightBlueProjectile)