include( "glua-patches/globals.lua" )
include( "glua-patches/client-menu-server.lua" )

if SERVER then
    AddCSLuaFile( "glua-patches/client-menu-server.lua" )
    AddCSLuaFile( "glua-patches/client-server.lua" )
    AddCSLuaFile( "glua-patches/client-menu.lua" )
    AddCSLuaFile( "glua-patches/globals.lua" )
end

if CLIENT or MENU then
    include( "glua-patches/client-menu.lua" )
end

if CLIENT or SERVER then
    include( "glua-patches/client-server.lua" )
end

MsgC( SERVER and Color( 50, 100, 250 ) or Color( 250, 100, 50 ), string.format( "[gLua Patches v%s] ", glua_patches.Version ), _G.color_white, table.Random( {
    "Patched!",
    "Here For You ♪",
    "Increasing performance!",
    "Thanks for installation <3",
    "We jump and touch the light ♪",
    "Why we always looking for more? ♪",
    "Sometimes we just need more cache :>",
    "When everything is wrong, we move along ♪",
    "Move along, move along like I know ya do ♪",
    "I'll prevail with every battle if I'm right ♪",
    "Look at where we started and where we will end ♪"
} ) .. "\n" )
