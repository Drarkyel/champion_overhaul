--[[ Red ]]--
local mod = ChampionOverhaul

local CHAMPION = "red"

---@param npc EntityNPC
local init = function(npc)
    local redList = {
        DamageDelay = 0,
        HealDelay = 0,
        HealAmount = 0
    }

    npc:GetData().co_champion_red = redList
end

ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(1, 0.15, 0.15),
    weight = 1.0,
    drop = "5.10.1", -- Red heart
    init = init
})

local DAMAGE_DELAY = 15
local HEAL_DELAY = 30
local HEAL_SCALE = 0.05 -- 5% HP

-- Resets heal
---@param entity Entity
function mod:RedDamage(entity)
    if not self:GetChampion(entity, CHAMPION) then return end
    if not entity:GetData().co_champion_red then return end

    entity:GetData().co_champion_red.DamageDelay = 0
    entity:GetData().co_champion_red.HealDelay = 0
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.RedDamage)

-- Resets heal
---@param npc EntityNPC
function mod:RedHeal(npc)
    if not self:GetChampion(npc, CHAMPION) then return end
    if npc.HitPoints >= npc.MaxHitPoints then return end

    local data = npc:GetData().co_champion_red
    if not data then return end

    -- Heal limit
    if data.HealAmount >= npc.MaxHitPoints then return end

    -- Damage delay
    if data.DamageDelay < DAMAGE_DELAY then
        npc:GetData().co_champion_red.DamageDelay = npc:GetData().co_champion_red.DamageDelay + 1
        return
    end

    -- Heart particles
    if npc.FrameCount % 5 == 0 then
        local pos = Vector(npc.Position.X - 10 + 20 * math.random(), npc.Position.Y)
        local velocity = Vector(-1 + 2 * math.random(), -3)
        self:SpawnParticle("../scripts/champions/red/particle.png", velocity, pos, Vector(0, -15))
    end

    -- Heal delay
    if data.HealDelay < HEAL_DELAY then
        npc:GetData().co_champion_red.HealDelay = npc:GetData().co_champion_red.HealDelay + 1
        return
    end

    -- Reset
    npc:GetData().co_champion_red.HealDelay = 0

    -- Sound
    npc:PlaySound(SoundEffect.SOUND_BOSS2_BUBBLES, 1, 2, false, 2)

    -- Heal
    local heal = npc.MaxHitPoints * HEAL_SCALE
    npc:GetData().co_champion_red.HealAmount = npc:GetData().co_champion_red.HealAmount + heal
    npc.HitPoints = math.min(npc.HitPoints + heal, npc.MaxHitPoints)
    npc:SetColor(Color(1, 1, 1, 1, 0.5, 0.5, 0), 20, 0, true, false)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.RedHeal)