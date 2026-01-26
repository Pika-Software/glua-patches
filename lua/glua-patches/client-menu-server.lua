---@diagnostic disable: duplicate-set-field

---@class ConVar
local Variable = FindMetaTable( "ConVar" )

local debug_getmetatable = debug.getmetatable or getmetatable
local setmetatable = setmetatable
local tonumber = tonumber
local CurTime = CurTime

local math = math
local math_random = math.random
local math_min, math_max = math.min, math.max

local bit = bit
local bit_bnot = bit.bnot
local bit_band = bit.band

do

    local metatable = debug_getmetatable( "" )

    do

        local string_sub = string.sub

        ---@private
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

    end

end

do

    local engine = engine
    local engine_GetGames = engine.GetGames
    local engine_GetAddons = engine.GetAddons

    local addons, games = engine_GetAddons(), engine_GetGames()
    local addon_count, game_count = #addons, #games

    hook.Add( "GameContentChanged", "glua.Patches - engine.GetAddons", function()
        addons, games = engine_GetAddons(), engine_GetGames()
        addon_count, game_count = #addons, #games

        ---@diagnostic disable-next-line: redundant-parameter
    end, PRE_HOOK )

    ---@return table[]
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

    ---@return table[]
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

    ---@class Color
    local COLOR = FindMetaTable( "Color" )
    local Lerp = Lerp

    ---@param value any
    ---@return boolean
    function IsColor( value )
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

    Color = color

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

    ---@param col Color
    ---@param frac number
    ---@return Color
    ---@diagnostic disable-next-line: duplicate-set-field
    function COLOR:Lerp( col, frac )
        return color(
            Lerp( frac, self.r, col.r ),
            Lerp( frac, self.g, col.g ),
            Lerp( frac, self.b, col.b ),
            Lerp( frac, self.a, col.a )
        )
    end

end

if CLIENT then

    local system_HasFocus = system.HasFocus

    -- No more mouse lock
    do

        local gui_IsGameUIVisible, gui_ActivateGameUI = gui.IsGameUIVisible, gui.ActivateGameUI
        local vgui_CursorVisible = vgui.CursorVisible
        local Variable_GetBool = Variable.GetBool

        ---@type ConVar
        ---@diagnostic disable-next-line: param-type-mismatch
        local gp_no_more_mouse_lock = CreateConVar( "gp_no_more_mouse_lock", "1", FCVAR_ARCHIVE, "Automatically open the pause menu when the game loses focus." )

        hook.Add( "Tick", "glua.Patches - No more mouse lock", function()
            if system_HasFocus() or not Variable_GetBool( gp_no_more_mouse_lock ) or vgui_CursorVisible() or gui_IsGameUIVisible() then return end
            gui_ActivateGameUI()
        end )

    end

    -- No more fake attacks
    do

        local last_no_focus_time = 0

        hook.Add( "CreateMove", "glua.Patches - No more fake attacks", function( cmd )
            if ( CurTime() - last_no_focus_time ) < 0.25 then
                local in_keys = cmd:GetButtons()

                if bit_band( in_keys, 1 ) ~= 0 then
                    in_keys = bit_band( in_keys, bit_bnot( 1 ) )
                end

                if bit_band( in_keys, 2048 ) ~= 0 then
                    in_keys = bit_band( in_keys, bit_bnot( 2048 ) )
                end

                cmd:SetButtons( in_keys )
            end

            if system_HasFocus() then return end
            last_no_focus_time = CurTime()

            ---@diagnostic disable-next-line: redundant-parameter
        end, PRE_HOOK )

    end

end
