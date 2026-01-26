include( "glua-patches/globals.lua" )

if SERVER then
	AddCSLuaFile( "glua-patches/globals.lua" )
end

local math = math
local math_floor = math.floor
local math_clamp = math.Clamp

local table = table
local table_remove = table.remove
local table_insert = table.insert

local isfunction = isfunction
local isstring = isstring
local isnumber = isnumber
local isbool = isbool

-- this is for addons that think every server only has ulx and supplies numbers for priorities instead of using the constants
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
			else
				return 0
			end
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

	---@class hook.PostReturnPriority : userdata
	POST_HOOK_RETURN = create_proxy( "POST_HOOK_RETURN", 3 )

	---@class hook.PostPriority : userdata
	POST_HOOK = create_proxy( "POST_HOOK", 4 )

end

---@alias hook.Priority hook.PrePriority | hook.PreReturnPriority | hook.NormalPriority | hook.PostReturnPriority | hook.PostPriority

local PRE_HOOK = PRE_HOOK
local PRE_HOOK_RETURN = PRE_HOOK_RETURN
local NORMAL_HOOK = NORMAL_HOOK
local POST_HOOK_RETURN = POST_HOOK_RETURN
local POST_HOOK = POST_HOOK

local hook_priorities = {
	[ PRE_HOOK ] = true,
	[ PRE_HOOK_RETURN ] = true,
	[ NORMAL_HOOK ] = true,
	[ POST_HOOK_RETURN ] = true,
	[ POST_HOOK ] = true
}

local ulx2priorities = {
	[ HOOK_MONITOR_HIGH ] = PRE_HOOK,
	[ HOOK_HIGH ] = PRE_HOOK_RETURN,
	[ HOOK_NORMAL ] = NORMAL_HOOK,
	[ HOOK_LOW ] = POST_HOOK_RETURN,
	[ HOOK_MONITOR_LOW ] = POST_HOOK
}

---@type table<string, table<integer, fun( ... ): any, any, any, any, any, any>>
local normal_functions = {}
---@type table<string, table<integer, fun( ... ): any, any, any, any, any, any>>
local normal_real_functions = {}
---@type table<string, table<integer, boolean>>
local normal_returnless = {}
---@type table<string, table<integer, any>>
local normal_identifiers = {}
---@type table<string, table<integer, hook.Priority>>
local normal_priorities = {}
---@type table<string, integer>
local normal_counts = {}


---@type table<string, table<integer, fun( ... ): any, any, any, any, any, any>>
local post_return_functions = {}
---@type table<string, table<integer, fun( ... ): any, any, any, any, any, any>>
local post_return_real_functions = {}
---@type table<string, table<integer, any>>
local post_return_identifiers = {}
---@type table<string, integer>
local post_return_counts = {}


---@type table<string, table<integer, fun( ... ): any, any, any, any, any, any>>
local post_functions = {}
---@type table<string, table<integer, fun( ... ): any, any, any, any, any, any>>
local post_real_functions = {}
---@type table<string, table<integer, any>>
local post_identifiers = {}
---@type table<string, integer>
local post_counts = {}


---@type table<string, boolean>
local event_exists = {}

module( "hook", package.seeall )

function GetTable()
	local output = {}

	for event_name in pairs( event_exists ) do
		local hooks = {}

		output[ event_name ] = hooks

		local normal_fns = normal_real_functions[ event_name ]
		if normal_fns ~= nil then
			for i = 1, normal_counts[ event_name ], 1 do
				hooks[ normal_identifiers[ event_name ][ i ] ] = normal_fns[ i ]
			end
		end

		local post_return_fns = post_return_real_functions[ event_name ]
		if post_return_fns ~= nil then
			for i = 1, post_return_counts[ event_name ], 1 do
				hooks[ post_return_identifiers[ event_name ][ i ] ] = post_return_fns[ i ]
			end
		end

		local post_fns = post_real_functions[ event_name ]
		if post_fns ~= nil then
			for i = 1, post_counts[ event_name ], 1 do
				hooks[ post_identifiers[ event_name ][ i ] ] = post_fns[ i ]
			end
		end
	end

	return output
end

local in_call = false

local queue, queue_size = {}, 0
local has_changes = false

