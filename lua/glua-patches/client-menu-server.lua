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

    -- ConVar performance
    do

        local Variable_GetBool, Variable_GetString, Variable_IsFlagSet = Variable.GetBool, Variable.GetString, Variable.IsFlagSet
        local util_TableToJSON, util_JSONToTable = util.TableToJSON, util.JSONToTable
        local file_Exists, file_Read, file_Write = file.Exists, file.Read, file.Write
        local file_Delete, file_IsDir, file_CreateDir = file.Delete, file.IsDir, file.CreateDir
        local RunConsoleCommand = RunConsoleCommand
        local GetConVar = GetConVar
        local pairs, next = pairs, next

        local dir_path = "glua_patches"
        local file_path = "glua_patches/cvars.json"

        local convar_list = {
            -- Source default is 0. Valve's own help text: "Use -1 to default to hardware
            -- settings", which is the right call on modern GPUs.
            [ "r_fastzreject" ] = "-1"
        }

        -- Deliberately not included:
        --   studio_queue_mode      - already defaults to 1, forcing it does nothing.
        --   r_queued_ropes         - already defaults to 1, forcing it does nothing.
        --   cl_threaded_bone_setup - part of the multicore set. History of launch crashes, and
        --                            worse on the x86-64 / Chromium beta branch. Not worth it.
        --   r_sse2                 - removed from the game in the September 2026 update.
        --   snd_* / dsp_*          - the September 2026 update blocks the saved ones from Lua.

        ---@type ConVar
        ---@diagnostic disable-next-line: param-type-mismatch
        local gp_cvars_performance = CreateConVar( "gp_cvars_performance", "1", FCVAR_ARCHIVE, "Force a set of client performance convars. Set to 0 to restore your original values." )

        -- Returns the ConVar only if it exists and we are actually allowed to write to it.
        -- The September 2026 update marked more convars as cheats, so this check matters.
        local function GetWritable( name )
            local convar = GetConVar( name )
            if convar == nil then return nil end
            if Variable_IsFlagSet( convar, FCVAR_CHEAT ) then return nil end
            return convar
        end

        local function ReadBackup()
            if not file_Exists( file_path, "DATA" ) then return {} end

            local raw = file_Read( file_path, "DATA" )
            if raw == nil then return {} end

            return util_JSONToTable( raw ) or {}
        end

        local function WriteBackup( saved )
            if next( saved ) == nil then
                file_Delete( file_path )
                return
            end

            if not file_IsDir( dir_path, "DATA" ) then
                file_CreateDir( dir_path )
            end

            file_Write( file_path, util_TableToJSON( saved, true ) )
        end

        -- Only records a convar the first time we touch it. Without this guard a second run
        -- would back up the values we already forced, destroying the user's originals.
        local function Apply()
            local saved, changed = ReadBackup(), false

            for name, value in pairs( convar_list ) do
                local convar = GetWritable( name )

                if convar ~= nil then
                    if saved[ name ] == nil then
                        saved[ name ] = Variable_GetString( convar )
                        changed = true
                    end

                    RunConsoleCommand( name, value )
                end
            end

            if changed then
                WriteBackup( saved )
            end
        end

        local function Restore()
            local saved = ReadBackup()
            if next( saved ) == nil then return end

            for name, value in pairs( saved ) do
                if GetWritable( name ) ~= nil then
                    RunConsoleCommand( name, value )
                end
            end

            file_Delete( file_path )
        end

        local function Refresh()
            if Variable_GetBool( gp_cvars_performance ) then
                Apply()
            else
                Restore()
            end
        end

        -- Initialize runs early, give the console a tick before issuing commands.
        hook.Add( "Initialize", "glua.Patches - ConVar performance", function()
            timer.Simple( 0, Refresh )
            ---@diagnostic disable-next-line: redundant-parameter
        end, PRE_HOOK )

        cvars.AddChangeCallback( "gp_cvars_performance", Refresh, "glua.Patches - ConVar performance" )

        -- Manual escape hatch, if something goes wrong and you want everything back now.
        concommand.Add( "gp_cvars_restore", function()
            Restore()
            RunConsoleCommand( "gp_cvars_performance", "0" )
        end, nil, "Restore the convar values gLua Patches changed." )

    end

end
