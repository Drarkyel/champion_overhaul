--[[ Ivory ]]--
local mod = ChampionOverhaul
local game = Game()
local sound = SFXManager()

local CHAMPION = "ivory"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    color = Color(1, 1, 0.85, 1),
    weight = 0.1,
    drop = "5.301.0" -- Special card
})

-- Beam Constants
local TARGET_DELAY = 5
local TARGET_DURATION = 15

-- Spawn beams upon death
---@param npc EntityNPC
function mod:IvoryDeath(npc)
	if not self:GetChampion(npc, CHAMPION) then return end

    npc:PlaySound(SoundEffect.SOUND_ANGEL_BEAM, 1, 2, false, 0.75)
	Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ENEMY_GHOST, 2, npc.Position + Vector(0, -20), Vector.Zero, npc)

    Isaac.CreateTimer(function()
        local room = game:GetRoom()
        local pos = room:GetRandomPosition(1)

        -- Align
        pos = room:FindFreeTilePosition(pos, 120)
       	pos = room:GetGridPosition(room:GetGridIndex(pos))

        sound:Play(SoundEffect.SOUND_BLACK_POOF, 0.5, 2, false, 1.5)

        local target = Isaac.Spawn(EntityType.ENTITY_EFFECT, self.IVORY_MARK, 0, pos, Vector.Zero, nil):ToEffect()
        ---@cast target EntityEffect
        target:GetData().co_champion_ivory_markDMG = npc.CollisionDamage
        target:GetSprite():Load("../scripts/champions/ivory/beam_mark.anm2", true)
        target:GetSprite():Play("Appear", true)
		target.Timeout = TARGET_DURATION
        target.DepthOffset = -500

    end, TARGET_DELAY, TARGET_DURATION, false)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.IvoryDeath)

-- Beam mark
---@param effect EntityEffect
function mod:IvoryMark(effect)
    -- Close doors
	for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
		local door = game:GetRoom():GetDoor(i)
		if door and door:IsOpen() then door:Close() end
	end

	-- Blink
	if effect:GetSprite():IsFinished("Appear") then effect:GetSprite():Play("Blink") end

	-- Spawn beams
	if effect.Timeout <= 0 then
		local beam = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 0, effect.Position, Vector.Zero, nil)
        beam.CollisionDamage = effect:GetData().co_champion_ivory_markDMG
        effect:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.IvoryMark, mod.IVORY_MARK)