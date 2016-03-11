local sti = require "sti"
local unit = require "unit"

local width, height, flags = love.window.getMode()

local board = {}
local map = {}
board.cells = {}          -- create the matrix
board.cursor = {x=1, y=1}         -- repersents the cell currently highlighted
board.origin = {x=1, y=1}         -- repersents the cell currently in the upper right of the screen
board.units = {}
board.menus = {}
board.selected = nil

function board:init(mapPath)
  map = sti.new(mapPath)
  board.width = map.layers.Background.width
  board.height = map.layers.Background.height

  -- Create Board Matrix
  for i = 1, board.width do
    board.cells[i] = {}     -- create a new row
    for j = 1, board.height do
      board.cells[i][j] = {}
    end
  end

  board.cursor.image = love.graphics.newImage("resources/images/ui/cursor.png")
  board.cursor.ismoving = false
  board.cursor.current = {x = 0, y = 0}

  board.margin = {}
  board.margin.x = math.floor((width/64)/2)
  board.margin.y  = math.floor((height/64)/2)

  board.units.enemy = {}
  board.units.enemy[1] = unit:new("bandit", love.graphics.newImage("resources/map/units/sword.png"), {x=4, y=4}, 10, 1, 3, 3)
  board.units.enemy[2] = unit:new("bandit", love.graphics.newImage("resources/map/units/sword.png"), {x=10, y=10}, 10, 1, 3, 3)

  board.menus.unit = {}
  board.menus.action = {}
  board.menus.unit.image = love.graphics.newImage("resources/images/ui/unitinfo.png")
  board.menus.unit.font = love.graphics.newFont(48)
  board.menus.action.image = love.graphics.newImage("resources/images/ui/unitactions.png")
  board.menus.action.font = love.graphics.newFont(64)
  board.menus.action.options = {}
  board.menus.action.options[1] = "move"
  board.menus.action.options[2] = "attack"
  board.menus.action.options[3] = "cancel"
end

function board:draw()

  love.graphics.push()
    love.graphics.translate(-(board.origin.x-1)*64, -(board.origin.y-1)*64)
    map:draw()

    for i = 0, board.width-1 do
      for j = 0, board.height-1 do
        love.graphics.rectangle("line", ((i)*64), ((j)*64), 64, 64)
      end
    end

    -- Draw Units
    -- need to translate here to facilate easier drawing of health and what not.
    for i, e in ipairs(board.units.enemy) do
      e.draw()
    end

    -- Draw Cursor
    love.graphics.draw(board.cursor.image, board.cursor.current.x, board.cursor.current.y)
  love.graphics.pop()

  -- check if cursor is over unit
  for i, e in ipairs(board.units.enemy) do
    if e.location.x == board.cursor.x and e.location.y == board.cursor.y then
      love.graphics.push()
        love.graphics.setColor(255,255,255,255)
        love.graphics.translate(32, height-128-32)
        love.graphics.setFont(board.menus.unit.font)
        love.graphics.draw(board.menus.unit.image, 0, 0)
        love.graphics.print(e.name, 20, 5)
        love.graphics.print("Health:"..e.health, 20, 55)
      love.graphics.pop()
    end
  end

  -- draw action sheet if unit is selected
  if gamestate == 'unitselected' then
    love.graphics.push()
      love.graphics.setColor(255,255,255,255)
      love.graphics.translate(width-256-32, 32)
      love.graphics.setFont(board.menus.action.font)
      love.graphics.draw(board.menus.action.image, 0, 0)
      for i, o in ipairs(board.menus.action.options) do
        love.graphics.print(o, 20, 20+(70*(i-1)))
      end
    love.graphics.pop()
  end
end

function board:update(dt)
  --map:update(dt)
  animateCursor(dt)
end

function animateCursor(dt)
  if board.cursor.ismoving then
    dttotal = dttotal + dt
    if (board.cursor.current.x == (board.cursor.x-1)*64 and board.cursor.current.y == (board.cursor.y-1)*64) or dttotal > .1 then
      board.cursor.ismoving = false
      board.cursor.current.x = (board.cursor.x-1)*64
      board.cursor.current.y = (board.cursor.y-1)*64
    else
      board.cursor.current.x = (board.cursor.oldx-1)*64 + ((board.cursor.x-1)*64 - (board.cursor.oldx-1)*64) * (dttotal*10)
      board.cursor.current.y = (board.cursor.oldy-1)*64 + ((board.cursor.y-1)*64 - (board.cursor.oldy-1)*64) * (dttotal*10)
    end
  end
end

function board:moveto(x, y)
  -- update cursor location
  board.cursor.ismoving = true
  dttotal = 0
  board.cursor.oldx = board.cursor.x
  board.cursor.oldy = board.cursor.y
  board.cursor.x = x
  board.cursor.y = y

  --ensure cursor doesn't go outside of map
  if board.cursor.x > board.width then
    board.cursor.x = board.width
  end

  if board.cursor.y > board.height then
    board.cursor.y = board.height
  end

  -- check bounds to ensure that we always have the screen filled with the map
  if board.cursor.x < board.margin.x then
    board.origin.x = 1
  elseif board.cursor.x > board.width - board.margin.x then
    board.origin.x = (board.width - board.margin.x*2)+1
  else
    board.origin.x = math.floor(board.cursor.x - board.margin.x)+1
  end

  if board.cursor.y < board.margin.y then
    board.origin.y = 1
  elseif board.cursor.y > board.height - board.margin.y then
    board.origin.y = (board.height - board.margin.y*2)+1
  else
    board.origin.y = math.floor(board.cursor.y - board.margin.y)+1
  end
end

function board:click(xm, ym)

  if gamestate == 'playerturn' then
    local xc = math.floor((xm)/64) + board.origin.x
    local yc = math.floor((ym)/64) + board.origin.y
    board:moveto(xc,yc)
  end
end

function board:select(x, y)
  for i, e in ipairs(board.units.enemy) do
    if e.location.x == x and e.location.y == y then
      board.selected = e
    end
  end

  if board.selected then
    gamestate = 'unitselected'
  end
end

function board:deselect()
  board.selected = nil
  gamestate = 'playerturn'
end

function board:keypressed(key, scancode, isrepeat)
  if gamestate == 'playerturn' then
    mapkey(key, scancode, isrepeat)
  elseif gamestate == 'unitselected' then
    menukey(key, scancode, isrepeat)
  end
end

function menukey(key, scancode, isrepeat)
  if key == 'c' then
    board:deselect()
  end
end

function mapkey(key, scancode, isrepeat)
  local x = board.cursor.x
  local y = board.cursor.y

  if key == 'left' and board.cursor.x > 1 then
    x = board.cursor.x - 1
  elseif key == 'right' and board.cursor.x < board.width then
    x = board.cursor.x + 1
  elseif key == 'up' and board.cursor.y > 1 then
    y = board.cursor.y - 1
  elseif key == 'down' and board.cursor.y < board.height then
    y = board.cursor.y + 1
  elseif key == 'space' then
    board:select(x,y)
  end
  board:moveto(x,y)
end

function board:addUnit(unit, x, y)
end

return board
