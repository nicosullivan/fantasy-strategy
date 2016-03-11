local board = require "board"

gamestate = 'playerturn'

local lg = love.graphics

function love.load()
  board:init("resources/map/river.lua")
end

function love.update(dt)
  board:update(dt)
end

function love.draw()
  board:draw()
  lg.reset()
end

function love.keypressed(key, scancode, isrepeat)
  board:keypressed(key, scancode, isrepeat)
end

function love.mousereleased(xm, ym, button, istouch)
  board:click(xm,ym)
end
