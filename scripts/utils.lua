--[[ Utils ]]--
local game = Game()

local CHAMPION_PATH = "../scripts/champions/"

-- Loggin system
---@param msg string
function ChampionOverhaul:Log(msg)
    ---@type string
    local prefix = "[" .. self.Name .. "] "

    Isaac.DebugString(prefix .. msg)
    print(prefix .. msg)
end

-- Register new champions
---@param data ChampionConfig
function ChampionOverhaul:Register(data)
    ChampionOverhaul.CHAMPION_COUNT = ChampionOverhaul.CHAMPION_COUNT + 1

    local id = self.CHAMPION_SUBTYPE + self.CHAMPION_COUNT - 1

    self.ChampionData[id] = {
        name = data.name,
        color = data.color or Color(1,1,1,1),
        colorVar = data.colorVar,
        colorType = data.colorType or 0,
        colorIntensity = data.colorIntensity ~= false,
        weight = data.weight or 1.0,
        drop = data.drop or "",
        hpScale = data.hpScale or 2,
        sizeScale = data.sizeScale,
        damage = data.damage or 2,
        entityFlags = data.entityFlags,
        projectileFlags = data.projectileFlags,
        hasShadow = data.hasShadow ~= false,
        hasShader = data.hasShader ~= false,
        hasIcon = data.hasIcon,
        init = data.init
    }

    self.ChampionID[data.name] = id
end

--[[ Entity Champion ]]--

-- Detects valid champion
---@param entity Entity
---@return boolean
function ChampionOverhaul:IsChampion(entity)
    local npc = entity:ToNPC()
    if not npc then return false end

    return npc:IsChampion() and npc:GetChampionColorIdx() == 0 and npc.SubType >= self.CHAMPION_SUBTYPE
end

-- Set champion by ID
---@param entity Entity
---@param id integer
function ChampionOverhaul:SetChampion(entity, id)
    local npc = entity:ToNPC()
    if not npc then return end

    -- Get rid of entities attached to the original NPC
    for _, ref in ipairs(Isaac.GetRoomEntities()) do
        -- Remove parents
        if ref.Parent == npc then ref.Parent:Remove() end
        -- Remove spawners
        if ref.SpawnerEntity == npc then ref.SpawnerEntity:Remove() end
        -- Remove effects
        if ref.Type == EntityType.ENTITY_EFFECT then
            local length = ref.Position:Distance(npc.Position)
            if length < 1 then ref:Remove() end
        end
    end

    -- Updates to champion system
    npc:Morph(npc.Type, npc.Variant, id, 0)

    ---@type ChampionConfig
    local data = self.ChampionData[id]
    local sprite = npc:GetSprite()
    local name = data.name

    -- Shader apply
    if data.hasShader then
        sprite:SetCustomChampionShader(CHAMPION_PATH .. name .. "/" .. name)
    else
        -- Brings champion sprite back to original
        for i = 0, sprite:GetLayerCount() - 1 do
            ---@diagnostic disable-next-line
            local img = sprite:GetSpritesheet(i)
            if img then
                local path = img:GetName()
                local fileName = string.gsub(path, "_champion", "")
                sprite:ReplaceSpritesheet(i, fileName)
            end
        end
        sprite:LoadGraphics()
        -- Removes red shader
        sprite:SetCustomChampionShader(CHAMPION_PATH .. "default/default")
    end

    -- Icon apply
    if data.hasIcon and not npc:GetData().co_champion_icon_init then
        npc:GetData().co_champion_icon_init = true

        local icon = Sprite()
        local name = data.name
        icon:Load(CHAMPION_PATH .. name .. "/icon.anm2", true)
        icon:Play("Idle", true)

        npc:GetData().co_champion_icon = icon
    end

    -- HP fix
    npc.MaxHitPoints = math.floor(npc.MaxHitPoints / 2.6) * data.hpScale
    npc.HitPoints = npc.MaxHitPoints

    -- Scale fix
    npc.Scale = 1
    sprite.Scale = Vector(1,1)

    -- Immunity fix
    npc:SetInvincible(false)

    -- Collision damage
    local stageScale = game:GetLevel():GetAbsoluteStage() < LevelStage.STAGE4_1 and 0 or math.min(data.damage, 2)
    npc.CollisionDamage = data.damage + stageScale

    --[[ Champion features ]]--

    -- Save ref by name
    npc:GetData().co_champion_name = data.name

    -- Splash color
    if data.color then
        npc.Color = data.color
        npc.SplatColor = data.color
    end

    -- Dynamic color
    if data.colorType then
        npc:GetData().co_champion_color = npc.Color
        npc:GetData().co_champion_colorType = data.colorType
        if data.colorVar then npc:GetData().co_champion_colorVar = data.colorVar end
    end

    -- Size scale
    if data.sizeScale then
        local gridColPts = EntityConfig.GetEntity(npc.Type, npc.Variant):GetGridCollisionPoints()

        npc:SetSize(npc.Size, Vector.One:__mul(data.sizeScale), math.floor(gridColPts * data.sizeScale))
        npc:GetSprite().Scale = Vector.One:__mul(data.sizeScale)
        npc.Mass = npc.Mass * data.sizeScale
        npc.Scale = data.sizeScale
    end

    -- Entityflags
    if data.entityFlags then npc:AddEntityFlags(data.entityFlags) end

    -- Removes shadow
    if not data.hasShadow then npc:SetShadowSize(0) end

    -- Changes champion features earlier
    if data.init and not npc:GetData().co_champion_init then
        npc:GetData().co_champion_init = true
        data.init(npc)
    end
