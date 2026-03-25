---@diagnostic disable: duplicate-set-field

local gameevent_Listen = ( gameevent ~= nil and isfunction( gameevent.Listen ) ) and gameevent.Listen
local debug_getmetatable = debug.getmetatable or getmetatable
local hook_Add, hook_Remove = hook.Add, hook.Remove

local FindMetaTable = FindMetaTable
local setmetatable = setmetatable
local GetConVar = GetConVar

local timer_Simple = timer.Simple
local string_byte = string.byte

local game = game

---@class Entity
local ENTITY = FindMetaTable( "Entity" )
local ENTITY_IsValid = ENTITY.IsValid

---@class Player
local PLAYER = FindMetaTable( "Player" )
local PLAYER_IsBot = PLAYER.IsBot

---@class Weapon
local WEAPON = FindMetaTable( "Weapon" )

---@class NPC
local NPC = FindMetaTable( "NPC" )

---@class NextBot
local NEXTBOT = FindMetaTable( "NextBot" )

---@class ConVar
local CONVAR = FindMetaTable( "ConVar" )

---@class Vehicle
local VEHICLE = FindMetaTable( "Vehicle" )

-- by https://github.com/Astralcircle
do

    local return_true = function() return true end
    local return_false = function() return false end

    ENTITY.IsNextBot = return_false
    ENTITY.IsNPC = return_false
    ENTITY.IsPlayer = return_false
    ENTITY.IsVehicle = return_false
    ENTITY.IsWeapon = return_false

    NEXTBOT.IsNextBot = return_true
    NEXTBOT.IsNPC = return_false
    NEXTBOT.IsPlayer = return_false
    NEXTBOT.IsVehicle = return_false
    NEXTBOT.IsWeapon = return_false

    NPC.IsNextBot = return_false
    NPC.IsNPC = return_true
    NPC.IsPlayer = return_false
    NPC.IsVehicle = return_false
    NPC.IsWeapon = return_false

    PLAYER.IsNextBot = return_false
    PLAYER.IsNPC = return_false
    PLAYER.IsPlayer = return_true
    PLAYER.IsVehicle = return_false
    PLAYER.IsWeapon = return_false

    VEHICLE.IsNextBot = return_false
    VEHICLE.IsNPC = return_false
    VEHICLE.IsPlayer = return_false
    VEHICLE.IsVehicle = return_true
    VEHICLE.IsWeapon = return_false

    WEAPON.IsNextBot = return_false
    WEAPON.IsNPC = return_false
    WEAPON.IsPlayer = return_false
    WEAPON.IsVehicle = return_false
    WEAPON.IsWeapon = return_true

end

do

    ---@type table<table, boolean>
    local entity_metas = {
        [ NEXTBOT ] = true,
        [ ENTITY ] = true,
        [ PLAYER ] = true,
        [ WEAPON ] = true,
        [ NPC ] = true
    }

    ---@param value any
    ---@return boolean
    function _G.isentity( value )
        if not value then return false end

        local metatable = debug_getmetatable( value )
        if metatable == nil then return false end

        return entity_metas[ metatable ] or metatable.MetaID == 9
    end

end

do

    local gamemode_name = engine.ActiveGamemode()

    ---@return string
    function engine.ActiveGamemode()
        return gamemode_name
    end

end

do

    local is_singleplayer = game.SinglePlayer()

    ---@return boolean
    function game.SinglePlayer()
        return is_singleplayer
    end

end

do

    local is_dedicated = game.IsDedicated()

    ---@return boolean
    function game.IsDedicated()
        return is_dedicated
    end

    if is_dedicated then

        ---@return boolean
        function PLAYER:IsListenServerHost()
            return false
        end

    end

end

do

    -- Max players cache
    local maxplayers = game.MaxPlayers()

    ---@return number
    function game.MaxPlayers()
        return maxplayers
    end

    -- Faster shitty GetConVar functions ( thanks garry )
    local GetString = CONVAR.GetString
    local GetFloat = CONVAR.GetFloat

    function _G.GetConVarNumber( name )
        if name == "maxplayers" then
            return maxplayers
        end

        local convar = GetConVar( name )
        return convar and GetFloat( convar ) or 0
    end

    local maxplayers_string = tostring( maxplayers )

    function _G.GetConVarString( name )
        if name == "maxplayers" then
            return maxplayers_string
        end

        local convar = GetConVar( name )
        return convar and GetString( convar ) or ""
    end

