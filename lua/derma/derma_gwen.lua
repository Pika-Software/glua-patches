---@diagnostic disable-next-line: undefined-global
local _G = _G

---@class Panel
local PANEL = _G.FindMetaTable( "Panel" )

---@type IMaterial
---@diagnostic disable-next-line: assign-type-mismatch
local IMaterial = _G.FindMetaTable( "IMaterial" )
local IMaterial_IsError = IMaterial.IsError

local surface_SetDrawColor, surface_SetMaterial, surface_DrawTexturedRectUV = surface.SetDrawColor, surface.SetMaterial, surface.DrawTexturedRectUV
local math_min, math_ceil, math_floor = math.min, math.ceil, math.floor

---@class GWEN
local GWEN = {}

---@diagnostic disable-next-line: inject-field
_G.GWEN = GWEN

function GWEN.CreateTextureBorder( x_offset, y_offset, width_offset, height_offset, l, t, r, b, material )
    if material == nil or IMaterial_IsError( material ) then
        ---@diagnostic disable-next-line: undefined-field
        local skin = _G.SKIN
        if skin ~= nil then
            local gwen_material = skin.GwenTexture
            if gwen_material ~= nil then
                material = gwen_material
            end
        end
    end

    local texture = material:GetTexture( "$basetexture" )
    local texture_width, texture_height = texture:Width(), texture:Height()

    width_offset, height_offset = width_offset / texture_width, height_offset / texture_height

    local startU = x_offset / texture_width
    local startV = y_offset / texture_height

    local left, right, top, bottom = 0, 0, 0, 0

    local left_offset, right_offset = 0, 0
    local top_offset, bottom_offset = 0, 0

    local horizontal_width, vertical_height = 0, 0

    local endU, endU2, endU3 = 0, 0, 0
    local endV, endV2, endV3 = 0, 0, 0

    return function( x, y, w, h, color )
        if color == nil then
            surface_SetDrawColor( 255, 255, 255, 255 )
        else
            surface_SetDrawColor( color.r, color.g, color.b, color.a )
        end

        surface_SetMaterial( material )

        left = math_min( l, math_ceil( w * 0.5 ) )
        right = math_min( r, math_floor( w * 0.5 ) )

        top = math_min( t, math_ceil( h * 0.5 ) )
        bottom = math_min( b, math_floor( h * 0.5 ) )

        left_offset = x + left
        right_offset = x + ( w - right )

        top_offset = y + top
        bottom_offset = y + ( h - bottom )

        horizontal_width = w - ( left + right )
        vertical_height = h - ( top + bottom )

        endU = startU + ( left / texture_width )
        endV = startV + ( top / texture_height )

        endU2 = startU + width_offset
        endU3 = endU2 - ( right / texture_width )

        endV2 = startV + height_offset
        endV3 = endV2 - ( bottom / texture_height )

        surface_DrawTexturedRectUV( x, y, left, top, startU, startV, endU, endV )

        surface_DrawTexturedRectUV( left_offset, y, horizontal_width, top, endU, startV, endU3, endV )
        surface_DrawTexturedRectUV( right_offset, y, right, top, endU3, startV, endU2, endV )

        surface_DrawTexturedRectUV( x, top_offset, left, vertical_height, startU, endV, endU, endV3 )

        surface_DrawTexturedRectUV( left_offset, top_offset, horizontal_width, vertical_height, endU, endV, endU3, endV3 )
        surface_DrawTexturedRectUV( right_offset, top_offset, right, vertical_height, endU3, endV, endU2, endV3 )

        surface_DrawTexturedRectUV( x, bottom_offset, left, bottom, startU, endV3, endU, endV2 )

        surface_DrawTexturedRectUV( left_offset, bottom_offset, horizontal_width, bottom, endU, endV3, endU3, endV2 )
        surface_DrawTexturedRectUV( right_offset, bottom_offset, right, bottom, endU3, endV3, endU2, endV2 )
    end
end

