---@diagnostic disable-next-line: undefined-global
local _G = _G

local surface_SetDrawColor, surface_SetMaterial, surface_DrawTexturedRectUV
do
    local surface = _G.surface
    surface_SetDrawColor, surface_SetMaterial, surface_DrawTexturedRectUV = surface.SetDrawColor, surface.SetMaterial, surface.DrawTexturedRectUV
end

local GWEN = {}
_G.GWEN = GWEN

do

    local math_min, math_ceil, math_floor
    do
        local math = _G.math
        math_min, math_ceil, math_floor = math.min, math.ceil, math.floor
    end

    function GWEN.CreateTextureBorder( _xo, _yo, _wo, _ho, l, t, r, b, material_override )
        ---@diagnostic disable-next-line: undefined-field
        local material = SKIN and SKIN.GwenTexture or material_override
        if material_override and not material_override:IsError() then
            material = material_override
        end

        local texture = material:GetTexture( "$basetexture" )
        local width, height = texture:Width(), texture:Height()

        local _x, _y, _w, _h = _xo / width, _yo / height, _wo / width, _ho / height

        local left, right, top, bottom = 0, 0, 0, 0
        local _l, _t, _r, _b = 0, 0, 0, 0

        return function( x, y, w, h, color )
            if color == nil then
                surface_SetDrawColor( 255, 255, 255, 255 )
            else
                surface_SetDrawColor( color )
            end

            surface_SetMaterial( material )

            left, right, top, bottom = math_min( l, math_ceil( w * 0.5 ) ), math_min( r, math_floor( w * 0.5 ) ), math_min( t, math_ceil( h * 0.5 ) ), math_min( b, math_floor( h * 0.5 ) )
            _l, _t, _r, _b = left / width, top / height, right / width, bottom / height

            surface_DrawTexturedRectUV( x, y, left, top, _x, _y, _x + _l, _y + _t )
            surface_DrawTexturedRectUV( x + left, y, w - left - right, top, _x + _l, _y, _x + _w - _r, _y + _t )
            surface_DrawTexturedRectUV( x + w - right, y, right, top, _x + _w - _r, _y, _x + _w, _y + _t )
            surface_DrawTexturedRectUV( x, y + top, left, h - top - bottom, _x, _y + _t, _x + _l, _y + _h - _b )
            surface_DrawTexturedRectUV( x + left, y + top, w - left - right, h - top - bottom, _x + _l, _y + _t, _x + _w - _r, _y + _h - _b )
            surface_DrawTexturedRectUV( x + w - right, y + top, right, h - top - bottom, _x + _w - _r, _y + _t, _x + _w, _y + _h - _b )
            surface_DrawTexturedRectUV( x, y + h - bottom, left, bottom, _x, _y + _h - _b, _x + _l, _y + _h )
            surface_DrawTexturedRectUV( x + left, y + h - bottom, w - left - right, bottom, _x + _l, _y + _h - _b, _x + _w - _r, _y + _h )

            return surface_DrawTexturedRectUV( x + w - right, y + h - bottom, right, bottom, _x + _w - _r, _y + _h - _b, _x + _w, _y + _h )
        end
    end

end

function GWEN.CreateTextureNormal( _xo, _yo, _wo, _ho, material_override )
    ---@diagnostic disable-next-line: undefined-field
    local material = SKIN and SKIN.GwenTexture or material_override
    if material_override and not material_override:IsError() then
        material = material_override
    end

    local texture = material:GetTexture( "$basetexture" )
    local width, height = texture:Width(), texture:Height()

    local _x, _y, _w, _h = _xo / width, _yo / height, _wo / width, _ho / height

    return function( x, y, w, h, color )
        if color == nil then
            surface_SetDrawColor( 255, 255, 255, 255 )
        else
            surface_SetDrawColor( color )
        end

        surface_SetMaterial( material )
        return surface_DrawTexturedRectUV( x, y, w, h, _x, _y, _x + _w, _y + _h )
    end

end

function GWEN.CreateTextureCentered( _xo, _yo, _wo, _ho, material_override )
    ---@diagnostic disable-next-line: undefined-field
    local material = SKIN and SKIN.GwenTexture or material_override
    if material_override and not material_override:IsError() then
        material = material_override
    end

    local texture = material:GetTexture( "$basetexture" )
    local width, height = texture:Width(), texture:Height()

    local _x, _y, _w, _h = _xo / width, _yo / height, _wo / width, _ho / height

    return function( x, y, w, h, color )
        if color == nil then
            surface_SetDrawColor( 255, 255, 255, 255 )
        else
            surface_SetDrawColor( color )
        end

        surface_SetMaterial( material )

        x = x + ( ( w - _wo ) * 0.5 )
        y = y + ( ( h - _ho ) * 0.5 )

        return surface_DrawTexturedRectUV( x, y, _wo, _ho, _x, _y, _x + _w, _y + _h )
    end

