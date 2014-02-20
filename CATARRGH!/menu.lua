----------------------------------------------------------------
-- CATARRGH! by Gary Crook for CoronaBlitz #2
-- Using Corona daily build v2014.2178
----------------------------------------------------------------

local composer = require( "composer" )
local scene = composer.newScene()
local fullW = display.contentWidth
local fullH = display.contentHeight
local halfW = math.floor( fullW / 2 )
local halfH = math.floor( fullH / 2 )

local background
local playLabel

local function onEnterFrame( event )
    playLabel:setFillColor( math.random( ), math.random( ), math.random( ) )
end

local function onPlayLabel_Touch( event )
    if event.phase == "ended" then
        media.playEventSound( "soundfx/start.mp3" )
        composer.gotoScene( "game", { effect = "fade", time = 250 } )
    end
end

function scene:create( event )
    local sceneGroup = self.view
    
    background = display.newImageRect( "images/menu.png", 480, 320 )
    background.x = halfW
    background.y = halfH

    playLabel = display.newText( 
        { 
            text = "PLAY", 
            width = 150, 
            x = halfW, 
            y = halfH + 5, 
            font = native.systemFont, 
            fontSize = 45, 
            align = "center" 
        } 
    )

    sceneGroup:insert( background )
    sceneGroup:insert( playLabel )
end

function scene:show( event )
    local sceneGroup = self.view

    Runtime:addEventListener( "enterFrame", onEnterFrame )
    playLabel:addEventListener( "touch", onPlayLabel_Touch )
    media.playSound( "music/CatSong.mp3", true )
end

function scene:hide( event )
    local sceneGroup = self.view

    media.stopSound( )
    playLabel:removeEventListener( "touch", onPlayLabel_Touch )
    Runtime:removeEventListener( "enterFrame", onEnterFrame )
end

function scene:destroy( event )
    local sceneGroup = self.view

    playLabel:removeSelf( )
    playLabel = nil

    background:removeSelf( )
    background = nil
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene
