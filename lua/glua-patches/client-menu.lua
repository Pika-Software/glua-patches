---@diagnostic disable: duplicate-set-field

local debug_getmetatable = debug.getmetatable or getmetatable
local timer_Create = timer.Create

---@class Panel
local PANEL = FindMetaTable( "Panel" )

---@param value any
---@return boolean
function ispanel( value )
    if not value then return false end

    local metatable = debug_getmetatable( value )
    if metatable == nil then return false end

    return metatable == PANEL or metatable.MetaID == 22
end

do

    local vgui_GetHoveredPanel = vgui.GetHoveredPanel

    local hovered_panel = vgui_GetHoveredPanel()

    ---@return boolean
    function PANEL:IsHovered()
        return hovered_panel == self
    end

    timer_Create( "glua.Patches - Panel.IsHovered", 0.02, 0, function()
        hovered_panel = vgui_GetHoveredPanel()
    end )

end

do

    local gui_IsConsoleVisible = gui.IsConsoleVisible

    local is_visible = gui_IsConsoleVisible()

    timer_Create( "glua.Patches - gui.IsConsoleVisible", 0.25, 0, function()
        is_visible = gui_IsConsoleVisible()
    end )

    ---@return boolean
    function gui.IsConsoleVisible()
        return is_visible
    end

end

do

    local gui_IsGameUIVisible = gui.IsGameUIVisible

    local is_visible = gui_IsGameUIVisible()

    timer_Create( "glua.Patches - gui.IsGameUIVisible", 0.1, 0, function()
        is_visible = gui_IsGameUIVisible()
    end )

    ---@return boolean
    function gui.IsGameUIVisible()
        return is_visible
    end

end

do

    local engine_IsPlayingDemo = engine.IsPlayingDemo

    local is_playing = engine_IsPlayingDemo()

    timer_Create( "glua.Patches - engine.IsPlayingDemo", 0.5, 0, function()
        is_playing = engine_IsPlayingDemo()
    end )

    ---@return boolean
    function engine.IsPlayingDemo()
        return is_playing
    end

end

do

    local engine_IsRecordingDemo = engine.IsRecordingDemo

    local is_recording = engine_IsRecordingDemo()

    timer_Create( "glua.Patches - engine.IsRecordingDemo", 0.25, 0, function()
        is_recording = engine_IsRecordingDemo()
    end )

    ---@return boolean
    function engine.IsRecordingDemo()
        return is_recording
    end

end