end

do

    local GetColor = FindMetaTable( "IMaterial" ).GetColor

    function GWEN.TextureColor( x, y, material_override )
        ---@diagnostic disable-next-line: undefined-field
        local material = SKIN and SKIN.GwenTexture or material_override
        if material_override and not material_override:IsError() then
            material = material_override
        end

        return GetColor( material, x, y )
    end

end

---@class Panel
local PANEL = FindMetaTable( "Panel" )

do

    local SetMultiline, Add = PANEL.SetMultiline, PANEL.Add
    local pairs = _G.pairs

    local types = {
        Base = "Panel",
        Button = "DButton",
        Label = "DLabel",
        TextBox = "DTextEntry",
        TextBoxMultiline = "DTextEntry",
        ComboBox = "DComboBox",
        HorizontalSlider = "Slider",
        ImagePanel = "DImage",
        CheckBoxWithLabel = "DCheckBoxLabel"
    }

    local function applyGWEN( self, tbl )
        if tbl.Type == "TextBoxMultiline" then
            SetMultiline( self, true )
        end

        for key, value in pairs( tbl.Properties ) do
            if self[ "GWEN_Set" .. key ] ~= nil then
                self[ "GWEN_Set" .. key ]( self, value )
            end
        end

        if not tbl.Children then
            return
        end

        for _, value in pairs( tbl.Children ) do
            if types[ value.Type ] ~= nil then
                applyGWEN( Add( self, types[ value.Type ] ), value )
            else
                MsgN( "Warning: No GWEN Panel Type ", value.Type )
            end
        end
    end

    PANEL.ApplyGWEN = applyGWEN

    local function loadGWENString( self, json )
        local tbl = util.JSONToTable( json )
        if tbl ~= nil and tbl.Controls ~= nil then
            return applyGWEN( self, tbl.Controls )
        end
    end

    PANEL.LoadGWENString = loadGWENString

    function PANEL:LoadGWENFile( filePath, gamePath )
        local json = file.Read( filePath, gamePath or "GAME" )
        return json == nil and nil or loadGWENString( self, json )
    end

end

do

    local SetPos = PANEL.SetPos

    function PANEL:GWEN_SetPosition( tbl )
        return SetPos( self, tbl.x, tbl.y )
    end

end

do

    local SetSize = PANEL.SetSize

    function PANEL:GWEN_SetSize( tbl )
        return SetSize( self, tbl.w, tbl.h )
    end

end

do

    local SetText = PANEL.SetText

    function PANEL:GWEN_SetText( text )
        return SetText( self, text )
    end

end

do

    local SetName = PANEL.SetName

    function PANEL:GWEN_SetControlName( name )
        return SetName( self, name )
    end

end

do

    local DockMargin = PANEL.DockMargin

    function PANEL:GWEN_SetMargin( tbl )
        return DockMargin( self, tbl.left, tbl.top, tbl.right, tbl.bottom )
    end

end

do

    local tonumber = _G.tonumber

    do

        ---@diagnostic disable-next-line: undefined-field
        local SetMin = PANEL.SetMin

        function PANEL:GWEN_SetMin( min )
            return SetMin( self, tonumber( min, 10 ) )
        end

    end

    do

        ---@diagnostic disable-next-line: undefined-field
        local SetMax = PANEL.SetMax

        function PANEL:GWEN_SetMax( max )
            return SetMax( self, tonumber( max, 10 ) )
        end

    end

end

do

    local align = {
        ["None"] = 0,
        ["Bottom-Left"] = 1,
        ["Bottom"] = 2,
        ["Bottom-Right"] = 3,
        ["Left"] = 4,
        ["Center"] = 5,
        ["Right"] = 6,
        ["Top-Left"] = 7,
        ["Top"] = 8,
        ["Top-Right"] = 9
    }

    local SetContentAlignment = PANEL.SetContentAlignment

    function PANEL:GWEN_SetHorizontalAlign( key )
        return align[ key ] and SetContentAlignment( self, align[ key ] ) or nil
    end

end

do

    local dock = {
        Fill = 1,
        Left = 2,
        Right = 3,
        Top = 4,
        Bottom = 5
    }

    local Dock = PANEL.Dock

    function PANEL:GWEN_SetDock( key )
        return dock[ key ] and Dock( self, dock[ key ] ) or nil
    end

end

do

    local SetText = PANEL.SetText

    function PANEL:GWEN_SetCheckboxText( tbl )
        return SetText( self, tbl )
    end

end