function GWEN.CreateTextureNormal( x_offset, y_offset, width_offset, height_offset, material )
    if material == nil or IMaterial_IsError( material ) then
        ---@diagnostic disable-next-line: undefined-field
        local skin = _G.SKIN
        if skin ~= nil then
            local gwen_material = skin.GwenTexture
            if gwen_material ~= nil then
                material = gwen_material
            end
        end
    end

    local texture = material:GetTexture( "$basetexture" )
    local texture_width, texture_height = texture:Width(), texture:Height()

    local startU = x_offset / texture_width
    local endU = startU + ( width_offset / texture_width )

    local startV = y_offset / texture_height
    local endV = startV + ( height_offset / texture_height )

    return function( x, y, w, h, color )
        if color == nil then
            surface_SetDrawColor( 255, 255, 255, 255 )
        else
            surface_SetDrawColor( color.r, color.g, color.b, color.a )
        end

        surface_SetMaterial( material )
        surface_DrawTexturedRectUV( x, y, w, h, startU, startV, endU, endV )
    end

end

function GWEN.CreateTextureCentered( x_offset, y_offset, width_offset, height_offset, material )
    if material == nil or IMaterial_IsError( material ) then
        ---@diagnostic disable-next-line: undefined-field
        local skin = _G.SKIN
        if skin ~= nil then
            local gwen_material = skin.GwenTexture
            if gwen_material ~= nil then
                material = gwen_material
            end
        end
    end

    local texture = material:GetTexture( "$basetexture" )
    local texture_width, texture_height = texture:Width(), texture:Height()

    local startU = x_offset / texture_width
    local endU = startU + ( width_offset / texture_width )

    local startV = y_offset / texture_height
    local endV = startV + ( height_offset / texture_height )

    return function( x, y, w, h, color )
        if color == nil then
            surface_SetDrawColor( 255, 255, 255, 255 )
        else
            surface_SetDrawColor( color.r, color.g, color.b, color.a )
        end

        surface_SetMaterial( material )
        surface_DrawTexturedRectUV( x + ( w - width_offset ) * 0.5, y + ( h - height_offset ) * 0.5, width_offset, height_offset, startU, startV, endU, endV )
    end

end

do

    local IMaterial_GetColor = IMaterial.GetColor

    function GWEN.TextureColor( x, y, material )
        if material == nil or IMaterial_IsError( material ) then
            ---@diagnostic disable-next-line: undefined-field
            local skin = _G.SKIN
            if skin ~= nil then
                local gwen_material = skin.GwenTexture
                if gwen_material ~= nil then
                    material = gwen_material
                end
            end
        end

        return IMaterial_GetColor( material, x, y )
    end

end

do

    local Panel_SetMultiline, Panel_Add = PANEL.SetMultiline, PANEL.Add
    local pairs = _G.pairs

    local classes = {
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
            Panel_SetMultiline( self, true )
        end

        for key, value in pairs( tbl.Properties ) do
            if self[ "GWEN_Set" .. key ] ~= nil then
                self[ "GWEN_Set" .. key ]( self, value )
            end
        end

        if tbl.Children ~= nil then
            for _, value in pairs( tbl.Children ) do
                local class_name = classes[ value.Type ]
                if class_name == nil then
                    MsgN( "Warning: No GWEN Panel Type ", value.Type )
                else
                    applyGWEN( Panel_Add( self, class_name ), value )
                end
            end
        end
    end

    PANEL.ApplyGWEN = applyGWEN

    local function loadGWENString( self, json )
        local tbl = util.JSONToTable( json )
        if tbl ~= nil then
            local controls = tbl.Controls
            if controls ~= nil then
                return applyGWEN( self, controls )
            end
        end

        return nil
    end

    PANEL.LoadGWENString = loadGWENString

    function PANEL:LoadGWENFile( filePath, gamePath )
        local json = file.Read( filePath, gamePath or "GAME" )
        if json ~= nil then
            return loadGWENString( self, json )
        end

        return nil
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

PANEL.GWEN_SetText = PANEL.SetText
PANEL.GWEN_SetControlName = PANEL.SetName

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
        local uint_value = align[ key ]
        if uint_value ~= nil then
            SetContentAlignment( self, uint_value )
        end
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
        local uint_value = dock[ key ]
        if uint_value ~= nil then
            Dock( self, uint_value )
        end
    end

end

PANEL.GWEN_SetCheckboxText = PANEL.SetText
