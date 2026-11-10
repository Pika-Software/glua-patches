include( "glua-patches/globals.lua" )

if SERVER then
    AddCSLuaFile( "glua-patches/globals.lua" )
end

local math_floor = math.floor
local math_clamp = math.Clamp

local string_gsub = string.gsub
local table_concat = table.concat
local string_format = string.format

local debug_traceback = debug.traceback

local isbool = isbool
local isnumber = isnumber
local isstring = isstring
local isfunction = isfunction

local type = type
local error = error
local pairs = pairs
local pcall = pcall
local xpcall = xpcall
local select = select
local tostring = tostring
local ErrorNoHalt = ErrorNoHalt
local ErrorNoHaltWithStack = ErrorNoHaltWithStack
local CompileString = CompileString or loadstring

local function traceback_handler( err )
    return debug_traceback( err, 2 )
end

---@param event_name string
---@param identifier any
---@param err any
local function report_error( event_name, identifier, err )
    ErrorNoHalt( string_format( "[ERROR] hook '%s' -> '%s' failed: %s\n", event_name, tostring( identifier ), tostring( err ) ) )
end

local function index_is_valid( identifier )
    return identifier.IsValid
end

---@param identifier any
---@return boolean
local function is_valid_identifier( identifier )
    if isstring( identifier ) then
        return true
    end

    if isnumber( identifier ) then
        -- NaN can't be used as a table key
        return identifier == identifier
    end

    if identifier == nil or isbool( identifier ) or isfunction( identifier ) then
        return false
    end

    -- pcall: indexing threads or userdata without __index throws
    local ok, is_valid = pcall( index_is_valid, identifier )
    return ok and isfunction( is_valid )
end

local function noop() end

HOOK_MONITOR_HIGH = -2
HOOK_HIGH = -1
HOOK_NORMAL = 0
HOOK_LOW = 1
HOOK_MONITOR_LOW = 2

