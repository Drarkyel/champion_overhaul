--[[ Dark Red ]]--
local mod = ChampionOverhaul
local sound = SFXManager()

local CHAMPION = "dark_red"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.5, 0, 0, 1),
    colorIntensity = false,
    weight = 0.5,
    hpScale = 1,
    drop = "5.10.5" -- Double red heart
})

local SHADER_PATH = "../scripts/champions/dark_red/"
local RESET_SCALE = 0.1 -- 10% reduced max HP
local MEAT_DURATION = 40

-- Regrow HP
function mod:DarkRedRegen(npc)
    if not self:GetChampion(npc, CHAMPION) then return end
    if not npc:GetData().co_champion_darkred_freeze then return end

    npc:PlaySound(SoundEffect.SOUND_MEAT_JUMPS, 1, 2, false, 0.25)

    -- Reset count
    npc:GetData().co_champion_darkred_reset = (npc:GetData().co_champion_darkred_reset or 0) + 1

    -- HP restored decreases per reset
    local hpRatio = math.max(0, 1 - (npc:GetData().co_champion_darkred_reset - 1) * RESET_SCALE)
    npc.HitPoints = npc.MaxHitPoints * hpRatio

    npc:GetSprite():SetCustomChampionShader(SHADER_PATH .. CHAMPION)
    npc:GetData().co_champion_darkred_freeze = nil
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.DarkRedRegen)

-- Meat damage
---@param entity Entity
---@param amount number
function mod:DarkRedMeat(entity, amount)
    if not self:GetChampion(entity, CHAMPION) then return end

    if not entity:GetData().co_champion_darkred_freeze then
        -- Start Meat
        if entity.HitPoints > amount then return end

        entity:ToNPC():PlaySound(SoundEffect.SOUND_MEAT_JUMPS, 1, 2, false, 0.25)

        -- Get meat HP
        entity:GetData().co_champion_darkred_hp = entity:GetData().co_champion_darkred_hp or entity.MaxHitPoints * 2
        entity.HitPoints = entity:GetData().co_champion_darkred_hp

        -- Update sprite
        entity:GetSprite():SetCustomChampionShader(SHADER_PATH .. "meat")
        entity:AddFreeze(EntityRef(entity), MEAT_DURATION)
        entity:GetData().co_champion_darkred_freeze = true

        return false
    elseif entity:GetData().co_champion_darkred_hp then
        -- Meat HP
        if entity.HitPoints > amount and entity:GetData().co_champion_darkred_hp ~= 0 then
            sound:Play(SoundEffect.SOUND_POISON_HURT, 1, 2, false, 1.5)
            entity:GetData().co_champion_darkred_hp = math.max(0, entity:GetData().co_champion_darkred_hp - amount)
        else
            self:SetDeath(entity)
            entity:ClearEntityFlags(EntityFlag.FLAG_FREEZE)

            return false
        end
    end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.DarkRedMeat)

-- Death effects
---@param npc EntityNPC
function mod:DarkRedDeath(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    sound:Stop(SoundEffect.SOUND_ROCK_CRUMBLE)
    npc:PlaySound(SoundEffect.SOUND_MEATY_DEATHS)

    local effect = Isaac.Spawn(1000, 97, 0, npc.Position, Vector.Zero, npc)
    effect:GetSprite().Scale = effect:GetSprite().Scale * 2
end

mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.DarkRedDeath)