end

if CLIENT then

    -- DirectX level caching
    do

        local render = _G.render
        local directx_level = render.GetDXLevel()

        -- https://wiki.facepunch.com/gmod/render.GetDXLevel
        function render.GetDXLevel()
            return directx_level
        end

        -- https://wiki.facepunch.com/gmod/render.SupportsPixelShaders_1_4
        do

            local hdr_supported = directx_level >= 80

            function render.SupportsHDR()
                return hdr_supported
            end

        end

        -- https://wiki.facepunch.com/gmod/render.SupportsPixelShaders_1_4
        do
            local ps_1_4_supported = render.SupportsPixelShaders_1_4()

            function render.SupportsPixelShaders_1_4()
                return ps_1_4_supported
            end

        end

        -- https://wiki.facepunch.com/gmod/render.SupportsPixelShaders_2_0
        do

            local ps_2_0_supported = render.SupportsPixelShaders_2_0()

            function render.SupportsPixelShaders_2_0()
                return ps_2_0_supported
            end

        end

        -- https://wiki.facepunch.com/gmod/render.SupportsVertexShaders_2_0
        do

            local vs_2_0_supported = render.SupportsVertexShaders_2_0()

            function render.SupportsVertexShaders_2_0()
                return vs_2_0_supported
            end

        end

        local render_SetMaterial = render.SetMaterial

        -- https://wiki.facepunch.com/gmod/render.SetColorMaterial
        do

            local color = Material( "color" )

            function render.SetColorMaterial()
                return render_SetMaterial( color )
            end

        end

        -- https://wiki.facepunch.com/gmod/render.SetColorMaterialIgnoreZ
        do

            local color_ignorez = Material( "color_ignorez" )

            function render.SetColorMaterialIgnoreZ()
                return render_SetMaterial( color_ignorez )
            end

        end

    end

    -- Faster cam functions
    do

        local cam = _G.cam
        local cam_Start = cam.Start

        do

            local view = { type = "2D" }

            function cam.Start2D()
                return cam_Start( view )
            end

        end

        do

            local view = { type = "3D" }

            function cam.Start3D( origin, angles, fov, x, y, w, h, znear, zfar )
                view.origin, view.angles, view.fov = origin, angles, fov

                if x ~= nil and y ~= nil and w ~= nil and h ~= nil then
                    view.x, view.y = x, y
                    view.w, view.h = w, h
                    view.aspect = w / h
                else
                    view.x, view.y = nil, nil
                    view.w, view.h = nil, nil
                    view.aspect = nil
                end

                if znear ~= nil and zfar ~= nil then
                    view.znear, view.zfar = znear, zfar
                else
                    view.znear, view.zfar = nil, nil
                end

                return cam_Start( view )
            end

        end

    end

    -- cl_drawhud chat fix
    do

        local cl_drawhud = GetConVar( "cl_drawhud" )
        if cl_drawhud ~= nil then
            ---@cast cl_drawhud ConVar

            local GetBool = cl_drawhud.GetBool
            local chat_Close = _G.chat.Close

            hook_Add( "StartChat", "glua.Patches - cl_drawhud chat fix", function()
                if GetBool( cl_drawhud ) then return end
                chat_Close()
                return true
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK_RETURN )

            _G.cvars.AddChangeCallback( "cl_drawhud", chat_Close, "glua.Patches - cl_drawhud chat fix" )
        end

    end

    -- OnConVarChanged for replicated cvars
    if gameevent_Listen ~= nil then

        local CONVAR_GetDefault = CONVAR.GetDefault
        gameevent_Listen( "server_cvar" )

        local old_values = {}

        hook_Add( "server_cvar", "glua.Patches - OnConVarChanged for replicated cvars", function( data )
            local name, new = data.cvarname, data.cvarvalue

            local old = old_values[ name ]
            if old == nil then
                local convar = GetConVar( name )
                if not convar then return end

                old = CONVAR_GetDefault( convar )
                old_values[ name ] = old
            else
                old_values[ name ] = new
            end

            _G.cvars.OnConVarChanged( name, old, new )
            ---@diagnostic disable-next-line: redundant-parameter
        end, PRE_HOOK )

    end

end

