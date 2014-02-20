----------------------------------------------------------------
-- CATARRGH! by Gary Crook for CoronaBlitz #2
-- Using Corona daily build v2014.2178
----------------------------------------------------------------

local composer = require( "composer" )
local physics = require( "physics" )

local scene = composer.newScene()
local halfW = display.contentCenterX
local halfH = display.contentCenterY
local fullW = display.contentWidth
local fullH = display.contentHeight
local layerPickups = display.newGroup()

local distanceTitleLabel
local distanceValueLabel
local chargeTitleLabel
local chargeValueLabel
local gameOverLabel
local timePrevious = system.getTimer()
local timeLastfoodPickup = 0
local floorTiles = { }
local spikesTiles = { }
local toRemove = { }
local gameMode = 1
local catSheet
local cat
local botSheet
local bot
local botCanShoot = true

local scrollSpeed = 0.1
local scrollSpeedChange = 0.007
local catScale = 1.0
local catScalePrevious = 1.0
local catScaleIncrement = 0.01
local catTimeScaleDecrement = 0.05
local catScaleDie = 2.0
local distanceIncrement = 0.05
local distance = 0
local chargeIncrement = 10 -- percent
local charge = 0
local critical = 0
local foodPickupMinMS = 1000
local foodPickupMaxMS = 2000

-- [ Pre-load sounds ]--
local soundFx = {
    arrgh = audio.loadSound("soundfx/arrgh.mp3"),
    sprintFire = audio.loadSound("soundfx/sprint-fire.mp3"),
    foodPickup = audio.loadSound("soundfx/food-pickup.mp3"),
    explode = audio.loadSound( "soundfx/explode.mp3" )
}

local function onGameLoop( event )
    local timeDelta = event.time - timePrevious
    local xOffset = ( scrollSpeed * timeDelta )
    timePrevious = event.time

    if gameMode == 1 then
        --[ Purge objects ]--
        if #toRemove > 0 then
            for i = 1, #toRemove do
                toRemove[i].parent:remove( toRemove[i] )
                toRemove[i] = nil
            end
        end

        --[ Set charge label colour ]--
        if charge == 100 then chargeValueLabel:setFillColor( math.random( ), math.random( ), math.random( ) ) end

        --[ Make the cat fatter and slower ]--
        if catScalePrevious ~= catScale then
            cat:scale( catScale, catScale )
            cat.timeScale = cat.timeScale - catTimeScaleDecrement
            catScalePrevious = catScale
            transition.to( cat, { time = 150, x = ( cat.x - cat.xScale * 2.5 ) } )
            transition.to( bot, { time = 150, y = ( bot.y - cat.yScale * 2.5 ) } )

            if cat.yScale >= catScaleDie then
                gameMode = 2
            end
        end 

        --[ Move the spikes ]--
        for k, v in pairs( spikesTiles ) do
            v.x = v.x - xOffset
            if ( v.x + ( v.contentWidth ) ) < -64 then
                v:translate( fullW + ( v.contentWidth * 5 ), 0 )
            end
        end

        --[ Move the floor ]--
        for k, v in pairs( floorTiles ) do
            v.x = v.x - xOffset
            if ( v.x + ( v.contentWidth ) ) < -64 then
                v:translate( fullW + ( v.contentWidth * 5 ), 0 )
            end
        end

        --[ Spawn a pickup ]--
        if event.time - timeLastfoodPickup >= math.random( foodPickupMinMS, foodPickupMaxMS ) and botCanShoot then
            local foodPickup = display.newImageRect( "images/foodpickup" .. math.random( 1, 3 ) .. ".png", 32, 32 )
            foodPickup.x = bot.x
            foodPickup.y = bot.y
            physics.addBody(foodPickup, "dynamic", { bounce = 0 } )
            foodPickup.name = "food"
            layerPickups:insert( foodPickup )
            timeLastfoodPickup = event.time
        end
    elseif gameMode == 2 then
        gameMode = 0
        media.stopSound( )
        audio.play( soundFx.arrgh )
        cat:pause( )
        bot:pause( )
        gameOverLabel:setFillColor( 0.0, 0.0, 1.0 )
    end
end

