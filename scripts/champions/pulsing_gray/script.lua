--[[ Pulsing Gray ]]--
local mod = ChampionOverhaul
local game = Game()

local CHAMPION = "pulsing_gray"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.5, 0.5, 0.5, 1),
    colorType = 2,
    weight = 0.1,
    drop = "5.20.3", -- Dime
    hasShader = false
})

local REPEL_DELAY = 45
local HOMING_DELAY = 10

---@param npc EntityNPC
function mod:PulsingGrayRepel(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    -- Delay
    if npc:GetData().co_champion_pulsinggray_delay then
        npc:GetData().co_champion_pulsinggray_delay = npc:GetData().co_champion_pulsinggray_delay + 1
        if npc:GetData().co_champion_pulsinggray_delay < REPEL_DELAY then return end
        npc:GetData().co_champion_pulsinggray_delay = nil
    end

    -- Chance
    local chance = math.random(10)
    if chance > 1 then return end

    ---@type EntityTear[]
    local tears = Isaac.FindInRadius(npc.Position, 80, EntityPartition.TEAR)
    if #tears == 0 then return end

    -- Start delay
    npc:PlaySound(SoundEffect.SOUND_BATTERYCHARGE, 1, 2, false, 0.5)
    npc:GetData().co_champion_pulsinggray_delay = 0

    -- Repel projectiles
    for i = 1, #tears do
        local tear = tears[i]
        local pos = tear.Position
        local size = tear.Size

        tear:Remove()

        local target = npc.Target
        if not target then target = Isaac.GetPlayer() end

        -- Converts to homing shot if big enough
        if size > 5 then
            local shot = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 6, 0, pos, Vector.Zero, npc)
            shot:GetData().co_champion_pulsinggray_delay = 0
            shot:ToProjectile().FallingSpeed = -3
        end
    end

    -- Aura effect
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HALLOWED_GROUND, 6, npc.Position, Vector.Zero, nil)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PulsingGrayRepel)

function mod:PulsingGrayAtkDelay(projectile)
    if not projectile:GetData().co_champion_pulsinggray_delay then return end

    projectile:GetData().co_champion_pulsinggray_delay = projectile:GetData().co_champion_pulsinggray_delay + 1
    if projectile:GetData().co_champion_pulsinggray_delay ~= HOMING_DELAY then return end

    projectile:AddProjectileFlags(ProjectileFlags.SMART)

    local target = Isaac.GetPlayer()
    local velocity = target.Position - projectile.Position
    if velocity:Length() <= 0 then return end

    local speed = game.Difficulty == Difficulty.DIFFICULTY_NORMAL and 8 or 10
    velocity = velocity:Resized(speed)
    projectile.Velocity = velocity
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.PulsingGrayAtkDelay)