do

    local game_GetMap = game.GetMap

    local map_name = game_GetMap()

    if CLIENT then

        hook_Add( "Initialize", "glua.Patches - Map name caching", function()
            hook_Remove( "Initialize", "glua.Patches - Map name caching" )
            map_name = game_GetMap()
        end )

    end

    ---@return string
    function game.GetMap()
        if map_name == nil or string_byte( map_name, 1, 1 ) == nil then
            map_name = game_GetMap()
        end

        return map_name
    end

end

if CLIENT then

    local LocalPlayer = _G.LocalPlayer
    local NULL = _G.NULL

    local player_entity = nil

    rawset( _G, "LocalPlayer", function()
        if player_entity == nil then
            local entity = LocalPlayer()
            if entity ~= nil and ENTITY_IsValid( entity ) then
                rawset( _G, "LocalPlayer", function()
                    return entity
                end )

                player_entity = entity
                return entity
            end

            return NULL
        end

        return player_entity
    end )

end

do

    ---@type table<Entity, integer>
    local entity_to_index = {}

    do

        local ENTITY_EntIndex = ENTITY.EntIndex

        setmetatable( entity_to_index, {
            __index = function( self, entity )
                local index = 0

                if ENTITY_IsValid( entity ) then
                    index = ENTITY_EntIndex( entity ) or index
                end

                self[ entity ] = index
                return index
            end,
            __mode = "k"
        } )

    end

    function ENTITY:EntIndex()
        return entity_to_index[ self ]
    end

    ---@type table<Entity, string>
    local entity_to_class = {}

    do

        local ENTITY_GetClass = ENTITY.GetClass

        setmetatable( entity_to_class, {
            __index = function( self, entity )
                if ENTITY_IsValid( entity ) then
                    local class = ENTITY_GetClass( entity )
                    self[ entity ] = class
                    return class
                end

                return "NULL"
            end,
            __mode = "k"
        } )

    end

    function ENTITY:GetClass()
        return entity_to_class[ self ]
    end

    ---@type table<Player, integer>
    local player_to_uid = {}

    do

        local PLAYER_UserID = PLAYER.UserID

        setmetatable( player_to_uid, {
            __index = function( self, pl )
                if ENTITY_IsValid( pl ) then
                    local uid = PLAYER_UserID( pl )
                    self[ pl ] = uid
                    return uid
                end

                return -1
            end,
            __mode = "k"
        } )

    end

    function PLAYER:UserID()
        return player_to_uid[ self ]
    end


    if CLIENT then

        ---@type table<Player, boolean>
        local player_is_bot = {}

        setmetatable( player_is_bot, {
            __index = function( self, pl )
                local is_bot = PLAYER_IsBot( pl )
                self[ pl ] = is_bot
                return is_bot
            end,
            __mode = "k"
        } )

        function PLAYER:IsBot()
            return player_is_bot[ self ]
        end

    end

    ---@type table<Player, string>
    local player_to_steamid = {}

    do

        local PLAYER_SteamID = PLAYER.SteamID

        setmetatable( player_to_steamid, {
            __index = function( self, pl )
                local value

                if pl:IsBot() then
                    value = "STEAM_0:0:" .. player_to_uid[ pl ] -- fake steamid for bots
                else
                    value = PLAYER_SteamID( pl )
                end

                self[ pl ] = value
                return value
            end,
            __mode = "k"
        } )

    end

    function PLAYER:SteamID()
        return player_to_steamid[ self ]
    end

    ---@type table<Player, string>
    local player_to_steamid64 = {}

    do

        local PLAYER_SteamID64 = PLAYER.SteamID64

        setmetatable( player_to_steamid64, {
            __index = function( self, pl )
                local value

                if PLAYER_IsBot( pl ) then
                    value = "765" .. ( ( player_to_uid[ pl ] * 2 ) + 61197960265728 ) -- fake steamid for bots
                else
                    value = PLAYER_SteamID64( pl )
                end

                self[ pl ] = value
                return value
            end,
            __mode = "k"
        } )

    end

    function PLAYER:SteamID64()
        return player_to_steamid64[ self ]
    end

    do

        ---@type table<integer, Player>
        local accountid2player = {}

        local PLAYER_AccountID = PLAYER.AccountID

        setmetatable( accountid2player, {
            __index = function( _, key )
                for _, pl in player.Iterator() do
                    if PLAYER_AccountID( pl ) == key then
                        accountid2player[ key ] = pl
                        return pl
                    end
                end
            end,
            __mode = "v"
        } )

        function player.GetByAccountID( accountid )
            return accountid2player[ accountid ] or false
        end

    end

    ---@type table<Player, string>
    local player2nick = {}

    do

        local PLAYER_Nick = PLAYER.Nick

        local nicknames_metatable = {
            __index = function( _, pl )
                local nickname = PLAYER_Nick( pl )
                player2nick[ pl ] = nickname
                return nickname
            end,
            __mode = "k"
        }

        setmetatable( player2nick, nicknames_metatable )

        if CLIENT then

            timer.Create( "glua.Patches - Player name re-cache", 3, 0, function()
                player2nick = {}
                setmetatable( player2nick, nicknames_metatable )
            end )

        end

        local function get_name( pl )
            return player2nick[ pl ]
        end

        PLAYER.GetName = get_name
        PLAYER.Nick = get_name

    end

    local function invalidateInternalEntityCache( entity )
        _G.InvalidateInternalEntityCache( entity:IsPlayer() )
    end

    hook_Add( "OnEntityCreated", "glua.Patches - Entity & player cache", invalidateInternalEntityCache, PRE_HOOK )
    hook_Add( "EntityRemoved", "glua.Patches - Entity & player cache", invalidateInternalEntityCache, PRE_HOOK )

