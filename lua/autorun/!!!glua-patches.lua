local _G = _G

-- Already patched
if _G.__gluaPatches then return end

---@diagnostic disable-next-line: inject-field
_G.__gluaPatches = true

local addon_name = "gLua Patches v1.15.5"

local debug, string, math, table, engine, game, util = _G.debug, _G.string, _G.math, _G.table, _G.engine, _G.game, _G.util
local pairs, tonumber, setmetatable, FindMetaTable, rawget = _G.pairs, _G.tonumber, _G.setmetatable, _G.FindMetaTable, _G.rawget
local gameevent_Listen = ( gameevent ~= nil and isfunction( gameevent.Listen ) ) and gameevent.Listen
local math_min, math_max, math_random, math_floor = math.min, math.max, math.random, math.floor
local debug_getmetatable = debug.getmetatable
local engine_TickCount = engine.TickCount
local timer_Create = _G.timer.Create

local MENU = _G.MENU_DLL == true
local CLIENT = _G.CLIENT == true and not MENU
local SERVER = _G.SERVER == true and not MENU

-- ULib support ( I really don't like this )
if ( CLIENT or SERVER ) and _G.file.Exists( "ulib/shared/hook.lua", "LUA" ) then
    _G.include( "ulib/shared/hook.lua" )
end

--- Srlion's Hook Library ( https://github.com/Srlion/Hook-Library )
---@diagnostic disable-next-line: undefined-field
local PRE_HOOK = _G.PRE_HOOK or -2

--- Srlion's Hook Library ( https://github.com/Srlion/Hook-Library )
---@diagnostic disable-next-line: undefined-field
local PRE_HOOK_RETURN = _G.PRE_HOOK_RETURN or -1

local hook_Add, hook_Remove = _G.hook.Add, _G.hook.Remove

---@param tbl table
function table.Empty( tbl )
    for key in pairs( tbl ) do
        tbl[ key ] = nil
    end
end

---@param value number
---@param min number
---@param max number
---@return number
function math.Clamp( value, min, max )
    return math_min( math_max( value, min ), max )
end

---@param value number
---@param decimals number
---@return number
function math.Round( value, decimals )
    if decimals then
        local mult = 10 ^ decimals
        return math_floor( value * mult + 0.5 ) / mult
    else
        return math_floor( value + 0.5 )
    end
end

---@param tbl table
---@return table
function table.Shuffle( tbl )
    local length = #tbl
    for i = length, 1, -1 do
        local j = math_random( 1, length )
        tbl[ i ], tbl[ j ] = tbl[ j ], tbl[ i ]
    end

    return tbl
end

---@param tbl table
---@return any, any
function table.Random( tbl )
    local count = 0
    for _ in pairs( tbl ) do
        count = count + 1
    end

    local i = math_random( 1, count )

    for key, value in pairs( tbl ) do
        if i == 1 then
            return value, key
        else
            i = i - 1
        end
    end
end

do

    local bit_lshift = _G.bit.lshift

    ---@param number number
    ---@param shift number
    ---@return integer
    function bit.lshift( number, shift )
        return shift > 31 and 0x0 or bit_lshift( number, shift )
    end

end

do

    local bit_rshift = _G.bit.rshift

    ---@param number number
    ---@param shift number
    ---@return integer
    function bit.rshift( number, shift )
        return shift > 31 and 0x0 or bit_rshift( number, shift )
    end

end

local CurTime = _G.CurTime

-- coroutine.wait
do

    local coroutine = _G.coroutine
    local coroutine_yield = coroutine.yield

    ---@param seconds number
    function coroutine.wait( seconds )
        local endTime = CurTime() + seconds
        while true do
            if endTime < CurTime() then return end
            coroutine_yield()
        end
    end

end

do

    local COLOR = FindMetaTable( "Color" )

    ---@param value any
    ---@return boolean
    function _G.IsColor( value )
        return debug_getmetatable( value ) == COLOR
    end

    ---@param r number
    ---@param g number
    ---@param b number
    ---@param a number?
    ---@return Color
    local function color( r, g, b, a )
        return setmetatable( {
            r = math_min( tonumber( r, 10 ), 255 ),
            g = math_min( tonumber( g, 10 ), 255 ),
            b = math_min( tonumber( b, 10 ), 255 ),
            a = math_min( tonumber( a or 255, 10 ), 255 )
        }, COLOR )
    end

    _G.Color = color

    ---@param c table
    ---@param a number?
    ---@return Color
    function ColorAlpha( c, a )
        return color( c.r, c.g, c.b, a )
    end

    ---@param alpha boolean
    ---@return Color
    function ColorRand( alpha )
        if alpha then
            return color( math_random( 0, 255 ), math_random( 0, 255 ), math_random( 0, 255 ), math_random( 0, 255 ) )
        else
            return color( math_random( 0, 255 ), math_random( 0, 255 ), math_random( 0, 255 ) )
        end
    end

    local Lerp = _G.Lerp

    ---@param col Color
    ---@param frac number
    ---@return Color
    function COLOR:Lerp( col, frac )
        return color(
            Lerp( frac, self.r, col.r ),
            Lerp( frac, self.g, col.g ),
            Lerp( frac, self.b, col.b ),
            Lerp( frac, self.a, col.a )
        )
    end

end

local GetConVar
do

    local GetConVar_Internal = _G.GetConVar_Internal
    local cache = {}

    function GetConVar( name )
        if cache[ name ] == nil then
            local value = GetConVar_Internal( name )
            if value == nil then return nil end
            cache[ name ] = value
            return value
        else
            return cache[ name ]
        end
    end

    _G.GetConVar = GetConVar

end

do

    local function math_Rand( low, high )
        return low + ( high - low ) * math_random()
    end

    math.Rand = math_Rand

    do

        local Vector = Vector

        function VectorRand( min, max )
            min, max = min or -1, max or 1
            return Vector( math_Rand( min, max ), math_Rand( min, max ), math_Rand( min, max ) )
        end

    end

    do

        local Angle = Angle

        function AngleRand( min, max )
            return Angle( math_Rand( min or -90, max or 90 ), math_Rand( min or -180, max or 180 ), math_Rand( min or -180, max or 180 ) )
        end

    end

end

do

    local debug_setmetatable = debug.setmetatable

    -- isnumber
    local isnumber
    do

        local object = 0
        local metatable = debug_getmetatable( object )
        if metatable == nil then
            metatable = {}
            debug_setmetatable( object, metatable )
        end

        ---@param value any
        ---@return boolean
        function isnumber( value )
            return debug_getmetatable( value ) == metatable
        end

        _G.isnumber = isnumber

    end

    -- isstring
    do

        local object = ""
        local metatable = debug_getmetatable( object )
        if metatable == nil then
            metatable = {}
            debug_setmetatable( object, metatable )
        end

        local string_sub = string.sub

        function metatable:__index( key )
            if isnumber( key ) then
                ---@diagnostic disable-next-line: cast-type-mismatch
                ---@cast self string
                ---@cast key number
                return string_sub( self, key, key )
            else
                return string[ key ]
            end
        end

        ---@param value any
        ---@return boolean
        function _G.isstring( value )
            return debug_getmetatable( value ) == metatable
        end

    end

    -- isbool
    do

        local object = true
        local metatable = debug_getmetatable( object )
        if metatable == nil then
            metatable = {}
            debug_setmetatable( object, metatable )
        end

        ---@param value any
        ---@return boolean
        function _G.isbool( value )
            return debug_getmetatable( value ) == metatable
        end

    end

    -- isfunction
    do

        local object = function() end
        local metatable = debug_getmetatable( object )
        if metatable == nil then
            metatable = {}
            debug_setmetatable( object, metatable )
        end

        ---@param value any
        ---@return boolean
        function _G.isfunction( value )
            return debug_getmetatable( value ) == metatable
        end

    end

end

-- isangle
do

    local ANGLE = FindMetaTable( "Angle" )

    ---@param value any
    ---@return boolean
    function _G.isangle( value )
        return debug_getmetatable( value ) == ANGLE
    end

end

-- isvector
do

    local VECTOR = FindMetaTable( "Vector" )

    ---@param value any
    ---@return boolean
    function _G.isvector( value )
        return debug_getmetatable( value ) == VECTOR
    end

end

-- ismatrix
do

    local MATRIX = FindMetaTable( "VMatrix" )

    ---@param value any
    ---@return boolean
    function _G.ismatrix( value )
        return debug_getmetatable( value ) == MATRIX
    end

end

do

    local system = _G.system

    do

        local is_linux = system.IsLinux()

        function system.IsLinux()
            return is_linux
        end

    end

    do

        local is_osx = system.IsOSX()

        function system.IsOSX()
            return is_osx
        end

    end

    do

        local is_windows = system.IsWindows()

        function system.IsWindows()
            return is_windows
        end

    end

    do

        local system_BatteryPower = system.BatteryPower
        local battery_power = system_BatteryPower()

        function system.BatteryPower()
            return battery_power
        end

        timer_Create( addon_name .. " - system.BatteryPower", 1, 0, function()
            battery_power = system_BatteryPower()
        end )

    end

    -- system focus tricks
    do

        local system_HasFocus = system.HasFocus
        local has_focus = system_HasFocus()
        local focus_changed

        function system.HasFocus()
            return has_focus
        end

        timer_Create( addon_name .. " - system.HasFocus", 0.05, 0, function()
            if system_HasFocus() == has_focus then return end
            has_focus = not has_focus

            if focus_changed == nil then return end
            focus_changed()
        end )

        if CLIENT then

            -- No more mouse lock
            do

                local gp_no_more_mouse_lock = _G.CreateConVar( "gp_no_more_mouse_lock", "1", FCVAR_ARCHIVE, "Automatically open the pause menu when the game loses focus." )
                if gp_no_more_mouse_lock ~= nil then
                    ---@cast gp_no_more_mouse_lock ConVar

                    local gui_IsGameUIVisible, gui_ActivateGameUI = gui.IsGameUIVisible, gui.ActivateGameUI
                    local vgui_CursorVisible = vgui.CursorVisible
                    local GetBool = gp_no_more_mouse_lock.GetBool

                    function focus_changed()
                        if has_focus or not GetBool( gp_no_more_mouse_lock ) or vgui_CursorVisible() or gui_IsGameUIVisible() then return end
                        gui_ActivateGameUI()
                    end
                end

            end

            -- No more fake attacks
            do

                local last_no_focus_time = 0

                hook_Add( "CreateMove", addon_name .. " - No more fake attacks", function( cmd )
                    if ( CurTime() - last_no_focus_time ) < 0.25 then
                        cmd:RemoveKey( 1 )
                        cmd:RemoveKey( 2048 )
                    end

                    if has_focus then return end
                    last_no_focus_time = CurTime()
                    ---@diagnostic disable-next-line: redundant-parameter
                end, PRE_HOOK )

            end

        end

    end

end

if CLIENT or MENU then

    -- ispanel
    do

        local PANEL = FindMetaTable( "Panel" )

        ---@param value any
        ---@return boolean
        function _G.ispanel( value )
            local metatable = debug_getmetatable( value )
            return metatable and ( metatable == PANEL or metatable.MetaID == 22 )
        end

    end

    -- faster gui.IsConsoleVisible
    do

        local gui_IsConsoleVisible = gui.IsConsoleVisible

        local is_visible = gui_IsConsoleVisible()

        timer_Create( addon_name .. " - gui.IsConsoleVisible", 0.25, 0, function()
            is_visible = gui_IsConsoleVisible()
        end )

        function gui.IsConsoleVisible()
            return is_visible
        end

    end

    -- faster gui.IsGameUIVisible
    do

        local gui_IsGameUIVisible = gui.IsGameUIVisible

        local is_visible = gui_IsGameUIVisible()

        timer_Create( addon_name .. " - gui.IsGameUIVisible", 0.1, 0, function()
            is_visible = gui_IsGameUIVisible()
        end )

        function gui.IsGameUIVisible()
            return is_visible
        end

    end

    -- faster engine.IsPlayingDemo
    do

        local engine_IsPlayingDemo = engine.IsPlayingDemo

        local is_playing = engine_IsPlayingDemo()

        timer_Create( addon_name .. " - engine.IsPlayingDemo", 0.5, 0, function()
            is_playing = engine_IsPlayingDemo()
        end )

        function engine.IsPlayingDemo()
            return is_playing
        end

    end

    -- faster engine.IsRecordingDemo
    do

        local engine_IsRecordingDemo = engine.IsRecordingDemo

        local is_recording = engine_IsRecordingDemo()

        timer_Create( addon_name .. " - engine.IsRecordingDemo", 0.25, 0, function()
            is_recording = engine_IsRecordingDemo()
        end )

        function engine.IsRecordingDemo()
            return is_recording
        end

    end

end

do

    local engine_GetAddons, engine_GetGames = engine.GetAddons, engine.GetGames

    local addons, games = engine_GetAddons(), engine_GetGames()
    local addon_count, game_count = #addons, #games

    hook.Add( "GameContentChanged", addon_name .. " - engine.GetAddons", function()
        addons, games = engine_GetAddons(), engine_GetGames()
        addon_count, game_count = #addons, #games

        ---@diagnostic disable-next-line: redundant-parameter
    end, PRE_HOOK )

    function engine.GetAddons()
        local lst = {}

        for i = 1, addon_count, 1 do
            local data = addons[ i ]
            lst[ i ] = {
                downloaded = data.downloaded,
                file = data.file,
                models = data.models,
                mounted = data.mounted,
                size = data.size,
                tags = data.tags,
                timeadded = data.timeadded,
                title = data.title,
                updated = data.updated,
                wsid = data.wsid
           }
        end

        return lst
    end

    function engine.GetGames()
        local lst = {}

        for i = 1, game_count, 1 do
            local data = games[ i ]
            lst[ i ] = {
                depot = data.depot,
                folder = data.folder,
                installed = data.installed,
                mounted = data.mounted,
                owned = data.owned,
                title = data.title
            }
        end

        return lst
    end

end

do

    local string_match = string.match

    --- Convert SteamID to SteamID64.
    ---@param str string: SteamID
    ---@return string: SteamID64
    function util.SteamIDTo64( str )
        local x, y, z = string_match( str, "STEAM_([0-5]):([01]):(%d+)" )
        return x == nil and "0" or ( "765" .. ( ( tonumber( z, 10 ) * 2 ) + 61197960265728 ) + ( y == "1" and 1 or 0 ) )
    end

end

do

    local string_sub = string.sub

    --- Convert SteamID64 to SteamID.
    ---@param str string: SteamID64
    ---@return string: SteamID
    function util.SteamIDFrom64( str )
        local account_id = math_max( 0, ( tonumber( string_sub( str, 4 ), 10 ) or 0 ) - 61197960265728 )
        return "STEAM_0:" .. ( account_id % 2 == 0 and "0" or "1" ) .. ":" .. math_floor( account_id * 0.5 )
    end

end

if CLIENT or SERVER then
    local timer_Simple = _G.timer.Simple

    ---@class Entity
    local ENTITY = FindMetaTable( "Entity" )
    local ENTITY_IsValid = ENTITY.IsValid

    ---@param value any
    ---@return boolean
    function _G.isentity( value )
        if not value then return false end
        local metatable = debug_getmetatable( value )
        if metatable == nil then return false end
        return metatable == ENTITY or metatable.MetaID == 9
    end

    ---@class Player
    local PLAYER = FindMetaTable( "Player" )
    local PLAYER_IsBot = PLAYER.IsBot

    ---@class ConVar
    local CONVAR = FindMetaTable( "ConVar" )

    do

        local gamemode_name = engine.ActiveGamemode()

        ---@return string
        function engine.ActiveGamemode()
            return gamemode_name
        end

    end

    do

        local isSingleplayer = game.SinglePlayer()

        ---@return boolean
        function game.SinglePlayer()
            return isSingleplayer
        end

    end

    do

        local isDedicated = game.IsDedicated()

        ---@return boolean
        function game.IsDedicated()
            return isDedicated
        end

        if isDedicated then
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

                hook_Add( "StartChat", addon_name .. " - cl_drawhud chat fix", function()
                    if GetBool( cl_drawhud ) then return end
                    chat_Close()
                    return true
                    ---@diagnostic disable-next-line: redundant-parameter
                end, PRE_HOOK_RETURN )

                _G.cvars.AddChangeCallback( "cl_drawhud", chat_Close, addon_name .. " - cl_drawhud chat fix" )
            end

        end

        -- OnConVarChanged for replicated cvars
        if gameevent_Listen ~= nil then

            local CONVAR_GetDefault = CONVAR.GetDefault
            gameevent_Listen( "server_cvar" )
            local old_values = {}

            hook_Add( "server_cvar", addon_name .. " - OnConVarChanged for replicated cvars", function( data )
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

        -- Map name caching
        hook_Add( "Initialize", addon_name .. " - Map name caching", function()
            hook_Remove( "Initialize", addon_name .. " - Map name caching" )
            local map_name = game.GetMap()

            ---@return string
            function game.GetMap()
                return map_name
            end
        end )

    else

        -- Map name caching
        local map_name = game.GetMap()

        ---@return string
        function game.GetMap()
            return map_name
        end

    end

    -- Entity index cache
    do

        local ents, player = _G.ents, _G.player
        local table_remove = table.remove

        local inext = ipairs( ents )

        local entities = ents.GetAll()
        local entity_count = #entities

        function ents.GetAll()
            local copy = {}
            for i = 1, entity_count, 1 do
                copy[ i ] = entities[ i ]
            end

            return copy
        end

        function ents.GetCount()
            return entity_count
        end

        function ents.Iterator()
            return inext, entities, 0
        end

        local players = player.GetAll()
        local player_count = #players

        function player.GetAll()
            local copy = {}
            for i = 1, player_count, 1 do
                copy[ i ] = players[ i ]
            end

            return copy
        end

        function player.GetCount()
            return player_count
        end

        function player.Iterator()
            return inext, players, 0
        end

        local index2entity = {}
        do

            local game_GetWorld = game.GetWorld
            local Entity = _G.Entity

            setmetatable( index2entity, {
                __index = function( _, index )
                    if index == 0 then
                        return game_GetWorld()
                    else
                        return Entity( index )
                    end
                end
            } )

        end

        function _G.Entity( index )
            return index2entity[ index ]
        end

        function game.GetWorld()
            return index2entity[ 0 ]
        end

        local entity2index = {}
        do

            local ENTITY_EntIndex = ENTITY.EntIndex

            setmetatable( entity2index, {
                __index = function( _, entity )
                    return ENTITY_IsValid( entity ) and ENTITY_EntIndex( entity ) or 0
                end
            } )

        end

        local function getEntIndex( entity )
            return entity2index[ entity ]
        end

        ENTITY.EntIndex = getEntIndex

        local entity2class = {}
        do

            local ENTITY_GetClass = ENTITY.GetClass

            setmetatable( entity2class, {
                __index = function( _, entity )
                    return ENTITY_GetClass( entity )
                end
            } )

        end

        local function getClass( entity )
            return entity2class[ entity ]
        end

        ENTITY.GetClass = getClass

        function ENTITY:IsWorld()
            return rawget( entity2index, self ) == 0
        end

        local function is_worldspawn( entity )
            return rawget( entity2index, entity ) == 0 and entity2class[ entity ] == "worldspawn"
        end

        -- tostring functions
        do

            local string_format = string.format

            ---@private
            function ENTITY:__tostring()
                if ENTITY_IsValid( self ) then
                    return string_format( "Entity [%d][%s]", getEntIndex( self ), getClass( self ) )
                elseif is_worldspawn( self ) then
                    return "Entity [0][worldspawn]"
                else
                    return "[NULL Entity]"
                end
            end

            ---@private
            function PLAYER:__tostring()
                if ENTITY_IsValid( self ) then
                    return string_format( "Player [%d][%s]", getEntIndex( self ), self:Nick() )
                else
                    return "[NULL Player]"
                end
            end

        end

        local uid2player = {}
        do

            local Player = _G.Player

            setmetatable( uid2player, {
                __index = function( _, index )
                    return Player( index )
                end
            } )

        end

        local player2uid = {}
        do

            local PLAYER_UserID = PLAYER.UserID

            setmetatable( player2uid, {
                __index = function( _, ply )
                    return PLAYER_UserID( ply )
                end
            } )

        end

        function PLAYER:UserID()
            return player2uid[ self ]
        end

        -- World and local player caching
        do

            local local_player_fn

            if CLIENT then

                local LocalPlayer = _G.LocalPlayer
                local NULL = _G.NULL
                local local_player

                ---@return Player
                function local_player_fn()
                    if local_player == nil then
                        local entity = LocalPlayer()
                        if entity and ENTITY_IsValid( entity ) then
                            _G.rawset( _G, "LocalPlayer", function() return entity end )
                            local_player = entity

                            -- caching if player is not cached
                            if rawget( entity2index, entity ) == nil then
                                -- id and class caching
                                index2entity[ getEntIndex( entity ) ] = entity
                                entity2index[ entity ] = getEntIndex( entity )
                                entity2class[ entity ] = "player"

                                -- adding player into entity list
                                table.insert( entities, 2, entity )
                                entity_count = entity_count + 1

                                -- adding player into player list
                                table.insert( players, 1, entity )
                                player_count = player_count + 1

                                -- player uid caching
                                local uid = player2uid[ entity ]
                                uid2player[ uid ] = entity
                                player2uid[ entity ] = uid
                            end

                            return entity
                        else
                            return NULL
                        end
                    else
                        return local_player
                    end
                end

                _G.LocalPlayer = local_player_fn

            end

            hook_Add( "InitPostEntity", addon_name .. " - World & LocalPlayer", function()
                hook_Remove( "InitPostEntity", addon_name .. " - World & LocalPlayer" )

                -- world entity caching
                local entity = index2entity[ 0 ]
                if rawget( entity2index, entity ) == nil then
                    index2entity[ 0 ] = entity
                    entity2index[ entity ] = 0
                    entity2class[ entity ] = "worldspawn"
                    table.insert( entities, 1, entity )
                    entity_count = entity_count + 1
                end

                -- local player caching
                if local_player_fn ~= nil then
                    local_player_fn()
                end

                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

        end

        local player2is_bot = {}

        if SERVER then

            local connected_players = {}

            hook_Add( "PlayerInitialSpawn", addon_name .. " - Player is bot cache", function( ply )
                connected_players[ ply ] = true
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

            hook_Add( "PlayerDisconnected", addon_name .. " - Player is bot cache", function( ply )
                connected_players[ ply ] = nil
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

            setmetatable( player2is_bot, {
                __index = function( _, ply )
                    if connected_players[ ply ] == nil then
                        return false
                    else
                        local value = PLAYER_IsBot( ply )
                        player2is_bot[ ply ] = value
                        return value
                    end
                end
            } )

        else
            setmetatable( player2is_bot, {
                __index = function( _, ply )
                    local value = PLAYER_IsBot( ply )
                    player2is_bot[ ply ] = value
                    return value
                end
            } )
        end

        function PLAYER:IsBot()
            return player2is_bot[ self ]
        end

        local player2steamid = {}
        do

            local PLAYER_SteamID = PLAYER.SteamID

            setmetatable( player2steamid, {
                __index = function( _, ply )
                    if PLAYER_IsBot( ply ) then
                        local value = "STEAM_0:0:" .. player2uid[ ply ] -- fake steamid for bots
                        player2steamid[ ply ] = value
                        return value
                    else
                        local value = PLAYER_SteamID( ply )
                        player2steamid[ ply ] = value
                        return value
                    end
                end
            } )

        end

        function PLAYER:SteamID()
            return player2steamid[ self ]
        end

        local player2steamid64 = {}
        do

            local PLAYER_SteamID64 = PLAYER.SteamID64

            setmetatable( player2steamid64, {
                __index = function( _, ply )
                    if PLAYER_IsBot( ply ) then
                        local value = "765" .. ( ( player2uid[ ply ] * 2 ) + 61197960265728 ) -- fake steamid for bots
                        player2steamid64[ ply ] = value
                        return value
                    else
                        local value = PLAYER_SteamID64( ply )
                        player2steamid64[ ply ] = value
                        return value
                    end
                end
            } )

        end

        function PLAYER:SteamID64()
            return player2steamid64[ self ]
        end

        local player2nick = {}
        do

            local PLAYER_Nick = PLAYER.Nick

            setmetatable( player2nick, {
                __index = function( _, ply )
                    local value = PLAYER_Nick( ply )
                    player2nick[ ply ] = value
                    return value
                end
            } )

            if CLIENT then

                timer_Create( addon_name .. " - Player name cache", 5, 0, function()
                    for i = 1, player_count, 1 do
                        local ply = players[ i ]
                        player2nick[ ply ] = PLAYER_Nick( ply )
                    end
                end )

            end

            local function get_name( ply )
                return player2nick[ ply ]
            end

            PLAYER.GetName = get_name
            PLAYER.Nick = get_name

        end

        if gameevent_Listen ~= nil then

            gameevent_Listen( "player_changename" )
            gameevent_Listen( "player_info" )

            hook_Add( "player_changename", addon_name .. " - Player name cache", function( data )
                timer_Simple( 0, function()
                    local nickname = data.newname
                    if nickname == "" then return end

                    local ply = uid2player[ data.userid ]
                    if ply ~= nil and ENTITY_IsValid( ply ) then
                        player2nick[ ply ] = nickname
                    end
                end )

                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

            hook_Add( "player_info", "player_info_example", function( data )
                timer_Simple( 0, function()
                    local ply = uid2player[ data.userid ]
                    if ply ~= nil and ENTITY_IsValid( ply ) then
                        player2nick[ ply ] = data.name
                    end
                end )

                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

        end

        hook_Add( "PostCleanupMap", addon_name .. " - Entity & player cache", function()
            -- entity list rebuild
            for i = entity_count, 1, -1 do
                local entity = entities[ i ]
                if not ( ENTITY_IsValid( entity ) or is_worldspawn( entity ) ) then
                    table_remove( entities, i )
                    entity_count = entity_count - 1
                end
            end

            -- indexes revalidation
            for index, entity in pairs( index2entity ) do
                if not ( ENTITY_IsValid( entity ) or is_worldspawn( entity ) ) then
                    index2entity[ index ] = nil
                    entity2index[ entity ] = nil
                    entity2class[ entity ] = nil
                end
            end

            ---@diagnostic disable-next-line: redundant-parameter
        end, PRE_HOOK )

        hook_Add( "OnEntityCreated", addon_name .. " - Entity & player cache", function( entity )
            -- stop if entity is already registred or invalid
            if not ENTITY_IsValid( entity ) or rawget( entity2index, entity ) ~= nil then return end

            -- adding entity into entity list
            entity_count = entity_count + 1
            entities[ entity_count ] = entity

            local index = entity2index[ entity ]

            -- client side id generating
            if index == -1 then
                while rawget( index2entity, index ) ~= nil do
                    index = index - 1
                end
            end

            -- caching entity index and class
            index2entity[ index ] = entity
            entity2index[ entity ] = index
            entity2class[ entity ] = entity2class[ entity ]

            -- is player?
            if entity:IsPlayer() then
                ---@cast entity Player

                -- adding player into player list
                player_count = player_count + 1
                players[ player_count ] = entity

                -- caching player uid
                local uid = player2uid[ entity ]
                uid2player[ uid ] = entity
                player2uid[ entity ] = uid
            end

            ---@diagnostic disable-next-line: redundant-parameter
        end, PRE_HOOK )

        local on_remove = {}

        hook_Add( "EntityRemoved", addon_name .. " - Entity & player cache", function( entity )
            -- if entity is already removed or not registred then return
            if rawget( entity2index, entity ) == nil or on_remove[ entity ] then return end
            on_remove[ entity ] = true

            -- remove from entity list
            for i = entity_count, 1, -1 do
                if entities[ i ] == entity then
                    entity_count = entity_count - 1
                    table_remove( entities, i )
                    break
                end
            end

            -- is player?
            local is_player = entity:IsPlayer()

            -- if player then remove from player list
            if is_player then
                for i = player_count, 1, -1 do
                    if players[ i ] == entity then
                        player_count = player_count - 1
                        table_remove( players, i )
                        break
                    end
                end
            end

            -- ids precache
            local index = entity2index[ entity ]
            local puid = is_player and player2uid[ entity ] or nil

            timer_Simple( 0, function()
                -- clean-up entity cache
                index2entity[ index ] = nil
                entity2class[ entity ] = nil
                entity2index[ entity ] = nil

                -- remove entity if it's still valid and removing is allowed
                if ( SERVER or index < 0 ) and ENTITY_IsValid( entity ) then
                    if is_player then
                        entity:Kick( "Player was removed." )
                    else
                        entity:Remove()
                    end
                end

                -- clean-up player cache
                if is_player then
                    uid2player[ puid or -1 ] = nil
                    player2uid[ entity ] = nil
                    player2nick[ entity ] = nil
                    player2is_bot[ entity ] = nil
                    player2steamid[ entity ] = nil
                    player2steamid64[ entity ] = nil
                end

                -- removing is done
                on_remove[ entity ] = nil
            end )

            ---@diagnostic disable-next-line: redundant-parameter
        end, PRE_HOOK )

    end

    function ENTITY:IsPlayer()
        return debug_getmetatable( self ) == PLAYER
    end

    do

        local WEAPON = FindMetaTable( "Weapon" )

        function ENTITY:IsWeapon()
            return debug_getmetatable( self ) == WEAPON
        end

    end

    do

        local NPC = FindMetaTable( "NPC" )

        function ENTITY:IsNPC()
            return debug_getmetatable( self ) == NPC
        end

    end

    do

        local NEXTBOT = FindMetaTable( "NextBot" )

        function ENTITY:IsNextbot()
            return debug_getmetatable( self ) == NEXTBOT
        end

    end

    -- Faster traces
    do

        local TraceLine = util.TraceLine
        local distance = 4096 * 8
        local trace = {}

        function util.GetPlayerTrace( ply, dir )
            local start = ply:EyePos()

            return {
                start = start,
                endpos = start + ( ( dir or ply:GetAimVector() ) * distance ),
                filter = ply
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

    do

        local IsOnGround, GetMoveType = ENTITY.IsOnGround, ENTITY.GetMoveType

        -- No more fake footsteps
        do

            local MOVETYPE_LADDER = _G.MOVETYPE_LADDER

            hook_Add( "PlayerFootstep", addon_name .. " - No more fake footsteps", function( ply )
                if not IsOnGround( ply ) and GetMoveType( ply ) ~= MOVETYPE_LADDER then return true end
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK_RETURN )

        end

        -- No more air crouching
        local MOVETYPE_NOCLIP, IN_DUCK = _G.MOVETYPE_NOCLIP, _G.IN_DUCK

        hook_Add( "StartCommand", addon_name .. " - No more air crouching", function( ply, cmd )
            if GetMoveType( ply ) == MOVETYPE_NOCLIP or IsOnGround( ply ) or cmd:KeyDown( IN_DUCK ) or not ply:Crouching() then return end
            cmd:AddKey( IN_DUCK )
            ---@diagnostic disable-next-line: redundant-parameter
        end, PRE_HOOK )

    end

    -- Decals fix
    if gameevent_Listen ~= nil then

        gameevent_Listen( "player_hurt" )
        local Player = _G.Player

        hook_Add( "player_hurt", addon_name .. " - Decals fix", function( data )
            if data.health > 0 then return end

            local ply = Player( data.userid )
            if not ( ply and ENTITY_IsValid( ply ) and ply:Alive() ) then return end

            timer_Simple( 0.25, function()
                if ENTITY_IsValid( ply ) then
                    ply:RemoveAllDecals()
                end
            end )
            ---@diagnostic disable-next-line: redundant-parameter
        end, PRE_HOOK )

    end

    if SERVER then

        -- Level reload command
        _G.concommand.Add( "reloadlevel", function( ply )
            if ply and not ( ply:IsSuperAdmin() or ply:IsListenServerHost() ) then return end
            RunConsoleCommand( "changelevel", game.GetMap() )
        end, nil, "Reload the current server map and reconnect all players." )

        -- License check
        do

            local sv_lan = GetConVar( "sv_lan" )
            if sv_lan ~= nil then
                ---@cast sv_lan ConVar

                local GetBool = sv_lan.GetBool

                hook_Add( "PlayerInitialSpawn", addon_name .. " - License check", function( ply )
                    if GetBool( sv_lan ) or PLAYER_IsBot( ply ) or ply:IsListenServerHost() or ply:IsFullyAuthenticated() then return end
                    ply:Kick( "Your SteamID wasn\'t fully authenticated, try restart your Steam client." )
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
                hook_Add( "EntityRemoved", addon_name .. " - func_areaportal", function( entity )
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
                hook_Remove( "EntityRemoved", addon_name .. " - func_areaportal" )
            end

            ---@diagnostic disable-next-line: redundant-parameter
            hook_Add( "PostCleanupMap", addon_name .. " - func_areaportal", start, PRE_HOOK )

            ---@diagnostic disable-next-line: redundant-parameter
            hook_Add( "PreCleanupMap", addon_name .. " - func_areaportal", stop, PRE_HOOK )

            ---@diagnostic disable-next-line: redundant-parameter
            hook_Add( "ShutDown", addon_name .. " - func_areaportal", stop, PRE_HOOK )

            start()

        end

        -- item_suitcharger & item_healthcharger physics
        do

            local SOLID_VPHYSICS = _G.SOLID_VPHYSICS

            hook_Add( "PlayerSpawnedSENT", addon_name .. " - item_suitcharger & item_healthcharger physics", function( _, entity )
                local className = entity:GetClass()
                if className == "item_suitcharger" or className == "item_healthcharger" then
                    entity:PhysicsInit( SOLID_VPHYSICS )
                    entity:PhysWake()
                end
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

        end

        -- https://github.com/Kefta/gs_podfix
        -- https://github.com/Facepunch/garrysmod-issues/issues/2452
        do

            local EFL_NO_THINK_FUNCTION = _G.EFL_NO_THINK_FUNCTION
            local table_remove = table.remove
            local entities = {}

            hook_Add( "OnEntityCreated", addon_name .. " - Kefta podfix", function( entity )
                if entity:GetClass() == "prop_vehicle_prisoner_pod" then
                    entity:AddEFlags( EFL_NO_THINK_FUNCTION )
                end

                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

            hook_Add( "PlayerLeaveVehicle", addon_name .. " - Kefta podfix", function( _, entity )
                if entity:GetClass() == "prop_vehicle_prisoner_pod" then
                    entities[ #entities + 1 ] = entity
                end

                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

            local function removeEntityFromList( entity )
                for i = #entities, 1, -1 do
                    if entities[ i ] == entity then
                        table_remove( entities, i )
                        break
                    end
                end
            end

            hook_Add( "PlayerEnteredVehicle", addon_name .. " - Kefta podfix", function( _, entity )
                if entity:GetClass() == "prop_vehicle_prisoner_pod" then
                    entity:RemoveEFlags( EFL_NO_THINK_FUNCTION )
                    removeEntityFromList( entity )
                end
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

            hook_Add( "EntityRemoved", addon_name .. " - prop_vehicle_prisoner_pod", function( entity )
                if entity:GetClass() == "prop_vehicle_prisoner_pod" then
                    removeEntityFromList( entity )
                end
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

            hook_Add( "Think", addon_name .. " - Kefta podfix", function()
                for i = #entities, 1, -1 do
                    local entity = entities[ i ]
                    entities[ i ] = nil

                    if ENTITY_IsValid( entity ) and not ENTITY_GetInternalVariable( entity, "m_bExitAnimOn" ) then
                        entity:AddEFlags( EFL_NO_THINK_FUNCTION )
                    end
                end
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

        end

        -- Fixes for prop_vehicle_prisoner_pod, worldspawn (and other not Valid but not NULL entities) damage taking (bullets only)
        -- Explosive damage only works if is located in front of prop_vehicle_prisoner_pod (wtf?)
        do

            local ENTITY_TakePhysicsDamage = ENTITY.TakePhysicsDamage

            hook_Add( "EntityTakeDamage", addon_name .. " - prop_vehicle_prisoner_pod damage fix", function( entity, damageInfo )
                if entity:GetClass() ~= "prop_vehicle_prisoner_pod" or entity.AcceptDamageForce then return end
                ENTITY_TakePhysicsDamage( entity, damageInfo )
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

        end

        -- Players alive cache
        do

            local PLAYER_Alive = PLAYER.Alive
            local players = {}

            setmetatable( players, {
                __index = function( _, ply )
                    return PLAYER_Alive( ply )
                end
            } )

            hook_Add( "PlayerSpawn", addon_name .. " - Alive cache", function( ply )
                players[ ply ] = true

                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

            hook_Add( "PostPlayerDeath", addon_name .. " - Alive cache", function( ply )
                players[ ply ] = false

                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

            hook_Add( "EntityRemoved", addon_name .. " - Alive cache", function( entity )
                if entity:IsPlayer() then
                    timer_Simple( 0, function()
                        players[ entity ] = nil
                    end )
                end

                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

            function PLAYER:Alive()
                return players[ self ]
            end

        end

    end

end

MsgC( SERVER and Color( 50, 100, 250 ) or Color( 250, 100, 50 ), "[" .. addon_name .. "] ", _G.color_white, table.Random( {
    "Here For You ♪", "Patched", "Alright", "Thanks for installation <3", "Increasing performance!", "Sometimes we just need more cache :>"
} ) .. "\n" )
