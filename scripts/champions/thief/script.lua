--[[ Thief ]]--
local mod = ChampionOverhaul

local CHAMPION = "thief"

-- Register
ChampionOverhaul:Register({
    name = CHAMPION,
    colorIntensity = false,
    weight = 0.1,
    drop = "5.69.1", -- Black sack
    damage = 1,
    hasShader = false,
    hasIcon = true
})

local QUALITY_WEIGHT = {
    [0] = 1,
    [1] = 2,
    [2] = 3,
    [3] = 5,
    [4] = 8
}

---@param player EntityPlayer
---@return integer?
local function GetRandomStealableItem(player)
    local itemConfig = Isaac.GetItemConfig()

    local candidates = {}
    local totalWeight = 0

    for itemID = 1, CollectibleType.NUM_COLLECTIBLES - 1 do
        local config = itemConfig:GetCollectible(itemID)

        -- Must have metadata
        if not (config and player:GetCollectibleNum(itemID) > 0) then goto continue end

        -- Avoids hidden item
        if config.Hidden then goto continue end

        local quality = config.Quality
        local weight = QUALITY_WEIGHT[quality] or 1

        totalWeight = totalWeight + weight

        candidates[#candidates + 1] = {
            id = itemID,
            weight = weight
        }

        ::continue::
    end

    if totalWeight <= 0 then return end

    local roll = math.random() * totalWeight

    for _, candidate in ipairs(candidates) do
        roll = roll - candidate.weight

        if roll <= 0 then
            return candidate.id
        end
    end

    return candidates[#candidates].id
end

---@param position Vector
---@param itemID CollectibleType
function mod:ThiefItemSprite(position, itemID)
    local config = Isaac.GetItemConfig():GetCollectible(itemID)
    if not config then return end

    local effect = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.LADDER,
        0,
        position + Vector(0, -20),
        Vector(0, -1.2),
        nil
    ):ToEffect()

    if not effect then return end

    -- Override the sprite with the item icon
    local sprite = effect:GetSprite()
    sprite:Load("gfx/005.100_collectible.anm2", true)
    sprite:ReplaceSpritesheet(1, config.GfxFileName)
    sprite:LoadGraphics()
    sprite:Play("Idle", true)

    -- Tweaks
    effect.Color = Color(0.25, 0, 0, 1)
    effect.DepthOffset = 100
    effect.Timeout = 20

    -- Store data
    effect:GetData().IsThiefItemSprite = true
end

---@param effect EntityEffect
function mod:ThiefEffectUpdate(effect)
    if not effect:GetData().IsThiefItemSprite then return end

    -- fade out
    local fadeStart = 10
    if effect.Timeout <= fadeStart then
        local progress = 1 - (effect.Timeout / fadeStart)
        effect.Color = Color(0.25, 0, 0, 1 - progress)
    end

    -- Safety removal
    if effect.Timeout <= 0 then effect:Remove() end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.ThiefEffectUpdate, EffectVariant.LADDER)

---@param entity Entity
---@param source EntityRef
function mod:ThiefSteal(entity, _, _, source)
    local ref = self:GetChampionRef(source, CHAMPION)
    if not ref then return end

    local player = entity:ToPlayer()
    if not player then return end

    -- Get itemID
    local itemID = GetRandomStealableItem(player)
    if not itemID then return end

    -- Remove item
    player:RemoveCollectible(itemID)

    -- Player animation
    player:AnimateSad()

    -- SoundEffect
    ref:ToNPC():PlaySound(SoundEffect.SOUND_THE_FORSAKEN_LAUGH, 1, 2, false, 0.5)

    -- BeamEffect
    local color = Color(0.5, 0.5, 0.5, 1)
    self:BeamEffect(player.Position, ref.Position, color, true)

    -- Stealed item sprite
    self:ThiefItemSprite(entity.Position, itemID)

    -- Champion disappears
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, ref.Position, Vector.Zero, nil)
    ref:Remove()
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.ThiefSteal, EntityType.ENTITY_PLAYER)