end

-- Get champion by name
---@param entity Entity
---@param name string
---@return boolean
function ChampionOverhaul:GetChampion(entity, name)
    if not entity then return false end

    local npc = entity:ToNPC()
    if not (npc and npc:IsChampion()) then return false end

    return npc.SubType == self.ChampionID[name]
end

-- Gets champion spawner by entity
---@param entity Entity?
---@param name string?
---@return EntityNPC?
function ChampionOverhaul:GetChampionSpawner(entity, name)
    if not (entity and entity.SpawnerEntity) then return end

    local spawner = entity.SpawnerEntity:ToNPC()
    if not spawner then return end

    if not self:IsChampion(spawner) then return end

    -- Specific champion
    if name and not self:GetChampion(spawner, name) then return end

    return spawner
end

-- Source entity is related to champion by spawner or reference
---@param source EntityRef?
---@param name string?
---@return EntityNPC?
function ChampionOverhaul:GetChampionRef(source, name)
    if not (source and source.Entity) then return end

    local entity = source.Entity

    -- Direct reference
    local npc = entity:ToNPC()
    if npc and self:IsChampion(npc) then
        if name and not self:GetChampion(npc, name) then
            return
        end

        return npc
    end

    -- Spawner reference
    local spawner = entity.SpawnerEntity
    local spawnerNPC = spawner and spawner:ToNPC()

    if spawnerNPC and self:IsChampion(spawnerNPC) then
        if name and not self:GetChampion(spawnerNPC, name) then
            return
        end

        return spawnerNPC
    end
end

-- Used to pass champion reference to spawned entity
---@param entity Entity
---@param source Entity
function ChampionOverhaul:SetChampionRef(entity, source)
    entity:GetData().co_champion_name = source:GetData().co_champion_name
    entity.CollisionDamage = source.CollisionDamage
end

-- Is entity related to champion (persistent data)
---@param entity Entity
---@param name? string
---@return boolean
function ChampionOverhaul:HasChampionSource(entity, name)
    if not entity then return false end
    if name then return entity:GetData().co_champion_name == name end

    return entity:GetData().co_champion_name
end

-- Sets champion color to entity
---@param entity Entity
function ChampionOverhaul:SetChampionColor(entity)
    if not entity then return end

    -- Avoids homing and ghost projectiles
    local projectile = entity:ToProjectile()
    if projectile then
        if projectile:HasProjectileFlags(ProjectileFlags.SMART)
        or projectile:HasProjectileFlags(ProjectileFlags.GHOST) then return end
    end

    local source = entity

    if not source:ToNPC() then
        source = entity.SpawnerEntity
    end

    if not source then return end

    local npc = source:ToNPC()
    if not npc then return end

    local color
    local intensity

    if not npc:IsBoss() then
        -- Entity Champion
        local champion = self.ChampionData[npc.SubType]
        if champion then
            color = champion.color
            entity:GetData().co_champion_colorVar = champion.colorVar
            entity:GetData().co_champion_colorType = champion.colorType
            intensity = champion.colorIntensity
        end
    else
        -- Boss Champion
        local xmlData = XMLData.GetBossColorByTypeVarSub(npc.Type, npc.Variant, npc.SubType)

        if xmlData then
            -- Try suffix first
            if xmlData.suffix then
                local suffix = xmlData.suffix:match("_([^_]+)$")
                if suffix and self.BOSS_COLOR[suffix] then
                    color = self.BOSS_COLOR[suffix]
                    intensity = true
                end
            end

            -- Try ANM2 filename
            if not color and xmlData.anm2path then
                local suffix = xmlData.anm2path:match("_([^_]+)%.anm2$")
                if suffix and self.BOSS_COLOR[suffix] then
                    color = self.BOSS_COLOR[suffix]
                    intensity = true
                end
            end
        end
    end

    if not color then return end

    -- Intensity
    local power = 4
    if entity:ToLaser() then
        local R, G, B, A = color.R * power, color.G * power, color.B * power, color.A
        color = Color(1,1,1,1)
        color:SetColorize(R, G, B, A)
    elseif intensity then
        color:SetColorize(color.R * power, color.G * power, color.B * power, color.A)
        color.RO, color.GO, color.BO = 0, 0, 0
    end

    entity:GetData().co_champion_color = color
    entity:GetSprite().Color = color
