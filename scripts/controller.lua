--[[ Controller ]]--
local mod = ChampionOverhaul

-- Champion color update
function mod:ChampionColor(npc)
    if not self:GetChampionColorModifier(npc) then return end
    if self:GetChampionColorModifier(npc) == 0 then return end

    -- Set color
    self:SetColorModifier(npc)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ChampionColor)

-- Champion icon
---@param npc EntityNPC
function mod:ChampionIcon(npc)
    ---@type Sprite
    local icon = npc:GetData().co_champion_icon

    if not icon then return end

    local screenPos = Isaac.WorldToScreen(npc.Position)
    local offset = Vector(0, -npc.Size)

    icon:Update()
    icon:Render(screenPos + offset, Vector.Zero, Vector.Zero)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.ChampionIcon)

-- Champion projectile color
---@param effect EntityEffect
function mod:ChampionEffectColor(effect)
    if not self:GetChampionColor(effect) then return end

    self:SetColorModifier(effect)
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.ChampionEffectColor)

-- Champion projectile color
---@param projectile EntityProjectile
function mod:ChampionProjectileColor(projectile)
    if not self:GetChampionColor(projectile) then return end

    self:SetColorModifier(projectile)
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.ChampionProjectileColor)

-- Champion laser color
---@param laser EntityLaser
function mod:ChampionLaserColor(laser)
    if not self:GetChampionColor(laser) then return end

    self:SetColorModifier(laser)
end
mod:AddCallback(ModCallbacks.MC_PRE_LASER_UPDATE, mod.ChampionLaserColor)

-- Champion damage
---@param player EntityPlayer
---@param flags DamageFlag
---@param source EntityRef
---@param countdown integer
---@return boolean?
function mod:ChampionDamage(player, _, flags, source, countdown)
    local src = source.Entity
    if not src then return end

    if not (self:HasChampionSource(src) or self:HasBossChampionSource(src)) then return end

    if flags & DamageFlag.DAMAGE_CLONES ~= 0 then return end

    local amount = src:GetData().co_champion_damage or src.CollisionDamage
    player:TakeDamage(amount, flags | DamageFlag.DAMAGE_CLONES, EntityRef(src), countdown)

    return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.ChampionDamage, EntityType.ENTITY_PLAYER)

--[[ Attack update ]]--

-- Champion color effect
---@param effect EntityEffect
function mod:ChampionEffect(effect)
    local enemyChampion = self:GetChampionSpawner(effect)
    local bossChampion = self:GetBossChampionSpawner(effect)

    if not (enemyChampion or bossChampion) then return end

    if effect.CollisionDamage > 0 then
        if enemyChampion then
            effect:GetData().co_champion_name = enemyChampion:GetData().co_champion_name
            effect:GetData().co_champion_damage = enemyChampion.CollisionDamage
        elseif bossChampion then
            effect:GetData().co_champion_boss = true
            effect:GetData().co_champion_damage = bossChampion.CollisionDamage
        end
    end

    local invalid = effect.IsFollowing or self:IsCritter(effect)
    if invalid then return end

    self:SetChampionColor(effect)
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.ChampionEffect)

-- Champion projectile
---@param projectile EntityProjectile
function mod:ChampionProjectile(projectile)
    local enemyChampion = self:GetChampionSpawner(projectile)
    local bossChampion = self:GetBossChampionSpawner(projectile)

    if not (enemyChampion or bossChampion) then return end

    if enemyChampion then
        projectile:GetData().co_champion_name = enemyChampion:GetData().co_champion_name
        projectile:GetData().co_champion_damage = enemyChampion.CollisionDamage
        projectile.Size = projectile.Size * 0.85

        -- Bullet flags
        local flags = self.ChampionData[enemyChampion.SubType].projectileFlags
        if flags then projectile:AddProjectileFlags(flags) end
    elseif bossChampion then
        projectile:GetData().co_champion_boss = true
        projectile:GetData().co_champion_damage = bossChampion.CollisionDamage
    end

    -- Bullet color
    self:SetChampionColor(projectile)
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, mod.ChampionProjectile)

-- Champion laser
---@param laser EntityLaser
function mod:ChampionLaser(laser)
    local enemyChampion = self:GetChampionSpawner(laser)
    local bossChampion = self:GetBossChampionSpawner(laser)

    if not (enemyChampion or bossChampion) then return end

    if enemyChampion then
        laser:GetData().co_champion_name = enemyChampion:GetData().co_champion_name
        laser:GetData().co_champion_damage = enemyChampion.CollisionDamage
    elseif bossChampion then
        laser:GetData().co_champion_boss = true
        laser:GetData().co_champion_damage = bossChampion.CollisionDamage
    end

    -- Laser color
    self:SetChampionColor(laser)
end
mod:AddCallback(ModCallbacks.MC_POST_LASER_INIT, mod.ChampionLaser)

-- Particles
---@param effect EntityEffect
function mod:ChampionParticle(effect)
    if not effect:GetData().co_champion_particle then return end

    if not effect:GetSprite():IsFinished("Idle") then return end
    effect:Remove()
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.ChampionParticle, EffectVariant.EFFECT_NULL)