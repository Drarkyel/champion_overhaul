--[[ Beige ]]--
local mod = ChampionOverhaul

local CHAMPION = "beige"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.76, 0.66, 0.5),
    weight = 1.0,
    drop = "5.69.0" -- Grab sack
})

local MIN_COOLDOWN = 10
local MAX_COOLDOWN = 60

-- Damage countdown
---@param entity Entity
---@param amount number
---@param flags DamageFlag
function mod:BeigeCountdown(entity, amount, flags)
    if not self:GetChampion(entity, CHAMPION) then return end

    -- Ignores poison/burn
    if flags == DamageFlag.DAMAGE_POISON_BURN then return end

    -- Invulnerable
    if entity:GetData().co_champion_beige then return false end

    -- Detects death
    if entity.HitPoints <= amount then return end

    -- 50% Chance to trigger cooldown
    local chance = math.random(2)
    if chance == 1 then return end

    local damageDelay = math.min(MIN_COOLDOWN + (amount - 2) * 10, MAX_COOLDOWN)
    if damageDelay < MIN_COOLDOWN then return end

    entity:ToNPC():PlaySound(SoundEffect.SOUND_HOLY_MANTLE, 0.5, 2, false, 3)

    entity:GetData().co_champion_beige = {Delay = damageDelay, Timer = 0}
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.BeigeCountdown)

-- Damage delay
---@param npc EntityNPC
function mod:BeigeDelay(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    local data = npc:GetData().co_champion_beige
    if not data then return end

    npc:GetData().co_champion_beige.Timer = npc:GetData().co_champion_beige.Timer + 1

    -- Flickering
    if data.Timer % 2 == 0 then
        npc:GetSprite().Color = Color(1, 1, 1, 0.25)
    else
        npc:GetSprite().Color = Color(1, 1, 1, 1)
    end

    if data.Timer < data.Delay then return end

    -- Basic color
    npc:GetSprite().Color = Color(1, 1, 1, 1)

    -- Reset
    npc:GetData().co_champion_beige = nil
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.BeigeDelay)