end

-- Get champion color
---@param entity Entity
---@return Color
function ChampionOverhaul:GetChampionColor(entity)
    return entity:GetData().co_champion_color
end

-- Get champion color variation
---@param entity Entity
---@return Color[]?
function ChampionOverhaul:GetChampionColorVar(entity)
    return entity:GetData().co_champion_colorVar
end

-- Get champion color modifier
---@param entity Entity
---@return ChampionColorModifier
function ChampionOverhaul:GetChampionColorModifier(entity)
    return entity:GetData().co_champion_colorType
end

-- Inheritance color modifier
---@param entity Entity
---@return Color?
function ChampionOverhaul:SetColorModifier(entity)
    local color = self:GetChampionColor(entity)
    local modifier = self:GetChampionColorModifier(entity) or 0

    -- Avoids homing and ghost projectiles
    local projectile = entity:ToProjectile()
    if projectile then
        if projectile:HasProjectileFlags(ProjectileFlags.SMART)
        or projectile:HasProjectileFlags(ProjectileFlags.GHOST) then return end
    end

    -- Default
    if modifier == 0 then
        entity:GetSprite().Color = color

    -- Camouflage
    elseif modifier == 1 then
        local spawner = entity.SpawnerEntity
        if not spawner then return end
        entity:GetSprite().Color = spawner:GetSprite().Color

    -- Pulsing
    elseif modifier == 2 then
        local init = entity:HasEntityFlags(EntityFlag.FLAG_APPEAR) and 33 or 0
        local frame = entity.FrameCount - init
        local period = 45

        local t = (1 - math.cos(2 * math.pi * frame / period)) * 0.5;

        entity:GetSprite().Color = Color.Lerp(Color(1,1,1,1), color, t)
    -- Transition
    elseif modifier == 3 then
        local colors = self:GetChampionColorVar(entity)
        if not colors then return end

        local init = entity:HasEntityFlags(EntityFlag.FLAG_APPEAR) and 33 or 0
        local frame = entity.FrameCount - init
        local period = 90
        local count = #colors

        -- Random starting color
        local offset = entity.InitSeed % count

        -- Progress between color sequency
        local progress = ((frame % period) / period * count + offset) % count

        -- Current color
        local index = math.floor(progress) + 1

        -- Next color
        local nextIndex = index % count + 1

        -- Progress between colors
        local t = progress - math.floor(progress)

        -- Smooth transition
        t = (1 - math.cos(math.pi * t)) * 0.5

        -- Change color
        local newColor = Color.Lerp(colors[index], colors[nextIndex], t)
        if not entity:ToLaser() then -- Any entity
            entity:GetSprite().Color = newColor
        else -- Laser
            local power = 4
            local R, G, B, A = newColor.R * power, newColor.G * power, newColor.B * power, newColor.A
            local laserColor = Color(1,1,1,1)
            laserColor:SetColorize(R, G, B, A)
            entity:GetSprite().Color = laserColor
        end
    end
end

-- Champion should drop anything
---@param npc EntityNPC
function ChampionOverhaul:CanDrop(npc)
    if game.Difficulty == Difficulty.DIFFICULTY_NORMAL then return true end
    if game.Difficulty == Difficulty.DIFFICULTY_GREEDIER then return false end
    if game.Challenge == Challenge.CHALLENGE_ULTRA_HARD then return false end

    -- 33% Chance
    local rng = npc.InitSeed % 3
    if rng > 0 then return false end

    return true
