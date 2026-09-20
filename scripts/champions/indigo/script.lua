--[[ Indigo ]]--
local mod = ChampionOverhaul

local CHAMPION = "indigo"
local flags = EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.3, 0.0, 0.5, 1.0),
    weight = 0.5,
    drop = "5.50.0", -- Chest
    entityFlags = flags
})

local DAMAGE_DELAY = 10
local KNOCKBACK_STRENGTH = 20
local PLAYER_DISTANCE = 120

-- Damage delay
---@param npc EntityNPC
function mod:IndigoDamageDelay(npc)
    if not self:GetChampion(npc, CHAMPION) then return end
    if not npc:GetData().co_champion_indigo_delay then return end

    if npc:GetData().co_champion_indigo_delay < DAMAGE_DELAY then
        npc:GetData().co_champion_indigo_delay = npc:GetData().co_champion_indigo_delay + 1
        return
    end

    npc:GetData().co_champion_indigo_delay = nil
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.IndigoDamageDelay)

-- Push mechanic
---@param entity Entity
---@param amount number
function mod:IndigoKnockback(entity, amount)
    if not self:GetChampion(entity, CHAMPION) then return end
    if entity:GetData().co_champion_indigo_delay then return end
    if amount <= 0 then return end

    local npc = entity:ToNPC()
    if not npc then return end

    local target = npc:GetPlayerTarget()
    if not target then return end

    entity:GetData().co_champion_indigo_delay = 0
    npc:PlaySound(SoundEffect.SOUND_CLAP, 1, 2, false, 0.5)

    -- Nerf strength for weak damage
    local strength = (amount > 1.5) and KNOCKBACK_STRENGTH or KNOCKBACK_STRENGTH / 2

    if self:IsStationary(entity) then
        -- Pushes the player away from the champion
        local distance = target.Position:Distance(entity.Position)
        if distance > PLAYER_DISTANCE then return end

        local direction = (target.Position - entity.Position):Normalized()
        target.Velocity = target.Velocity + direction * (strength / 2)
    else
        -- Pushes the champion towards the player
        local direction = (target.Position - entity.Position):Normalized()
        local velocity = entity.Velocity
        local directionalVelocity = velocity:Dot(direction)

        if directionalVelocity < strength then
            entity.Velocity = velocity + direction * (strength - directionalVelocity)
        end
    end

    -- Particles
    local effAmount = math.min(4 + math.floor(amount), 15)

    for _ = 1, effAmount do
        local effVel = RandomVector() * (2 + math.random())
        local offset = Vector(0, -15)
        local scale = Vector(0.75, 0.75)
        local rotation = math.floor(360 * math.random())

        self:SpawnParticle("../scripts/champions/indigo/particle.png", effVel, entity.Position, offset, scale, rotation)
    end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.IndigoKnockback)