--[[ Constants ]]--

ChampionOverhaul.CHAMPION_SUBTYPE = 100
ChampionOverhaul.CHAMPION_COUNT = 0

-- Main config related to champions
---@class ChampionConfig
---@field name? string
---@field color? Color
---@field colorVar? Color[]
---@field colorType? ChampionColorModifier
---@field colorIntensity? boolean
---@field weight? integer
---@field drop? string
---@field hpScale? number
---@field sizeScale? number
---@field damage? integer
---@field entityFlags? integer | EntityFlag
---@field projectileFlags? integer | ProjectileFlags
---@field hasShadow? boolean
---@field hasShader? boolean
---@field hasIcon? boolean
---@field init? fun(npc: EntityNPC)

---@type ChampionConfig
ChampionOverhaul.ChampionData = {}

---@type table<string, integer>
ChampionOverhaul.ChampionID = {}

-- Color modifiers
---@alias ChampionColorModifier
---| 0 # Default
---| 1 # Camouflage
---| 2 # Pulsing
---| 3 # Transition

---@type table<string, ChampionColorModifier>
ChampionOverhaul.COLOR_MODIFIER = {
    DEFAULT = 0,
    CAMOUFLAGE = 1,
    PULSING = 2,
    TRANSITION = 3
}

-- Boss champion colors
---@type table<string, Color>
ChampionOverhaul.BOSS_COLOR = {
    green = Color(0.25, 0.75, 0.25),
    blue = Color(0.45, 0.45, 1),
    black = Color(0.35, 0.35, 0.35),
    yellow = Color(0.75, 0.75, 0.0),
    red = Color(1, 0.25, 0.25),
    grey = Color(0.5, 0.5, 0.5),
    orange = Color(-0.8, -0.4, 0),
    pink = Color(1, 0.3, 0.7),
    cyan = Color(0, 0.65, 0.65),
    brown = Color(0.7, 0.4, 0.1)
}

-- Critters
ChampionOverhaul.CRITTERS = {
    EffectVariant.TINY_BUG,
    EffectVariant.TINY_FLY,
    EffectVariant.WORM,
    EffectVariant.BEETLE,
    EffectVariant.WISP,
    EffectVariant.WALL_BUG,
    EffectVariant.BUTTERFLY,
    EffectVariant.TADPOLE,
    EffectVariant.LIL_GHOST
}

-- List of entities unable to move cardinally by default
ChampionOverhaul.STATIONARY_ENTITIES = {
    EntityType.ENTITY_BOIL,
    EntityType.ENTITY_LUMP,
    EntityType.ENTITY_FRED,
    EntityType.ENTITY_EYE,
    EntityType.ENTITY_COD_WORM,
    EntityType.ENTITY_HOMUNCULUS,
    EntityType.ENTITY_NERVE_ENDING,
    EntityType.ENTITY_WALL_CREEP,
    EntityType.ENTITY_RAGE_CREEP,
    EntityType.ENTITY_BLIND_CREEP,
    EntityType.ENTITY_ROUND_WORM,
    EntityType.ENTITY_ROUNDY,
    EntityType.ENTITY_BEGOTTEN,
    EntityType.ENTITY_NIGHT_CRAWLER,
    EntityType.ENTITY_ROUNDY,
    EntityType.ENTITY_ULCER,
    EntityType.ENTITY_HUSH_BOIL,
    EntityType.ENTITY_THE_THING,
    EntityType.ENTITY_PORTAL,
    EntityType.ENTITY_TARBOY,
    EntityType.ENTITY_MUSHROOM,
    EntityType.ENTITY_GUSH,
    EntityType.ENTITY_MR_MINE,
    EntityType.ENTITY_BISHOP,
    EntityType.ENTITY_FIRE_WORM,
    EntityType.ENTITY_MOLE,
    EntityType.ENTITY_GASBAG,
    EntityType.ENTITY_PUSTULE,
}

-- Room scale used to balance spacement
ChampionOverhaul.ROOM_GRIDSCALE = {
    [RoomShape.ROOMSHAPE_1x1] = 10,
    [RoomShape.ROOMSHAPE_IH]  = 3,
    [RoomShape.ROOMSHAPE_IV]  = 3,
    [RoomShape.ROOMSHAPE_1x2] = 10,
    [RoomShape.ROOMSHAPE_IIV] = 5,
    [RoomShape.ROOMSHAPE_2x1] = 10,
    [RoomShape.ROOMSHAPE_IIH] = 5,
    [RoomShape.ROOMSHAPE_2x2] = 20,
    [RoomShape.ROOMSHAPE_LTL] = 15,
    [RoomShape.ROOMSHAPE_LTR] = 15,
    [RoomShape.ROOMSHAPE_LBL] = 15,
    [RoomShape.ROOMSHAPE_LBR] = 15,
}