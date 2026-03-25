if glua_patches ~= nil then return end

---@class glua_patches
---@diagnostic disable: duplicate-set-field
---@diagnostic disable-next-line: lowercase-global
glua_patches = glua_patches or {}
glua_patches.Version = "1.20.0"

local bit = bit
local table = table
local coroutine = coroutine

---@diagnostic disable: duplicate-set-field
local debug_getmetatable = debug.getmetatable or getmetatable
local FindMetaTable = FindMetaTable

local math = math
local math_floor = math.floor
local math_random = math.random
local math_min, math_max = math.min, math.max

local tonumber = tonumber
local CurTime = CurTime
local pairs = pairs

MENU = MENU_DLL == true
CLIENT = CLIENT == true and not MENU
SERVER = SERVER == true and not MENU

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

    local system = system

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

        ---@return number
        function system.BatteryPower()
            return battery_power
        end

        timer.Create( "glua.Patches - system.BatteryPower", 1, 0, function()
            battery_power = system_BatteryPower()
        end )

    end

    do

        local system_HasFocus = system.HasFocus

        local has_focus = system_HasFocus()

        ---@return boolean
        function system.HasFocus()
            return has_focus
        end

        timer.Create( "glua.Patches - system.HasFocus", 0.05, 0, function()
            if system_HasFocus() == has_focus then return end
            has_focus = not has_focus
        end )

    end

end

do

    ---@type table<number, number>
    local cache = {}

    setmetatable( cache, {
        __index = function( self, power )
            local value = 10 ^ power
            self[ power ] = value
            return value
        end
    } )

    ---@param value number
    ---@param decimals number
    ---@return number
    function math.Round( value, decimals )
        if decimals then
            local mult = cache[ decimals ]
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

    local bit_lshift = bit.lshift

    ---@param x number
    ---@param shift number
    ---@return integer
    function bit.lshift( x, shift )
        return shift > 31 and 0x0 or bit_lshift( x, shift )
    end

end

do

    local bit_rshift = bit.rshift

    ---@param x number
    ---@param shift number
    ---@return integer
    function bit.rshift( x, shift )
        return shift > 31 and 0x0 or bit_rshift( x, shift )
    end

end

do

    local coroutine_yield = coroutine.yield

    ---@param seconds number
    function coroutine.wait( seconds )
        local end_time = CurTime() + seconds
        while true do
            if end_time < CurTime() then return end
            coroutine_yield()
        end
    end

end

do

    local GetConVar_Internal = GetConVar_Internal

    ---@type table<string, ConVar>
    local cache = {}

    setmetatable( cache, {
        __index = function( self, name )
            local value = GetConVar_Internal( name )
            if value == nil then return nil end
            self[ name ] = value
            return value
        end
    } )

    ---@param name string
    ---@return ConVar | nil
    function GetConVar( name )
        return cache[ name ]
    end

end

do

    ---@param low number
    ---@param high number
    ---@return number
    local function math_Rand( low, high )
        return low + ( high - low ) * math_random()
    end

    math.Rand = math_Rand

    do

        local Vector = Vector

        ---@param min number
        ---@param max number
        ---@return Vector
        function VectorRand( min, max )
            min, max = min or -1, max or 1
            return Vector( math_Rand( min, max ), math_Rand( min, max ), math_Rand( min, max ) )
        end

    end

    do

        local Angle = Angle

        ---@param min number
        ---@param max number
        ---@return Angle
        function AngleRand( min, max )
            return Angle( math_Rand( min or -90, max or 90 ), math_Rand( min or -180, max or 180 ), math_Rand( min or -180, max or 180 ) )
        end

    end

end

do

    local string_match = string.match

    ---@param str string
    ---@return string
    function util.SteamIDTo64( str )
        local x, y, z = string_match( str, "STEAM_([0-5]):([01]):(%d+)" )
        return x == nil and "0" or ( "765" .. ( ( tonumber( z, 10 ) * 2 ) + 61197960265728 ) + ( y == "1" and 1 or 0 ) )
    end

end

do

    local string_sub = string.sub

    ---@param str string
    ---@return string
    function util.SteamIDFrom64( str )
        local account_id = math_max( 0, ( tonumber( string_sub( str, 4 ), 10 ) or 0 ) - 61197960265728 )
        return "STEAM_0:" .. ( account_id % 2 == 0 and "0" or "1" ) .. ":" .. math_floor( account_id * 0.5 )
    end

end

do

    local debug_setmetatable = debug.setmetatable

    do

        local object = 0

        local metatable = debug_getmetatable( object ) or {}
        debug_setmetatable( object, metatable )

        ---@param value any
        ---@return boolean
        function isnumber( value )
            return debug_getmetatable( value ) == metatable
        end

    end

    do

        local object = ""

        local metatable = debug_getmetatable( object ) or {}
        debug_setmetatable( object, metatable )

        ---@param value any
        ---@return boolean
        function isstring( value )
            return debug_getmetatable( value ) == metatable
        end

    end

    do

        local object = true

        local metatable = debug_getmetatable( object ) or {}
        debug_setmetatable( object, metatable )

        ---@param value any
        ---@return boolean
        function isbool( value )
            return debug_getmetatable( value ) == metatable
        end

    end

    do

        local object = function() end

        local metatable = debug_getmetatable( object ) or {}
        debug_setmetatable( object, metatable )

        ---@param value any
        ---@return boolean
        function isfunction( value )
            return debug_getmetatable( value ) == metatable
        end

    end

end

do

    ---@class Angle
    local ANGLE = FindMetaTable( "Angle" )

    ---@param value any
    ---@return boolean
    function isangle( value )
        return debug_getmetatable( value ) == ANGLE
    end

end

do

    ---@class Vector
    local VECTOR = FindMetaTable( "Vector" )

    ---@param value any
    ---@return boolean
    function isvector( value )
        return debug_getmetatable( value ) == VECTOR
    end

end

do

    ---@class VMatrix
    local VMATRIX = FindMetaTable( "VMatrix" )

    ---@param value any
    ---@return boolean
    function ismatrix( value )
        return debug_getmetatable( value ) == VMATRIX
    end

end
