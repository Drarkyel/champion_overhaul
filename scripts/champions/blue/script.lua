--[[ Dark Blue ]]--
local mod = ChampionOverhaul
local game = Game()

local CHAMPION = "blue"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(0.3, 0.3, 1, 1),
    weight = 1.0,
    drop = "3.43.0.2.4" -- Blue flies (2-4)
})

local DAMAGE_DELAY = 15

-- Damage delay
---@param npc EntityNPC
function mod:BlueDelay(npc)
    if not self:GetChampion(npc, CHAMPION) then return end

    if not npc:GetData().co_dark_blue_delay then return end

    -- Counter
    npc:GetData().co_dark_blue_delay = npc:GetData().co_dark_blue_delay + 1
    if npc:GetData().co_dark_blue_delay < DAMAGE_DELAY then return end
    npc:GetData().co_dark_blue_delay = nil
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.BlueDelay)

-- Shoots projectile upon damage
---@param entity Entity
function mod:BlueTakeDamage(entity)
    if not self:GetChampion(entity, CHAMPION) then return end
    if entity:GetSprite():IsPlaying("Appear") then return end
    if entity:GetData().co_dark_blue_delay then return end

    entity:GetData().co_dark_blue_delay = 0

    local speed = 1.0 + math.random() / 5
    if game.Difficulty ~= Difficulty.DIFFICULTY_NORMAL then speed = speed + 0.2 end

    local velocity = EntityPickup.GetRandomPickupVelocity(entity.Position, nil, 0) * speed

    local params = ProjectileParams()
    params.Variant = 6

    entity:ToNPC():PlaySound(SoundEffect.SOUND_LITTLE_SPIT, 1, 2, false, 2)
    entity:ToNPC():FireProjectiles(entity.Position, velocity, 0, params)
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.BlueTakeDamage)