end

-- Faster traces
do

    local engine_TickCount = engine.TickCount
    local TraceLine = util.TraceLine

    local distance = 4096 * 8

    local trace = {}

    setmetatable( trace, {
        __mode = "v"
    } )

    function util.GetPlayerTrace( pl, dir )
        local start = pl:EyePos()

        return {
            start = start,
            endpos = start + ( ( dir or pl:GetAimVector() ) * distance ),
            filter = pl
        }
    end

    function util.QuickTrace( origin, dir, filter )
        trace.start = origin
        trace.endpos = origin + dir
        trace.filter = filter

        return TraceLine( trace )
    end

    function PLAYER:GetEyeTrace()
        if CLIENT then
            if self.m_iLastEyeTrace == engine_TickCount() then
                return self.m_tEyeTrace
            end

            self.m_iLastEyeTrace = engine_TickCount()
        end

        local start = self:EyePos()

        trace.start = start
        trace.endpos = start + ( self:GetAimVector() * distance )
        trace.filter = self

        local traceResult = TraceLine( trace )
        self.m_tEyeTrace = traceResult
        return traceResult
    end

    function PLAYER:GetEyeTraceNoCursor()
        if CLIENT then
            if self.m_iLastAimTrace == engine_TickCount() then
                return self.m_tAimTrace
            end

            self.m_iLastAimTrace = engine_TickCount()
        end

        local start = self:EyePos()

        trace.start = start
        trace.endpos = start + ( self:EyeAngles():Forward() * distance )
        trace.filter = self

        local traceResult = TraceLine( trace )
        self.m_tAimTrace = traceResult
        return traceResult
    end

end

-- No more fake footsteps
do

    local ENTITY_IsOnGround, ENTITY_GetMoveType = ENTITY.IsOnGround, ENTITY.GetMoveType
    local MOVETYPE_LADDER = _G.MOVETYPE_LADDER

    hook_Add( "PlayerFootstep", "glua.Patches - No more fake footsteps", function( pl )
        if not ENTITY_IsOnGround( pl ) and ENTITY_GetMoveType( pl ) ~= MOVETYPE_LADDER then return true end
        ---@diagnostic disable-next-line: redundant-parameter
    end, PRE_HOOK_RETURN )

end

-- Decals fix
if gameevent_Listen ~= nil then

    gameevent_Listen( "player_hurt" )
    local Player = _G.Player

    hook_Add( "player_hurt", "glua.Patches - Decals fix", function( data )
        if data.health > 0 then return end

        local pl = Player( data.userid )
        if pl ~= nil and ENTITY_IsValid( pl ) and pl:Alive() then
            timer_Simple( 0.25, function()
                if ENTITY_IsValid( pl ) then
                    pl:RemoveAllDecals()
                end
            end )
        end

        ---@diagnostic disable-next-line: redundant-parameter
    end, PRE_HOOK )