do

    ---@type table<userdata, string>
    local names = {}

    ---@type table<userdata, integer>
    local values = {}

    setmetatable( values, {
        __index = function( self, key )
            if isnumber( key ) then
                return key
            end

            return 0
        end
    } )

    local base = newproxy( true )

    local metatable = getmetatable( base )
    metatable.__index = metatable

    ---@private
    function metatable:__tostring()
        return names[ self ]
    end

    ---@private
    function metatable:__eq( other )
        return values[ self ] == values[ other ]
    end

    ---@private
    function metatable:__lt( other )
        return values[ self ] < values[ other ]
    end

    ---@private
    function metatable:__le( other )
        return values[ self ] <= values[ other ]
    end

    local function create_proxy( name, value )
        local proxy = newproxy( base )
        values[ proxy ] = value
        names[ proxy ] = name
        return proxy
    end

    ---@class hook.PrePriority : userdata
    PRE_HOOK = create_proxy( "PRE_HOOK", -4 )

    ---@class hook.PreReturnPriority : userdata
    PRE_HOOK_RETURN = create_proxy( "PRE_HOOK_RETURN", -3 )

    ---@class hook.NormalPriority : userdata
    NORMAL_HOOK = create_proxy( "NORMAL_HOOK", 0 )

    --- Runs after NORMAL_HOOK but before the gamemode; can return values (ULib's HOOK_LOW).
    ---@class hook.LowPriority : userdata
    LOW_HOOK = create_proxy( "LOW_HOOK", 1 )

    ---@class hook.PostReturnPriority : userdata
    POST_HOOK_RETURN = create_proxy( "POST_HOOK_RETURN", 3 )

    ---@class hook.PostPriority : userdata
    POST_HOOK = create_proxy( "POST_HOOK", 4 )

end

---@alias hook.Priority hook.PrePriority | hook.PreReturnPriority | hook.NormalPriority | hook.LowPriority | hook.PostReturnPriority | hook.PostPriority

local PRE_HOOK = PRE_HOOK
local PRE_HOOK_RETURN = PRE_HOOK_RETURN
local NORMAL_HOOK = NORMAL_HOOK
local LOW_HOOK = LOW_HOOK
local POST_HOOK_RETURN = POST_HOOK_RETURN
local POST_HOOK = POST_HOOK

---@type table<hook.Priority, boolean>
local hook_priorities = {
    [ PRE_HOOK ] = true,
    [ PRE_HOOK_RETURN ] = true,
    [ NORMAL_HOOK ] = true,
    [ LOW_HOOK ] = true,
    [ POST_HOOK_RETURN ] = true,
    [ POST_HOOK ] = true
}

---@type table<integer, hook.Priority>
local ulx2priorities = {
    [ HOOK_MONITOR_HIGH ] = PRE_HOOK,
    [ HOOK_HIGH ] = PRE_HOOK_RETURN,
    [ HOOK_NORMAL ] = NORMAL_HOOK,
    [ HOOK_LOW ] = LOW_HOOK,
    [ HOOK_MONITOR_LOW ] = POST_HOOK
}

---@type table<hook.Priority, integer>
local priority2ulx = {
    [ PRE_HOOK ] = HOOK_MONITOR_HIGH,
    [ PRE_HOOK_RETURN ] = HOOK_HIGH,
    [ NORMAL_HOOK ] = HOOK_NORMAL,
    [ LOW_HOOK ] = HOOK_LOW,
    [ POST_HOOK_RETURN ] = HOOK_LOW,
    [ POST_HOOK ] = HOOK_MONITOR_LOW
}

--[[

    Hook lists are immutable snapshots (copy-on-write): `add` / `remove` always build
    a new list and swap it in. A `call` that is already iterating keeps its own snapshot,
    so changes can be applied immediately without any deferred queue.

    A list is an array of entries with the count in `[0]` (array part in LuaJIT, cheaper than a hash key), iterated from `[0]` down to 1.
    Entries are never modified after creation, except `[1]` being replaced with `noop` on removal,
    which only affects in-progress iterations of old snapshots (new lists don't contain the entry).

--]]

---@class hook.Entry
---@field [1] function function that is actually called (may be a wrapper)
---@field [2] function original function passed to `hook.Add`
---@field [3] any identifier
---@field [4] hook.Priority
---@field [5] boolean returnless

---@class hook.List
---@field [0] integer number of entries
---@field [integer] hook.Entry

---@param list hook.List
---@return integer?
local function list_find( list, identifier )
    for i = 1, list[ 0 ], 1 do
        if list[ i ][ 3 ] == identifier then
            return i
        end
    end
end

---@param list hook.List
---@return hook.List? new_list `nil` if the list became empty
local function list_remove( list, index )
    -- the old snapshot may still be iterated by an in-progress `call`, make sure it won't run the removed hook
    list[ index ][ 1 ] = noop

    local n = list[ 0 ]
    if n == 1 then return nil end

    ---@type hook.List
    local new = { [ 0 ] = n - 1 }

    for i = 1, index - 1, 1 do
        new[ i ] = list[ i ]
    end

    for i = index + 1, n, 1 do
        new[ i - 1 ] = list[ i ]
    end

    return new
end

---@param list hook.List?
---@param entry hook.Entry
---@return hook.List
local function list_insert( list, index, entry )
    if list == nil then
        return { [ 0 ] = 1, entry }
    end

    local n = list[ 0 ]

    ---@type hook.List
    local new = {
        [ 0 ] = n + 1,
    }

    for i = 1, index - 1, 1 do
        new[ i ] = list[ i ]
    end

    new[ index ] = entry

    for i = index, n, 1 do
        new[ i + 1 ] = list[ i ]
    end

    return new
end

---@type table<string, hook.List>
local normal_lists = {}

---@type table<string, hook.List>
local post_return_lists = {}

---@type table<string, hook.List>
local post_lists = {}

---@type table<string, boolean>
local event_exists = {}

---@type table?
local table_cache

--[[

    `hook.Call` implementation.

    LuaJIT can't compile a loop that forwards `...` (NYI: bytecode VARG), which would keep
    the whole hook loop in the interpreter. So the body is generated once per argument count
    with named parameters, and `call` dispatches on `select( "#", ... )`. The exact argument
    count is preserved, so `select( "#", ... )` inside hooks behaves as usual.
    Versions are compiled lazily (on the first call with that argument count) by `fixed_calls.__index`.
    Calls with more than `MAX_FIXED_ARGS` arguments use the vararg version.

    `$ARGS` is replaced with the parameter list prefixed by ", " (or nothing for zero arguments).

--]]

local call_template = [==[
local event_exists, normal_lists, post_return_lists, post_lists, xpcall, traceback_handler, report_error = ...

return function( event_name, tbl$ARGS )
    if event_exists[ event_name ] == nil then
        -- like stock, `false` also means "no gamemode table"
        if not tbl then return end

        local fn = tbl[ event_name ]
        if fn == nil then return end

        local ok, a, b, c, d, e, f = xpcall( fn, traceback_handler, tbl$ARGS )
        if ok then
            return a, b, c, d, e, f
        end

        report_error( event_name, "GAMEMODE", a )
        return
    end

    local a, b, c, d, e, f

    -- identifier of the hook whose values are returned, the gamemode table if it was the gamemode, `nil` if nothing returned
    local hook_name

    local list = normal_lists[ event_name ]
    if list ~= nil then
        for index = list[ 0 ], 1, -1 do
            local entry = list[ index ]
            local ok, n_a, n_b, n_c, n_d, n_e, n_f = xpcall( entry[ 1 ], traceback_handler$ARGS )
            if not ok then
                report_error( event_name, entry[ 3 ], n_a )
            elseif n_a ~= nil and not entry[ 5 ] then
                a, b, c, d, e, f = n_a, n_b, n_c, n_d, n_e, n_f
                hook_name = entry[ 3 ]
                break
            end
        end
    end

    if hook_name == nil and tbl then
        local fn = tbl[ event_name ]
        if fn ~= nil then
            local ok, n_a, n_b, n_c, n_d, n_e, n_f = xpcall( fn, traceback_handler, tbl$ARGS )
            if ok then
                a, b, c, d, e, f = n_a, n_b, n_c, n_d, n_e, n_f

                if n_a ~= nil then
                    hook_name = tbl
                end
            else
                report_error( event_name, "GAMEMODE", n_a )
            end
        end
    end

    -- allocated per call: a shared table would leak values between events and nested calls
    local returned_values

    list = post_return_lists[ event_name ]
    if list ~= nil then
        returned_values = { hook_name, a, b, c, d, e, f }

        for index = list[ 0 ], 1, -1 do
            local entry = list[ index ]
            local ok, n_a, n_b, n_c, n_d, n_e, n_f = xpcall( entry[ 1 ], traceback_handler, returned_values$ARGS )
            if not ok then
                report_error( event_name, entry[ 3 ], n_a )
            elseif n_a ~= nil then
                a, b, c, d, e, f = n_a, n_b, n_c, n_d, n_e, n_f
                hook_name = entry[ 3 ]
            end

            -- sync every iteration, a hook may have modified the table
            returned_values[ 1 ], returned_values[ 2 ], returned_values[ 3 ], returned_values[ 4 ],
            returned_values[ 5 ], returned_values[ 6 ], returned_values[ 7 ] = hook_name, a, b, c, d, e, f
        end
    end

    list = post_lists[ event_name ]
    if list ~= nil then
        if returned_values == nil then
            returned_values = { hook_name, a, b, c, d, e, f }
        end

        for index = list[ 0 ], 1, -1 do
            local entry = list[ index ]
            local ok, err = xpcall( entry[ 1 ], traceback_handler, returned_values$ARGS )
            if not ok then
                report_error( event_name, entry[ 3 ], err )
            end
        end
    end

    return a, b, c, d, e, f
end
]==]

-- Each parameter takes a local slot and a stack slot; LuaJIT allows 200 locals / 250 slots per function.
-- The current template compiles up to 114 parameters, keep a margin for future template changes.
local MAX_FIXED_ARGS = 100

---@param args string
---@param chunk_name string
---@return function
local function compile_call( args, chunk_name )
    local code = string_gsub( call_template, "%$ARGS", args )

    local factory = CompileString( code, chunk_name )
    if not isfunction( factory ) then
        error( "failed to compile " .. chunk_name .. ": " .. tostring( factory ) )
    end

    ---@cast factory function
    return factory( event_exists, normal_lists, post_return_lists, post_lists, xpcall, traceback_handler, report_error )
end

-- Compiled eagerly: `call` isn't installed as `hook.Call` yet, so anything `CompileString` triggers can't reach it.
local vararg_call = compile_call( ", ...", "includes/modules/hook.lua (call/...)" )

--- `CompileString` can itself run hooks (engine / binary modules), which would re-enter
--- `fixed_calls.__index` for the same argument count and recurse until stack overflow.
local compiling = false

---@param count integer
---@return function
local function compile_fixed_call( count )
    local args = ""

    if count ~= 0 then
        local params = {}

        for i = 1, count, 1 do
            params[ i ] = "p" .. i
        end

        args = ", " .. table_concat( params, ", " )
    end

    return compile_call( args, "includes/modules/hook.lua (call/" .. count .. ")" )
end

--- Argument count -> `call` implementation, compiled on first use and cached.
---@type table<integer, function>
local fixed_calls = {}

setmetatable( fixed_calls, {
    __index = function( self, count )
        if count > MAX_FIXED_ARGS then
            self[ count ] = vararg_call
            return vararg_call
        end

        -- re-entered from a hook run by `CompileString`: serve this call with the vararg version, don't cache it
        if compiling then
            return vararg_call
        end

        compiling = true
        local ok, fn = pcall( compile_fixed_call, count )
        compiling = false

        if not ok then
            -- keep hook.Call working; the error is reported once, then the vararg version is cached for this count
            ErrorNoHaltWithStack( "hook: failed to compile call/" .. count .. ": " .. tostring( fn ) )
            fn = vararg_call
        end

        self[ count ] = fn
        return fn
    end
} )

local function call( event_name, tbl, ... )
    return fixed_calls[ select( "#", ... ) ]( event_name, tbl, ... )
end

module( "hook", package.seeall )

local function fill_hooks( hooks, list )
    if list == nil then return end

    for i = 1, list[ 0 ], 1 do
        local entry = list[ i ]
        hooks[ entry[ 3 ] ] = entry[ 2 ]
    end
end

--- Returns a cached table; it is rebuilt whenever hooks change.
--- Modifying the returned table does not affect registered hooks.
function GetTable()
    if table_cache ~= nil then
        return table_cache
    end

    local output = {}

    for event_name in pairs( event_exists ) do
        local hooks = {}
        fill_hooks( hooks, normal_lists[ event_name ] )
        fill_hooks( hooks, post_return_lists[ event_name ] )
        fill_hooks( hooks, post_lists[ event_name ] )
        output[ event_name ] = hooks
    end

    table_cache = output
    return output
end

---@param lists table<string, hook.List>
---@return boolean removed
local function remove_from( lists, event_name, identifier )
    local list = lists[ event_name ]
    if list == nil then return false end

    local index = list_find( list, identifier )
    if index == nil then return false end

    lists[ event_name ] = list_remove( list, index )
    return true
end

local function remove( event_name, identifier )
    if not isstring( event_name ) then
        ErrorNoHaltWithStack( "bad argument #1 to 'Remove' (string expected, got " .. type( event_name ) .. ")" )
        return
    end

    if identifier == nil or event_exists[ event_name ] == nil then return end

    local removed = remove_from( normal_lists, event_name, identifier )
    removed = remove_from( post_return_lists, event_name, identifier ) or removed
    removed = remove_from( post_lists, event_name, identifier ) or removed

    if not removed then return end

    table_cache = nil

    if normal_lists[ event_name ] == nil and post_return_lists[ event_name ] == nil and post_lists[ event_name ] == nil then
        event_exists[ event_name ] = nil
    end
end

Remove = remove

---@param event_name string
---@param identifier any
---@param fn function
---@param priority? integer | hook.Priority
local function add( event_name, identifier, fn, priority )
    if not isstring( event_name ) then
        ErrorNoHaltWithStack( "bad argument #1 to 'Add' (string expected, got " .. type( event_name ) .. ")" )
        return
    end

    if not isfunction( fn ) then
        ErrorNoHaltWithStack( "bad argument #3 to 'Add' (function expected, got " .. type( fn ) .. ")" )
        return
    end

    if not is_valid_identifier( identifier ) then
        ErrorNoHaltWithStack( "bad argument #2 to 'Add' (string, number or object with IsValid expected, got " .. type( identifier ) .. ")" )
        return
    end

    remove( event_name, identifier )

    local real_fn = fn

    if not isstring( identifier ) and not isnumber( identifier ) then
        local main_fn = fn

        fn = function( ... )
            local is_valid = identifier.IsValid
            if is_valid ~= nil and is_valid( identifier ) then
                return main_fn( identifier, ... )
            end

            remove( event_name, identifier )
        end
    end

    ---@type hook.Priority
    local hook_priority

    if isnumber( priority ) then
        ---@cast priority number
        if priority ~= priority then
            -- NaN, math.Clamp would turn it into -2
            hook_priority = NORMAL_HOOK
        else
            hook_priority = ulx2priorities[ math_clamp( math_floor( priority ), -2, 2 ) ] or NORMAL_HOOK
        end

        if hook_priority == POST_HOOK then
            -- ULib monitor hooks don't know about the returned values argument
            local main_fn = fn
            fn = function( _, ... )
                main_fn( ... )
            end
        end
    elseif priority ~= nil and hook_priorities[ priority ] then
        ---@cast priority hook.Priority
        hook_priority = priority
    else
        if priority ~= nil then
            ErrorNoHaltWithStack( "bad argument #4 to 'Add' (priority expected, got " .. type( priority ) .. ")" )
        end

        -- we probably don't want to stop the function here because it's not a critical error
        hook_priority = NORMAL_HOOK
    end

    event_exists[ event_name ] = true
    table_cache = nil

    ---@type hook.Entry
    local entry = {
        fn, real_fn, identifier,
        hook_priority, hook_priority == PRE_HOOK or hook_priority == POST_HOOK,
    }

    if hook_priority == POST_HOOK then
        local list = post_lists[ event_name ]
        post_lists[ event_name ] = list_insert( list, (list == nil and 0 or list[ 0 ]) + 1, entry )
        return
    end

    if hook_priority == POST_HOOK_RETURN then
        local list = post_return_lists[ event_name ]
        post_return_lists[ event_name ] = list_insert( list, (list == nil and 0 or list[ 0 ]) + 1, entry )
        return
    end

    local list = normal_lists[ event_name ]
    local index = 1

    if list ~= nil then
        index = list[ 0 ] + 1

        -- Descending priority values at low indices (iterated backwards, so lower values run first);
        -- the newest hook of equal priority goes after the others, so it runs first.
        for i = 1, list[ 0 ], 1 do
            if list[ i ][ 4 ] < hook_priority then
                index = i
                break
            end
        end
    end

    normal_lists[ event_name ] = list_insert( list, index, entry )
end

Add = add

Call = call

local function debug_list( name, lists )
    print( "\n" .. name .. ":" )

    for event_name, list in pairs( lists ) do
        print( "  " .. event_name .. ":" )

        for i = list[ 0 ], 1, -1 do
            local entry = list[ i ]
            print( "    " .. tostring( entry[ 3 ] ) .. " (" .. tostring( entry[ 4 ] ) .. ")" )
        end
    end
end

--- Prints hooks in execution order.
function Debug()
    debug_list( "normal", normal_lists )
    debug_list( "post_return", post_return_lists )
    debug_list( "post", post_lists )
end

function Run( name, ... )
    -- `Call` is looked up from the module table, so detours of `hook.Call` are respected
    return Call( name, gmod and gmod.GetGamemode() or nil, ... )
end

if file.Exists( "ulib/shared/hook.lua", "LUA" ) then

    function GetULibTable()
        local output = {}

        for event_name in pairs( event_exists ) do
            local hooks = {
                [ HOOK_MONITOR_HIGH ] = {},
                [ HOOK_HIGH ] = {},
                [ HOOK_NORMAL ] = {},
                [ HOOK_LOW ] = {},
                [ HOOK_MONITOR_LOW ] = {},
            }

            for _, lists in pairs( { normal_lists, post_return_lists, post_lists } ) do
                local list = lists[ event_name ]
                if list ~= nil then
                    for i = 1, list[ 0 ], 1 do
                        local entry = list[ i ]
                        hooks[ priority2ulx[ entry[ 4 ] ] or HOOK_NORMAL ][ entry[ 3 ] ] = entry[ 2 ]
                    end
                end
            end

            output[ event_name ] = hooks
        end

        return output
    end

end