end

-- Tries to kill entity
---@param entity Entity
function ChampionOverhaul:SetDeath(entity)
    local attempts = 5

    Isaac.CreateTimer(function()
        entity:Kill()
        if not entity:Exists() then return end
    end, 1, attempts, false)
end

-- Is stationary entity
---@param entity Entity
function ChampionOverhaul:IsStationary(entity)
    for _, type_ in ipairs(self.STATIONARY_ENTITIES) do
        if type_ == entity.Type then return true end
    end
    return false
end

-- Is critter entity effect
---@param effect EntityEffect
function ChampionOverhaul:IsCritter(effect)
    for _, variant in ipairs(self.CRITTERS) do
        if variant == effect.Variant then return true end
    end
    return false
end

-- Champion particle
---@param spritePath string
---@param velocity Vector
---@param position Vector
---@param offset? Vector
---@param scale? Vector
---@param rotation? number
function ChampionOverhaul:SpawnParticle(spritePath, velocity, position, offset, scale, rotation)
    local particle = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.EFFECT_NULL, 0, position, velocity, nil)
    particle:GetData().co_champion_particle = true

    local sprite = particle:GetSprite()
    sprite:Load("gfx/champion_particle.anm2", true)
    sprite:Play("Idle", true)
    sprite:ReplaceSpritesheet(0, spritePath, true)

    particle.SpriteOffset = offset or Vector(0,0)
    particle.SpriteScale = scale or Vector(1,1)
    particle.SpriteRotation = rotation or 0
end

-- Beam effect
---@param origin Vector
---@param target Vector
---@param color? Color
---@param canGrow? boolean
function ChampionOverhaul:BeamEffect(origin, target, color, canGrow)
    local distance = origin:Distance(target)
    local direction = target - origin
    if distance > 0 then direction = direction:Normalized() end

    local perpendicular = Vector(-direction.Y, direction.X)

    -- Number of segments
    local spacing = 8
    local segments = math.ceil(distance / spacing)

    for i = 0, segments do
        local t = i / segments

        -- Position along the line
        local pos = origin + direction * (distance * t)

        -- Small lateral variation
        local offset = perpendicular * math.random(-3, 3)

        pos = pos + offset

        local blood = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HAEMO_TRAIL, 0, pos, Vector.Zero, nil)

        local sprite = blood:GetSprite()
        sprite:ReplaceSpritesheet(0, "gfx/effects/champ_beam.png", true)
        sprite.Color = color or Color(1,1,1,1)

        -- Make each segment progressively larger
        if canGrow then
            local scale = 0.2 + t * 0.4
            blood.SpriteScale = Vector(scale, scale)
        else
            blood.SpriteScale = Vector(0.25, 0.25)
        end

        -- Point toward target
        blood.SpriteRotation = direction:GetAngleDegrees()

        -- Small vertical offset
        blood.SpriteOffset = Vector(0, -8)
    end
end

--[[ Boss Champion ]]--

-- Entity is a boss champion
---@param entity Entity
---@return boolean
function ChampionOverhaul:IsBossChampion(entity)
    if not (entity and entity:ToNPC()) then return false end

    if not (entity:IsBoss() and entity.SubType > 0) then return false end

    return true
end

-- Entity is related to boss champion by spawner
---@param entity Entity
---@return EntityNPC?
function ChampionOverhaul:GetBossChampionSpawner(entity)
    if not (entity and entity.SpawnerEntity) then return end

    local spawner = entity.SpawnerEntity:ToNPC()
    if not spawner then return end

    if not self:IsBossChampion(spawner) then return end

    return spawner
end

-- Source entity is related to boss champion by spawner or reference
---@param source EntityRef
---@return EntityNPC?
function ChampionOverhaul:GetBossChampionRef(source)
    if not (source and source.Entity) then return end

    local entity = source.Entity

    -- Direct reference
    local npc = entity:ToNPC()
    if npc and self:IsBossChampion(npc) then
        return npc
    end

    local spawner = entity.SpawnerEntity
    local spawnerNPC = spawner and spawner:ToNPC()

    if spawnerNPC and self:IsBossChampion(spawnerNPC) then
        return spawnerNPC
    end
end

-- Is entity related to boss champion (persistent data)
---@param entity Entity
---@return boolean
function ChampionOverhaul:HasBossChampionSource(entity)
    return entity:GetData().co_champion_boss
end