end

if SERVER then

    -- Level reload command
    _G.concommand.Add( "reloadlevel", function( pl )
        if ( pl and pl:IsValid() ) and not ( pl:IsSuperAdmin() or pl:IsListenServerHost() ) then
            pl:ChatPrint( "You don\'t have permission to use this command." )
            return
        end

        RunConsoleCommand( "changelevel", game.GetMap() )
    end, nil, "Reload the current server map and reconnect all players." )

    -- License check
    do

        local sv_lan = GetConVar( "sv_lan" )
        if sv_lan ~= nil then
            ---@cast sv_lan ConVar

            local GetBool = sv_lan.GetBool

            hook_Add( "PlayerInitialSpawn", "glua.Patches - License check", function( pl )
                if GetBool( sv_lan ) or PLAYER_IsBot( pl ) or pl:IsListenServerHost() or pl:IsFullyAuthenticated() then return end
                pl:Kick( "Your SteamID wasn\'t fully authenticated, try restart your Steam client." )
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

        end

    end

    -- info_ladder fix
    scripted_ents.Register( {
        Base = "base_point",
        Type = "point"
    }, "info_ladder" )

    local ENTITY_GetInternalVariable = ENTITY.GetInternalVariable

    -- func_areaportal fix
    do

        local ENTITY_GetName, ENTITY_SetSaveValue, ENTITY_Fire = ENTITY.GetName, ENTITY.SetSaveValue, ENTITY.Fire
        local ents_FindByClass = ents.FindByClass

        local classes = {
            func_door_rotating = true,
            prop_door_rotating = true,
            func_movelinear = true,
            func_door = true
        }

        local function start()
            hook_Add( "EntityRemoved", "glua.Patches - func_areaportal", function( entity )
                if classes[ entity:GetClass() ] == nil then return end

                local name = ENTITY_GetName( entity )
                if #name == 0 then return end

                local portals = ents_FindByClass( "func_areaportal" )
                for i = 1, #portals, 1 do
                    local portal = portals[ i ]
                    if ENTITY_GetInternalVariable( portal, "target" ) == name then
                        ENTITY_SetSaveValue( portal, "target", "" )
                        ENTITY_Fire( portal, "open" )
                    end
                end
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )
        end

        local function stop()
            hook_Remove( "EntityRemoved", "glua.Patches - func_areaportal" )
        end

        ---@diagnostic disable-next-line: redundant-parameter
        hook_Add( "PostCleanupMap", "glua.Patches - func_areaportal", start, PRE_HOOK )

        ---@diagnostic disable-next-line: redundant-parameter
        hook_Add( "PreCleanupMap", "glua.Patches - func_areaportal", stop, PRE_HOOK )

        ---@diagnostic disable-next-line: redundant-parameter
        hook_Add( "ShutDown", "glua.Patches - func_areaportal", stop, PRE_HOOK )

        start()

    end

    -- item_suitcharger & item_healthcharger physics
    do

        local SOLID_VPHYSICS = _G.SOLID_VPHYSICS

        hook_Add( "PlayerSpawnedSENT", "glua.Patches - item_suitcharger & item_healthcharger physics", function( _, entity )
            local className = entity:GetClass()
            if className == "item_suitcharger" or className == "item_healthcharger" then
                entity:PhysicsInit( SOLID_VPHYSICS )
                entity:PhysWake()
            end
            ---@diagnostic disable-next-line: redundant-parameter
        end, PRE_HOOK )

    end

    -- Fixes for prop_vehicle_prisoner_pod, worldspawn (and other not Valid but not NULL entities) damage taking (bullets only)
    -- Explosive damage only works if is located in front of prop_vehicle_prisoner_pod (wtf?)
    do

        local ENTITY_TakePhysicsDamage = ENTITY.TakePhysicsDamage

        hook_Add( "EntityTakeDamage", "glua.Patches - prop_vehicle_prisoner_pod damage fix", function( entity, damageInfo )
            ---@diagnostic disable-next-line: undefined-field
            if entity:GetClass() ~= "prop_vehicle_prisoner_pod" or entity.AcceptDamageForce then return end
            ENTITY_TakePhysicsDamage( entity, damageInfo )
            ---@diagnostic disable-next-line: redundant-parameter
        end, PRE_HOOK )

    end

end
