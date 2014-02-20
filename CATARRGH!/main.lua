----------------------------------------------------------------
-- CATARRGH! by Gary Crook for CoronaBlitz #2
-- Using Corona daily build v2014.2178
----------------------------------------------------------------

display.setStatusBar( display.HiddenStatusBar ) 
display.setDefault( "background", .0, .0, .0 )

local composer = require( "composer" )

math.randomseed( os.time( ) )
composer.gotoScene( "menu", { effect = "fade", time = 250 } )