local function remove( event_name, identifier )
	if not isstring( event_name ) then
		error( "bad argument #1 to 'Remove' (string expected, got " .. type( event_name ) .. ")", 2 )
	end

	if not isstring( identifier ) and ( identifier == nil or isnumber( identifier ) or isbool( identifier ) or isfunction( identifier ) or not isfunction( identifier.IsValid ) ) then
		error( "bad argument #2 to 'Remove' (string expected, got " .. type( identifier ) .. ")", 2 )
	end

	if event_exists[ event_name ] == nil then return end

	if in_call then
		queue_size = queue_size + 1
		queue[ queue_size ] = { false, event_name, identifier }
		has_changes = true
		return
	end

	local normal_count = normal_counts[ event_name ] or 0
	local post_return_count = post_return_counts[ event_name ] or 0
	local post_count = post_counts[ event_name ] or 0

	local normal_identifier_list = normal_identifiers[ event_name ]
	if normal_identifier_list ~= nil then
		for i = normal_count, 1, -1 do
			if normal_identifier_list[ i ] == identifier then
				table_remove( normal_identifier_list, i )
				table_remove( normal_functions[ event_name ], i )
				table_remove( normal_priorities[ event_name ], i )
				table_remove( normal_returnless[ event_name ], i )
				table_remove( normal_real_functions[ event_name ], i )
				normal_count = normal_count - 1
				break
			end
		end
	end

	local post_return_identifier_list = post_return_identifiers[ event_name ]
	if post_return_identifier_list ~= nil then
		for i = post_return_count, 1, -1 do
			if post_return_identifier_list[ i ] == identifier then
				table_remove( post_return_real_functions[ event_name ], i )
				table_remove( post_return_functions[ event_name ], i )
				table_remove( post_return_identifier_list, i )
				post_return_count = post_return_count - 1
				break
			end
		end
	end

	local post_identifier_list = post_identifiers[ event_name ]
	if post_identifier_list ~= nil then
		for i = post_count, 1, -1 do
			if post_identifier_list[ i ] == identifier then
				table_remove( post_real_functions[ event_name ], i )
				table_remove( post_functions[ event_name ], i )
				table_remove( post_identifier_list, i )
				post_count = post_count - 1
				break
			end
		end
	end

	if normal_count == 0 then
		normal_identifiers[ event_name ] = nil
		normal_returnless[ event_name ] = nil
		normal_priorities[ event_name ] = nil
		normal_counts[ event_name ] = nil

		normal_functions[ event_name ] = nil
		normal_real_functions[ event_name ] = nil
	else
		normal_counts[ event_name ] = normal_count
	end

	if post_return_count == 0 then
		post_return_identifiers[ event_name ] = nil
		post_return_counts[ event_name ] = nil

		post_return_functions[ event_name ] = nil
		post_return_real_functions[ event_name ] = nil
	else
		post_return_counts[ event_name ] = post_return_count
	end

	if post_count == 0 then
		post_identifiers[ event_name ] = nil
		post_counts[ event_name ] = nil

		post_functions[ event_name ] = nil
		post_real_functions[ event_name ] = nil
	else
		post_counts[ event_name ] = post_count
	end

	if normal_count == 0 and post_count == 0 and post_return_count == 0 then
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
		error( "bad argument #1 to 'Add' (string expected, got " .. type( event_name ) .. ")", 2 )
	end

	if not isstring( identifier ) and ( identifier == nil or isnumber( identifier ) or isbool( identifier ) or isfunction( identifier ) or not isfunction( identifier.IsValid ) ) then
		error( "bad argument #2 to 'Add' (string expected, got " .. type( identifier ) .. ")", 2 )
	end

	if not isfunction( fn ) then
		error( "bad argument #3 to 'Add' (function expected, got " .. type( fn ) .. ")", 2 )
	end

	if in_call then
		queue_size = queue_size + 1
		queue[ queue_size ] = { true, event_name, identifier, fn, priority }
		has_changes = true
		return
	end

	remove( event_name, identifier )
	local orignal_fn = fn

	if not isstring( identifier ) then
		local is_valid_fn = identifier.IsValid
		local main_fn = fn

		fn = function( ... )
			if is_valid_fn( identifier ) then
				return main_fn( identifier, ... )
			end

			remove( event_name, identifier )
		end
	end

	if isnumber( priority ) then
		---@cast priority integer
		priority = ulx2priorities[ math_clamp( math_floor( priority ), -2, 2 ) ]

		if priority == PRE_HOOK_RETURN then
			local main_fn = fn
			fn = function( ... )
				return main_fn( ... )
			end
		elseif priority == POST_HOOK or priority == POST_HOOK_RETURN then
			local main_fn = fn
			fn = function( _, ... )
				main_fn( ... )
			end
		end
	elseif hook_priorities[ priority ] == nil then
		if priority ~= nil then
			ErrorNoHaltWithStack( "bad argument #4 to 'Add' (priority expected, got " .. type( priority ) .. ")" )
		end

		-- we probably don't want to stop the function here because it's not a critical error
		priority = NORMAL_HOOK
	end

	event_exists[ event_name ] = true

	if priority == POST_HOOK then
		local index = ( post_counts[ event_name ] or 0 ) + 1
		post_counts[ event_name ] = index

		local identifiers = post_identifiers[ event_name ]
		if identifiers == nil then
			identifiers = {}
			post_identifiers[ event_name ] = identifiers
		end

		table_insert( identifiers, index, identifier )

		local fns = post_functions[ event_name ]
		if fns == nil then
			fns = {}
			post_functions[ event_name ] = fns
		end

		table_insert( fns, index, fn )

		local rfns = post_real_functions[ event_name ]
		if rfns == nil then
			rfns = {}
			post_real_functions[ event_name ] = rfns
		end

		table_insert( rfns, index, orignal_fn )
		return
	end

	if priority == POST_HOOK_RETURN then
		local index = ( post_return_counts[ event_name ] or 0 ) + 1
		post_return_counts[ event_name ] = index

		local identifiers = post_return_identifiers[ event_name ]
		if identifiers == nil then
			identifiers = {}
			post_return_identifiers[ event_name ] = identifiers
		end

		table_insert( identifiers, index, identifier )

		local fns = post_return_functions[ event_name ]
		if fns == nil then
			fns = {}
			post_return_functions[ event_name ] = fns
		end

		table_insert( fns, index, fn )

		local rfns = post_return_real_functions[ event_name ]
		if rfns == nil then
			rfns = {}
			post_return_real_functions[ event_name ] = rfns
		end

		table_insert( rfns, index, orignal_fn )
		return
	end

	local priorities = normal_priorities[ event_name ]
	if priorities == nil then
		priorities = {}
		normal_priorities[ event_name ] = priorities
	end

	local count = normal_counts[ event_name ] or 0
	local index = count == 0 and 1 or 0

	for i = 1, count, 1 do
		local value = priorities[ i ]
		if value > priority then
			index = i
			break
		elseif value == priority then
			index = i + 1
			break
		end
	end

	count = count + 1

	if index == 0 then
		index = count
	end

	normal_counts[ event_name ] = count

	table_insert( priorities, index, priority )

	local returnless = normal_returnless[ event_name ]
	if returnless == nil then
		returnless = {}
		normal_returnless[ event_name ] = returnless
	end

	table_insert( returnless, index, priority == PRE_HOOK )

	local identifiers = normal_identifiers[ event_name ]
	if identifiers == nil then
		identifiers = {}
		normal_identifiers[ event_name ] = identifiers
	end

	table_insert( identifiers, index, identifier )

	local fns = normal_functions[ event_name ]
	if fns == nil then
		fns = {}
		normal_functions[ event_name ] = fns
	end

	table_insert( fns, index, fn )

	local rfns = normal_real_functions[ event_name ]
	if rfns == nil then
		rfns = {}
		normal_real_functions[ event_name ] = rfns
	end

	table_insert( rfns, index, orignal_fn )