local function onCollision( self, event )
    if gameMode == 1 then
        -- [ Pickup hit cat ]--
        if self.name == "cat" and event.other.name == "food" then
            audio.play( soundFx.foodPickup )
            table.insert( toRemove, event.other )
            charge = charge + chargeIncrement
            catScale = catScale + catScaleIncrement
            scrollSpeed = scrollSpeed - scrollSpeedChange

            if charge >= 100 then
                charge = 100
            else
                chargeValueLabel:setFillColor( 1.0, 0.0, 0.0 )
            end

            chargeValueLabel.text = charge .. "%"
        end
    end
end

local function onBotShootComplete( obj )
    audio.play( soundFx.explode )
    table.insert( toRemove, obj )
    catScale = 1.0
    catScalePrevious = 1.0
    cat.timeScale = 1.0
    scrollSpeed = 0.1
    cat.xScale = 1.0
    cat.yScale = 1.0
    foodPickupMinMS = foodPickupMinMS - 100
    foodPickupMaxMS = foodPickupMaxMS - 100
    cat.x = 5
    cat.y = fullH - 32
    bot.y = cat.y - 30
end

local function onCatSprintComplete( obj )
    catScale = 1.0
    catScalePrevious = 1.0
    cat.timeScale = 1.0
    scrollSpeed = 0.1
    cat.xScale = 1.0
    cat.yScale = 1.0
    distanceIncrement = 0.05
    foodPickupMinMS = foodPickupMinMS - 100
    foodPickupMaxMS = foodPickupMaxMS - 100
    cat.x = 5
    cat.y = fullH - 32
    bot.y = cat.y - 30
    botCanShoot = true
end

local function onCatSprite( event )
    if event.phase == "next" then
        distance = distance + distanceIncrement
        distanceValueLabel.text = math.round( distance ) .. "m"
    end
end

local function onCatTouch( event )
    if event.phase == "ended" then
        if charge == 100 then
            charge = 50
            chargeValueLabel:setFillColor( 1.0, 0.0, 0.0 )
            chargeValueLabel.text = charge .. "%"
            audio.play( soundFx.sprintFire )
            cat.timeScale = 1.75
            scrollSpeed = 0.5
            distanceIncrement = 0.2
            botCanShoot = false
            transition.to( cat, { time = 3000, xScale = 1.0, yScale = 1.0, x = 5 } )
            transition.to( bot, { time = 3000, y = fullH - 62 } )
            timer.performWithDelay( 3000, onCatSprintComplete )
        end
    end
end

local function onBotTouch( event )
    if event.phase == "ended" then
        if charge == 100 then
            charge = 0
            chargeValueLabel:setFillColor( 1.0, 0.0, 0.0 )
            chargeValueLabel.text = charge .. "%"
            local projectile = display.newImageRect( "images/projectile.png", 16, 16 )
            projectile.x = cat.x + 70
            projectile.y = cat.y - 50
            layerPickups:insert( projectile )
            audio.play( soundFx.sprintFire )
            transition.to( projectile, { time = 500, x = bot.x + 16, y = bot.y - 16, onComplete = onBotShootComplete } )
        end
    end
end

function scene:create( event )
    local sceneGroup = self.view

    physics.start( )
    physics.setGravity( -9.8, 0.0 )
    
    --[ GUI ]--
    distanceTitleLabel = display.newText( 
        { 
            text = "Escape Distance:", 
            width = 130, 
            x = 5, 
            y = 5, 
            font = native.systemFont, 
            fontSize = 15, 
            align = "left"
        } 
    )

    distanceTitleLabel.anchorX = 0
    distanceTitleLabel.anchorY = 0

    distanceValueLabel = display.newText( 
        { 
            text = distance .. "m", 
            width = 50, 
            x = 145, 
            y = 5, 
            font = native.systemFont, 
            fontSize = 15, 
            align = "left" 
        } 
    )

    distanceValueLabel.anchorX = 0
    distanceValueLabel.anchorY = 0

    chargeTitleLabel = display.newText( 
        { 
            text = "Food Boost:", 
            width = 130, 
            x = 330, 
            y = 5, 
            font = native.systemFont, 
            fontSize = 15, 
            align = "left"
        } 
    )

    chargeTitleLabel.anchorX = 0
    chargeTitleLabel.anchorY = 0

    chargeValueLabel = display.newText( 
        { 
            text = charge .. "%", 
            width = 50, 
            x = 435, 
            y = 5, 
            font = native.systemFont, 
            fontSize = 15, 
            align = "left" 
        } 
    )

    chargeValueLabel.anchorX = 0
    chargeValueLabel.anchorY = 0
    chargeValueLabel:setFillColor( 1.0, 0.0, 0.0 )

    gameOverLabel = display.newText( 
        { 
            text = "GAME OVER!", 
            width = 200, 
            x = halfW, 
            y = 100, 
            font = native.systemFont, 
            fontSize = 25, 
            align = "center"
        } 
    )

    gameOverLabel:setFillColor( 0.0, 0.0, 0.0 )

    sceneGroup:insert( distanceTitleLabel )
    sceneGroup:insert( distanceValueLabel )
    sceneGroup:insert( chargeTitleLabel )
    sceneGroup:insert( chargeValueLabel )
    sceneGroup:insert( gameOverLabel )

    --[ Spikes ]--
    for i = 1, math.floor( fullW / 32 ) + 5 do
        local spikesTile = display.newImageRect( sceneGroup, "images/spikes.png", 32, 32 )
        spikesTile.anchorX = 0
        spikesTile.anchorY = 0
        spikesTile.x = ( i - 4 ) * 32
        spikesTile.y = fullH - 160
        table.insert( spikesTiles, spikesTile )
    end

    --[ Floor ]--
    for i = 1, math.floor( fullW / 32 ) + 5 do
        local floorTile = display.newImageRect( sceneGroup, "images/ground" .. math.random( 1, 4 ) .. ".png", 32, 32 )
        floorTile.anchorX = 0
        floorTile.anchorY = 0
        floorTile.x = ( i - 4 ) * 32
        floorTile.y = fullH - 32
        table.insert( floorTiles, floorTile )
    end

    --[ Cat ]--
    catSheet = graphics.newImageSheet( "images/catsheet.png", { width = 100, height = 60, numFrames = 6 } )
    cat = display.newSprite( sceneGroup, catSheet, { start = 1, count = 6, time = 500 } )
    cat.anchorX = 0
    cat.anchorY = 1
    cat.x = 5
    cat.y = fullH - 32
    cat.xScale = catScale
    cat.yScale = catScale
    cat.name = "cat"
    physics.addBody( cat, "kinematic", { bounce = 0 } )
    cat.collision = onCollision
    cat:addEventListener( "collision", cat )

    --[ Enemy bot ]--
    botSheet = graphics.newImageSheet( "images/botsheet.png", { width = 32, height = 20, numFrames = 2 } )
    bot = display.newSprite( sceneGroup, botSheet, { start = 1, count = 2, time = 500 } )
    bot.anchorX = 0
    bot.anchorY = 1
    bot.x = fullW - 40
    bot.y = cat.y - 30
    bot.xScale = 1.0
    bot.yScale = 1.0
    bot.name = "bot"
    physics.addBody( bot, "kinematic", { bounce = 0 } )
    bot.collision = onCollision
    bot:addEventListener( "collision", bot )
end

function scene:show( event )
    local sceneGroup = self.view

    cat:play( )
    bot:play( )
    media.playSound( "music/NeverStopRunning8Bit.mp3", true )
    cat:addEventListener( "sprite", onCatSprite )
    cat:addEventListener( "touch", onCatTouch )
    bot:addEventListener( "touch", onBotTouch )
    Runtime:addEventListener( "enterFrame", onGameLoop )
end

function scene:hide( event )
    local sceneGroup = self.view

    cat:pause( )
    bot:pause( )
    media.stopSound( )
    cat:removeEventListener( "sprite", onCatSprite )
    cat:removeEventListener( "touch", onCatTouch )
    bot:removeEventListener( "touch", onBotTouch )
    Runtime:removeEventListener( "enterFrame", onGameLoop )
end

function scene:destroy( event )
    local sceneGroup = self.view

    physics.stop( )

    layerPickups:removeSelf( )
    layerPickups = nil

    distanceTitleLabel:removeSelf( )
    distanceTitleLabel = nil

    distanceValueLabel:removeSelf( )
    distanceValueLabel = nil

    chargeTitleLabel:removeSelf( )
    chargeTitleLabel = nil

    chargeValueLabel:removeSelf( )
    chargeValueLabel = nil

    cat.collision = nil
    cat:removeEventListener( "collision", cat )
    cat:removeSelf( )
    cat = nil
    catSheet = nil

    bot:removeSelf( )
    bot = nil
    botSheet = nil

    spikesTiles = nil
    floorTiles = nil

    toRemove = nil
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene
