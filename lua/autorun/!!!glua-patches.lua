local _G = _G

-- Already patched
if _G.__gluaPatches then return end

---@diagnostic disable-next-line: inject-field
_G.__gluaPatches = true

local addon_name = "gLua Patches v1.7.0"

local string, math, table, engine = _G.string, _G.math, _G.table, _G.engine
local pairs, tonumber, setmetatable, FindMetaTable, rawget, rawset = _G.pairs, _G.tonumber, _G.setmetatable, _G.FindMetaTable, _G.rawget, _G.rawset
local math_min, math_max, math_random = math.min, math.max, math.random
local debug_getmetatable = _G.debug.getmetatable
local engine_TickCount = engine.TickCount

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

do

    local math_floor = math.floor

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

    local index = math_random( 1, count )

    for key, value in pairs( tbl ) do
        if index == 1 then
            return value, key
        else
            index = index - 1
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

    local debug_setmetatable = _G.debug.setmetatable

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

    local timer_Create = _G.timer.Create

    do

        local system_BatteryPower = system.BatteryPower
        local battery_power = system_BatteryPower()

        function system.BatteryPower()
            return battery_power
        end

        timer_Create( addon_name .. " - system.BatteryPower", 1, 0, function()
            battery_power = system_BatteryPower()
            ---@diagnostic disable-next-line: redundant-parameter
        end )

    end

    do

        local system_HasFocus = system.HasFocus
        local has_focus = system_HasFocus()

        function system.HasFocus()
            return has_focus
        end

        timer_Create( addon_name .. " - system.HasFocus", 0.05, 0, function()
            has_focus = system_HasFocus()
            ---@diagnostic disable-next-line: redundant-parameter
        end )

    end

end

-- ispanel
if CLIENT or MENU then

    local PANEL = FindMetaTable( "Panel" )

    ---@param value any
    ---@return boolean
    function _G.ispanel( value )
        local metatable = debug_getmetatable( value )
        return metatable and ( metatable == PANEL or metatable.MetaID == 22 )
    end

end

do

    local engine_GetAddons = engine.GetAddons

    local lastTick = 0
    local addons, length

    ---@return table
    function engine.GetAddons()
        local tick = engine_TickCount()
        if tick ~= lastTick then
            addons = engine_GetAddons()
            length = #addons
            lastTick = tick
        end

        local lst = {}

        for i = 1, length, 1 do
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

end

if CLIENT or SERVER then
    local return_false = function() return false end
    local return_true = function() return true end
    local timer_Simple = _G.timer.Simple

    ---@class Entity
    local ENTITY = FindMetaTable( "Entity" )
    local ENTITY_GetClass = ENTITY.GetClass
    local ENTITY_IsValid = ENTITY.IsValid
    local NULL = _G.NULL

    ---@param value any
    ---@return boolean
    function _G.isentity( value )
        if value == NULL then return true end
        local metatable = debug_getmetatable( value )
        if metatable == nil then return false end
        return metatable == ENTITY or metatable.MetaID == 9
    end

    ---@class Player
    local PLAYER = FindMetaTable( "Player" )

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

            local convar = GetConVar( "cl_drawhud" )
            if convar ~= nil then
                ---@cast convar ConVar
                local chat_Close = _G.chat.Close

                hook_Add( "StartChat", addon_name .. " - cl_drawhud chat fix", function()
                    if convar:GetBool() then return end
                    chat_Close()
                    return true
                    ---@diagnostic disable-next-line: redundant-parameter
                end, PRE_HOOK_RETURN )

                _G.cvars.AddChangeCallback( "cl_drawhud", chat_Close, addon_name .. " - cl_drawhud chat fix" )
            end

        end

        -- OnConVarChanged for replicated cvars
        do

            local CONVAR_GetDefault = CONVAR.GetDefault
            _G.gameevent.Listen( "server_cvar" )
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

                _G.cvars.OnConVarChanged( name, old, data.cvarvalue )
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

        -- LocalPlayer caching
        do

            local LocalPlayer = _G.LocalPlayer
            local player = NULL

            ---@return Player
            function _G.LocalPlayer()
                if player == NULL then
                    local entity = LocalPlayer()
                    if entity and ENTITY_IsValid( entity ) then
                        player = entity
                        return entity
                    end
                end

                return player
            end

        end

        do

            local HasFocus = _G.system.HasFocus

            -- No more fake attacks
            do

                local IN_ATTACK, IN_ATTACK2 = _G.IN_ATTACK, _G.IN_ATTACK2
                local lastNoFocusTime = 0

                hook_Add( "CreateMove", addon_name .. " - No more fake attacks", function( cmd )
                    if ( CurTime() - lastNoFocusTime ) < 0.25 then
                        cmd:RemoveKey( IN_ATTACK )
                        cmd:RemoveKey( IN_ATTACK2 )
                    end

                    if HasFocus() then return end
                    lastNoFocusTime = CurTime()
                    ---@diagnostic disable-next-line: redundant-parameter
                end, PRE_HOOK )

            end

            -- No more mouse lock
            local gui_IsGameUIVisible, gui_ActivateGameUI = gui.IsGameUIVisible, gui.ActivateGameUI
            local vgui_CursorVisible = vgui.CursorVisible
            local ui_state = false

            hook_Add( "Think", addon_name .. " - No more mouse lock", function()
                if HasFocus() then
                    if ui_state then
                        ui_state = false
                    end
                elseif not ui_state then
                    if vgui_CursorVisible() then return end

                    if not gui_IsGameUIVisible() then
                        gui_ActivateGameUI()
                    end

                    ui_state = true
                end
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

        end

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

        local ENTITY_EntIndex = ENTITY.EntIndex
        local Entity = _G.Entity

        local index2entity = {}
        setmetatable( index2entity, {
            __index = function( _, index )
                local entity = Entity( index )
                if entity == NULL then
                    return entity
                end

                if ENTITY_IsValid( entity ) then
                    rawset( index2entity, index, entity )
                end

                return entity
            end
        } )

        local entity2index = {}
        setmetatable( entity2index, {
            __index = function( _, entity )
                return ENTITY_EntIndex( entity )
            end
        } )

        -- World entity support
        hook_Add( "InitPostEntity", addon_name .. " - Entity index cache", function()
            local world = game.GetWorld()
            index2entity[ 0 ] = world
            entity2index[ world ] = 0
        end )

        do

            local string_format = string.format

            function ENTITY:__tostring()
                return string_format( "Entity [%d][%s]", self:EntIndex(), self:GetClass() )
            end

        end

        function ENTITY:EntIndex()
            return entity2index[ self ]
        end

        function _G.Entity( index )
            return index2entity[ index ]
        end

        local entity2class = {}
        setmetatable( entity2class, {
            __index = function( _, entity )
                return ENTITY_GetClass( entity )
            end
        } )

        function ENTITY:GetClass()
            return entity2class[ self ]
        end

        hook_Add( "OnEntityCreated", addon_name .. " - Entity index cache", function( entity )
            entity2class[ entity ] = ENTITY_GetClass( entity )

            local index = entity2index[ entity ]
            if index == -1 then
                while rawget( index2entity, index ) ~= nil do
                    index = index - 1
                end
            end

            index2entity[ index ] = entity
            entity2index[ entity ] = index
            ---@diagnostic disable-next-line: redundant-parameter
        end, PRE_HOOK )

        hook_Add( "EntityRemoved", addon_name .. " - Entity index cache", function( entity )
            timer_Simple( 0, function()
                if ENTITY_IsValid( entity ) then return end
                index2entity[ entity2index[ entity ] ] = nil
                entity2class[ entity ] = nil
                entity2index[ entity ] = nil
            end )

            ---@diagnostic disable-next-line: redundant-parameter
        end, PRE_HOOK )

    end

    -- Faster player functions
    do

        local ents, player = _G.ents, _G.player
        local table_remove = table.remove
        local inext = ipairs( ents )

        local entities = ents.GetAll()
        local entity_count = #entities

        function ents.GetAll()
            local copy = {}
            for i = 1, entity_count do
                rawset( copy, i, rawget( entities, i ) )
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
            for i = 1, player_count do
                rawset( copy, i, rawget( players, i ) )
            end

            return copy
        end

        function player.GetCount()
            return player_count
        end

        function player.Iterator()
            return inext, players, 0
        end

        local PLAYER_IsBot = PLAYER.IsBot
        local is_bot = {}

        setmetatable( is_bot, {
            __index = function( _, ply )
                local value = PLAYER_IsBot( ply )
                rawset( is_bot, ply, value )
                return value
            end
        } )

        hook_Add( "OnEntityCreated", addon_name .. " - Faster iterator's", function( entity )
            -- shitty code protection
            for i = entity_count, 1, -1 do
                if entities[ i ] == entity then return end
            end

            if entity:IsPlayer() then
                player_count = player_count + 1
                rawset( players, player_count, entity )
                rawset( is_bot, entity, PLAYER_IsBot( entity ) )
            end

            entity_count = entity_count + 1
            rawset( entities, entity_count, entity )
            ---@diagnostic disable-next-line: redundant-parameter
        end, PRE_HOOK )

        hook_Add( "EntityRemoved", addon_name .. " - Faster iterator's", function( entity )
            for i = entity_count, 1, -1 do
                if entities[ i ] == entity then
                    entity_count = entity_count - 1
                    table_remove( entities, i )
                    break
                end
            end

            if entity:IsPlayer() then
                for i = player_count, 1, -1 do
                    if players[ i ] == entity then
                        player_count = player_count - 1
                        table_remove( players, i )
                        break
                    end
                end

                timer_Simple( 0, function()
                    is_bot[ entity ] = nil
                end )
            end
            ---@diagnostic disable-next-line: redundant-parameter
        end, PRE_HOOK )

        function PLAYER:IsBot()
            return is_bot[ self ]
        end

    end

    ENTITY.IsPlayer = return_false
    ENTITY.IsWeapon = return_false
    ENTITY.IsNPC = return_false
    ENTITY.IsNextbot = return_false

    PLAYER.IsWeapon = return_false
    PLAYER.IsNPC = return_false
    PLAYER.IsNextbot = return_false
    PLAYER.IsPlayer = return_true

    do
        local WEAPON = FindMetaTable( "Weapon" )
        WEAPON.IsPlayer = return_false
        WEAPON.IsWeapon = return_true
        WEAPON.IsNPC = return_false
        WEAPON.IsNextbot = return_false
    end

    do
        local NPC = FindMetaTable( "NPC" )
        NPC.IsPlayer = return_false
        NPC.IsWeapon = return_false
        NPC.IsNPC = return_true
        NPC.IsNextbot = return_false
    end

    do
        local PHYSOBJ = FindMetaTable( "PhysObj" )
        PHYSOBJ.IsWeapon = return_false
        PHYSOBJ.IsNPC = return_false
        PHYSOBJ.IsNextbot = return_false
        PHYSOBJ.IsPlayer = return_false
    end

    do
        local NEXTBOT = FindMetaTable( "NextBot" )
        NEXTBOT.IsPlayer = return_false
        NEXTBOT.IsWeapon = return_false
        NEXTBOT.IsNPC = return_false
        NEXTBOT.IsNextbot = return_true
    end

    -- Faster traces
    do

        local util = _G.util

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

    -- Player cache
    do

        local userids = {}
        do

            local PLAYER_UserID = PLAYER.UserID

            function PLAYER:UserID()
                local value = userids[ self ]
                if value == nil then
                    value = PLAYER_UserID( self )
                    userids[ self ] = value
                end

                return value
            end

        end

        local steamids = {}
        do

            local PLAYER_SteamID = PLAYER.SteamID

            function PLAYER:SteamID()

                local value = steamids[ self ]
                if value == nil then
                    if self:IsBot() then return nil end
                    value = PLAYER_SteamID( self )
                    steamids[ self ] = value
                end

                return value
            end

        end

        local steamids64 = {}
        do

            local PLAYER_SteamID64 = PLAYER.SteamID64

            function PLAYER:SteamID64()
                local value = steamids64[ self ]
                if value == nil then
                    if self:IsBot() then return nil end
                    value = PLAYER_SteamID64( self )
                    steamids64[ self ] = value
                end

                return value
            end

        end

        hook_Add( "EntityRemoved", addon_name .. " - SteamID cache", function( entity )
            if not entity:IsPlayer() then return end
            local isRealPlayer = not entity:IsBot()

            timer_Simple( 0, function()
                userids[ entity] = nil

                if isRealPlayer then
                    steamids[ entity ] = nil
                    steamids64[ entity ] = nil
                end
            end )
            ---@diagnostic disable-next-line: redundant-parameter
        end, PRE_HOOK )

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
    do

        _G.gameevent.Listen( "player_hurt" )
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

    -- TODO: usermessage.SendUserMessage

    if SERVER then
        -- License check
        do

            local sv_lan = GetConVar( "sv_lan" )
            ---@cast sv_lan ConVar

            hook_Add( "PlayerInitialSpawn", addon_name .. " - License check", function( ply )
                if sv_lan:GetBool() or ply:IsBot() or ply:IsListenServerHost() or ply:IsFullyAuthenticated() then return end
                ply:Kick( "Your SteamID wasn\'t fully authenticated, try restart your Steam client." )
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

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
                    if classes[ ENTITY_GetClass( entity ) ] == nil then return end

                    local name = ENTITY_GetName( entity )
                    if #name == 0 then return end

                    local portals = ents_FindByClass( "func_areaportal" )
                    for index = 1, #portals, 1 do
                        local portal = portals[ index ]
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
                local className = ENTITY_GetClass( entity )
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
                if ENTITY_GetClass( entity ) == "prop_vehicle_prisoner_pod" then
                    entity:AddEFlags( EFL_NO_THINK_FUNCTION )
                end
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

            hook_Add( "PlayerLeaveVehicle", addon_name .. " - Kefta podfix", function( _, entity )
                if ENTITY_GetClass( entity ) == "prop_vehicle_prisoner_pod" then
                    entities[ #entities + 1 ] = entity
                end
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

            local function removeEntityFromList( entity )
                for index = #entities, 1, -1 do
                    if entities[ index ] == entity then
                        table_remove( entities, index )
                        break
                    end
                end
            end

            hook_Add( "PlayerEnteredVehicle", addon_name .. " - Kefta podfix", function( _, entity )
                if ENTITY_GetClass( entity ) == "prop_vehicle_prisoner_pod" then
                    entity:RemoveEFlags( EFL_NO_THINK_FUNCTION )
                    removeEntityFromList( entity )
                end
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

            hook_Add( "EntityRemoved", addon_name .. " - prop_vehicle_prisoner_pod", function( entity )
                if ENTITY_GetClass( entity ) == "prop_vehicle_prisoner_pod" then
                    removeEntityFromList( entity )
                end
                ---@diagnostic disable-next-line: redundant-parameter
            end, PRE_HOOK )

            hook_Add( "Think", addon_name .. " - Kefta podfix", function()
                for index = #entities, 1, -1 do
                    local entity = entities[ index ]
                    entities[ index ] = nil

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
                if ENTITY_GetClass( entity ) ~= "prop_vehicle_prisoner_pod" or entity.AcceptDamageForce then return end
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
    "Here For You ♪", "Patched", "Alright", "Thanks for installation <3"
} ) .. "\n" )
