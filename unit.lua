local unit = {}

-- Create new unit object
function unit:new(name, img, loc, health, range, move, damage)
  local u = {}

  u.name = name
  u.image = img
  u.location = loc
  u.health = health
  u.range = range
  u.move = move
  u.damage = damage
  u.update = function(dt)end
  u.move = function(x, y)end
  u.attack = function(defender)end
  u.draw = function ()
          love.graphics.draw(u.image, (u.location.x-1)*64-4, (u.location.y-1)*64)
        end

  return u
end

return unit