end

Add = add

local function call( event_name, tbl, ... )
	if event_exists[ event_name ] == nil then
		if tbl == nil then return end

		local fn = tbl[ event_name ]
		if fn == nil then return end

		return fn( tbl, ... )
	end

	in_call = true

	local a, b, c, d, e, f
	local hook_name

	local normal_fns = normal_functions[ event_name ]
	if normal_fns ~= nil then
		local returnless = normal_returnless[ event_name ]
		for index = normal_counts[ event_name ], 1, -1 do
			if returnless[ index ] then
				normal_fns[ index ]( ... )
			else
				local n_a, n_b, n_c, n_d, n_e, n_f = normal_fns[ index ]( ... )
				if n_a ~= nil then
					a, b, c, d, e, f = n_a, n_b, n_c, n_d, n_e, n_f
					hook_name = normal_identifiers[ index ]
					break
				end
			end
		end
	end

	if hook_name == nil and tbl ~= nil then
		local fn = tbl[ event_name ]
		if fn ~= nil then
			a, b, c, d, e, f = fn( tbl, ... )
			hook_name = nil
		end
	end

	local post_return_fns = post_return_functions[ event_name ]
	if post_return_fns ~= nil then
		for index = post_return_counts[ event_name ], 1, -1 do
			local n_a, n_b, n_c, n_d, n_e, n_f = post_return_fns[ index ]( { hook_name, a, b, c, d, e, f }, ... )
			if n_a ~= nil then
				a, b, c, d, e, f = n_a, n_b, n_c, n_d, n_e, n_f
				hook_name = post_return_identifiers[ index ]
			end
		end
	end

	local post_fns = post_functions[ event_name ]
	if post_fns ~= nil then
		local returned_values = { hook_name, a, b, c, d, e, f }

		for index = post_counts[ event_name ], 1, -1 do
			post_fns[ index ]( returned_values, ... )
		end
	end

	in_call = false

	if has_changes then
		has_changes = false

		for i = 1, queue_size, 1 do
			local action = queue[ i ]

			if action[ 1 ] then
				add( action[ 2 ], action[ 3 ], action[ 4 ], action[ 5 ] )
			else
				remove( action[ 2 ], action[ 3 ] )
			end

			queue[ i ] = nil
		end

		queue_size = 0
	end

	return a, b, c, d, e, f
end

Call = call

local gamemode_cache

function Run( name, ... )
	if gamemode_cache == nil then
		gamemode_cache = gmod and gmod.GetGamemode() or nil
	end

	return call( name, gamemode_cache, ... )
end
